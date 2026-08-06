import ActivityKit
import Foundation
import os

// P20-EXP-19b: Manages Live Activity lifecycle
@available(iOS 16.2, *)
struct LiveActivityManager {
    @MainActor
    static func start(challengeDay: Int, habitsCompleted: Int, habitsGoal: Int, streak: Int, tierName: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = RNFActivityAttributes(challengeDay: challengeDay)
        let state = RNFActivityAttributes.ContentState(
            habitsCompleted: habitsCompleted,
            habitsGoal: habitsGoal,
            streak: streak,
            tierName: tierName
        )
        do {
            _ = try Activity.request(attributes: attributes, content: .init(state: state, staleDate: nil))
        } catch {
            RNFLogger.sync.error("LiveActivityManager: Failed to start activity — \(error.localizedDescription)")
        }
    }

    @MainActor
    static func update(habitsCompleted: Int, habitsGoal: Int, streak: Int, tierName: String) {
        let state = RNFActivityAttributes.ContentState(
            habitsCompleted: habitsCompleted,
            habitsGoal: habitsGoal,
            streak: streak,
            tierName: tierName
        )
        Task {
            for activity in Activity<RNFActivityAttributes>.activities {
                await activity.update(.init(state: state, staleDate: nil))
            }
        }
    }

    @MainActor
    static func end() {
        Task {
            for activity in Activity<RNFActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
