import SwiftUI
import WidgetKit
import AppIntents

// MARK: - P26-APL-12: Interactive Medium Widget (Habit Checkboxes)
//
// NOTE: This file requires `CompleteHabitFromWidgetIntent` to be included in the
// RNFWidget target's "Compile Sources" build phase. Add
// `RNF/Intents/CompleteHabitIntent.swift` to the widget target membership in Xcode,
// or create a shared framework for intents.

/// Medium widget with interactive habit completion buttons.
/// Each habit row has a Button(intent:) that marks it complete without opening the app.
struct InteractiveMediumWidgetView: View {

    let data: RNFWidgetData

    var body: some View {
        HStack(spacing: 12) {
            // Left: Streak + Progress
            VStack(spacing: 6) {
                streakBadge
                progressRing
            }
            .frame(width: 72)

            // Right: Interactive habit list
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(zip(data.questNames.indices, data.questNames)), id: \.0) { index, name in
                    habitRow(index: index, name: name)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var streakBadge: some View {
        VStack(spacing: 2) {
            Image(systemName: "flame.fill")
                .font(.system(size: 18))
                .foregroundStyle(.orange)
            Text("\(data.streakCount)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text("days")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 3)
            Circle()
                .trim(from: 0, to: data.dailyProgress)
                .stroke(Color.purple, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(data.dailyCompleted)/\(data.dailyGoal)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
        }
        .frame(width: 36, height: 36)
    }

    @ViewBuilder
    private func habitRow(index: Int, name: String) -> some View {
        let isCompleted = index < data.questCompletions.count && data.questCompletions[index]

        if isCompleted {
            // Completed — show static checkmark
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.green)
                Text(name)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .strikethrough(true, color: .secondary)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        } else {
            // Not completed — interactive button
            Button(intent: CompleteHabitFromWidgetIntent(habitIndex: index)) {
                HStack(spacing: 6) {
                    Image(systemName: "circle")
                        .font(.system(size: 14))
                        .foregroundStyle(.purple)
                    Text(name)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - P26-APL-13: Interactive Large Widget (Habits + Quest + Streak)

/// Large widget showing full habit list with checkboxes, current quest progress,
/// and streak tier visualization.
struct InteractiveLargeWidgetView: View {

    let data: RNFWidgetData

    var body: some View {
        VStack(spacing: 12) {
            // Header: Streak + Level
            headerSection

            Divider()
                .opacity(0.5)

            // Habits with interactive checkboxes
            habitsSection

            Spacer(minLength: 4)

            // Footer: Daily progress bar
            footerSection
        }
        .padding(14)
    }

    private var headerSection: some View {
        HStack {
            // Streak badge
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(data.streakCount) days")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Text(tierName)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Level badge
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.yellow)
                Text("Lv. \(data.level)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.yellow.opacity(0.15))
            .clipShape(Capsule())
        }
    }

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TODAY'S QUESTS")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .tracking(0.5)

            ForEach(Array(zip(data.questNames.indices, data.questNames)), id: \.0) { index, name in
                largeHabitRow(index: index, name: name)
            }
        }
    }

    @ViewBuilder
    private func largeHabitRow(index: Int, name: String) -> some View {
        let isCompleted = index < data.questCompletions.count && data.questCompletions[index]

        if isCompleted {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.green)
                Text(name)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .strikethrough(true, color: .secondary)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Text("✓")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.green)
            }
        } else {
            Button(intent: CompleteHabitFromWidgetIntent(habitIndex: index)) {
                HStack(spacing: 8) {
                    Image(systemName: "circle")
                        .font(.system(size: 16))
                        .foregroundStyle(.purple)
                    Text(name)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var footerSection: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * data.dailyProgress, height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Text("\(data.dailyCompleted)/\(data.dailyGoal) complete")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(data.dailyProgress * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.purple)
            }
        }
    }

    private var tierName: String {
        WidgetStreakTier.tier(for: data.streakCount).rawValue
    }
}

// MARK: - P26-APL-14: Lock Screen Widgets

/// Rectangular Lock Screen widget showing streak + today's progress.
struct LockScreenRectangularView: View {

    let data: RNFWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("RNF — Day \(data.streakCount)")
                .font(.headline)
                .widgetAccentable()

            HStack(spacing: 8) {
                Label("\(data.streakCount)", systemImage: "flame.fill")
                    .font(.caption)

                Text("•")
                    .font(.caption)

                Text("\(data.dailyCompleted)/\(data.dailyGoal) today")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
    }
}

/// Circular Lock Screen widget showing streak count with flame icon.
struct LockScreenCircularView: View {

    let data: RNFWidgetData

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 0) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .widgetAccentable()

                Text("\(data.streakCount)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
        }
    }
}

/// Inline Lock Screen widget (single line of text).
struct LockScreenInlineView: View {

    let data: RNFWidgetData

    var body: some View {
        ViewThatFits {
            Text("🔥 \(data.streakCount) day streak • \(data.dailyCompleted)/\(data.dailyGoal) done")
            Text("🔥 \(data.streakCount) days • \(data.dailyCompleted)/\(data.dailyGoal)")
            Text("🔥 \(data.streakCount)")
        }
    }
}

// MARK: - P26-APL-15: StandBy Mode Layout

/// Rectangular StandBy widget — optimized for dark always-on display.
struct StandByRectangularView: View {

    let data: RNFWidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.orange)
                    .widgetAccentable()
                Text("Day \(data.streakCount)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }

            HStack(spacing: 8) {
                Text(tierName)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Text("•")
                    .foregroundStyle(.secondary)

                Text("\(data.dailyCompleted)/\(data.dailyGoal) today")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .standByOptimized()
    }

    private var tierName: String {
        let tier = WidgetStreakTier.tier(for: data.streakCount)
        return "\(WidgetStreakTier.icon(for: tier)) \(tier.rawValue)"
    }
}

/// Circular StandBy widget — streak number with accent ring.
struct StandByCircularView: View {

    let data: RNFWidgetData

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            // Progress ring
            Circle()
                .trim(from: 0, to: data.dailyProgress)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .widgetAccentable()
                Text("\(data.streakCount)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
        }
        .standByOptimized()
    }
}

// MARK: - StandBy Optimization Modifier

extension View {
    /// Applies dark-background optimizations for StandBy mode.
    func standByOptimized() -> some View {
        self
            .foregroundStyle(.white)
    }
}

// MARK: - Widget Streak Tier (Local to widget target)

/// Lightweight streak tier calculation for widget display.
/// Mirrors StreakTierSystem from the main app without requiring cross-target dependency.
private enum WidgetStreakTier {
    enum Tier: String {
        case spark = "Spark"
        case ember = "Ember"
        case flame = "Flame"
        case blaze = "Blaze"
        case inferno = "Inferno"
        case eternal = "Eternal"
    }

