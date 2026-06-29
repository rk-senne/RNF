import SwiftUI

struct EveningReflectionView: View {

    @EnvironmentObject private var game: GameState
    @EnvironmentObject private var ritualManager: RitualManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Victory acknowledgment — not a data dump
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(RNFColors.success)

            Text("Day complete.")
                .font(RNFFont.titleMedium)
                .foregroundStyle(.primary)

            // Key stat — only the one thing that matters most
            VStack(spacing: 8) {
                Text("\(game.streak) day streak")
                    .font(RNFFont.cardTitle)
                    .foregroundStyle(RNFColors.streak)

                Text("+\(todayXP) XP earned today")
                    .font(RNFFont.body)
                    .foregroundStyle(.secondary)
            }

            // Closing line — human, warm, brief
            Text("Tomorrow is day \(game.streak + 1). Rest well.")
                .font(.system(size: 15, weight: .medium, design: .serif))
                .italic()
                .foregroundStyle(.tertiary)

            Text(QuoteEngine.todayQuote().text)
                .font(.system(size: 13, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(.quaternary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                RNFHaptics.buttonTap()
                ritualManager.dismissEvening()
            } label: {
                Text("Close Day")
                    .font(RNFFont.bodyBold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Close today and end session")
            .padding(.bottom, 48)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .presentationDetents([.medium])
    }

    private var todayXP: Int {
        // Approximate from daily completed habits
        game.dailyCompleted * 10
    }
}
