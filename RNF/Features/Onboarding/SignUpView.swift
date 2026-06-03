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
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(Color.accentColor)

                Text("RNF")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Color.secondary)

                Text("Create Account")
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
                    .textContentType(.newPassword)
                    .submitLabel(.next)
                    .textFieldStyle(.roundedBorder)

                SecureField("Confirm Password", text: $confirmedPassword)
                    .textContentType(.newPassword)
                    .submitLabel(.go)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(signUp)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: signUp) {
                HStack(spacing: 10) {
                    if isSigningUp {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Text(isSigningUp ? "Creating Account" : "Continue")
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
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !confirmedPassword.isEmpty && !isSigningUp
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
