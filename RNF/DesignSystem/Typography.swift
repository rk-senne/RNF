import SwiftUI

/// RNF Typography tokens using Dynamic Type-aware sizing.
/// All custom font sizes use relative text styles for Dynamic Type support (P21-A11Y-01).
struct RNFFont {
    // Display (hero numbers, big statements)
    static let display = Font.system(.largeTitle, design: .rounded).weight(.black)
    static let displayLarge = Font.system(size: 48, weight: .black, design: .rounded)

    // Titles
    static let title = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let titleLarge = Font.system(size: 32, weight: .bold, design: .rounded)
    static let titleMedium = Font.system(size: 28, weight: .bold, design: .rounded)

    // Sections (card headings, group titles)
    static let section = Font.system(.headline, design: .rounded).weight(.bold)
    static let sectionMedium = Font.system(.headline, design: .rounded).weight(.medium)

    // Headlines
    static let headline = Font.system(.headline, design: .rounded)

    // Body (descriptions, secondary text)
    static let body = Font.system(.body, design: .rounded)
    static let bodyBold = Font.system(.body, design: .rounded).weight(.bold)
    static let bodySemibold = Font.system(.body, design: .rounded).weight(.semibold)

    // Captions (metadata, supplementary info)
    static let caption = Font.system(.caption, design: .rounded).weight(.medium)
    static let captionBold = Font.system(.caption, design: .rounded).weight(.bold)
    static let captionSmall = Font.system(.caption2, design: .rounded).weight(.medium)
    static let captionBoldSmall = Font.system(.caption2, design: .rounded).weight(.bold)

    // Overline (section headers, labels)
    static let overline = Font.system(.caption2, design: .rounded).weight(.black)

    // Pills (badges, tags, tiny labels)
    static let pill = Font.system(.caption2, design: .rounded).weight(.black)
    static let pillSmall = Font.system(.caption2, design: .rounded).weight(.black)
    static let pillMedium = Font.system(.caption2, design: .rounded).weight(.bold)

    // Metrics (timers, XP counters, big numbers)
    static let metric = Font.system(size: 64, weight: .black, design: .rounded).monospacedDigit()
    static let metricSmall = Font.system(.title3, design: .rounded).weight(.bold).monospacedDigit()

    // Icons/emphasis (specific use cases)
    static let iconLabel = Font.system(.title2, design: .rounded).weight(.semibold)
    static let statValue = Font.system(.subheadline, design: .rounded).weight(.bold)
    static let cardTitle = Font.system(.title3, design: .rounded).weight(.black)
    static let heroSubtitle = Font.system(.title2, design: .rounded).weight(.bold)

    // Convenience aliases matching SwiftUI text style names
    static let title2 = Font.system(.title2, design: .rounded).weight(.bold)
    static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)
    static let subheadline = Font.system(.subheadline, design: .rounded).weight(.medium)
}

extension View {
    func overlineStyle() -> some View {
        self.font(RNFFont.overline)
            .tracking(1.2)
            .foregroundStyle(Color.secondary)
    }

    /// P21-A11Y-02: Limits dynamic type range to prevent extreme sizes breaking layouts.
    func dynamicTypeLimited() -> some View {
        self.dynamicTypeSize(.xSmall ... .accessibility2)
    }
}
