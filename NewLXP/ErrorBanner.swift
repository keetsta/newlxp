import SwiftUI

/// Транзиентный баннер ошибки в верхней части экрана. Подписан на
/// `AppStore.lastError`: всплывает при появлении, через ~5 секунд сам прячется,
/// и `lastError` обнуляется. Показывается поверх контента, не блокируя UI.
struct ErrorBanner: View {
    @EnvironmentObject private var store: AppStore
    @State private var visibleMessage: String?
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        VStack {
            if let msg = visibleMessage {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Не удалось обновить данные")
                            .font(.subheadline.weight(.semibold))
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 8)
                    Button {
                        dismiss()
                    } label: {
                        // Хитпойнт у одного «голого» SF Symbol .caption размера —
                        // буквально ~10pt, попасть в него без увеличения экрана
                        // нереально. Выдаём кнопке нормальный target 32×32 и
                        // прозрачный hit shape, чтобы тапалось всё это поле.
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .lxpGlass(cornerRadius: 16, tint: .red.opacity(0.18))
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: visibleMessage)
        .onChange(of: store.lastError) { newValue in
            handleErrorChange(newValue)
        }
    }

    private func handleErrorChange(_ newError: String?) {
        guard let newError, !newError.isEmpty else { return }
        visibleMessage = newError
        hideTask?.cancel()
        hideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    private func dismiss() {
        visibleMessage = nil
        store.lastError = nil
        hideTask?.cancel()
    }
}
