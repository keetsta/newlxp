import SwiftUI

struct ServicesView: View {
    @Environment(AppStore.self) private var store
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
                Text(initials)
                    .font(.headline.weight(.semibold))
                    .frame(width: 52, height: 52)
                    .glassEffect(.regular, in: .circle)
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
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
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
                DisclosureRow(title: "Дневник", subtitle: "История посещаемости и тем", symbol: "book.closed")
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
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }
}

// MARK: - Assignments

struct AssignmentsView: View {
    @Environment(AppStore.self) private var store
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

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                filtersRow
                if items.isEmpty {
                    emptyState
                } else {
                    ForEach(items) { item in
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
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
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
                .glassEffect(isSelected ? .regular.tint(.primary.opacity(0.18)) : .regular,
                              in: .capsule)
        }
        .buttonStyle(.plain)
    }
}

struct AssignmentCard: View {
    let assignment: Assignment

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if !assignment.discipline.isEmpty {
                    Text(assignment.discipline.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                        .lineLimit(1)
                } else if !assignment.topic.isEmpty {
                    Text(assignment.topic.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                        .lineLimit(1)
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
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
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
            .glassEffect(.regular, in: .capsule)
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
    @Environment(AppStore.self) private var store
    @State private var query = ""

    private var items: [Discipline] {
        if query.isEmpty { return store.disciplines }
        return store.disciplines.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if items.isEmpty {
                    emptyState
                } else {
                    ForEach(items) { discipline in
                        NavigationLink {
                            DisciplineDetailView(discipline: discipline)
                        } label: {
                            DisciplineCard(discipline: discipline)
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
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }
}

struct DisciplineCard: View {
    let discipline: Discipline

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "book.closed.fill")
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
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
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }
}

struct DisciplineDetailView: View {
    @Environment(AppStore.self) private var store
    let discipline: Discipline

    private var detail: DisciplineDetail? { store.disciplineDetails[discipline.id] }
    private var attendance: AppStore.AttendanceMetric { store.attendanceFor(disciplineTitle: discipline.title) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                summary
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
                Text(discipline.title)
                    .font(.title3.weight(.semibold))
                if let code = discipline.code, !code.isEmpty {
                    Text(code)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
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
                .glassEffect(.regular, in: .rect(cornerRadius: 22))
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
                        Text("\(Int(s.rounded())) / \(Int(m.rounded()))")
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

// MARK: - Diary

struct DiaryView: View {
    @Environment(AppStore.self) private var store

    private var entries: [DiaryEntry] { store.diary }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if entries.isEmpty {
                    emptyState
                } else {
                    ForEach(grouped, id: \.0) { (day, items) in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(headerTitle(for: day))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .tracking(0.5)
                                .padding(.horizontal, 4)
                            VStack(spacing: 0) {
                                ForEach(Array(items.enumerated()), id: \.element.id) { index, entry in
                                    diaryItem(entry)
                                    if index < items.count - 1 {
                                        Divider().padding(.leading, 56).opacity(0.4)
                                    }
                                }
                            }
                            .glassEffect(.regular, in: .rect(cornerRadius: 22))
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle("Дневник")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func diaryItem(_ entry: DiaryEntry) -> some View {
        if let id = entry.topicId, !id.isEmpty {
            NavigationLink {
                TopicDetailView(topicId: id, fallbackTitle: entry.topic)
            } label: {
                DiaryRow(entry: entry, hasChevron: true)
            }
            .buttonStyle(.plain)
        } else {
            DiaryRow(entry: entry, hasChevron: false)
        }
    }

    private var grouped: [(Date, [DiaryEntry])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: entries) { cal.startOfDay(for: $0.date) }
        return dict.sorted { $0.key > $1.key }
    }

    private func headerTitle(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMMM, EEEE"
        return f.string(from: date).capitalized
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.closed")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Пока ничего нет")
                .font(.subheadline.weight(.semibold))
            Text("Здесь появятся пары с известным посещением")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 16)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }
}

struct DiaryRow: View {
    let entry: DiaryEntry
    var hasChevron: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: entry.attendance.symbol)
                .font(.body.weight(.medium))
                .foregroundStyle(entry.attendance.tint)
                .frame(width: 32, height: 32)
                .glassEffect(.regular, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.discipline)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(entry.topic)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Text(entry.date, format: .dateTime.hour().minute())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .monospacedDigit()
            if hasChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

// MARK: - Attendance overview

struct AttendanceOverviewView: View {
    @Environment(AppStore.self) private var store
    @State private var range: Range = .week
    @State private var legendExpanded: Bool = false

    enum Range: String, CaseIterable, Identifiable {
        case week = "Неделя"
        case month = "Месяц"
        var id: String { rawValue }
    }

    private var rangeInterval: ClosedRange<Date> {
        let cal = Calendar.current
        let endOfToday = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date()))!
        let days = range == .week ? 6 : 29
        let start = cal.date(byAdding: .day, value: -days, to: cal.startOfDay(for: Date()))!
        return start...endOfToday
    }

    private var metric: AppStore.AttendanceMetric {
        store.attendance(in: rangeInterval)
    }

    private var disciplineRows: [(Discipline, AppStore.AttendanceMetric)] {
        store.disciplines
            .map { ($0, store.attendanceFor(disciplineTitle: $0.title, in: rangeInterval)) }
            .filter { $0.1.totalHours > 0 }
            .sorted { $0.1.rate < $1.1.rate }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                rangePicker
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
                    withAnimation(.snappy) { range = r }
                }
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var summary: some View {
        GlassCard(padding: 20, corner: 26) {
            VStack(alignment: .leading, spacing: 12) {
                Text("За \(range == .week ? "неделю" : "месяц")".uppercased())
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

    private func formatHours(_ h: Double) -> String {
        if h.rounded() == h { return String(Int(h)) }
        return String(format: "%.1f", h)
    }

    private var legend: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.snappy) { legendExpanded.toggle() }
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
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
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
                        DisciplineAttendanceRow(discipline: pair.0, metric: pair.1)
                        if index < disciplineRows.count - 1 {
                            Divider().padding(.leading, 16).opacity(0.4)
                        }
                    }
                }
                .glassEffect(.regular, in: .rect(cornerRadius: 22))
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
    @Environment(AppStore.self) private var store
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
                            .glassEffect(.regular, in: .rect(cornerRadius: 22))
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
            Text(initials)
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .frame(width: 96, height: 96)
                .glassEffect(.regular, in: .circle)
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
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
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
                            Text(mate.initials)
                                .font(.caption.weight(.semibold))
                                .frame(width: 36, height: 36)
                                .glassEffect(.regular, in: .circle)
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
                        .glassEffect(.regular, in: .rect(cornerRadius: 18))
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
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var theme = "Системная"
    @State private var locale = "Русский"
    @State private var notifications = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    settingRow("Цветовая тема", value: theme)
                    settingRow("Локализация", value: locale)
                    settingToggle("Уведомления", isOn: $notifications)

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
                    .glassEffect(.regular.tint(.red.opacity(0.2)), in: .rect(cornerRadius: 18))
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

    private func settingRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title).font(.subheadline)
            Spacer()
            Text(value).font(.subheadline).foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    private func settingToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title).font(.subheadline)
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
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
                .glassEffect(.regular, in: .rect(cornerRadius: 22))
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
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
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
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
        } else {
            VStack(spacing: 0) {
                ForEach(Array(digest.events.enumerated()), id: \.element.id) { index, event in
                    eventRow(event)
                    if index < digest.events.count - 1 {
                        Divider().padding(.leading, 58).opacity(0.4)
                    }
                }
            }
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
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
