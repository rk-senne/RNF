import SwiftUI

struct SignUpView: View {

    private let authService: AuthService
    private let onSignUp: (SignUpResult) -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var confirmedPassword = ""
    @State private var isSigningUp = false
    @State private var errorMessage: String?

    init(
        authService: AuthService = AuthService(),
        onSignUp: @escaping (SignUpResult) -> Void = { _ in }
    ) {
        self.authService = authService
        self.onSignUp = onSignUp
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

                Text("Activate The Forge")
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
                    .textContentType(.newPassword)
                    .submitLabel(.next)
                    .textFieldStyle(.roundedBorder)

                Text("Minimum 8 characters")
                    .font(RNFFont.caption)
                    .foregroundStyle(password.isEmpty ? Color.secondary.opacity(0.5) : (password.count >= 8 ? RNFColors.success : RNFColors.destructive))

                SecureField("Confirm Password", text: $confirmedPassword)
                    .textContentType(.newPassword)
                    .submitLabel(.go)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(signUp)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(RNFFont.caption)
                    .foregroundStyle(RNFColors.destructive)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: signUp) {
                HStack(spacing: 10) {
                    if isSigningUp {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Text(isSigningUp ? "Creating Account" : "Continue")
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
                            onSignUp(SignUpResult(session: session, userId: session.user.id, email: session.user.email))
                        } catch {
                            errorMessage = "Apple Sign-In failed. Try again."
                        }
                    }
                },
                onError: { _ in
                    errorMessage = "Apple Sign-In was cancelled."
                }
            )

            // P21-NAV-06: Navigate to Login
            NavigationLink("Already have an account? Sign In") {
                LoginView(authService: authService, onLogin: { session in
                    onSignUp(SignUpResult(session: session, userId: session.user.id, email: session.user.email))
                })
            }
            .font(RNFFont.body)
            .frame(maxWidth: .infinity)

            Spacer(minLength: 24)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canSubmit: Bool {
        isValidEmail(email) && password.count >= 8 && password == confirmedPassword && !isSigningUp
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private var motivationalLine: String {
        let lines = [
            "Most people live unranked. You chose differently.",
            "The system activates only under one condition: commitment.",
            "What you build here, no one can take from you.",
            "The Forge does not care about intentions. Only actions."
        ]
        return lines[Calendar.current.component(.day, from: Date()) % lines.count]
    }

    private func signUp() {
        guard canSubmit else {
            return
        }

        guard password == confirmedPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isSigningUp = true
        errorMessage = nil

        Task {
            do {
                let result = try await authService.signUp(
                    email: email,
                    password: password
                )
                isSigningUp = false
                onSignUp(result)
            } catch {
                isSigningUp = false
                errorMessage = "Unable to create account. Try again."
            }
        }
    }

}

#Preview {
    NavigationStack {
        SignUpView()
    }
}
