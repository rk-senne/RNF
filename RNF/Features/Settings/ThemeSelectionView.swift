import SwiftUI

// MARK: - P28-INC-05: Theme Selection View

/// Persona theme selection — used in both onboarding flow and settings.
/// Shows theme options with preview of accent colors and sample text.
struct ThemeSelectionView: View {

    @ObservedObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss

    /// Whether this is shown during onboarding (no dismiss button).
    var isOnboarding: Bool = false

    /// Callback when selection is confirmed (used in onboarding flow).
    var onConfirm: (() -> Void)?

    @State private var selectedTheme: PersonaTheme

    init(
        themeProvider: ThemeProvider = .shared,
        isOnboarding: Bool = false,
        onConfirm: (() -> Void)? = nil
    ) {
        self.themeProvider = themeProvider
        self.isOnboarding = isOnboarding
        self.onConfirm = onConfirm
        self._selectedTheme = State(initialValue: themeProvider.currentTheme)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: RNFSpacing.lg) {
                headerSection

                ForEach(PersonaTheme.allCases) { theme in
                    themeCard(for: theme)
                }

                confirmButton
            }
            .padding(.horizontal, RNFSpacing.md)
            .padding(.vertical, RNFSpacing.lg)
        }
        .navigationTitle("Choose Your Path")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !isOnboarding {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: RNFSpacing.sm) {
            Text("Your Persona")
                .font(.title2.bold())
                .foregroundStyle(Color(.label))

            Text("Choose how the Forge speaks to you. This changes language, colors, and narrative — not difficulty.")
                .font(.subheadline)
                .foregroundStyle(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Theme Card

    private func themeCard(for theme: PersonaTheme) -> some View {
        let isSelected = selectedTheme == theme
        let colors = themeProvider.accentColors

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTheme = theme
            }
        } label: {
            VStack(alignment: .leading, spacing: RNFSpacing.sm) {
                HStack {
                    themeIcon(for: theme)
                        .font(.title)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(theme.displayName)
                            .font(.headline)
                            .foregroundStyle(Color(.label))

                        Text(theme.tagline)
                            .font(.caption)
                            .foregroundStyle(Color(.secondaryLabel))
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(accentColor(for: theme))
                            .font(.title2)
                    }
                }

                Divider()

                previewSection(for: theme)
            }
            .padding(RNFSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: RNFRadius.md)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: RNFRadius.md)
                    .stroke(
                        isSelected ? accentColor(for: theme) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.displayName) theme. \(theme.tagline)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Preview Section

    private func previewSection(for theme: PersonaTheme) -> some View {
        let provider = ThemeProvider()
        provider.setTheme(theme)

        return VStack(alignment: .leading, spacing: RNFSpacing.xs) {
            Text("Preview")
                .font(.caption.bold())
                .foregroundStyle(Color(.tertiaryLabel))

            HStack(spacing: RNFSpacing.sm) {
                colorSwatch(accentColor(for: theme), label: "Primary")
                colorSwatch(secondaryColor(for: theme), label: "Secondary")
                colorSwatch(streakColor(for: theme), label: "Streak")
            }

            Text(provider.dailyCompletionPhrase())
                .font(.caption)
                .foregroundStyle(Color(.secondaryLabel))
                .italic()
                .lineLimit(2)
        }
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button {
            themeProvider.setTheme(selectedTheme)
            if let onConfirm {
                onConfirm()
            } else {
                dismiss()
            }
        } label: {
            Text(isOnboarding ? "Continue" : "Apply Theme")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, RNFSpacing.sm)
        }
        .buttonStyle(.borderedProminent)
        .tint(accentColor(for: selectedTheme))
        .padding(.top, RNFSpacing.md)
    }

    // MARK: - Helpers

    private func themeIcon(for theme: PersonaTheme) -> some View {
        Group {
            switch theme {
            case .warrior: Text("⚔️")
            case .garden: Text("🌱")
            case .scholar: Text("📚")
            }
        }
    }

    private func colorSwatch(_ color: Color, label: String) -> some View {
        VStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(Color(.tertiaryLabel))
        }
    }

    private func accentColor(for theme: PersonaTheme) -> Color {
        switch theme {
        case .warrior: return Color(hex: "#DC2626")
        case .garden: return Color(hex: "#22A559")
        case .scholar: return Color(hex: "#2563EB")
        }
    }

    private func secondaryColor(for theme: PersonaTheme) -> Color {
        switch theme {
        case .warrior: return Color(hex: "#9B6BF7")
        case .garden: return Color(hex: "#86EFAC")
        case .scholar: return Color(hex: "#93C5FD")
        }
    }

    private func streakColor(for theme: PersonaTheme) -> Color {
        switch theme {
        case .warrior: return Color(hex: "#F97316")
        case .garden: return Color(hex: "#FDE047")
        case .scholar: return Color(hex: "#A78BFA")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ThemeSelectionView(isOnboarding: true)
    }
}
