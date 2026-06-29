import Foundation

// P20-EXP-07a: Journey milestone model for the 90-day map visualization
struct JourneyMilestone: Identifiable {
    let id: String
    let day: Int
    let name: String
    let icon: String
    let description: String

    static let defaults: [JourneyMilestone] = [
        JourneyMilestone(id: "d1", day: 1, name: "Begin", icon: "🌱", description: "The forge ignites"),
        JourneyMilestone(id: "d7", day: 7, name: "First Week", icon: "🔥", description: "Ember tier reached"),
        JourneyMilestone(id: "d14", day: 14, name: "Two Weeks", icon: "⚡", description: "Custom habit unlocked"),
        JourneyMilestone(id: "d30", day: 30, name: "One Month", icon: "💎", description: "Blaze tier"),
        JourneyMilestone(id: "d60", day: 60, name: "Two Months", icon: "🗡️", description: "Inferno tier"),
        JourneyMilestone(id: "d90", day: 90, name: "Challenge Complete", icon: "👑", description: "Eternal"),
    ]
}
