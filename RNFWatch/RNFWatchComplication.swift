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
        WatchComplicationEntry(date: Date(), streak: 7, progress: 0.5)
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchComplicationEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchComplicationEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh every 30 minutes
        let nextUpdate = Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    // P21-FIX-05: Read real data from shared UserDefaults (App Group)
    private func loadEntry() -> WatchComplicationEntry {
        let defaults = UserDefaults(suiteName: "group.com.rnf.shared") ?? .standard
        let streak = defaults.integer(forKey: "rnf_widget_streak")
        let completed = defaults.integer(forKey: "rnf_widget_daily_completed")
        let goal = max(defaults.integer(forKey: "rnf_widget_daily_goal"), 1)
        let progress = Double(completed) / Double(goal)

        return WatchComplicationEntry(
            date: Date(),
            streak: streak,
            progress: min(progress, 1.0)
        )
    }
}

struct WatchComplicationView: View {
    let entry: WatchComplicationEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
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
            Text("\(StreakTierSystem.icon(for: StreakTierSystem.tier(for: entry.streak))) \(entry.streak)d • \(StreakTierSystem.tier(for: entry.streak).rawValue)")
        default:
            Text("\(entry.streak)")
        }
    }
}
