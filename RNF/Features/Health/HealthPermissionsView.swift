import SwiftUI

struct HealthPermissionsView: View {
    var onRequestPermission: (() async -> Void)?
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "heart.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Connect Apple Health")
                .font(.system(size: 22, weight: .bold, design: .rounded))

            Text("Import workouts from Apple Health to automatically credit your daily progress.")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                isRequesting = true
                Task {
                    await onRequestPermission?()
                    isRequesting = false
                }
            } label: {
                Text("Allow Access")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRequesting)
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }
}
