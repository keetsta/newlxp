import SwiftUI

struct ScheduleView: View {
    @Environment(AppStore.self) private var store
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var weekAnchor = Calendar.current.startOfDay(for: Date())

    private var lessons: [Lesson] { store.lessons(on: selectedDate) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    weekHeader
                    weekStrip
                    weekSummary
                    lessonList
                }
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .background(.background)
            .navigationTitle("Расписание")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Lesson.self) { lesson in
                LessonDetailView(lesson: lesson)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !Calendar.current.isDateInToday(selectedDate) {
                        Button("Сегодня") { selectToday() }
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .task {
                await store.ensureScheduleAround(selectedDate)
            }
        }
    }

    // MARK: - Week navigation

    private var weekHeader: some View {
        HStack {
            Button {
                shiftWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular, in: .circle)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(weekRangeTitle)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()

            Spacer()

            Button {
                shiftWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular, in: .circle)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
    }

    private var weekStrip: some View {
        let cal = Calendar.current
        let weekStart = startOfWeek(for: weekAnchor)
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }
        return HStack(spacing: 8) {
            ForEach(days, id: \.self) { day in
                DayChip(date: day,
                        isSelected: cal.isDate(day, inSameDayAs: selectedDate),
                        isToday: cal.isDateInToday(day)) {
                    selectDay(day)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
    }

    private var weekRangeTitle: String {
        let cal = Calendar.current
        let start = startOfWeek(for: weekAnchor)
        let end = cal.date(byAdding: .day, value: 6, to: start)!
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        if cal.component(.month, from: start) == cal.component(.month, from: end) {
            f.dateFormat = "d"
            let s = f.string(from: start)
            f.dateFormat = "d MMMM"
            let e = f.string(from: end)
            return "\(s)–\(e)"
        }
        f.dateFormat = "d MMM"
        return "\(f.string(from: start)) – \(f.string(from: end))"
    }

    private func startOfWeek(for date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Monday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps)!
    }

    private func shiftWeek(by weeks: Int) {
        guard let newAnchor = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: weekAnchor) else { return }
        withAnimation(.snappy) {
            weekAnchor = newAnchor
            // Pick first day of the new week as selected.
            selectedDate = startOfWeek(for: newAnchor)
        }
        Task { await store.ensureScheduleAround(newAnchor) }
    }

    private func selectDay(_ day: Date) {
        withAnimation(.snappy) { selectedDate = day }
        Task { await store.ensureScheduleAround(day) }
    }

    private func selectToday() {
        let today = Calendar.current.startOfDay(for: Date())
        withAnimation(.snappy) {
            weekAnchor = today
            selectedDate = today
        }
        Task { await store.ensureScheduleAround(today) }
    }

    // MARK: - Summary

    private var weekSummary: some View {
        let wa = store.weekAttendance()
        let rate = wa.rate
        let pct = Int((rate * 100).rounded())
        return VStack(alignment: .leading, spacing: 8) {
            Text("Посещаемость за неделю")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(wa.totalHours > 0 ? "\(pct)%" : "—")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                if wa.totalHours > 0 {
                    Text(detailLine(wa))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Нет данных за последние 7 дней")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            AttendanceBar(rate: rate)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .padding(.horizontal, 18)
    }

    private func detailLine(_ wa: AppStore.AttendanceMetric) -> String {
        let attended = formatHours(wa.attendedHours)
        let total = formatHours(wa.totalHours)
        if wa.missedHours > 0 {
            return "\(attended) из \(total) ч · пропущено \(formatHours(wa.missedHours)) ч"
        }
        return "\(attended) из \(total) ч"
    }

    private func formatHours(_ h: Double) -> String {
        if h.rounded() == h { return String(Int(h)) }
        return String(format: "%.1f", h)
    }

    // MARK: - Lessons

    private var lessonList: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: dateTitle, trailing: lessons.isEmpty ? "" : "\(lessons.count) \(RussianPlural.pairs(lessons.count))")
                .padding(.horizontal, 18)
            if lessons.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                        NavigationLink(value: lesson) {
                            LessonRow(lesson: lesson)
                        }
                        .buttonStyle(.plain)
                        if index < lessons.count - 1 {
                            Divider().padding(.leading, 16).opacity(0.4)
                        }
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: 24).fill(Color.clear)
                        .glassEffect(.regular, in: .rect(cornerRadius: 24))
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 18)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Пар нет")
                .font(.subheadline.weight(.semibold))
            Text("В этот день расписание свободно")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .padding(.horizontal, 18)
    }

    private var dateTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMMM, EEEE"
        return f.string(from: selectedDate).capitalized
    }
}

