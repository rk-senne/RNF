import SwiftUI

struct GuildView: View {
    let guild: Guild?
    var onCreate: ((String) -> Void)?
    var onJoin: ((UUID) -> Void)?

    @State private var newGuildName = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let guild {
                    guildCard(guild)
                } else {
                    createGuildSection
                }
            }
            .padding()
        }
        .navigationTitle("Guild")
    }

    private func guildCard(_ guild: Guild) -> some View {
        VStack(spacing: 12) {
            Text(guild.name)
                .font(RNFFont.section)
            HStack(spacing: 20) {
                Label("\(guild.memberCount)", systemImage: "person.2.fill")
                Label("\(guild.totalXP) XP", systemImage: "star.fill")
            }
            .font(RNFFont.body)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemBackground)))
    }

    private var createGuildSection: some View {
        VStack(spacing: 12) {
            Text("Create a Guild")
                .font(RNFFont.section)
            TextField("Guild name", text: $newGuildName)
                .textFieldStyle(.roundedBorder)
            Button("Create") { onCreate?(newGuildName) }
                .buttonStyle(.borderedProminent)
                .disabled(newGuildName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.secondarySystemBackground)))
    }
}
