import SwiftUI

struct ServicesView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    profileHeader
                    quickAccess
                    menu
                }
                .padding(.horizontal, 18)
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .background(.background)
            .navigationTitle("Сервисы")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.body.weight(.semibold))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private var profileHeader: some View {
        NavigationLink {
            ProfileView()
        } label: {
            HStack(spacing: 14) {
                AvatarView(avatarPath: store.profile.avatar,
                           initials: initials,
                           size: 52,
                           fontSize: 17)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(store.profile.lastName) \(store.profile.firstName)")
                        .font(.headline)
                    Text(store.profile.group)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .lxpGlass(cornerRadius: 22)
        }
        .buttonStyle(.plain)
    }

    private var initials: String {
        let f = store.profile.firstName.first.map { String($0) } ?? ""
        let l = store.profile.lastName.first.map { String($0) } ?? ""
        return l + f
    }

    private var quickAccess: some View {
        HStack(spacing: 12) {
            NavigationLink { AssignmentsView() } label: {
                CountTile(title: "Задания", value: store.assignmentsCount, symbol: "tray.full")
            }
            .buttonStyle(.plain)
            NavigationLink { DisciplinesView() } label: {
                CountTile(title: "Дисциплины", value: store.disciplinesCount, symbol: "books.vertical")
            }
            .buttonStyle(.plain)
        }
    }

    private var menu: some View {
        VStack(spacing: 0) {
            NavigationLink { DiaryView() } label: {
                DisclosureRow(title: "Успеваемость", subtitle: "Баллы и оценки по дисциплинам", symbol: "graduationcap")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            Divider().padding(.leading, 56).opacity(0.4)
            NavigationLink { AttendanceOverviewView() } label: {
                DisclosureRow(title: "Посещаемость",
                              subtitle: "Сводка по неделе и дисциплинам",
                              symbol: "chart.bar")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            Divider().padding(.leading, 56).opacity(0.4)
            NavigationLink { AboutView() } label: {
                DisclosureRow(title: "О приложении", symbol: "info.circle")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
        }
        .lxpGlass(cornerRadius: 22)
    }
}

// MARK: - Assignments

struct AssignmentsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var query = ""
    @State private var filter: AssignmentStatus? = nil

    private var items: [Assignment] {
        store.assignments.filter {
            (filter == nil || $0.status == filter) &&
            (query.isEmpty ||
             $0.title.localizedCaseInsensitiveContains(query) ||
             $0.discipline.localizedCaseInsensitiveContains(query))
        }
    }

    /// Группы заданий по дисциплине. Внутри группы — по дедлайну (ближайший первый),
    /// сами группы — по ближайшему дедлайну в группе. Задания без названия
    /// дисциплины сваливаются в «Прочее» в самый низ.
    private var groups: [(discipline: String, items: [Assignment])] {
        let buckets = Dictionary(grouping: items) { a in
            a.discipline.isEmpty ? "Прочее" : a.discipline
        }
        return buckets
            .map { (key, list) in
                (key, list.sorted { $0.deadline < $1.deadline })
            }
            .sorted { lhs, rhs in
                if lhs.0 == "Прочее" { return false }
                if rhs.0 == "Прочее" { return true }
                let l = lhs.1.first?.deadline ?? .distantFuture
                let r = rhs.1.first?.deadline ?? .distantFuture
                return l < r
            }
    }

    /// Стор пустой и сетевая загрузка ещё не отработала — показываем скелетоны.
    private var isInitialLoad: Bool {
        store.assignments.isEmpty && store.lastError == nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                filtersRow
                if items.isEmpty {
                    if isInitialLoad {
                        ForEach(0..<3, id: \.self) { _ in SkeletonAssignmentCard() }
                    } else {
                        emptyState
                    }
                } else {
                    ForEach(groups, id: \.discipline) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(group.discipline)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .tracking(0.5)
                                    .textCase(.uppercase)
                                Spacer()
                                Text("\(group.items.count)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                                    .monospacedDigit()
                            }
                            .padding(.horizontal, 4)
                            VStack(spacing: 8) {
                                ForEach(group.items) { item in
                                    if let id = item.topicId, !id.isEmpty {
                                        NavigationLink {
                                            TopicDetailView(topicId: id, fallbackTitle: item.title)
                                        } label: {
                                            AssignmentCard(assignment: item)
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        AssignmentCard(assignment: item)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .searchable(text: $query, prompt: "Поиск")
        .navigationTitle("Задания")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filtersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(title: "Все", isSelected: filter == nil) { filter = nil }
                FilterPill(title: "Открытые", isSelected: filter == .open) { filter = .open }
                FilterPill(title: "Сданные", isSelected: filter == .submitted) { filter = .submitted }
                FilterPill(title: "Просроченные", isSelected: filter == .overdue) { filter = .overdue }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Заданий нет")
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .lxpGlass(cornerRadius: 22)
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .lxpGlassCapsule(tint: isSelected ? .primary.opacity(0.18) : nil)
        }
        .buttonStyle(.plain)
    }
}

struct AssignmentCard: View {
    let assignment: Assignment

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // В шапке — тема, к которой относится задание (дисциплина уже
                // в заголовке группы выше).
                if !assignment.topic.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.caption2.weight(.semibold))
                        Text(assignment.topic)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.secondary)
                    .tracking(0.3)
                }
                Spacer()
                statusPill
            }
            Text(assignment.title)
                .font(.body.weight(.semibold))
            HStack(spacing: 6) {
                Image(systemName: "clock")
                Text(deadlineText)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .lxpGlass(cornerRadius: 22)
    }

    private var deadlineText: String {
        if assignment.deadline >= Date.distantFuture.addingTimeInterval(-1) {
            return "Срок не задан"
        }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMMM, HH:mm"
        return "Срок: " + f.string(from: assignment.deadline)
    }

    private var statusPill: some View {
        Text(assignment.status.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .lxpGlassCapsule()
    }
}

struct AssignmentDetailView: View {
    let assignment: Assignment

    var body: some View {
        // Kept for compatibility; not used directly anymore. Assignments
        // navigate straight to the related topic.
        TopicDetailView(topicId: assignment.topicId ?? "", fallbackTitle: assignment.title)
    }
}

// MARK: - Disciplines

struct DisciplinesView: View {
    @EnvironmentObject private var store: AppStore
    @State private var query = ""

    private var items: [Discipline] {
        let active = store.activeDisciplines
        if query.isEmpty { return active }
        return active.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    private var isInitialLoad: Bool {
        store.disciplines.isEmpty && store.lastError == nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if items.isEmpty {
                    if isInitialLoad {
                        ForEach(0..<5, id: \.self) { _ in SkeletonDisciplineCard() }
                    } else {
                        emptyState
                    }
                } else {
                    ForEach(items) { discipline in
                        NavigationLink {
                            DisciplineDetailView(discipline: discipline)
                        } label: {
                            DisciplineCard(discipline: discipline,
                                           score: store.scores(disciplineId: discipline.id))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .searchable(text: $query, prompt: "Поиск")
        .navigationTitle("Дисциплины")
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.loadAllDisciplineDetails() }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "books.vertical")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Дисциплин нет")
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .lxpGlass(cornerRadius: 22)
    }
}

struct DisciplineCard: View {
    let discipline: Discipline
    var score: AppStore.ScoreMetric? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "book.closed.fill")
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .lxpGlass(cornerRadius: 12)
            VStack(alignment: .leading, spacing: 4) {
                Text(discipline.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(2)
                HStack(spacing: 6) {
                    if let code = discipline.code, !code.isEmpty {
                        Text(code)
                    }
                    if discipline.totalHours > 0 {
                        if discipline.code != nil { Text("·").foregroundStyle(.tertiary) }
                        Text("\(discipline.totalHours) ч")
                    }
                    if let s = score, s.maxScore > 0 {
                        Text("·").foregroundStyle(.tertiary)
                        Text("\(formatScore(s.earned)) / \(formatScore(s.maxScore)) б")
                            .monospacedDigit()
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if let g = score?.grade {
                GradePill(grade: g)
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .lxpGlass(cornerRadius: 22)
    }

    private func formatScore(_ v: Double) -> String {
        if v.rounded() == v { return String(Int(v)) }
        return String(format: "%.1f", v)
    }
}

/// Бейдж 2-5 цветом по оценке: 5 — зелёный, 4 — синий, 3 — жёлтый, 2 — красный.
struct GradePill: View {
    let grade: Int

    private var tint: Color {
        switch grade {
        case 5: return .green
        case 4: return .blue
        case 3: return .yellow
        default: return .red
        }
    }

    var body: some View {
        Text("\(grade)")
            .font(.subheadline.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(tint)
            .frame(width: 30, height: 30)
            .lxpGlassCircle(tint: tint.opacity(0.18))
    }
}

struct DisciplineDetailView: View {
    @EnvironmentObject private var store: AppStore
    let discipline: Discipline

    private var detail: DisciplineDetail? { store.disciplineDetails[discipline.id] }
    private var attendance: AppStore.AttendanceMetric { store.attendanceFor(disciplineTitle: discipline.title) }
    private var score: AppStore.ScoreMetric? { store.scores(disciplineId: discipline.id) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                summary
                if let s = score, s.assigned > 0 {
                    scoreBreakdown(s)
                }
                topicsSection
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle("Дисциплина")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if detail == nil {
                await store.loadDisciplineDetail(disciplineId: discipline.id)
            }
        }
    }

    private var summary: some View {
        GlassCard(padding: 20, corner: 26) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(discipline.title)
                            .font(.title3.weight(.semibold))
                        if let code = discipline.code, !code.isEmpty {
                            Text(code)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .tracking(0.5)
                        }
                    }
                    Spacer()
                    if let g = score?.grade {
                        GradePill(grade: g)
                    }
                }
                HStack(spacing: 20) {
                    metric(title: "Часы", value: "\(discipline.totalHours)")
                    if attendance.totalHours > 0 {
                        let pct = Int((attendance.rate * 100).rounded())
                        metric(title: "Посещение", value: "\(pct)%")
                    }
                    if let topics = detail?.topics, !topics.isEmpty {
                        metric(title: "Тем", value: "\(topics.count)")
                    }
                }
                if attendance.totalHours > 0 {
                    AttendanceBar(rate: attendance.rate)
                }
            }
        }
    }

    /// Карточка с баллами по дисциплине: `earned из assigned / maxScore` —
    /// ровно то же, что показывает сайт ITHub.
    private func scoreBreakdown(_ s: AppStore.ScoreMetric) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Баллы")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Spacer()
                if let g = s.grade {
                    Text("Оценка \(g)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(gradeColor(g))
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(formatScore(s.earned)) из \(formatScore(s.assigned))")
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                Text("/ \(formatScore(s.maxScore))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Spacer()
                Text("\(Int((s.rate * 100).rounded()))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            ProgressBar(rate: s.rate, color: s.grade.map(gradeColor) ?? .accentColor)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lxpGlass(cornerRadius: 22)
    }

    private func gradeColor(_ g: Int) -> Color {
        switch g {
        case 5: return .green
        case 4: return .blue
        case 3: return .yellow
        default: return .red
        }
    }

    private func formatScore(_ v: Double) -> String {
        if v.rounded() == v { return String(Int(v)) }
        return String(format: "%.1f", v)
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private var topicsSection: some View {
        if let topics = detail?.topics, !topics.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Темы", trailing: "\(topics.count)")
                VStack(spacing: 0) {
                    ForEach(Array(topics.enumerated()), id: \.element.id) { index, topic in
                        NavigationLink {
                            TopicDetailView(topicId: topic.id, fallbackTitle: topic.title)
                        } label: {
                            TopicRow(topic: topic)
                        }
                        .buttonStyle(.plain)
                        if index < topics.count - 1 {
                            Divider().padding(.leading, 56).opacity(0.4)
                        }
                    }
                }
                .lxpGlass(cornerRadius: 22)
            }
        } else {
            HStack {
                ProgressView().controlSize(.small)
                Text("Загружаем темы…").font(.footnote).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 18)
        }
    }
}

struct TopicRow: View {
    let topic: Topic

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: topic.isCheckpoint ? "flag.fill" : "circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(topic.status.tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(topic.title)
                    .font(.subheadline)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(topic.status.label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(topic.status.tint)
                        .tracking(0.4)
                    if let s = topic.score, let m = topic.maxScore, m > 0 {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text("\(Int(min(s, m).rounded())) / \(Int(m.rounded()))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

// MARK: - Grades

/// Журнал оценок: группы по дисциплинам, внутри список тем с уже выставленными
/// баллами. Показываем сразу две метрики (текущая + полный потенциал) — чтобы
/// было ясно, откуда берётся 4 в семестре, который только начался.
struct DiaryView: View {
    @EnvironmentObject private var store: AppStore
    @State private var expanded: Set<String> = []
    @State private var legendExpanded: Bool = false

    private struct Section: Identifiable {
        let discipline: Discipline
        let detail: DisciplineDetail
        /// `nil`, если оценок ещё нет — карточка покажет «—» вместо процентов.
        let score: AppStore.ScoreMetric?
        var id: String { discipline.id }
    }

    private var sections: [Section] {
        store.activeDisciplines.compactMap { d in
            guard let detail = store.disciplineDetails[d.id] else { return nil }
            return Section(
                discipline: d,
                detail: detail,
                score: store.scores(disciplineId: d.id)
            )
        }
    }

    /// Первые N тем показываем сразу, остальные прячем под кнопку «Показать ещё».
    private let collapsedLimit = 3

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                explainer
                if sections.isEmpty {
                    emptyState
                } else {
                    ForEach(sections) { s in
                        sectionCard(s)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle("Успеваемость")
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.loadAllDisciplineDetails() }
    }

    private var explainer: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { legendExpanded.toggle() }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "info.circle")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Как считаются оценки")
                            .font(.subheadline.weight(.semibold))
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(legendExpanded ? 180 : 0))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if legendExpanded {
                Divider().padding(.leading, 44).opacity(0.4)
                gradeLegendRow(grade: 5, range: "≥ 90%")
                Divider().padding(.leading, 44).opacity(0.4)
                gradeLegendRow(grade: 4, range: "70–89%")
                Divider().padding(.leading, 44).opacity(0.4)
                gradeLegendRow(grade: 3, range: "50–69%")
                Divider().padding(.leading, 44).opacity(0.4)
                gradeLegendRow(grade: 2, range: "< 50%")
                Divider().padding(.leading, 44).opacity(0.4)
                Text("В строке баллов: набрано из выставленных, через слэш — полная шкала дисциплины (обычно 100). Процент и оценка считаются по выставленным.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .lxpGlass(cornerRadius: 22)
    }

    private func gradeLegendRow(grade: Int, range: String) -> some View {
        HStack(spacing: 14) {
            GradePill(grade: grade)
                .frame(width: 28)
            Text(range)
                .font(.subheadline)
                .monospacedDigit()
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }

    /// Темы дисциплины, у которых уже есть оценка, дедупнутые по `topicId`.
    /// Сервер часто шлёт одну и ту же тему через несколько learning paths —
    /// без дедупа в журнале они задваивались.
    private func gradedTopics(for detail: DisciplineDetail) -> [Topic] {
        var byId: [String: Topic] = [:]
        for t in detail.topics {
            let isGraded = (t.score ?? 0) > 0 || t.status == .passed || t.status == .failed
            guard isGraded else { continue }
            if let ex = byId[t.id] {
                if (t.score ?? 0) > (ex.score ?? 0) { byId[t.id] = t }
            } else {
                byId[t.id] = t
            }
        }
        return Array(byId.values).sorted {
            $0.number.compare($1.number, options: .numeric) == .orderedAscending
        }
    }

    @ViewBuilder
    private func sectionCard(_ s: Section) -> some View {
        let graded = gradedTopics(for: s.detail)
        let isExpanded = expanded.contains(s.id)
        let visible = isExpanded ? graded : Array(graded.prefix(collapsedLimit))
        let hidden = max(0, graded.count - visible.count)

        VStack(alignment: .leading, spacing: 10) {
            // Заголовок дисциплины с метриками — кликабельный, ведёт на экран дисциплины.
            NavigationLink {
                DisciplineDetailView(discipline: s.discipline)
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.discipline.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(2)
                            if let code = s.discipline.code, !code.isEmpty {
                                Text(code)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        if let g = s.score?.grade {
                            GradePill(grade: g)
                        }
                    }
                    if let score = s.score, score.assigned > 0 {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(formatScore(score.earned)) из \(formatScore(score.assigned))")
                                .font(.title3.weight(.semibold))
                                .monospacedDigit()
                            Text("/ \(formatScore(score.maxScore))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            Spacer()
                            Text("\(Int((score.rate * 100).rounded()))%")
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        ProgressBar(rate: score.rate, color: gradeColor(for: score.grade))
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "hourglass")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text("Баллов пока нет")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let score = s.score, score.maxScore > 0 {
                                Text("·").foregroundStyle(.tertiary)
                                Text("максимум \(formatScore(score.maxScore))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Список оценённых тем.
            VStack(spacing: 0) {
                if graded.isEmpty {
                    Text("Пока нет выставленных оценок")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(Array(visible.enumerated()), id: \.element.id) { index, topic in
                        NavigationLink {
                            TopicDetailView(topicId: topic.id, fallbackTitle: topic.title)
                        } label: {
                            GradeRow(topic: topic)
                        }
                        .buttonStyle(.plain)
                        if index < visible.count - 1 {
                            Divider().padding(.leading, 16).opacity(0.4)
                        }
                    }
                    if graded.count > collapsedLimit {
                        Divider().padding(.leading, 16).opacity(0.4)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                if isExpanded { expanded.remove(s.id) }
                                else { expanded.insert(s.id) }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(isExpanded ? "Свернуть" : "Показать ещё \(hidden)")
                                    .font(.caption.weight(.semibold))
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption2.weight(.semibold))
                            }
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
        .lxpGlass(cornerRadius: 22)
    }

    private func gradeColor(for grade: Int?) -> Color {
        switch grade {
        case 5: return .green
        case 4: return .blue
        case 3: return .yellow
        case 2: return .red
        default: return .secondary
        }
    }

    private func formatScore(_ v: Double) -> String {
        if v.rounded() == v { return String(Int(v)) }
        return String(format: "%.1f", v)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "graduationcap")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Оценок пока нет")
                .font(.subheadline.weight(.semibold))
            Text("Здесь появятся темы с выставленными баллами")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 16)
        .lxpGlass(cornerRadius: 22)
    }
}

struct GradeRow: View {
    let topic: Topic

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: topic.isCheckpoint ? "flag.fill" : "circle.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(topic.status.tint)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(topic.title)
                    .font(.subheadline)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    if !topic.number.isEmpty {
                        Text("Тема \(topic.number)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                        Text("·").foregroundStyle(.tertiary)
                    }
                    Text(topic.status.label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(topic.status.tint)
                        .tracking(0.4)
                }
            }
            Spacer()
            if let s = topic.score, let m = topic.maxScore, m > 0 {
                // Сырой score из API может превышать maxScore — обрезаем,
                // как это делает сайт ITHub.
                Text("\(formatScore(min(s, m))) / \(formatScore(m))")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    private func formatScore(_ v: Double) -> String {
        if v.rounded() == v { return String(Int(v)) }
        return String(format: "%.1f", v)
    }
}

// MARK: - Attendance overview

struct AttendanceOverviewView: View {
    @EnvironmentObject private var store: AppStore
    @State private var range: Range = .week
    @State private var legendExpanded: Bool = false
    /// 0 — текущая неделя/месяц, -1 — прошлая, и т.д.
    @State private var periodOffset: Int = 0

    enum Range: String, CaseIterable, Identifiable {
        case week = "Неделя"
        case month = "Месяц"
        var id: String { rawValue }
    }

    /// Календарный интервал текущего выбранного периода с учётом `periodOffset`.
    /// `offset=0` — текущая неделя/месяц (правый край = сейчас).
    /// `offset<0` — прошлый, окно полное.
    private var rangeInterval: ClosedRange<Date> {
        let now = Date()
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Monday
        switch range {
        case .week:
            let thisWeekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let start = cal.date(byAdding: .weekOfYear, value: periodOffset, to: thisWeekStart)!
            let endExclusive = cal.date(byAdding: .day, value: 7, to: start)!
            // Если это текущая неделя — обрезаем по «сейчас», чтобы не считать
            // ещё не прошедшие пары.
            let upper = min(endExclusive, now)
            guard upper >= start else { return start...start }
            return start...upper
        case .month:
            let thisMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            let start = cal.date(byAdding: .month, value: periodOffset, to: thisMonthStart)!
            let endExclusive = cal.date(byAdding: .month, value: 1, to: start)!
            let upper = min(endExclusive, now)
            guard upper >= start else { return start...start }
            return start...upper
        }
    }

    /// Дальше в будущее листать нельзя — нет смысла смотреть ещё не прошедший период.
    private var canGoForward: Bool { periodOffset < 0 }

    /// Заголовок периода для подписи между стрелками.
    private var periodTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        switch range {
        case .week:
            if periodOffset == 0 { return "Эта неделя" }
            if periodOffset == -1 { return "Прошлая неделя" }
            let now = Date()
            let thisWeekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let start = cal.date(byAdding: .weekOfYear, value: periodOffset, to: thisWeekStart)!
            let end = cal.date(byAdding: .day, value: 6, to: start)!
            if cal.component(.month, from: start) == cal.component(.month, from: end) {
                f.dateFormat = "d"
                let s = f.string(from: start)
                f.dateFormat = "d MMMM"
                return "\(s)–\(f.string(from: end))"
            }
            f.dateFormat = "d MMM"
            return "\(f.string(from: start)) – \(f.string(from: end))"
        case .month:
            if periodOffset == 0 { return "Этот месяц" }
            if periodOffset == -1 { return "Прошлый месяц" }
            let now = Date()
            let thisMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: now))!
            let start = cal.date(byAdding: .month, value: periodOffset, to: thisMonthStart)!
            f.dateFormat = "LLLL yyyy"
            return f.string(from: start).capitalized
        }
    }

    private var metric: AppStore.AttendanceMetric {
        store.attendance(in: rangeInterval)
    }

    private var disciplineRows: [(Discipline, AppStore.AttendanceMetric)] {
        store.activeDisciplines
            .map { ($0, store.attendanceFor(disciplineTitle: $0.title, in: rangeInterval)) }
            .filter { $0.1.totalHours > 0 }
            .sorted { $0.1.rate < $1.1.rate }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                rangePicker
                periodNav
                summary
                legend
                list
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle("Посещаемость")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.ensurePastSchedule(days: 60)
        }
    }

    private var rangePicker: some View {
        HStack(spacing: 8) {
            ForEach(Range.allCases) { r in
                FilterPill(title: r.rawValue, isSelected: range == r) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        range = r
                        periodOffset = 0
                    }
                }
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var periodNav: some View {
        HStack {
            Button {
                shift(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .lxpGlassCircle()
            }
            .buttonStyle(.plain)

            Spacer()

            Text(periodTitle)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)

            Spacer()

            Button {
                shift(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(canGoForward ? .primary : .tertiary)
                    .frame(width: 36, height: 36)
                    .lxpGlassCircle()
            }
            .buttonStyle(.plain)
            .disabled(!canGoForward)
        }
    }

    private func shift(by step: Int) {
        let next = periodOffset + step
        guard next <= 0 else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            periodOffset = next
        }
        // Если уходим в далёкое прошлое — догружаем расписание.
        let cal = Calendar.current
        let daysBack: Int
        switch range {
        case .week: daysBack = abs(next) * 7 + 14
        case .month: daysBack = abs(next) * 31 + 31
        }
        if daysBack > 60 {
            Task { await store.ensurePastSchedule(days: daysBack + 7) }
        }
    }

    private var summary: some View {
        GlassCard(padding: 20, corner: 26) {
            VStack(alignment: .leading, spacing: 12) {
                Text(summaryHeader.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                if metric.totalHours == 0 {
                    Text("Нет данных")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    let pct = Int((metric.rate * 100).rounded())
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(pct)%")
                            .font(.system(size: 48, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                        Text(detailText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    AttendanceBar(rate: metric.rate)
                }
            }
        }
    }

    private var detailText: String {
        let attended = formatHours(metric.attendedHours)
        let total = formatHours(metric.totalHours)
        if metric.missedHours > 0 {
            return "\(attended) из \(total) ч · пропущено \(formatHours(metric.missedHours)) ч"
        }
        return "\(attended) из \(total) ч"
    }

    private var summaryHeader: String {
        switch range {
        case .week:
            if periodOffset == 0 { return "За эту неделю" }
            if periodOffset == -1 { return "За прошлую неделю" }
            return "За неделю"
        case .month:
            if periodOffset == 0 { return "За этот месяц" }
            if periodOffset == -1 { return "За прошлый месяц" }
            return "За месяц"
        }
    }

    private func formatHours(_ h: Double) -> String {
        if h.rounded() == h { return String(Int(h)) }
        return String(format: "%.1f", h)
    }

    private var legend: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { legendExpanded.toggle() }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "info.circle")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 28)
                    Text("Как считаются отметки")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(legendExpanded ? 180 : 0))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if legendExpanded {
                Divider().padding(.leading, 44).opacity(0.4)
                legendRow(.present)
                Divider().padding(.leading, 44).opacity(0.4)
                legendRow(.online)
                Divider().padding(.leading, 44).opacity(0.4)
                legendRow(.absent)
                Divider().padding(.leading, 44).opacity(0.4)
                legendRow(.noMark)
            }
        }
        .lxpGlass(cornerRadius: 22)
    }

    private func legendRow(_ s: AttendanceStatus) -> some View {
        HStack(spacing: 14) {
            Image(systemName: s.symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(s.tint)
                .frame(width: 28)
            Text(s.label).font(.subheadline)
            Spacer()
            Text(detailText(for: s))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    private func detailText(for s: AttendanceStatus) -> String {
        switch s {
        case .absent: "снимает часы"
        case .noMark: "не учитывается"
        default: "не снимает"
        }
    }

    @ViewBuilder
    private var list: some View {
        if disciplineRows.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "По дисциплинам")
                VStack(spacing: 0) {
                    ForEach(Array(disciplineRows.enumerated()), id: \.offset) { index, pair in
                        NavigationLink {
                            DisciplineDetailView(discipline: pair.0)
                        } label: {
                            DisciplineAttendanceRow(discipline: pair.0, metric: pair.1)
                        }
                        .buttonStyle(.plain)
                        if index < disciplineRows.count - 1 {
                            Divider().padding(.leading, 16).opacity(0.4)
                        }
                    }
                }
                .lxpGlass(cornerRadius: 22)
            }
        }
    }
}

struct DisciplineAttendanceRow: View {
    let discipline: Discipline
    let metric: AppStore.AttendanceMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(discipline.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Spacer()
                Text("\(Int((metric.rate * 100).rounded()))%")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            AttendanceBar(rate: metric.rate)
            Text(detailLine)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .contentShape(Rectangle())
    }

    private var detailLine: String {
        let attended = format(metric.attendedHours)
        let total = format(metric.totalHours)
        return "\(attended) из \(total) ч · пропущено \(format(metric.missedHours)) ч"
    }

    private func format(_ h: Double) -> String {
        if h.rounded() == h { return String(Int(h)) }
        return String(format: "%.1f", h)
    }
}

// MARK: - Profile

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    private var p: Profile { store.profile }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                avatar
                infoBlock(title: "Личная информация",
                          rows: [
                            ("Фамилия", p.lastName),
                            ("Имя", p.firstName),
                            ("Отчество", p.middleName),
                            ("Email", p.email)
                          ])
                infoBlock(title: "Организация",
                          rows: [
                            ("Учреждение", p.organization),
                            ("Группа", p.group),
                            ("Специальность", p.speciality)
                          ])
                if !p.groupMates.isEmpty {
                    NavigationLink {
                        GroupListView(group: p.group, mates: p.groupMates)
                    } label: {
                        DisclosureRow(title: "Группа \(p.group)",
                                      subtitle: "\(p.groupMates.count + 1) человек",
                                      symbol: "person.3")
                            .padding(16)
                            .lxpGlass(cornerRadius: 22)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var avatar: some View {
        VStack(spacing: 12) {
            AvatarView(avatarPath: p.avatar,
                       initials: initials,
                       size: 96,
                       fontSize: 36)
            Text("\(p.lastName) \(p.firstName) \(p.middleName)")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var initials: String {
        let f = p.firstName.first.map { String($0) } ?? ""
        let l = p.lastName.first.map { String($0) } ?? ""
        return l + f
    }

    private func infoBlock(title: String, rows: [(String, String)]) -> some View {
        let nonEmpty = rows.filter { !$0.1.isEmpty }
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title)
            VStack(spacing: 0) {
                ForEach(Array(nonEmpty.enumerated()), id: \.offset) { i, row in
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.0)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(width: 110, alignment: .leading)
                        Text(row.1)
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    if i < nonEmpty.count - 1 {
                        Divider().padding(.leading, 16).opacity(0.4)
                    }
                }
            }
            .lxpGlass(cornerRadius: 22)
        }
    }
}

struct GroupListView: View {
    let group: String
    let mates: [GroupMate]

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if mates.isEmpty {
                    Text("В группе пока никого нет")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 32)
                } else {
                    ForEach(mates) { mate in
                        HStack(spacing: 14) {
                            AvatarView(avatarPath: mate.avatar,
                                       initials: mate.initials,
                                       size: 36,
                                       fontSize: 13)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mate.fullName).font(.subheadline)
                                if let email = mate.email, !email.isEmpty {
                                    Text(email)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lxpGlass(cornerRadius: 18)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle(group)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearance") private var appearance: AppearanceMode = .system

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    appearancePicker

                    Button(role: .destructive) {
                        store.signOut()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Выйти из аккаунта")
                                .font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                    }
                    .lxpGlass(cornerRadius: 18, tint: .red.opacity(0.2))
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .background(.background)
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    private var appearancePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Цветовая тема")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
                .padding(.horizontal, 16)
                .padding(.top, 14)
            HStack(spacing: 8) {
                ForEach(AppearanceMode.allCases) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            appearance = mode
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: mode.symbol)
                                .font(.title3)
                            Text(mode.title)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(appearance == mode ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .lxpGlass(cornerRadius: 14,
                                  tint: appearance == mode ? .accentColor.opacity(0.18) : nil)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lxpGlass(cornerRadius: 18)
    }
}

/// Цветовая тема приложения. Сохраняется через `@AppStorage`, применяется к
/// `WindowGroup` через `.preferredColorScheme` в `NewLXPApp`.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Система"
        case .light: return "Светлая"
        case .dark: return "Тёмная"
        }
    }

    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - About

struct AboutView: View {
    private var marketingVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1"
    }
    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
    private var systemVersion: String {
        let device = UIDevice.current
        return "\(device.systemName) \(device.systemVersion)"
    }
    private var deviceModel: String {
        UIDevice.current.model
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero
                links
                creditAndSystem
            }
            .padding(.horizontal, 18)
            .padding(.top, 4)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle("О приложении")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(spacing: 12) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 36, weight: .semibold))
                .frame(width: 88, height: 88)
                .lxpGlass(cornerRadius: 22)
            Text("LXP IThub").font(.title3.weight(.semibold))
            Text("Версия \(marketingVersion) (build \(buildNumber))")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.top, 12)
    }

    private var links: some View {
        VStack(spacing: 0) {
            link(title: "Открыть newlxp.ru", symbol: "safari",
                 url: URL(string: "https://newlxp.ru")!)
            Divider().padding(.leading, 56).opacity(0.4)
            link(title: "Сайт ITHub", symbol: "graduationcap",
                 url: URL(string: "https://ithub.ru")!)
            Divider().padding(.leading, 56).opacity(0.4)
            link(title: "Исходники на GitHub", symbol: "chevron.left.forwardslash.chevron.right",
                 url: URL(string: "https://github.com/keetsta/NewLXP")!)
        }
        .lxpGlass(cornerRadius: 22)
    }

    private func link(title: String, symbol: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(width: 28)
                Text(title).font(.body)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var creditAndSystem: some View {
        VStack(spacing: 10) {
            Text("made by keet")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.6)
            Text("\(deviceModel) · \(systemVersion)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }
}

// MARK: - Digest

struct DigestDetailView: View {
    let digest: Digest

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(digest.date, format: .dateTime.day().month().year())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .tracking(0.6)
                        Text("Ежедневный дайджест")
                            .font(.title3.weight(.semibold))
                        Text(digest.oneLine)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                DigestSections(digest: digest)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle("Дайджест")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DigestSections: View {
    let digest: Digest

    var body: some View {
        if digest.events.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "tray")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Сегодня всё спокойно")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .lxpGlass(cornerRadius: 22)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(digest.events.enumerated()), id: \.element.id) { index, event in
                    eventRow(event)
                    if index < digest.events.count - 1 {
                        Divider().padding(.leading, 58).opacity(0.4)
                    }
                }
            }
            .lxpGlass(cornerRadius: 22)
        }
    }

    @ViewBuilder
    private func eventRow(_ event: DigestEvent) -> some View {
        if let id = event.topicId, !id.isEmpty {
            NavigationLink {
                TopicDetailView(topicId: id, fallbackTitle: event.title)
            } label: {
                rowContent(event, hasChevron: true)
            }
            .buttonStyle(.plain)
        } else {
            rowContent(event, hasChevron: false)
        }
    }

    private func rowContent(_ event: DigestEvent, hasChevron: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: event.symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(event.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline.weight(.semibold))
                Text(event.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if hasChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

#Preview {
    ServicesView()
}
