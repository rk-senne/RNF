import SwiftUI
import Supabase

struct LoginView: View {

    private let authService: AuthService
    private let onLogin: (Session) -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isLoggingIn = false
    @State private var errorMessage: String?

    init(
        authService: AuthService = AuthService(),
        onLogin: @escaping (Session) -> Void = { _ in }
    ) {
        self.authService = authService
        self.onLogin = onLogin
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(Color.accentColor)

                Text("RNF")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Color.secondary)

                Text("Welcome Back")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 14) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .submitLabel(.next)
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .submitLabel(.go)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(login)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: login) {
                HStack(spacing: 10) {
                    if isLoggingIn {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Text(isLoggingIn ? "Signing In" : "Continue")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSubmit)

            Spacer(minLength: 24)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !isLoggingIn
    }

    private func login() {
        guard canSubmit else {
            return
        }

        isLoggingIn = true
        errorMessage = nil

        Task {
            do {
                let session = try await authService.login(
                    email: email,
                    password: password
                )
                isLoggingIn = false
                onLogin(session)
            } catch {
                isLoggingIn = false
                errorMessage = "Unable to sign in. Check your email and password."
            }
        }
    }

}

#Preview {
    NavigationStack {
        LoginView()
    }
}
