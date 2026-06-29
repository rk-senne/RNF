import SwiftUI

struct RNFFont {
    // Display (hero numbers, big statements)
    static let display = Font.system(size: 42, weight: .black, design: .rounded)
    static let displayLarge = Font.system(size: 48, weight: .black, design: .rounded)

    // Titles
    static let title = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let titleLarge = Font.system(size: 32, weight: .bold, design: .rounded)
    static let titleMedium = Font.system(size: 28, weight: .bold, design: .rounded)

    // Sections (card headings, group titles)
    static let section = Font.system(size: 18, weight: .bold, design: .rounded)
    static let sectionMedium = Font.system(size: 18, weight: .medium, design: .rounded)

    // Body (descriptions, secondary text)
    static let body = Font.system(.body, design: .rounded)
    static let bodyBold = Font.system(size: 16, weight: .bold, design: .rounded)
    static let bodySemibold = Font.system(size: 16, weight: .semibold, design: .rounded)

    // Captions (metadata, supplementary info)
    static let caption = Font.system(size: 13, weight: .medium, design: .rounded)
    static let captionBold = Font.system(size: 13, weight: .bold, design: .rounded)
    static let captionSmall = Font.system(size: 12, weight: .medium, design: .rounded)
    static let captionBoldSmall = Font.system(size: 12, weight: .bold, design: .rounded)

    // Overline (section headers, labels)
    static let overline = Font.system(size: 12, weight: .black, design: .rounded)

    // Pills (badges, tags, tiny labels)
    static let pill = Font.system(size: 11, weight: .black, design: .rounded)
    static let pillSmall = Font.system(size: 10, weight: .black, design: .rounded)
    static let pillMedium = Font.system(size: 11, weight: .bold, design: .rounded)

    // Metrics (timers, XP counters, big numbers)
    static let metric = Font.system(size: 64, weight: .black, design: .rounded).monospacedDigit()
    static let metricSmall = Font.system(size: 20, weight: .bold, design: .rounded).monospacedDigit()

    // Icons/emphasis (specific use cases)
    static let iconLabel = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let statValue = Font.system(size: 15, weight: .bold, design: .rounded)
    static let cardTitle = Font.system(size: 20, weight: .black, design: .rounded)
    static let heroSubtitle = Font.system(size: 24, weight: .bold, design: .rounded)
}

extension View {
    func overlineStyle() -> some View {
        self.font(RNFFont.overline)
            .tracking(1.2)
            .foregroundStyle(Color.secondary)
    }
}
