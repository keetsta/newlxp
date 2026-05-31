import SwiftUI

struct HomeView: View {
    @State private var showNotifications = false

    private var lessons: [Lesson] { AppStore.shared.todayLessons }
    private var current: Lesson? { AppStore.shared.currentLesson }
    private var next: Lesson? { AppStore.shared.nextLesson }
    private var deadline: Assignment? { AppStore.shared.nearestDeadline }
    private var digest: Digest? { AppStore.shared.digests.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    heroBlock
                    metrics
                    digestStrip
                    todaySchedule
                }
                .padding(.horizontal, 18)
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .background(.background)
            .navigationTitle("Главная")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Lesson.self) { lesson in
                LessonDetailView(lesson: lesson)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNotifications = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .font(.body.weight(.semibold))
                            if AppStore.shared.unreadNotifications > 0 {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -2)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsView()
            }
        }
    }

    @ViewBuilder
    private var heroBlock: some View {
        if let lesson = current {
            NavigationLink(value: lesson) { heroCard(lesson: lesson, leading: "Сейчас идёт") }
                .buttonStyle(.plain)
        } else if let lesson = next {
            let minutes = max(0, Int(lesson.start.timeIntervalSinceNow / 60))
            NavigationLink(value: lesson) {
                heroCard(lesson: lesson, leading: minutes > 0 ? "Через \(minutes) мин" : "Скоро")
            }
            .buttonStyle(.plain)
        } else {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Пары на сегодня закончились")
                        .font(.title3.weight(.semibold))
                    Text("Хорошего отдыха")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func heroCard(lesson: Lesson, leading: String) -> some View {
        GlassCard(padding: 20, corner: 28) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(leading.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.6)
                    Spacer()
                    Text("\(lesson.order) пара")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .glassEffect(.regular, in: .capsule)
                }
                Text(lesson.discipline)
                    .font(.title2.weight(.semibold))
                    .lineLimit(2)
                Text(lesson.topic)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                Divider().opacity(0.5)
                HStack(spacing: 10) {
                    Label(lesson.timeRange, systemImage: "clock")
                        .monospacedDigit()
                    Text("·").foregroundStyle(.tertiary)
                    Label(lesson.location, systemImage: "mappin.and.ellipse")
                    Spacer()
                    if lesson.attendance != .scheduled {
                        AttendanceBadge(status: lesson.attendance, compact: true)
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var metrics: some View {
        HStack(spacing: 12) {
            let total = lessons.count
            let done = lessons.filter { $0.isPast }.count
            CountTile(title: "Пары сегодня", value: total, symbol: "calendar")
            CountTile(title: "Пройдено", value: done, symbol: "checkmark")
        }
    }

    @ViewBuilder
    private var digestStrip: some View {
        if let digest {
            NavigationLink {
                DigestDetailView(digest: digest)
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.body.weight(.semibold))
                        .frame(width: 32, height: 32)
                        .glassEffect(.regular, in: .circle)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Дайджест дня")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                        Text(digest.oneLine)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
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
    }

    private var todaySchedule: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Сегодня", trailing: "\(lessons.count) пар")
            VStack(spacing: 0) {
                ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                    NavigationLink(value: lesson) {
                        LessonRow(lesson: lesson)
                    }
                    .buttonStyle(.plain)
                    if index < lessons.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                            .opacity(0.4)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.clear)
                    .glassEffect(.regular, in: .rect(cornerRadius: 24))
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}

#Preview {
    HomeView()
}
