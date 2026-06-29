import SwiftUI

struct CustomHabitCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedStat = "Discipline"
    let onSave: (CustomHabit) -> Void

    private let stats = ["Strength", "Discipline", "Focus", "Energy", "Wisdom", "Mind", "Spirit"]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("You earned this. Name your discipline.")
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(.secondary)

                TextField("Habit name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Custom habit name")
                    .onChange(of: name) { _, new in if new.count > 50 { name = String(new.prefix(50)) } }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Stat").font(RNFFont.caption).foregroundStyle(.secondary)
                    Picker("Stat", selection: $selectedStat) {
                        ForEach(stats, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Choose which stat this habit builds")
                }

                Spacer()

                Button {
                    let habit = CustomHabit(name: name.trimmingCharacters(in: .whitespaces), stat: selectedStat.lowercased())
                    onSave(habit)
                    dismiss()
                } label: {
                    Text("Forge It")
                        .font(RNFFont.bodyBold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(24)
            .navigationTitle("Custom Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
