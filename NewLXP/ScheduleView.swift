import SwiftUI

struct ScheduleView: View {
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())

    private var lessons: [Lesson] { AppStore.shared.lessons(on: selectedDate) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    weekStrip
                    monthSummary
                    lessonList
                }
                .padding(.horizontal, 18)
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
        }
    }

    private var weekStrip: some View {
        let cal = Calendar.current
        let weekStart = cal.date(byAdding: .day, value: -3, to: cal.startOfDay(for: Date()))!
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(days, id: \.self) { day in
                    DayChip(date: day,
                            isSelected: cal.isDate(day, inSameDayAs: selectedDate),
                            isToday: cal.isDateInToday(day)) {
                        withAnimation(.snappy) { selectedDate = day }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var monthSummary: some View {
        HStack(spacing: 12) {
            let attended = AppStore.shared.disciplines.reduce(0) { $0 + $1.attendedHours }
            let total = AppStore.shared.disciplines.reduce(0) { $0 + $1.totalHours }
            let rate = total > 0 ? Double(attended) / Double(total) : 0
            VStack(alignment: .leading, spacing: 8) {
                Text("Посещено в этом месяце")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(Int(rate * 100))%")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text("\(attended) из \(total) ч")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                AttendanceBar(rate: rate)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
        }
    }

    private var lessonList: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: dateTitle, trailing: "\(lessons.count) пар")
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
        }
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
                    .foregroundStyle(.primary)
                Circle()
                    .frame(width: 4, height: 4)
                    .foregroundStyle(isToday ? .primary : .secondary)
            }
            .frame(width: 56, height: 78)
            .glassEffect(isSelected ? .regular.tint(.primary.opacity(0.15)) : .regular,
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

    private var topicLink: some View {
        NavigationLink {
            TopicDetailView(disciplineTitle: lesson.discipline, topicTitle: lesson.topic)
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

struct TopicDetailView: View {
    let disciplineTitle: String
    let topicTitle: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(disciplineTitle.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .tracking(0.6)
                        Text(topicTitle)
                            .font(.title3.weight(.semibold))
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Содержание")
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Количество часов для изучения: 4")
                                .font(.subheadline)
                            Text("В данной теме познакомимся с новой дисциплиной. Рассмотрим содержание дисциплины, поговорим о правилах выполнения КТ.")
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text("Цель курса — развивать навыки устной и письменной коммуникации, навыки критического мышления и навыки командной работы.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .background(.background)
        .navigationTitle("Тема")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ScheduleView()
}
