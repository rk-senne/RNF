import SwiftUI

struct CommitmentView: View {

    var onBegin: () -> Void = {}

    @State private var acceptedCommitment = false

    var body: some View {

        VStack(alignment: .leading, spacing: 24) {

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 12) {
                Text("COMMITMENT")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Color.secondary)

                Text("Commit to 90 Days")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("This is structured progression. Consistency matters more than perfection.")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                acceptedCommitment.toggle()
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: acceptedCommitment ? "checkmark.square.fill" : "square")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(acceptedCommitment ? Color.accentColor : Color.secondary)

                    Text("I understand this requires daily consistency.")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onBegin) {
                Text("Begin Day 1")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!acceptedCommitment)

            Spacer(minLength: 24)

        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .navigationTitle("Commitment")
        .navigationBarTitleDisplayMode(.inline)

    }

}

#Preview {
    NavigationStack {
        CommitmentView()
    }
}
