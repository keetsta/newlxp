import Foundation
import SwiftUI
import Combine

@MainActor
final class AppStore: ObservableObject {
    static let shared = AppStore()

    // Auth
    @Published var isAuthenticated: Bool = TokenStore.accessToken?.isEmpty == false
    @Published var authError: String?
    @Published var isAuthLoading: Bool = false

    // Profile
    @Published var profile: Profile = MockData.profile

    // Schedule
    @Published var lessonsByDay: [Date: [Lesson]] = [:]
    @Published var loadedRanges: [DateInterval] = []
    @Published var isScheduleLoading: Bool = false

    // Disciplines
    @Published var disciplines: [Discipline] = MockData.disciplines
    @Published var disciplineDetails: [String: DisciplineDetail] = [:]
    @Published var topicDetails: [String: TopicDetail] = [:]

    // Assignments
    @Published var assignments: [Assignment] = MockData.assignments

    // Last load error to surface in UI / debug
    @Published var lastError: String?

    var assignmentsCount: Int { assignments.count }
    var disciplinesCount: Int { activeDisciplines.count }

    var fullName: String {
        [profile.lastName, profile.firstName, profile.middleName]
            .filter { !$0.isEmpty }.joined(separator: " ")
    }

    private init() {
        hydrateFromCache()
    }

    private func hydrateFromCache() {
        if let p = DiskCache.load(.profile, as: Profile.self) { self.profile = p }
        if let d = DiskCache.load(.disciplines, as: [Discipline].self) { self.disciplines = d }
        if let a = DiskCache.load(.assignments, as: [Assignment].self) { self.assignments = a }
        if let l = DiskCache.load(.lessonsByDay, as: [Date: [Lesson]].self) { self.lessonsByDay = l }
        if let r = DiskCache.load(.loadedRanges, as: [DateInterval].self) { self.loadedRanges = r }
        if let dd = DiskCache.load(.disciplineDetails, as: [String: DisciplineDetail].self) {
            // Миграции старого кэша:
            //  • до scoreForAnsweredTasks — `maxScoreForAnsweredTasks == 0` у всех
            //  • до chapter в Topic — у тем нет `chapterName`
            // В обоих случаях сбрасываем кэш, чтобы при следующем заходе в
            // дисциплину он перекачался свежим.
            let hasScores = dd.values.contains { $0.maxScoreForAnsweredTasks > 0 }
            let hasChapters = dd.values.contains { d in
                d.topics.contains { $0.chapterName?.isEmpty == false }
            }
            if hasScores && hasChapters {
                self.disciplineDetails = dd
            } else {
                DiskCache.save(.disciplineDetails, [String: DisciplineDetail]())
            }
        }
        if let td = DiskCache.load(.topicDetails, as: [String: TopicDetail].self) {
            self.topicDetails = td
        }
    }

    // MARK: - Lessons

    func lessons(on date: Date) -> [Lesson] {
        let key = Calendar.current.startOfDay(for: date)
        return lessonsByDay[key] ?? []
    }

    var todayLessons: [Lesson] { lessons(on: Date()) }

    var currentLesson: Lesson? {
        let now = Date()
        return todayLessons.first { $0.start <= now && $0.end >= now }
    }

    var nextLesson: Lesson? {
        let now = Date()
        return todayLessons.first { $0.start > now }
    }

    var nearestDeadline: Assignment? {
        assignments
            .filter { $0.status == .open }
            .sorted { $0.deadline < $1.deadline }
            .first
    }

    /// All past lessons, including ones without an explicit attendance verdict.
    var pastLessons: [Lesson] {
        let now = Date()
        return lessonsByDay.values.flatMap { $0 }
            .filter { $0.end <= now && $0.attendance != .scheduled }
            .sorted { $0.start > $1.start }
    }

    // MARK: - Attendance metrics

    struct AttendanceMetric {
        let totalHours: Double
        let missedHours: Double
        var attendedHours: Double { max(0, totalHours - missedHours) }
        var rate: Double { totalHours > 0 ? attendedHours / totalHours : 0 }
    }

    // MARK: - Score metrics

    /// Баллы по дисциплине, как считает ITHub. На сайте показывается «X из Y / Z»:
    /// - `earned` — заработано (X)
    /// - `assigned` — сумма maxScore тем с уже выставленными баллами (Y)
    /// - `maxScore` — нормировка дисциплины (Z), обычно 100
    /// Оценка 2-5 идёт по `earned/assigned`, а не по `earned/maxScore` —
    /// это ключевой момент.
    struct ScoreMetric {
        let earned: Double
        let assigned: Double
        let maxScore: Double

