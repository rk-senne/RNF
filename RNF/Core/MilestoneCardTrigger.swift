import Foundation

// P20-EXP-04c: Determines whether a milestone celebration card should display.
struct MilestoneCardTrigger {
    static func shouldShowCard(streak: Int, level: Int, challengeDay: Int) -> Bool {
        streak == 7 || streak == 30 || streak == 90 ||
        level == 10 || level == 20 || level == 30 ||
        challengeDay == 90
    }
}
