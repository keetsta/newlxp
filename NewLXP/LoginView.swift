import SwiftUI

struct LoginView: View {
    @ObservedObject var store: AppStore
    @State private var email: String = ""
    @State private var password: String = ""
    @FocusState private var focus: Field?

    enum Field { case email, password }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 40)
            VStack(spacing: 6) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 72, height: 72)
                    .lxpGlassCircle()
                Text("NewLXP")
                    .font(.title.weight(.semibold))
                Text("Вход для студентов")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                TextField("E-mail", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .focused($focus, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focus = .password }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .lxpGlass(cornerRadius: 16)

                SecureField("Пароль", text: $password)
                    .focused($focus, equals: .password)
                    .submitLabel(.go)
                    .onSubmit(performLogin)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .lxpGlass(cornerRadius: 16)

                if let err = store.authError {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(action: performLogin) {
                    HStack {
                        if store.isAuthLoading { ProgressView().controlSize(.small) }
                        Text(store.isAuthLoading ? "Входим…" : "Войти")
                            .font(.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .lxpGlass(cornerRadius: 18, tint: .accentColor.opacity(0.25))
                .buttonStyle(.plain)
                .disabled(email.isEmpty || password.isEmpty || store.isAuthLoading)
            }

            Spacer()
            Text("api.newlxp.ru")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 22)
        .background(.background)
        .onAppear { focus = .email }
    }

    private func performLogin() {
        guard !email.isEmpty, !password.isEmpty else { return }
        Task { await store.signIn(email: email, password: password) }
    }
}

#Preview {
    LoginView(store: AppStore.shared)
}
