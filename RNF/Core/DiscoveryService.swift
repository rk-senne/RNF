import Foundation

struct DiscoveryService {
    private static let key = "rnf_discovery_history"

    static func loadHistory() -> [DiscoveryRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([DiscoveryRecord].self, from: data)
        else { return [] }
        return records
    }

    static func save(discovery: Discovery) {
        var history = loadHistory()
        let record = DiscoveryRecord(
            discoveryID: discovery.id,
            earnedDate: DateFormatter.rnfDate.string(from: Date())
        )
        guard !history.contains(where: { $0.discoveryID == discovery.id }) else { return }
        history.append(record)
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func earnedCount() -> Int {
        loadHistory().count
    }

    // P20-EXP-14e: Evaluate passive discoveries on foreground
    @MainActor
    static func evaluateOnForeground(game: GameState, notifications: NotificationManager) async {
        let steps = (try? await HealthKitService().fetchTodaySteps()) ?? 0
        let history = loadHistory()
        let hour = Calendar.current.component(.hour, from: Date())
        let isWeekend = Calendar.current.isDateInWeekend(Date())
        let stats = [game.stats.strength, game.stats.discipline, game.stats.focus, game.stats.energy, game.stats.wisdom, game.stats.mind, game.stats.spirit].map(Double.init)
        let daysSinceStart: Int = {
            guard let created = game.profile.created_at else { return 1 }
            return max(1, Calendar.current.dateComponents([.day], from: created, to: .now).day ?? 1)
        }()

        let discoveries = PassiveDiscoverySystem.evaluate(
            steps: steps, streak: game.streak, totalHabits: game.profile.xp_total / 10,
            level: game.level, stats: stats, hour: hour,
            daysSinceStart: daysSinceStart, isWeekend: isWeekend, history: history
        )

        if let first = discoveries.first {
            save(discovery: first)
            notifications.showToast(.discovery(first.name, first.xp))
        }
    }
}

private extension DateFormatter {
    static let rnfDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
