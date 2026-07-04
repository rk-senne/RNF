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
                    .font(RNFFont.titleLarge)
                    .foregroundStyle(Color.accentColor)

                Text("RNF")
                    .overlineStyle()

                Text("The Forge Awaits")
                    .font(RNFFont.display)
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
                    .font(RNFFont.caption)
                    .foregroundStyle(RNFColors.destructive)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: login) {
                HStack(spacing: 10) {
                    if isLoggingIn {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Text(isLoggingIn ? "Signing In" : "Continue")
                        .font(RNFFont.bodyBold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSubmit)

            Text(motivationalLine)
                .font(RNFFont.caption)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            // P21-FIX-10: Sign in with Apple
            AppleSignInButton(
                onSuccess: { credential in
                    Task {
                        do {
                            let session = try await authService.signInWithApple(credential: credential)
                            onLogin(session)
                        } catch {
                            errorMessage = "Apple Sign-In failed. Try again."
                        }
                    }
                },
                onError: { _ in
                    errorMessage = "Apple Sign-In was cancelled."
                }
            )

            // P21-NAV-06: Navigate to Sign Up
            NavigationLink("Create Account") {
                SignUpView(authService: authService, onSignUp: { result in
                    if let session = result.session {
                        onLogin(session)
                    }
                })
            }
            .font(RNFFont.body)
            .frame(maxWidth: .infinity)

            Spacer(minLength: 24)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var motivationalLine: String {
        let lines = [
            "The system remembers those who return.",
            "Your flame was never extinguished. Only dimmed.",
            "Absence is not failure. Return is proof.",
            "The Forge is patient. It was always here."
        ]
        return lines[Calendar.current.component(.day, from: Date()) % lines.count]
    }

    private var canSubmit: Bool {
        isValidEmail(email) && !password.isEmpty && !isLoggingIn
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return email.range(of: pattern, options: .regularExpression) != nil
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