    static func tier(for streak: Int) -> Tier {
        switch streak {
        case 0...6: return .spark
        case 7...13: return .ember
        case 14...29: return .flame
        case 30...59: return .blaze
        case 60...89: return .inferno
        default: return .eternal
        }
    }

    static func icon(for tier: Tier) -> String {
        switch tier {
        case .spark: return "🌱"
        case .ember: return "🔥"
        case .flame: return "⚡"
        case .blaze: return "💎"
        case .inferno: return "🗡️"
        case .eternal: return "👑"
        }
    }
}

// MARK: - Updated Widget Entry View (Integrates all families)

/// Routes to the appropriate widget view based on the widget family.
struct InteractiveWidgetEntryView: View {

    let entry: RNFWidgetEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            InteractiveMediumWidgetView(data: entry.data)
        case .systemLarge:
            InteractiveLargeWidgetView(data: entry.data)
        case .accessoryRectangular:
            LockScreenRectangularView(data: entry.data)
        case .accessoryCircular:
            LockScreenCircularView(data: entry.data)
        case .accessoryInline:
            LockScreenInlineView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}

// MARK: - Interactive Widget Configuration

/// Widget configuration that supports all families including interactive and Lock Screen.
struct RNFInteractiveWidget: Widget {

    let kind = "RNFInteractiveWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RNFWidgetProvider()) { entry in
            InteractiveWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("RNF Habits")
        .description("Track and complete habits with interactive checkboxes.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline
        ])
    }
}