struct DayChip: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void

    private var weekday: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "EE"
        return f.string(from: date).uppercased()
    }
    private var day: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(weekday)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Text(day)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(isToday ? Color.accentColor : .primary)
                Circle()
                    .frame(width: 4, height: 4)
                    .foregroundStyle(isToday ? Color.accentColor : .clear)
            }
            .frame(height: 78)
            .frame(maxWidth: .infinity)
            .glassEffect(isSelected ? .regular.tint(.accentColor.opacity(0.22)) : .regular,
                          in: .rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

struct LessonDetailView: View {
    let lesson: Lesson

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                if lesson.attendance != .scheduled {
                    attendanceCard
                }
                if let m = lesson.lateMinutes {
                    LateBanner(minutes: m)
                }
                if let link = lesson.meetingLink {
                    meetingLinkButton(link)
                }
                infoCard
                topicLink
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle("Пара")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        GlassCard(padding: 20, corner: 26) {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(lesson.order) пара · \(lesson.timeRange)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                Text(lesson.discipline)
                    .font(.title2.weight(.semibold))
                Text(lesson.topic)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var attendanceCard: some View {
        HStack(spacing: 14) {
            Image(systemName: lesson.attendance.symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(lesson.attendance.tint)
                .frame(width: 44, height: 44)
                .glassEffect(.regular, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text("Посещаемость")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Text(lesson.attendance.label)
                    .font(.body.weight(.semibold))
                if let reason = lesson.attendance.reason {
                    Text(reason)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }

    private var infoCard: some View {
        VStack(spacing: 0) {
            infoRow(symbol: "person", title: "Преподаватель", value: lesson.teacher)
            Divider().padding(.leading, 56).opacity(0.4)
            infoRow(symbol: "mappin.and.ellipse", title: "Аудитория", value: lesson.location)
            Divider().padding(.leading, 56).opacity(0.4)
            infoRow(symbol: "clock", title: "Время", value: lesson.timeRange)
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }

    private func infoRow(symbol: String, title: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline)
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func meetingLinkButton(_ link: URL) -> some View {
        Link(destination: link) {
            HStack(spacing: 12) {
                Image(systemName: "video.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.green))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Подключиться к занятию")
                        .font(.subheadline.weight(.semibold))
                    Text(link.host ?? link.absoluteString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .contentShape(Rectangle())
            .glassEffect(.regular.tint(.green.opacity(0.18)), in: .rect(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var topicLink: some View {
        if let id = lesson.topicId, !id.isEmpty {
            NavigationLink {
                TopicDetailView(topicId: id, fallbackTitle: lesson.topic)
            } label: {
                DisclosureRow(title: "Материалы темы",
                              subtitle: lesson.topic,
                              symbol: "text.book.closed")
                    .padding(16)
                    .glassEffect(.regular, in: .rect(cornerRadius: 22))
            }
            .buttonStyle(.plain)
        }
    }
}

struct TopicDetailView: View {
    @Environment(AppStore.self) private var store
    let topicId: String
    let fallbackTitle: String

    private var detail: TopicDetail? { store.topicDetails[topicId] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if let d = detail {
                    if let how = d.howToStudy, !how.isEmpty {
                        howToStudy(how)
                    }
                    if !d.blocks.isEmpty {
                        blocks(d.blocks)
                    } else {
                        Text("Материалов пока нет")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                    }
                } else {
                    HStack {
                        ProgressView().controlSize(.small)
                        Text("Загружаем материалы…").font(.footnote).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle("Тема")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if detail == nil {
                await store.loadTopicDetail(topicId: topicId)
            }
        }
    }

    private var header: some View {
        GlassCard(padding: 20, corner: 26) {
            VStack(alignment: .leading, spacing: 8) {
                if let topic = detail?.topic {
                    if topic.isCheckpoint {
                        Text("Контрольная точка".uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.blue)
                            .tracking(0.6)
                    }
                    Text(topic.title)
                        .font(.title3.weight(.semibold))
                    HStack(spacing: 14) {
                        Label("\(formatHours(topic.hours)) ч", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let s = topic.score, let m = topic.maxScore, m > 0 {
                            Label("\(Int(s.rounded()))/\(Int(m.rounded()))", systemImage: "star")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Spacer()
                        Text(topic.status.label)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .foregroundStyle(topic.status.tint)
                            .glassEffect(.regular, in: .capsule)
                    }
                } else {
                    Text(fallbackTitle)
                        .font(.title3.weight(.semibold))
                }
            }
        }
    }

    private func howToStudy(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Как изучить")
            GlassCard {
                if let blocks = EditorJSParser.parse(text), !blocks.isEmpty {
                    EditorContentView(blocks: blocks)
                } else {
                    Text(InlineHTML.attributed(text))
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func blocks(_ list: [TopicContentBlock]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Содержание", trailing: "\(list.count)")
            VStack(spacing: 10) {
                ForEach(list) { block in
                    TopicContentBlockCard(block: block)
                }
            }
        }
    }

    private func formatHours(_ h: Double) -> String {
        if h.rounded() == h { return String(Int(h)) }
        return String(format: "%.1f", h)
    }
}

struct TopicContentBlockCard: View {
    let block: TopicContentBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: kindSymbol)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(kindColor)
                Text(kindLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(kindColor)
                    .tracking(0.5)
                Spacer()
                if let m = block.maxScore, m > 0 {
                    Text(scoreText(m: m))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            Text(block.name)
                .font(.body.weight(.semibold))
            bodyView
            if let dl = block.deadline {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                    Text(deadlineText(dl))
                }
                .font(.caption)
                .foregroundStyle(dl < Date() ? .red : .secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    @ViewBuilder
    private var bodyView: some View {
        if !block.body.isEmpty {
            if let blocks = EditorJSParser.parse(block.body), !blocks.isEmpty {
                EditorContentView(blocks: blocks)
            } else {
                Text(InlineHTML.attributed(block.body))
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var kindSymbol: String {
        switch block.kind {
        case .info: "doc.text"
        case .task: "pencil.and.list.clipboard"
        case .test: "checkmark.square"
        }
    }
    private var kindLabel: String {
        switch block.kind {
        case .info: "ИНФОРМАЦИЯ"
        case .task: "ЗАДАНИЕ"
        case .test: "ТЕСТ"
        }
    }
    private var kindColor: Color {
        switch block.kind {
        case .info: .secondary
        case .task: .orange
        case .test: .blue
        }
    }
    private func scoreText(m: Double) -> String {
        if let s = block.score { return "\(Int(s.rounded()))/\(Int(m.rounded()))" }
        return "До \(Int(m.rounded())) б."
    }
    private func deadlineText(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMMM, HH:mm"
        return "Срок: " + f.string(from: d)
    }
}

#Preview {
    ScheduleView()
}
