import SwiftUI

/// Shimmer-плейсхолдер на время загрузки. Рисуется как RoundedRect с заливкой
/// secondary.opacity и бликом, бегущим слева направо. Цикл бесшовный: блик
/// уезжает за правый край и появляется слева в одной фазе; никаких видимых
/// прыжков. Все скелетоны на экране синхронизированы через общий `TimelineView`.
struct SkeletonRect: View {
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 6

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            shimmer(at: context.date)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    /// Расчёт фазы 0..1 от текущего момента — общий tick для всех скелетонов
    /// на экране, поэтому блики идут синхронно. Период 1.5 сек.
    private func shimmer(at date: Date) -> some View {
        let period: TimeInterval = 1.5
        let phase = (date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period)) / period
        return GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.secondary.opacity(0.18))

                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .white.opacity(0.35),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                // Полоса блика шириной 0.5 ширины контейнера движется от
                // -0.5 (полностью слева) до 1.0 (полностью справа за правым
                // краем). На -0.5 и 1.0 блик невидим, так что цикл бесшовный.
                .frame(width: geo.size.width * 0.5, height: geo.size.height)
                .offset(x: -geo.size.width * 0.5 + (geo.size.width * 1.5) * CGFloat(phase))
                .blendMode(.plusLighter)
            }
        }
    }
}

/// Скелетон-вариант строки урока для расписания/главной.
struct SkeletonLessonRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                SkeletonRect(height: 10, cornerRadius: 4).frame(width: 50)
                SkeletonRect(height: 14, cornerRadius: 4).frame(width: 70)
            }
            .frame(width: 78, alignment: .leading)
            Rectangle().frame(width: 1).foregroundStyle(.quaternary)
            VStack(alignment: .leading, spacing: 6) {
                SkeletonRect(height: 14).frame(maxWidth: .infinity)
                SkeletonRect(height: 12).frame(width: 180)
                SkeletonRect(height: 10, cornerRadius: 4).frame(width: 110)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}

/// Скелетон для карточки дисциплины (DisciplinesView).
struct SkeletonDisciplineCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            SkeletonRect(height: 36, cornerRadius: 10).frame(width: 36)
            VStack(alignment: .leading, spacing: 6) {
                SkeletonRect(height: 14).frame(maxWidth: 220)
                SkeletonRect(height: 10, cornerRadius: 4).frame(width: 140)
            }
            Spacer(minLength: 8)
            SkeletonRect(height: 30, cornerRadius: 15).frame(width: 30)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lxpGlass(cornerRadius: 22)
    }
}

/// Скелетон для строки задания.
struct SkeletonAssignmentCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SkeletonRect(height: 10, cornerRadius: 4).frame(width: 90)
            SkeletonRect(height: 16).frame(maxWidth: .infinity)
            SkeletonRect(height: 12).frame(width: 200)
            SkeletonRect(height: 10, cornerRadius: 4).frame(width: 130)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lxpGlass(cornerRadius: 22)
    }
}
