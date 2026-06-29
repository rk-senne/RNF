import SwiftUI

struct HabitSelectionView: View {

    var onComplete: () -> Void

    @State private var selected: Set<String> = []

    private let maxSelection = 3

    var body: some View {
        VStack(alignment: .leading, spacing: RNFSpacing.lg) {

            Spacer(minLength: RNFSpacing.lg)

            VStack(alignment: .leading, spacing: 12) {
                Text("CHOOSE YOUR HABITS")
                    .overlineStyle()

                Text("Pick 3 Daily Habits")
                    .font(RNFFont.display)
                    .foregroundStyle(Color.primary)

                Text("These will form your daily discipline loop.")
                    .font(RNFFont.sectionMedium)
                    .foregroundStyle(Color.secondary)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: RNFSpacing.lg) {
                    ForEach(HabitPreset.Category.allCases, id: \.self) { category in
                        categorySection(category)
                    }
                }
            }

            Button(action: {
                RNFHaptics.buttonTap()
                HabitAgencyService.saveSelections(Array(selected))
                onComplete()
            }) {
                Text("Continue")
                    .font(RNFFont.bodyBold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selected.count != maxSelection)

            Spacer(minLength: RNFSpacing.sm)
        }
        .padding(RNFSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    // MARK: - Category Section

    @ViewBuilder
    private func categorySection(_ category: HabitPreset.Category) -> some View {
        let presets = HabitPreset.all.filter { $0.category == category }
        VStack(alignment: .leading, spacing: RNFSpacing.sm) {
            Text(category.rawValue)
                .font(RNFFont.section)
                .foregroundStyle(Color.primary)

            ForEach(presets) { preset in
                presetRow(preset)
            }
        }
    }

    // MARK: - Preset Row

    @ViewBuilder
    private func presetRow(_ preset: HabitPreset) -> some View {
        let isSelected = selected.contains(preset.id)
        Button {
            toggle(preset.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(RNFFont.iconLabel)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(RNFFont.bodySemibold)
                        .foregroundStyle(Color.primary)
                    Text("+\(preset.stat)")
                        .font(RNFFont.caption)
                        .foregroundStyle(Color.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, RNFSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preset.name), targets \(preset.stat)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Selection Logic

    private func toggle(_ id: String) {
        if selected.contains(id) {
            selected.remove(id)
        } else if selected.count < maxSelection {
            selected.insert(id)
        }
    }
}

#Preview {
    NavigationStack {
        HabitSelectionView(onComplete: {})
    }
}
