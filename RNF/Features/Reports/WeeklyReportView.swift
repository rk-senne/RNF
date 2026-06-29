import SwiftUI

// P20-EXP-17b: Weekly report full-screen view
struct WeeklyReportView: View {
    let report: WeeklyReport
    let onDismiss: () -> Void

    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("WEEK \(report.weekNumber)")
                .font(RNFFont.overline)
                .tracking(1.2)
                .foregroundStyle(RNFColors.textSecondary)

            Text("Weekly Report")
                .font(RNFFont.title)
                .foregroundStyle(RNFColors.textPrimary)

            VStack(spacing: 16) {
                reportRow("Days Active", "\(report.daysActive)/7")
                reportRow("Habits Completed", "\(report.habitsCompleted)")
                reportRow("XP Earned", "\(report.xpEarned)")
                reportRow("Streak", "\(report.streakLength) days")
                reportRow("Best Day", "\(report.bestDayXP) XP")
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                    .fill(RNFColors.surface)
            )

            Spacer()

            Button("Share Week") { showShareSheet = true }
                .font(RNFFont.bodyBold)
                .foregroundStyle(RNFColors.primary)
                .padding(.bottom, 8)

            Button(action: onDismiss) {
                Text("Continue")
                    .font(RNFFont.bodyBold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RNFColors.primary, in: RoundedRectangle(cornerRadius: RNFRadius.md))
                    .foregroundStyle(.white)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).ignoresSafeArea())
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
    }

    private func reportRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(RNFFont.body).foregroundStyle(RNFColors.textSecondary)
            Spacer()
            Text(value).font(RNFFont.bodyBold).foregroundStyle(RNFColors.textPrimary)
        }
    }

    private var shareText: String {
        "RNF Week \(report.weekNumber): \(report.daysActive) days active, \(report.xpEarned) XP earned, \(report.streakLength) day streak 🔥"
    }
}
