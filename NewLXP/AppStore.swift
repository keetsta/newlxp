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
    /// Идущие сейчас загрузки расписания — чтобы parallel `loadSchedule` за тот же
    /// диапазон ждали один сетевой запрос вместо дублирования.
    private var inflightSchedule: [DateInterval: Task<Void, Never>] = [:]

    // Disciplines
    @Published var disciplines: [Discipline] = MockData.disciplines
    @Published var disciplineDetails: [String: DisciplineDetail] = [:]
    @Published var topicDetails: [String: TopicDetail] = [:]

    // Assignments
    @Published var assignments: [Assignment] = MockData.assignments

    /// Ответы студента по блоку задания/КТ. Ключ — `contentBlockId`.
    @Published var answersByBlock: [String: [StudentTaskAnswer]] = [:]

    // Last load error to surface in UI / debug
    @Published var lastError: String?

    /// Время последнего успешного запуска `refreshAll`. Используется, чтобы при
    /// возврате из фона не дёргать сеть слишком часто (флип экрана/нотификации).
    private var lastRefreshAt: Date?

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
            .filter { $0.status == .open && $0.deadline < Date.distantFuture.addingTimeInterval(-1) }
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
            .filter { $0.status == .open && $0.deadline < Date.distantFuture.addingTimeInterval(-1) }
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

    /// Обработка ошибки фоновой загрузки. Пишем в лог (DEBUG) — но `lastError`
    /// и баннер НЕ дёргаем. У фоновых load* всё равно есть кэш + скелетоны;
    /// баннер «не удалось обновить» выскакивающий на каждый чих сети только
    /// мешает. Баннер оставляем для пользовательских действий, где явный
    /// провал важно показать (submit/delete ответа, signIn).
    private func recordSilent(_ error: Error, op: String) {
        if LXPError.isCancellation(error) { return }
        LXPLog.debug("[LXP] \(op) FAIL \(error)")
    }

    /// Обработка ошибки пользовательского действия — наоборот, должна ярко
    /// показаться через `ErrorBanner`.
    private func recordUserAction(_ error: Error, op: String) {
        if LXPError.isCancellation(error) { return }
        LXPLog.debug("[LXP] \(op) FAIL \(error)")
        self.lastError = error.localizedDescription
    }

    func bootstrap() async {
        guard isAuthenticated else { return }
        await refreshAll()
    }

    /// Вызывается из `NewLXPApp` при возврате приложения в `.active`. Чтобы не
    /// бить сеть на каждом мелком флипе сцены (Control Center, шторка
    /// уведомлений, переключение задач), пропускаем рефреш, если прошлый был
    /// меньше 30 секунд назад.
    func refreshIfStale() async {
        guard isAuthenticated else { return }
        if let last = lastRefreshAt, Date().timeIntervalSince(last) < 30 { return }
        await refreshAll()
    }

    func refreshAll() async {
        let cal = Calendar.current
        let from = cal.date(byAdding: .day, value: -30, to: cal.startOfDay(for: Date()))!
        let to = cal.date(byAdding: .day, value: 21, to: cal.startOfDay(for: Date()))!

        // На каждом старте сбрасываем «уже загруженные» диапазоны — иначе
        // отметки посещаемости, выставленные после прошлой загрузки, не
        // подтягиваются (ScheduleView показывает старые статусы из кэша).
        // Сами уроки в `lessonsByDay` остаются для тёплого старта; новый
        // ответ сервера их перезапишет.
        self.loadedRanges = []
        DiskCache.save(.loadedRanges, self.loadedRanges)

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
            // После загрузки списка дисциплин — обновляем детали (баллы/темы)
            // тоже на каждом старте. Иначе `disciplineDetails` хранится с
            // прошлого запуска: преподаватель ставит баллы, юзер открывает
            // приложение, а оценка прежняя из кэша.
            await self.refreshAllDisciplineDetails()
            self.lastRefreshAt = Date()
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
        await self.refreshAllDisciplineDetails()
        self.lastRefreshAt = Date()
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
            recordSilent(error, op: "loadProfile")
        }
    }

    func loadSchedule(studentId: String, from: Date, to: Date) async {
        let interval = DateInterval(start: from, end: to)
        if loadedRanges.contains(where: { $0.start <= interval.start && $0.end >= interval.end }) {
            return
        }
        // Если запрос за тот же интервал уже идёт — переиспользуем его, а не
        // дёргаем сеть второй раз. Иначе при холодном старте `refreshAll` и
        // `ScheduleView.task` могут одновременно стартовать одинаковые загрузки.
        if let task = inflightSchedule[interval] {
            await task.value
            return
        }
        isScheduleLoading = true
        let task = Task<Void, Never> {
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
                self.recordSilent(error, op: "loadSchedule")
            }
        }
        inflightSchedule[interval] = task
        await task.value
        inflightSchedule[interval] = nil
        isScheduleLoading = !inflightSchedule.isEmpty
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

    /// Активные дисциплины. Сервер `studentDisciplinesThroughClassesWithPagination`
    /// возвращает всё, к чему студент когда-либо был привязан, в т.ч. архивы
    /// прошлых семестров (без `archivedAt`) и разовые замены, у которых в окне
    /// всего 1-2 пары (классика — «Английский A2», у которого 1 пара 26 мая,
    /// а реальный курс — «Английский B1»).
    ///
    /// Считаем дисциплину активной если:
    ///  • у неё есть будущая пара (включая сегодня), ИЛИ
    ///  • у неё ≥3 пар за последние 30 дней.
    /// Первый критерий ловит курсы текущего семестра, второй — те, что
    /// только что завершились (последние пары уже прошли, но баллы свежие).
    /// Однопарные «замены» отсекаются по второму, а курсы прошлого семестра —
    /// и по первому, и по второму. Фолбэк на полный список — пока расписание
    /// не подгрузилось.
    var activeDisciplines: [Discipline] {
        guard !lessonsByDay.isEmpty else { return disciplines }
        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)
        let monthAgo = cal.date(byAdding: .day, value: -30, to: today) ?? Date.distantPast
        var hasFuture: Set<String> = []
        var recentCounts: [String: Int] = [:]
        for (_, lessons) in lessonsByDay {
            for l in lessons {
                if l.start >= today { hasFuture.insert(l.discipline) }
                if l.start >= monthAgo { recentCounts[l.discipline, default: 0] += 1 }
            }
        }
        return disciplines.filter { d in
            hasFuture.contains(d.title) || (recentCounts[d.title] ?? 0) >= 3
        }
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
            recordSilent(error, op: "loadDisciplines")
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
            recordSilent(error, op: "loadDisciplineDetail")
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

    /// То же, что `loadAllDisciplineDetails`, но ИГНОРИРУЕТ существующий кэш —
    /// обновляет всё, что считаем активным. Зовётся в `refreshAll` на каждом
    /// старте, чтобы свежие баллы (которые препод выставил после прошлого
    /// захода) подтянулись. Сам по себе `loadAllDisciplineDetails` для этого
    /// не годится: он пропускает дисциплины с уже закэшированным detail-ом.
    func refreshAllDisciplineDetails() async {
        guard let studentId = TokenStore.studentId, !studentId.isEmpty else { return }
        let toLoad = activeDisciplines
        guard !toLoad.isEmpty else { return }
        await withTaskGroup(of: Void.self) { group in
            for d in toLoad {
                group.addTask { await self.loadDisciplineDetail(disciplineId: d.id) }
            }
            await group.waitForAll()
        }
    }

    @discardableResult
    func loadTopicDetail(topicId: String) async -> String? {
        guard let studentId = TokenStore.studentId, !studentId.isEmpty else {
            return "Требуется вход"
        }
        do {
            let t = try await TopicRepository.detail(studentId: studentId, topicId: topicId)
            self.topicDetails[topicId] = t
            DiskCache.save(.topicDetails, self.topicDetails)
            LXPLog.debug("[LXP] loadTopicDetail OK \(topicId) blocks=\(t.blocks.count)")
            for b in t.blocks {
                LXPLog.debug("[LXP][topic-block] kind=\(b.kind) id=\(b.id) name=\(b.name) bodyLen=\(b.body.count)")
                // Полный дамп body чанками по 800 символов — иначе syslog режет
                // длинные строки. Нужно для диагностики потерянных Editor.js
                // блоков (например, у задания «КТ5 Анализ трафика»).
                if !b.body.isEmpty {
                    let chunkSize = 800
                    let s = b.body
                    var i = s.startIndex
                    var idx = 0
                    while i < s.endIndex {
                        let end = s.index(i, offsetBy: chunkSize, limitedBy: s.endIndex) ?? s.endIndex
                        LXPLog.debug("[LXP][block-body] \(b.id) #\(idx): \(s[i..<end])")
                        i = end
                        idx += 1
                    }
                }
            }
            return nil
        } catch {
            if LXPError.isCancellation(error) { return nil }
            LXPLog.debug("[LXP] loadTopicDetail FAIL \(error)")
            return error.localizedDescription
        }
    }

    func loadAssignments(studentId: String) async {
        do {
            let list = try await TasksRepository.availableTasks(studentId: studentId)
            self.assignments = list
            DiskCache.save(.assignments, list)
            LXPLog.debug("[LXP] loadAssignments OK \(list.count)")
        } catch {
            recordSilent(error, op: "loadAssignments")
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
        answersByBlock = [:]
        lastError = nil
    }

    // MARK: - Task answers

    /// Возвращает текст ошибки или `nil` при успехе. Ошибку показываем
    /// локально внутри `AnswerView`, а не через глобальный баннер — так
    /// пользователю проще понять контекст и нажать «Попробовать снова».
    @discardableResult
    func loadAnswers(topicId: String, contentBlockId: String) async -> String? {
        guard let studentId = TokenStore.studentId, !studentId.isEmpty else {
            return "Требуется вход"
        }
        do {
            let list = try await AnswersRepository.fetchAnswers(studentId: studentId, topicId: topicId, contentBlockId: contentBlockId)
            self.answersByBlock[contentBlockId] = list
            let allUrls = list.flatMap(\.filesUrls)
            LXPLog.debug("[LXP] loadAnswers OK \(contentBlockId) count=\(list.count) files=\(allUrls.count) urls=\(allUrls)")
            return nil
        } catch {
            if LXPError.isCancellation(error) { return nil }
            LXPLog.debug("[LXP] loadAnswers FAIL \(error)")
            return error.localizedDescription
        }
    }

    func submitAnswer(topicId: String, contentBlockId: String, text: String, filesUrl: [String]) async -> Bool {
        do {
            LXPLog.debug("[LXP] submitAnswer → \(contentBlockId) text=\(text.count)ch files=\(filesUrl.count) urls=\(filesUrl)")
            let new = try await AnswersRepository.createAnswer(
                topicId: topicId, contentBlockId: contentBlockId,
                text: text, filesUrl: filesUrl
            )
            LXPLog.debug("[LXP] submitAnswer ← id=\(new.id) text=\(new.text.count)ch files=\(new.filesUrls.count) urls=\(new.filesUrls)")
            // На случай, если мутация вернула неполный список (бэк-баг) —
            // перезапросим список ответов с сервера.
            _ = await self.loadAnswers(topicId: topicId, contentBlockId: contentBlockId)
            return true
        } catch {
            recordUserAction(error, op: "submitAnswer")
            return false
        }
    }

    func deleteAnswer(answerId: String, topicId: String, contentBlockId: String) async -> Bool {
        guard let studentId = TokenStore.studentId, !studentId.isEmpty else { return false }
        do {
            try await AnswersRepository.deleteAnswer(
                answerId: answerId, studentId: studentId,
                topicId: topicId, contentBlockId: contentBlockId
            )
            self.answersByBlock[contentBlockId]?.removeAll { $0.id == answerId }
            LXPLog.debug("[LXP] deleteAnswer OK \(answerId)")
            return true
        } catch {
            recordUserAction(error, op: "deleteAnswer")
            return false
        }
    }
}
