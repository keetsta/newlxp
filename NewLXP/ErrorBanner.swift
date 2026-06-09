import SwiftUI

/// Транзиентный баннер ошибки в верхней части экрана. Подписан на
/// `AppStore.lastError`: всплывает при появлении, через ~3 секунды сам прячется,
/// и `lastError` обнуляется. Показывается поверх контента, не блокируя UI.
///
/// Пишется ТОЛЬКО для пользовательских действий (submit/delete ответа,
/// signIn). Фоновые загрузки (расписание/дисциплины/задания/ответы) не
/// дёргают баннер — там уже есть кэш и локальные «Повторить».
struct ErrorBanner: View {
    @EnvironmentObject private var store: AppStore
    @State private var visibleMessage: String?
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        VStack {
            if let msg = visibleMessage {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .lxpGlass(cornerRadius: 14, tint: .red.opacity(0.10))
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
            try? await Task.sleep(nanoseconds: 3_000_000_000)
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
