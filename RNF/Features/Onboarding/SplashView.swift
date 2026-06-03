import SwiftUI

struct SplashView: View {

    var body: some View {

        VStack(spacing: 20) {
            Spacer(minLength: 24)

            Image(systemName: "flame.fill")
                .font(.system(size: 48, weight: .black))
                .foregroundStyle(Color.accentColor)
                .frame(width: 96, height: 96)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                )

            VStack(spacing: 10) {
                Text("RNF")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(Color.primary)

                Text("Turn daily habits into lasting discipline.")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
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
