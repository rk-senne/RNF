import WidgetKit
import SwiftUI

struct RNFWidgetEntry: TimelineEntry {
    let date: Date
    let data: RNFWidgetData
}

struct RNFWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> RNFWidgetEntry {
        RNFWidgetEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (RNFWidgetEntry) -> Void) {
        completion(RNFWidgetEntry(date: Date(), data: loadData()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RNFWidgetEntry>) -> Void) {
        let entry = RNFWidgetEntry(date: Date(), data: loadData())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadData() -> RNFWidgetData {
        guard
            let defaults = UserDefaults(suiteName: RNFWidgetData.appGroupID),
            let data = defaults.data(forKey: RNFWidgetData.userDefaultsKey),
            let widgetData = try? JSONDecoder().decode(RNFWidgetData.self, from: data)
        else {
            return .placeholder
        }
        return widgetData
    }
}
