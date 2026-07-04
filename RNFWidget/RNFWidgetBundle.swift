import WidgetKit
import SwiftUI

@main
struct RNFWidgetBundle: WidgetBundle {
    var body: some Widget {
        RNFStreakWidget()
        RNFInteractiveWidget()
    }
}

struct RNFStreakWidget: Widget {
    let kind = "RNFStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RNFWidgetProvider()) { entry in
            RNFWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("RNF Progress")
        .description("Your streak and daily progress at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
