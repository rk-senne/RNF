import ActivityKit
import SwiftUI

// P20-EXP-19a: Live Activity attributes
struct RNFActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var habitsCompleted: Int
        var habitsGoal: Int
        var streak: Int
        var tierName: String
    }
    var challengeDay: Int
}

// P20-EXP-19b: Live Activity view
@available(iOS 16.2, *)
struct RNFLiveActivityView: View {
    let context: ActivityViewContext<RNFActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("🔥 Day \(context.attributes.challengeDay) • \(context.state.tierName)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text("\(context.state.habitsCompleted)/\(context.state.habitsGoal) habits")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if context.state.habitsCompleted >= context.state.habitsGoal {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
            } else {
                ProgressView(value: Double(context.state.habitsCompleted), total: Double(max(context.state.habitsGoal, 1)))
                    .frame(width: 40)
            }
        }
        .padding(16)
    }
}

// P20-EXP-19c: Dynamic Island layout
import WidgetKit

@available(iOS 16.2, *)
struct RNFLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RNFActivityAttributes.self) { context in
            // Lock screen view (already exists)
            RNFLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Text("🔥 \(context.state.streak)d")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.habitsCompleted)/\(context.state.habitsGoal)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.tierName)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: Double(context.state.habitsCompleted), total: Double(max(context.state.habitsGoal, 1)))
                        .tint(.green)
                }
            } compactLeading: {
                Text("🔥")
            } compactTrailing: {
                Text("\(context.state.habitsCompleted)/\(context.state.habitsGoal)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            } minimal: {
                Text("🔥")
            }
        }
    }
}
