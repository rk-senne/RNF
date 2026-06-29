import SwiftUI

struct DayDetailSheet: View {
    let date: Date
    let status: DailyLogStatus

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(date.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(RNFFont.section)
                Spacer()
                statusBadge
            }

            Divider()

            HStack(spacing: 12) {
                Image(systemName: statusIcon)
                    .font(RNFFont.heroSubtitle)
                    .foregroundStyle(statusColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(RNFFont.bodyBold)
                    Text(statusDescription)
                        .font(RNFFont.body)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Spacer()
        }
        .padding(24)
        .presentationDetents([.height(200)])
    }

    private var statusBadge: some View {
        Text(status.rawValue.capitalized)
            .font(RNFFont.pill)
            .foregroundStyle(statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(statusColor.opacity(0.12)))
    }

    private var statusIcon: String {
        switch status {
        case .complete: return "checkmark.circle.fill"
        case .partial: return "circle.lefthalf.filled"
        case .missed: return "xmark.circle.fill"
        case .forgiven: return "heart.circle.fill"
        }
    }

    private var statusColor: Color {
        switch status {
        case .complete: return RNFColors.success
        case .partial: return Color(red: 0.75, green: 0.91, blue: 0.68)
        case .missed: return RNFColors.textTertiary
        case .forgiven: return RNFColors.success
        }
    }

    private var statusTitle: String {
        switch status {
        case .complete: return "Day Completed"
        case .partial: return "Partially Completed"
        case .missed: return "Day Missed"
        case .forgiven: return "Protected by Forgiveness"
        }
    }

    private var statusDescription: String {
        switch status {
        case .complete: return "All daily goals were met."
        case .partial: return "Some goals completed."
        case .missed: return "No progress recorded."
        case .forgiven: return "Streak preserved with a forgiveness token."
        }
    }
}
