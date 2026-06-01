import SwiftUI

enum RussianPlural {
    /// Picks one of three forms by Russian plural rules.
    /// - one: «пара», «минута», «час»
    /// - few: «пары», «минуты», «часа»
    /// - many: «пар», «минут», «часов»
    static func form(_ n: Int, one: String, few: String, many: String) -> String {
        let mod10 = abs(n) % 10
        let mod100 = abs(n) % 100
        if mod10 == 1 && mod100 != 11 { return one }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return few }
        return many
    }

    static func pairs(_ n: Int) -> String { form(n, one: "пара", few: "пары", many: "пар") }
    static func minutes(_ n: Int) -> String { form(n, one: "минута", few: "минуты", many: "минут") }
    static func hours(_ n: Int) -> String { form(n, one: "час", few: "часа", many: "часов") }
}

/// Formats a positive minute count as a short countdown:
/// 25 → "25 мин", 60 → "1 ч", 90 → "1 ч 30 мин", 120 → "2 ч".
func formatMinutesAsCountdown(_ totalMinutes: Int) -> String {
    let m = max(0, totalMinutes)
    if m < 60 { return "\(m) \(RussianPlural.minutes(m))" }
    let hours = m / 60
    let mins = m % 60
    let h = "\(hours) \(RussianPlural.hours(hours))"
    if mins == 0 { return h }
    return "\(h) \(mins) \(RussianPlural.minutes(mins))"
}

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 18
    var corner: CGFloat = 24
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: corner))
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }
}

struct AttendanceDot: View {
    let status: AttendanceStatus

    var body: some View {
        Group {
            switch status {
            case .present, .online:
                Circle().fill(.green)
            case .absent:
                Circle().fill(.red)
            case .noMark:
                Circle().strokeBorder(.secondary, lineWidth: 1.5)
            case .scheduled:
                Circle().strokeBorder(.tertiary, lineWidth: 1)
            }
        }
        .frame(width: 8, height: 8)
    }
}

struct AttendanceBadge: View {
    let status: AttendanceStatus
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.symbol)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(status.tint)
            if !compact {
                VStack(alignment: .leading, spacing: 0) {
                    Text(status.label)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                    if let reason = status.reason {
                        Text(reason)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 4 : 6)
        .glassEffect(.regular, in: .capsule)
    }
}

struct AttendanceBar: View {
    let rate: Double

    private var color: Color {
        if rate >= 0.75 { return .green }
        if rate >= 0.5 { return .yellow }
        return .red
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * rate)
            }
        }
        .frame(height: 4)
    }
}

struct DisclosureRow: View {
    let title: String
    var subtitle: String? = nil
    var symbol: String? = nil
    var badge: String? = nil

    var body: some View {
        HStack(spacing: 14) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(width: 28)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let badge {
                Text(badge)
                    .font(.footnote.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}

struct LateBanner: View {
    let minutes: Int

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "clock.badge.exclamationmark.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.orange)
                .frame(width: 40, height: 40)
                .glassEffect(.regular, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text("Опоздание")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(minutes)")
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                    Text(RussianPlural.minutes(minutes))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(14)
        .glassEffect(.regular.tint(.orange.opacity(0.18)), in: .rect(cornerRadius: 20))
    }
}

struct LessonRow: View {
    let lesson: Lesson

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(lesson.order) пара")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Text(lesson.timeRange)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            .frame(width: 78, alignment: .leading)

            Rectangle()
                .frame(width: 1)
                .foregroundStyle(.quaternary)

            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.discipline)
                    .font(.body.weight(.semibold))
                    .lineLimit(2)
                Text(lesson.topic)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                        Text(lesson.location)
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                    if let m = lesson.lateMinutes {
                        HStack(spacing: 3) {
                            Image(systemName: "clock.badge.exclamationmark.fill")
                            Text("+\(m) мин")
                                .monospacedDigit()
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .glassEffect(.regular.tint(.orange.opacity(0.15)), in: .capsule)
                    }
                }
            }

            Spacer(minLength: 0)

            if lesson.attendance != .scheduled {
                AttendanceDot(status: lesson.attendance)
                    .padding(.top, 6)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

struct CountTile: View {
    let title: String
    let value: Int
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.primary)
            Text("\(value)")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .contentShape(Rectangle())
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }
}
