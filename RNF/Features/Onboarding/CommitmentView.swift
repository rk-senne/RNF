import SwiftUI

struct CommitmentView: View {

    var onBegin: () -> Void = {}

    @State private var acceptedCommitment = false
    @State private var gradientPulse = false
    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    var body: some View {

        VStack(alignment: .leading, spacing: 24) {

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 12) {
                Text("COMMITMENT")
                    .overlineStyle()

                Text("Activate The Forge")
                    .font(RNFFont.display)
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Every human carries a dormant Forge within them. Most never activate it. You're about to.")
                    .font(RNFFont.sectionMedium)
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                acceptedCommitment.toggle()
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: acceptedCommitment ? "checkmark.square.fill" : "square")
                        .font(RNFFont.iconLabel)
                        .foregroundStyle(acceptedCommitment ? Color.accentColor : Color.secondary)

                    Text("I understand the Forge demands daily consistency. I choose this.")
                        .font(RNFFont.bodySemibold)
                        .foregroundStyle(Color.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: {
                RNFHaptics.buttonTap()
                onBegin()
            }) {
                Text("Ignite")
                    .font(RNFFont.bodyBold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!acceptedCommitment)

            Spacer(minLength: 24)

        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background {
            ZStack {
                Color(.systemBackground)
                RadialGradient(
                    colors: [RNFColors.streak.opacity(gradientPulse ? 0.12 : 0.06), .clear],
                    center: .center,
                    startRadius: 50,
                    endRadius: 300
                )
            }
            .ignoresSafeArea()
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    gradientPulse = true
                }
            }
        }
        .navigationTitle("Commitment")
        .navigationBarTitleDisplayMode(.inline)

    }

}

#Preview {
    NavigationStack {
        CommitmentView()
    }
}
