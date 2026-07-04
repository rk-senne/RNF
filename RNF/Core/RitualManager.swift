import Foundation

// P20-EXP-03a: RitualManager – controls morning intention and evening reflection state.
@MainActor
final class RitualManager: ObservableObject {
    @Published var showMorningIntention = false
    @Published var showEveningReflection = false
    @Published var todayFocusStat: String = ""

    private let defaults = UserDefaults.standard
    private var lastIntentDate: String {
        get { defaults.string(forKey: "rnf_last_intent_date") ?? "" }
        set { defaults.set(newValue, forKey: "rnf_last_intent_date") }
    }

    func checkMorningIntention() {
        let today = dateString()
        if lastIntentDate != today {
            showMorningIntention = true
            // P20-VOX-03: Voice trigger for morning ritual
            ForgeVoice.speak("The forge awaits. Set your intention.")
        }
    }

    func setIntention(stat: String) {
        todayFocusStat = stat
        lastIntentDate = dateString()
        showMorningIntention = false
        defaults.set(stat, forKey: "rnf_today_focus_stat")
    }

    func dismissMorning() {
        lastIntentDate = dateString()
        showMorningIntention = false
    }

    func triggerEveningReflection() {
        let key = "rnf_evening_shown_\(dateString())"
        guard !defaults.bool(forKey: key) else { return }
        defaults.set(true, forKey: key)
        showEveningReflection = true
    }

    func dismissEvening() {
        showEveningReflection = false
    }

    var intentMultiplier: Double {
        todayFocusStat.isEmpty ? 1.0 : 1.10
    }

    private func dateString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
