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
            ZStack {
                ProgressView(value: entry.progress)
                    .progressViewStyle(.circular)
                Text("\(entry.streak)")
                    .font(.system(size: 14, weight: .bold))
            }
        case .accessoryInline:
            Text("🔥 \(entry.streak) streak")
        default:
            Text("\(entry.streak)")
        }
    }
}
