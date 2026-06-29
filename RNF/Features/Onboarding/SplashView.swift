import SwiftUI

struct SplashView: View {

    @State private var glowing = false
    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    var body: some View {

        VStack(spacing: 20) {
            Spacer(minLength: 24)

            Image(systemName: "flame.fill")
                .font(.system(size: 48, weight: .black))
                .foregroundStyle(Color.accentColor)
                .frame(width: 96, height: 96)
                .scaleEffect(glowing ? 1.06 : 1.0)
                .opacity(glowing ? 1.0 : 0.85)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(glowing ? 0.18 : 0.12))
                        .scaleEffect(glowing ? 1.1 : 1.0)
                )
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                        glowing = true
                    }
                }

            VStack(spacing: 10) {
                Text("RNF")
                    .font(RNFFont.display)
                    .foregroundStyle(Color.primary)

                Text("Every human carries a dormant Forge. Most never activate theirs.")
                    .font(RNFFont.section)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 24)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

}

#Preview {
    SplashView()
}
