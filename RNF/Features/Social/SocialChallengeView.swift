import SwiftUI

struct SocialChallengeView: View {
    let challenges: [SocialChallenge]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(challenges) { challenge in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(challenge.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        if let desc = challenge.description {
                            Text(desc)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: challenge.progress)
                            .tint(.green)
                        Text("\(challenge.current_completions)/\(challenge.target_completions)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(.secondarySystemBackground)))
                }
            }
            .padding()
        }
        .navigationTitle("Challenges")
    }
}
