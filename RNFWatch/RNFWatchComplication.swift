import WidgetKit
import SwiftUI

struct RNFWatchComplication: Widget {
    let kind = "RNFWatchComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchComplicationProvider()) { entry in
            WatchComplicationView(entry: entry)
        }
        .configurationDisplayName("RNF Progress")
        .description("Daily streak and progress")
        .supportedFamilies([.accessoryCircular, .accessoryInline])
    }
}

struct WatchComplicationEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let progress: Double
}

struct WatchComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchComplicationEntry {
        WatchComplicationEntry(date: Date(), streak: 0, progress: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchComplicationEntry) -> Void) {
        completion(WatchComplicationEntry(date: Date(), streak: 0, progress: 0))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchComplicationEntry>) -> Void) {
        let entry = WatchComplicationEntry(date: Date(), streak: 0, progress: 0)
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800))))
    }
}

struct WatchComplicationView: View {
    let entry: WatchComplicationEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            // P20-EXP-19d: Show progress gauge with streak
            ZStack {
                Gauge(value: entry.progress) {
                    Text("")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                VStack(spacing: 0) {
                    Text(StreakTierSystem.icon(for: StreakTierSystem.tier(for: entry.streak)))
                        .font(.system(size: 10))
                    Text("\(entry.streak)")
                        .font(.system(size: 12, weight: .bold))
                }
            }
        case .accessoryInline:
            // P20-EXP-19d: Show tier name in inline
            Text("\(StreakTierSystem.icon(for: StreakTierSystem.tier(for: entry.streak))) \(entry.streak)d • \(StreakTierSystem.tier(for: entry.streak).rawValue)")
        default:
            Text("\(entry.streak)")
        }
    }
}
