import SwiftUI

struct ErrorBanner: View {
    let message: String
    var retryAction: (() -> Void)?
    var dismissAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            Text(message)
                .font(RNFFont.body)
                .lineLimit(2)

            Spacer()

            if let retryAction {
                Button(action: retryAction) {
                    Text("Retry")
                        .font(RNFFont.caption)
                        .foregroundStyle(.blue)
                }
            }

            if let dismissAction {
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .font(RNFFont.captionBoldSmall)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Dismiss error")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }
}

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .foregroundStyle(.secondary)
            Text("No internet connection")
                .font(RNFFont.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("No internet connection")
    }
}
