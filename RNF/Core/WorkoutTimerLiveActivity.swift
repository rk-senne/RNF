import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - P26-APL-30/31/32/33: WorkoutTimer & FocusSession Live Activities

// MARK: - Activity Attributes

/// P26-APL-30: WorkoutTimer Live Activity attributes.
struct WorkoutTimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var elapsedSeconds: Int
        var phase: String           // "warmup", "active", "cooldown"
        var isActive: Bool
        var exerciseName: String?
    }

    let workoutType: String
    let startedAt: Date
}

/// P26-APL-32: FocusSession Live Activity attributes.
struct FocusSessionActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
        var totalSeconds: Int
        var isActive: Bool
        var sessionType: String     // "meditation", "deepWork", "breathing"
    }

    let sessionName: String
    let targetDurationSeconds: Int
}

// MARK: - P26-APL-30: Workout Timer Live Activity View

@available(iOS 16.2, *)
struct WorkoutTimerLiveActivityView: View {
    let context: ActivityViewContext<WorkoutTimerActivityAttributes>

    private var elapsed: String {
        let secs = context.state.elapsedSeconds
        let minutes = secs / 60
        let seconds = secs % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var phaseEmoji: String {
        switch context.state.phase {
        case "warmup": return "🔥"
        case "cooldown": return "❄️"
        default: return "💪"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(phaseEmoji)
                    Text(context.attributes.workoutType)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                if let exercise = context.state.exerciseName {
                    Text(exercise)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(elapsed)
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundStyle(context.state.isActive ? .primary : .secondary)
                Text(context.state.phase.capitalized)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
    }
}

// MARK: - P26-APL-32: Focus Session Live Activity View

@available(iOS 16.2, *)
struct FocusSessionLiveActivityView: View {
    let context: ActivityViewContext<FocusSessionActivityAttributes>

    private var remaining: String {
        let secs = context.state.remainingSeconds
        let minutes = secs / 60
        let seconds = secs % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var progress: Double {
        let total = Double(context.state.totalSeconds)
        guard total > 0 else { return 0 }
        return 1.0 - (Double(context.state.remainingSeconds) / total)
    }

    private var sessionEmoji: String {
        switch context.state.sessionType {
        case "meditation": return "🧘"
        case "breathing": return "🌬️"
        default: return "🎯"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(sessionEmoji)
                    Text(context.attributes.sessionName)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                Text(context.state.sessionType.capitalized)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(remaining)
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundStyle(context.state.isActive ? .primary : .secondary)
                ProgressView(value: progress)
                    .tint(.green)
                    .frame(width: 50)
            }
        }
        .padding(16)
    }
}

// MARK: - P26-APL-31/33: Dynamic Island Widgets

@available(iOS 16.2, *)
struct WorkoutTimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutTimerActivityAttributes.self) { context in
            WorkoutTimerLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Text("💪")
                        Text(context.attributes.workoutType)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    let secs = context.state.elapsedSeconds
                    Text("\(secs / 60):\(String(format: "%02d", secs % 60))")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                }
                DynamicIslandExpandedRegion(.center) {
                    if let exercise = context.state.exerciseName {
                        Text(exercise)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.phase.capitalized)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if context.state.isActive {
                            Image(systemName: "figure.run")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "pause.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            } compactLeading: {
                Text("💪")
            } compactTrailing: {
                let secs = context.state.elapsedSeconds
                Text("\(secs / 60):\(String(format: "%02d", secs % 60))")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
            } minimal: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.green)
            }
        }
    }
}

@available(iOS 16.2, *)
struct FocusSessionLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusSessionActivityAttributes.self) { context in
            FocusSessionLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Text("🎯")
                        Text(context.attributes.sessionName)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    let secs = context.state.remainingSeconds
                    Text("\(secs / 60):\(String(format: "%02d", secs % 60))")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.sessionType.capitalized)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    let total = Double(context.state.totalSeconds)
                    let remaining = Double(context.state.remainingSeconds)
                    let progress = total > 0 ? 1.0 - (remaining / total) : 0
                    ProgressView(value: progress)
                        .tint(.purple)
                }
            } compactLeading: {
                Text("🎯")
            } compactTrailing: {
                let secs = context.state.remainingSeconds
                Text("\(secs / 60):\(String(format: "%02d", secs % 60))")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
            } minimal: {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.purple)
            }
        }
    }
}

// MARK: - Live Activity Manager Extensions

@available(iOS 16.2, *)
struct WorkoutTimerActivityManager {

    // MARK: - Workout Timer

    @MainActor
    static func startWorkout(type: String) -> Activity<WorkoutTimerActivityAttributes>? {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return nil }

        let attributes = WorkoutTimerActivityAttributes(
            workoutType: type,
            startedAt: Date()
        )
        let state = WorkoutTimerActivityAttributes.ContentState(
            elapsedSeconds: 0,
            phase: "warmup",
            isActive: true,
            exerciseName: nil
        )

        do {
            let activity = try Activity.request(attributes: attributes, content: .init(state: state, staleDate: nil))
            return activity
        } catch {
            return nil
        }
    }

    @MainActor
    static func updateWorkout(elapsedSeconds: Int, phase: String, isActive: Bool, exerciseName: String? = nil) {
        let state = WorkoutTimerActivityAttributes.ContentState(
            elapsedSeconds: elapsedSeconds,
            phase: phase,
            isActive: isActive,
            exerciseName: exerciseName
        )
        Task {
            for activity in Activity<WorkoutTimerActivityAttributes>.activities {
                await activity.update(.init(state: state, staleDate: nil))
            }
        }
    }

    @MainActor
    static func endWorkout() {
        Task {
            for activity in Activity<WorkoutTimerActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    // MARK: - Focus Session

    @MainActor
    static func startFocusSession(name: String, totalSeconds: Int, type: String) -> Activity<FocusSessionActivityAttributes>? {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return nil }

        let attributes = FocusSessionActivityAttributes(
            sessionName: name,
            targetDurationSeconds: totalSeconds
        )
        let state = FocusSessionActivityAttributes.ContentState(
            remainingSeconds: totalSeconds,
            totalSeconds: totalSeconds,
            isActive: true,
            sessionType: type
        )

        do {
            let activity = try Activity.request(attributes: attributes, content: .init(state: state, staleDate: nil))
            return activity
        } catch {
            return nil
        }
    }

    @MainActor
    static func updateFocusSession(remainingSeconds: Int, totalSeconds: Int, isActive: Bool, sessionType: String) {
        let state = FocusSessionActivityAttributes.ContentState(
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            isActive: isActive,
            sessionType: sessionType
        )
        Task {
            for activity in Activity<FocusSessionActivityAttributes>.activities {
                await activity.update(.init(state: state, staleDate: nil))
            }
        }
    }

    @MainActor
    static func endFocusSession() {
        Task {
            for activity in Activity<FocusSessionActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
