import SwiftUI

/// Кросс-версионная обёртка над `.glassEffect`. На iOS 26+ использует нативный
/// эффект, на iOS 16-25 — `.ultraThinMaterial` с тем же тинтом.
///
/// Все места, где раньше стояло `.glassEffect(.regular, in: .rect(cornerRadius: X))`
/// или `.glassEffect(.regular.tint(C), in: .rect(...))`, должны звать `.lxpGlass(...)`.
extension View {
    func lxpGlass(cornerRadius: CGFloat, tint: Color? = nil) -> some View {
        modifier(LXPGlassRect(cornerRadius: cornerRadius, tint: tint))
    }

    func lxpGlassCapsule(tint: Color? = nil) -> some View {
        modifier(LXPGlassCapsule(tint: tint))
    }

    func lxpGlassCircle(tint: Color? = nil) -> some View {
        modifier(LXPGlassCircle(tint: tint))
    }
}

private struct LXPGlassRect: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color?

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                content.glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
            } else {
                content.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            content
                .background(.ultraThinMaterial, in: shape)
                .background(tint ?? .clear, in: shape)
                .overlay(shape.strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
        }
    }
}

private struct LXPGlassCapsule: ViewModifier {
    let tint: Color?

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                content.glassEffect(.regular.tint(tint), in: .capsule)
            } else {
                content.glassEffect(.regular, in: .capsule)
            }
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
                .background(tint ?? .clear, in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
        }
    }
}

private struct LXPGlassCircle: ViewModifier {
    let tint: Color?

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                content.glassEffect(.regular.tint(tint), in: .circle)
            } else {
                content.glassEffect(.regular, in: .circle)
            }
        } else {
            content
                .background(.ultraThinMaterial, in: Circle())
                .background(tint ?? .clear, in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
        }
    }
}