        /// Доля «оцененного» — основа для оценки 2-5.
        var rate: Double { assigned > 0 ? earned / assigned : 0 }
        /// Доля от полной нормировки — сколько уже набрано «из 100».
        var fullRate: Double { maxScore > 0 ? earned / maxScore : 0 }

        /// Шкала ITHub: <50% → 2, <70% → 3, <90% → 4, ≥90% → 5.
        var grade: Int? {
            guard assigned > 0 else { return nil }
            let r = rate
            if r >= 0.90 { return 5 }
            if r >= 0.70 { return 4 }
            if r >= 0.50 { return 3 }
            return 2
        }
    }

    func scores(disciplineId: String) -> ScoreMetric? {
        guard let detail = disciplineDetails[disciplineId] else { return nil }
        // На сайте ITHub числитель и знаменатель оценки приходят отдельными
        // полями `scoreForAnsweredTasks` / `maxScoreForAnsweredTasks` —
        // сервер сам решает, что считать «выставленным», и считает корректно
        // во всех краевых случаях (бонусные баллы, дубли тем через learning
        // paths, разные способы оценивания). Доверяем серверу, не пересчитываем
        // вручную из topics.
        let earned = detail.scoreForAnsweredTasks
        let assigned = detail.maxScoreForAnsweredTasks
        let normalized = detail.discipline.maxScore
        let maxScore = normalized > 0 ? normalized : assigned
        if assigned == 0 && maxScore == 0 { return nil }
        return ScoreMetric(earned: earned, assigned: assigned, maxScore: maxScore)
    }

    /// Aggregate attendance over a date interval. Only `.absent` counts as missed.
    /// Lessons without a verdict (no mark) are excluded from the denominator.
    func attendance(in range: ClosedRange<Date>) -> AttendanceMetric {
        var total: Double = 0
        var missed: Double = 0
        for (_, list) in lessonsByDay {
            for l in list where l.start >= range.lowerBound && l.start <= range.upperBound {
                guard l.attendance.hasVerdict else { continue }
                let hours = l.end.timeIntervalSince(l.start) / 3600.0
                total += hours
                if l.attendance == .absent { missed += hours }
            }
        }
        return AttendanceMetric(totalHours: total, missedHours: missed)
    }

