import SwiftUI

/// Shimmer-плейсхолдер на время загрузки. Используется когда стор пустой
/// и идёт активный запрос — чтобы вьюха не моргала «ничего нет».
struct SkeletonRect: View {
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 6

    @State private var phase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.secondary.opacity(0.18))
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .white.opacity(0.25),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 200)
                .blendMode(.plusLighter)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .frame(height: height)
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

/// Вьюха-карточка скелетон-варианта строки урока для расписания/главной.
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
