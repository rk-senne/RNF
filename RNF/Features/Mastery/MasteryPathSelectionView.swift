import SwiftUI

struct MasteryPathSelectionView: View {
    var onSelect: ((MasteryPath.PathType) -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Choose Your Path")
                    .font(RNFFont.heroSubtitle)
                    .padding(.top)

                Text("Habits aligned with your path earn bonus mastery XP.")
                    .font(RNFFont.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                ForEach(MasteryPath.PathType.allCases, id: \.self) { path in
                    Button { onSelect?(path) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(path.rawValue.capitalized)
                                    .font(RNFFont.section)
                                Text(pathDescription(path))
                                    .font(RNFFont.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemBackground)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Mastery")
    }

    private func pathDescription(_ path: MasteryPath.PathType) -> String {
        switch path {
        case .warrior: return "Strength & physical discipline"
        case .scholar: return "Mind & wisdom through knowledge"
        case .monk: return "Spirit & inner discipline"
        case .athlete: return "Energy & endurance"
        case .strategist: return "Focus & mental clarity"
        }
    }
}