    /// Текущая календарная неделя: с понедельника по сегодня включительно.
    /// На утро понедельника, до первой пары, метрика будет пустой — это ожидаемо.
    func weekAttendance(reference: Date = Date()) -> AttendanceMetric {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Monday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: reference)
        let weekStart = cal.date(from: comps)!
        let now = reference
        // Окно: [пн 00:00 ... сейчас]. Берём именно сейчас, чтобы не считать
        // ещё не прошедшие пары.
        return attendance(in: weekStart...now)
    }

    /// Посещаемость для произвольной недели: пн → вс относительно `anchor`.
    /// Для прошлых недель окно полное, для текущей — обрезается «до сейчас»,
    /// чтобы не считать ещё не прошедшие пары.
    func weekAttendance(forAnchor anchor: Date) -> AttendanceMetric {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Monday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: anchor)
        let weekStart = cal.date(from: comps)!
        let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart)!
        let upper = min(weekEnd, Date())
        guard upper >= weekStart else {
            return AttendanceMetric(totalHours: 0, missedHours: 0)
        }
        return attendance(in: weekStart...upper)
    }

    /// Текущий календарный месяц: с 1-го числа по сегодня включительно.
    func monthAttendance(reference: Date = Date()) -> AttendanceMetric {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: reference)
        let monthStart = cal.date(from: comps)!
        return attendance(in: monthStart...reference)
    }

    /// Attendance for one discipline within a date interval (past lessons only).
    func attendanceFor(disciplineTitle: String, in range: ClosedRange<Date>) -> AttendanceMetric {
        var total: Double = 0
        var missed: Double = 0
        let now = Date()
        for (_, list) in lessonsByDay {
            for l in list where l.discipline == disciplineTitle
                && l.start >= range.lowerBound && l.start <= range.upperBound
                && l.end <= now && l.attendance.hasVerdict {
                let hours = l.end.timeIntervalSince(l.start) / 3600.0
                total += hours
                if l.attendance == .absent { missed += hours }
            }
        }
        return AttendanceMetric(totalHours: total, missedHours: missed)
    }

    /// Attendance for one discipline across all loaded lessons (past only).
    func attendanceFor(disciplineTitle: String) -> AttendanceMetric {
        let now = Date()
        return attendanceFor(disciplineTitle: disciplineTitle, in: Date.distantPast...now)
    }

    // MARK: - Digest

    var dailyDigest: Digest {
        let cal = Calendar.current
        var events: [DigestEvent] = []
        let today = todayLessons
        let now = Date()

        let upcoming = today.first { $0.start > now }
        if let u = upcoming {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            formatter.locale = Locale(identifier: "ru_RU")
            events.append(DigestEvent(
                symbol: "clock",
                tint: .blue,
                title: "Ближайшая пара в \(formatter.string(from: u.start))",
                detail: "\(u.discipline) · \(u.location)",
                topicId: u.topicId,
                lessonId: u.id
            ))
        }

        let openDeadlines = assignments
            .filter { $0.status == .open }
            .sorted { $0.deadline < $1.deadline }
        for a in openDeadlines.prefix(3) {
            let days = cal.dateComponents([.day], from: cal.startOfDay(for: now), to: cal.startOfDay(for: a.deadline)).day ?? 0
            let detail: String = {
                if days < 0 { return "Просрочено · \(a.discipline)" }
                if days == 0 { return "Срок сегодня · \(a.discipline)" }
                if days == 1 { return "Срок завтра · \(a.discipline)" }
                return "Через \(days) дн. · \(a.discipline)"
            }()
            let tint: Color = days <= 0 ? .red : (days <= 2 ? .orange : .secondary)
            events.append(DigestEvent(
                symbol: "clock.badge.exclamationmark.fill",
                tint: tint,
                title: a.title,
                detail: detail,
                topicId: a.topicId,
                assignmentId: a.id
            ))
        }

        let overdue = assignments.filter { $0.status == .overdue }
        if !overdue.isEmpty {
            events.append(DigestEvent(
                symbol: "exclamationmark.triangle.fill",
                tint: .red,
                title: "Просроченных заданий: \(overdue.count)",
                detail: overdue.prefix(2).map(\.title).joined(separator: ", ")
            ))
        }

        if !today.isEmpty {
            let first = today.first!
            let last = today.last!
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            events.append(DigestEvent(
                symbol: "calendar",
                tint: .secondary,
                title: "\(today.count) \(RussianPlural.pairs(today.count)) сегодня",
                detail: "\(f.string(from: first.start))–\(f.string(from: last.end))"
            ))
        }

        let wa = weekAttendance()
        if wa.totalHours > 0 {
            let pct = Int((wa.rate * 100).rounded())
            let tint: Color = pct >= 90 ? .green : (pct >= 75 ? .yellow : .red)
            events.append(DigestEvent(
                symbol: "chart.bar.fill",
                tint: tint,
                title: "Посещаемость за неделю \(pct)%",
                detail: "Пропущено \(formatHours(wa.missedHours)) ч"
            ))
        }

        let oneLine = makeOneLine(today: today, deadline: openDeadlines.first)
        return Digest(date: cal.startOfDay(for: now), oneLine: oneLine, events: events)
    }

    private func makeOneLine(today: [Lesson], deadline: Assignment?) -> String {
        var parts: [String] = []
        if today.isEmpty {
            parts.append("Сегодня пар нет")
        } else {
            parts.append("\(today.count) \(RussianPlural.pairs(today.count)) сегодня")
        }
        if let d = deadline {
            let f = DateFormatter()
            f.locale = Locale(identifier: "ru_RU")
            f.dateFormat = "HH:mm"
            let cal = Calendar.current
            let days = cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: d.deadline)).day ?? 0
            if days < 0 { parts.append("просрочено: \(d.title)") }
            else if days == 0 { parts.append("дедлайн в \(f.string(from: d.deadline)): \(d.title)") }
            else if days == 1 { parts.append("дедлайн завтра: \(d.title)") }
            else { parts.append("ближайший дедлайн через \(days) дн.") }
        }
        return parts.joined(separator: ", ")
    }

    private func formatHours(_ h: Double) -> String {
        if h.rounded() == h { return String(Int(h)) }
        return String(format: "%.1f", h)
    }

    // MARK: - Loading

    func bootstrap() async {
        guard isAuthenticated else { return }
        await refreshAll()
    }

    func refreshAll() async {
        let cal = Calendar.current
        let from = cal.date(byAdding: .day, value: -30, to: cal.startOfDay(for: Date()))!
        let to = cal.date(byAdding: .day, value: 21, to: cal.startOfDay(for: Date()))!

        // Если studentId уже известен (из прошлого запуска), запускаем всё параллельно
        // включая профиль — не блокируем дисциплины ожиданием профиля.
        if let studentId = TokenStore.studentId, !studentId.isEmpty {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadProfile() }
                group.addTask { await self.loadSchedule(studentId: studentId, from: from, to: to) }
                group.addTask { await self.loadDisciplines(studentId: studentId) }
                group.addTask { await self.loadAssignments(studentId: studentId) }
                await group.waitForAll()
            }
            return
        }

        // Первый запуск: сначала получим studentId через профиль.
        await loadProfile()
        guard let studentId = TokenStore.studentId, !studentId.isEmpty else {
            LXPLog.debug("[LXP] refreshAll: no studentId after loadProfile, skipping the rest")
            return
        }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadSchedule(studentId: studentId, from: from, to: to) }
            group.addTask { await self.loadDisciplines(studentId: studentId) }
            group.addTask { await self.loadAssignments(studentId: studentId) }
            await group.waitForAll()
        }
    }

    func loadProfile() async {
        do {
            let me = try await ProfileRepository.fetchMe()
            self.profile = me.profile
            TokenStore.userId = me.userId
            TokenStore.studentId = me.studentId
            DiskCache.save(.profile, me.profile)
            LXPLog.debug("[LXP] loadProfile OK studentId=\(me.studentId ?? "nil") mates=\(me.profile.groupMates.count)")
        } catch {
            self.lastError = error.localizedDescription
            LXPLog.debug("[LXP] loadProfile FAIL \(error)")
        }
    }

    func loadSchedule(studentId: String, from: Date, to: Date) async {
        let interval = DateInterval(start: from, end: to)
        if loadedRanges.contains(where: { $0.start <= interval.start && $0.end >= interval.end }) {
            return
        }
        isScheduleLoading = true
        defer { isScheduleLoading = false }
        do {
            let lessons = try await ScheduleRepository.lessons(studentId: studentId, from: from, to: to)
            var bucket = self.lessonsByDay
            let cal = Calendar.current
            var day = cal.startOfDay(for: from)
            let endDay = cal.startOfDay(for: to)
            while day <= endDay {
                bucket[day] = []
                day = cal.date(byAdding: .day, value: 1, to: day)!
            }
            for l in lessons {
                let d = cal.startOfDay(for: l.start)
                bucket[d, default: []].append(l)
            }
            self.lessonsByDay = bucket
            self.loadedRanges.append(interval)
            DiskCache.save(.lessonsByDay, self.lessonsByDay)
            DiskCache.save(.loadedRanges, self.loadedRanges)
            LXPLog.debug("[LXP] loadSchedule OK \(lessons.count) lessons in \(from)..\(to)")
        } catch {
            self.lastError = error.localizedDescription
            LXPLog.debug("[LXP] loadSchedule FAIL \(error)")
        }
    }

    func ensureScheduleAround(_ date: Date) async {
        guard let studentId = TokenStore.studentId, !studentId.isEmpty else { return }
        let cal = Calendar.current
        let from = cal.date(byAdding: .day, value: -14, to: cal.startOfDay(for: date))!
        let to = cal.date(byAdding: .day, value: 14, to: cal.startOfDay(for: date))!
        await loadSchedule(studentId: studentId, from: from, to: to)
    }

    /// Ensure that lessons for the past `days` are loaded, anchored at today.
    func ensurePastSchedule(days: Int) async {
        guard let studentId = TokenStore.studentId, !studentId.isEmpty else { return }
        let cal = Calendar.current
        let from = cal.date(byAdding: .day, value: -days, to: cal.startOfDay(for: Date()))!
        let to = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date()))!
        await loadSchedule(studentId: studentId, from: from, to: to)
    }

    /// Активные дисциплины — те, у которых в загруженном расписании есть
    /// **3 и более пар**. Сервер `studentDisciplinesThroughClassesWithPagination`
    /// возвращает все записи, к которым студент когда-либо был привязан, в т.ч.
    /// артефакты вроде разовой замены (например, «Английский A2», у которого
    /// в окне всего 1 пара 26 мая — реальный курс это «Английский B1» с 30
    /// парами). Порог 3 надёжно отсекает такие single-shot записи, не задевая
    /// курсы текущего семестра, у которых пары уже закончились (минимум 5-8 пар).
    /// Фолбэк на полный список — если расписание ещё не подгрузилось.
    var activeDisciplines: [Discipline] {
        var counts: [String: Int] = [:]
        for (_, lessons) in lessonsByDay {
            for l in lessons {
                counts[l.discipline, default: 0] += 1
            }
        }
        guard !counts.isEmpty else { return disciplines }
        return disciplines.filter { (counts[$0.title] ?? 0) >= 3 }
    }

    func loadDisciplines(studentId: String) async {
        do {
            let list = try await DisciplinesRepository.list(studentId: studentId)
            // Сервер возвращает разные «инстансы» одной дисциплины (разные семестры/группы)
            // как отдельные записи с одинаковым name. Склеиваем их, суммируя часы.
            // `maxScore` берём максимальный среди инстансов — это нормировка дисциплины
            // (обычно 100, иногда 80/70). Суммировать его нельзя.
            var byTitle: [String: Discipline] = [:]
            var order: [String] = []
            for d in list {
                if let existing = byTitle[d.title] {
                    byTitle[d.title] = Discipline(
                        id: existing.id,
                        title: existing.title,
                        code: existing.code ?? d.code,
                        totalHours: existing.totalHours + d.totalHours,
                        maxScore: max(existing.maxScore, d.maxScore)
                    )
                } else {
                    byTitle[d.title] = d
                    order.append(d.title)
                }
            }
            self.disciplines = order.compactMap { byTitle[$0] }
            DiskCache.save(.disciplines, self.disciplines)
            LXPLog.debug("[LXP] loadDisciplines OK \(list.count) raw → \(self.disciplines.count) unique")
        } catch {
            self.lastError = error.localizedDescription
            LXPLog.debug("[LXP] loadDisciplines FAIL \(error)")
        }
    }

    func loadDisciplineDetail(disciplineId: String) async {
        guard let studentId = TokenStore.studentId, !studentId.isEmpty else { return }
        do {
            let d = try await DisciplinesRepository.detail(studentId: studentId, disciplineId: disciplineId)
            self.disciplineDetails[disciplineId] = d
            DiskCache.save(.disciplineDetails, self.disciplineDetails)
            LXPLog.debug("[LXP] loadDisciplineDetail OK \(disciplineId) topics=\(d.topics.count)")
        } catch {
            self.lastError = error.localizedDescription
            LXPLog.debug("[LXP] loadDisciplineDetail FAIL \(error)")
        }
    }

    /// Параллельно подгружает детали для всех известных дисциплин, чтобы корректно
    /// посчитать сводные баллы. Уже закэшированные пропускаем. Архивные/неактивные
    /// (нет пар в окне) тоже пропускаем — они не нужны для оценок этого семестра.
    func loadAllDisciplineDetails() async {
        guard let studentId = TokenStore.studentId, !studentId.isEmpty else { return }
        let toLoad = activeDisciplines.filter { disciplineDetails[$0.id] == nil }
        guard !toLoad.isEmpty else { return }
        await withTaskGroup(of: Void.self) { group in
            for d in toLoad {
                group.addTask { await self.loadDisciplineDetail(disciplineId: d.id) }
            }
            await group.waitForAll()
        }
    }

    func loadTopicDetail(topicId: String) async {
        guard let studentId = TokenStore.studentId, !studentId.isEmpty else { return }
        do {
            let t = try await TopicRepository.detail(studentId: studentId, topicId: topicId)
            self.topicDetails[topicId] = t
            DiskCache.save(.topicDetails, self.topicDetails)
            LXPLog.debug("[LXP] loadTopicDetail OK \(topicId) blocks=\(t.blocks.count)")
        } catch {
            self.lastError = error.localizedDescription
            LXPLog.debug("[LXP] loadTopicDetail FAIL \(error)")
        }
    }

    func loadAssignments(studentId: String) async {
        do {
            let list = try await TasksRepository.availableTasks(studentId: studentId)
            self.assignments = list
            DiskCache.save(.assignments, list)
            LXPLog.debug("[LXP] loadAssignments OK \(list.count)")
        } catch {
            self.lastError = error.localizedDescription
            LXPLog.debug("[LXP] loadAssignments FAIL \(error)")
        }
    }

    // MARK: - Sign in / out

    func signIn(email: String, password: String) async {
        isAuthLoading = true
        authError = nil
        defer { isAuthLoading = false }
        do {
            let r = try await AuthRepository.signIn(email: email, password: password)
            TokenStore.accessToken = r.accessToken
            TokenStore.refreshToken = r.refreshToken
            TokenStore.userId = r.userId
            LXPLog.debug("[LXP] signIn OK userId=\(r.userId)")
            self.isAuthenticated = true
            await self.refreshAll()
        } catch {
            self.authError = error.localizedDescription
            LXPLog.debug("[LXP] signIn FAIL \(error)")
        }
    }

    func signOut() {
        TokenStore.clear()
        DiskCache.clearAll()
        isAuthenticated = false
        profile = MockData.profile
        lessonsByDay = [:]
        loadedRanges = []
        disciplines = MockData.disciplines
        disciplineDetails = [:]
        topicDetails = [:]
        assignments = MockData.assignments
        lastError = nil
    }
}
