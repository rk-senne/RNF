import SwiftUI
import AuthenticationServices

/// Reusable Sign in with Apple button component.
/// Integrates into LoginView and SignUpView.
struct AppleSignInButton: View {
    let onSuccess: (ASAuthorizationAppleIDCredential) -> Void
    let onError: (Error) -> Void

    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.email, .fullName]
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                    onSuccess(credential)
                }
            case .failure(let error):
                onError(error)
            }
        }
        .signInWithAppleButtonStyle(.white)
        .frame(height: 50)
        .cornerRadius(RNFRadius.md)
        .accessibilityLabel("Sign in with Apple")
    }
}
