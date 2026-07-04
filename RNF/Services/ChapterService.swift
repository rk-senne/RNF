import Foundation

// P27-LIF-01/02/03/04/05/06: Chapter progression system post-Day 90
// After the initial 90-day challenge, players enter the chapter system.
// Each chapter has distinct unlock criteria and progression tracking.

@MainActor
final class ChapterService: ObservableObject {

    // MARK: - Types

    enum Chapter: Int, Codable, CaseIterable, Comparable {
        case origin = 1       // Days 1-90 (the challenge itself)
        case newPillar = 2    // Any stat > 25
        case balanced = 3     // All stats > 15
        case specialist = 4   // Any one stat > 40
        case complete = 5     // All stats > 25

        var title: String {
            switch self {
            case .origin: return "Chapter 1: Origin"
            case .newPillar: return "Chapter 2: New Pillar"
            case .balanced: return "Chapter 3: Balanced"
            case .specialist: return "Chapter 4: Specialist"
            case .complete: return "Chapter 5: Complete"
            }
        }

        var subtitle: String {
            switch self {
            case .origin: return "Complete the 90-day challenge"
            case .newPillar: return "Raise any stat above 25"
            case .balanced: return "Raise all stats above 15"
            case .specialist: return "Raise any stat above 40"
            case .complete: return "Raise all stats above 25"
            }
        }

        var rewardTitle: String {
            switch self {
            case .origin: return "Forged"
            case .newPillar: return "Pillar Breaker"
            case .balanced: return "Equilibrium"
            case .specialist: return "Specialist"
            case .complete: return "Complete"
            }
        }

        static func < (lhs: Chapter, rhs: Chapter) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    struct ChapterProgress: Codable {
        let chapter: Chapter
        let startedAt: Date
        var completedAt: Date?
        var progress: Double

        var isComplete: Bool { completedAt != nil }
    }

    // MARK: - Published State

    @Published private(set) var currentChapter: Chapter = .origin
    @Published private(set) var chapterHistory: [ChapterProgress] = []
    @Published private(set) var currentObjective: String = ""
    @Published private(set) var currentProgress: Double = 0.0

    // MARK: - Dependencies

    private let supabase: SupabaseService
    private let userDefaults: UserDefaults

    // MARK: - UserDefaults Keys

    private static let currentChapterKey = "rnf_current_chapter"
    private static let chapterHistoryKey = "rnf_chapter_history"

    // MARK: - Init

    init(supabase: SupabaseService = .shared, userDefaults: UserDefaults = .standard) {
        self.supabase = supabase
        self.userDefaults = userDefaults
        loadLocal()
    }

    // MARK: - Public API

    /// Evaluate stats and challenge status to determine current chapter
    func evaluateProgress(stats: Stats, challengeCompleted: Bool, dayCount: Int) {
        guard challengeCompleted || dayCount > 90 else {
            currentChapter = .origin
            currentObjective = "Complete the 90-day challenge"
            currentProgress = Double(min(dayCount, 90)) / 90.0
            return
        }

        let previousChapter = currentChapter
        let detectedChapter = detectChapter(stats: stats)

        if detectedChapter > currentChapter {
            completeCurrentChapter()
            currentChapter = detectedChapter
            startNewChapter(detectedChapter)
        }

        updateObjectiveAndProgress(stats: stats)

        if detectedChapter != previousChapter {
            saveLocal()
            syncToRemote()
        }
    }

    /// Check if a specific chapter has been completed
    func isChapterCompleted(_ chapter: Chapter) -> Bool {
        chapterHistory.first { $0.chapter == chapter }?.isComplete ?? false
    }

    /// Get the next chapter objective description
    func nextObjective(for chapter: Chapter, stats: Stats) -> String {
        switch chapter {
        case .origin:
            return "Complete the 90-day challenge"
        case .newPillar:
            let highest = maxStat(stats)
            return "Raise any stat above 25 (highest: \(highest)/25)"
        case .balanced:
            let lowest = minStat(stats)
            return "Raise all stats above 15 (lowest: \(lowest)/15)"
        case .specialist:
            let highest = maxStat(stats)
            return "Raise any stat above 40 (highest: \(highest)/40)"
        case .complete:
            let lowest = minStat(stats)
            return "Raise all stats above 25 (lowest: \(lowest)/25)"
        }
    }

    /// Sync chapter data from remote on app launch
    func syncFromRemote(userID: UUID) async {
        guard let client = supabase.client else { return }

        do {
            struct ChapterRow: Decodable {
                let chapter_number: Int
                let started_at: String
                let completed_at: String?
            }

            let rows: [ChapterRow] = try await client
                .from("chapters")
                .select()
                .eq("user_id", value: userID.uuidString)
                .order("chapter_number", ascending: true)
                .execute()
                .value

            let formatter = ISO8601DateFormatter()
            var history: [ChapterProgress] = []

            for row in rows {
                guard let chapter = Chapter(rawValue: row.chapter_number),
                      let startedAt = formatter.date(from: row.started_at) else { continue }

                let completedAt = row.completed_at.flatMap { formatter.date(from: $0) }
                history.append(ChapterProgress(
                    chapter: chapter,
                    startedAt: startedAt,
                    completedAt: completedAt,
                    progress: completedAt != nil ? 1.0 : 0.0
                ))
            }

            if !history.isEmpty {
                chapterHistory = history
                if let latest = history.last(where: { !$0.isComplete }) {
                    currentChapter = latest.chapter
                } else if let last = history.last {
                    currentChapter = last.chapter
                }
                saveLocal()
            }
        } catch {
            RNFLogger.challenge.error("ChapterService: syncFromRemote failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers

    private func detectChapter(stats: Stats) -> Chapter {
        let allStats = allStatValues(stats)
        let highest = allStats.max() ?? 0
        let lowest = allStats.min() ?? 0

        if lowest > 25 { return .complete }
        if highest > 40 { return .specialist }
        if lowest > 15 { return .balanced }
        if highest > 25 { return .newPillar }
        return .origin
    }

    private func completeCurrentChapter() {
        if let idx = chapterHistory.firstIndex(where: { $0.chapter == currentChapter && $0.completedAt == nil }) {
            chapterHistory[idx].completedAt = Date()
            chapterHistory[idx].progress = 1.0
        }
    }

    private func startNewChapter(_ chapter: Chapter) {
        chapterHistory.append(ChapterProgress(
            chapter: chapter,
            startedAt: Date(),
            completedAt: nil,
            progress: 0.0
        ))
    }

    private func updateObjectiveAndProgress(stats: Stats) {
        let next = nextUncompletedChapter()
        currentObjective = nextObjective(for: next, stats: stats)
        currentProgress = calculateProgress(for: next, stats: stats)
    }

    private func nextUncompletedChapter() -> Chapter {
        for chapter in Chapter.allCases where chapter > .origin {
            if !isChapterCompleted(chapter) {
                return chapter
            }
        }
        return currentChapter
    }

    private func calculateProgress(for chapter: Chapter, stats: Stats) -> Double {
        let allStats = allStatValues(stats)

        switch chapter {
        case .origin: return 0.0
        case .newPillar: return min(Double(allStats.max() ?? 0) / 25.0, 1.0)
        case .balanced: return min(Double(allStats.min() ?? 0) / 15.0, 1.0)
        case .specialist: return min(Double(allStats.max() ?? 0) / 40.0, 1.0)
        case .complete: return min(Double(allStats.min() ?? 0) / 25.0, 1.0)
        }
    }

    private func allStatValues(_ stats: Stats) -> [Int] {
        [stats.strength, stats.discipline, stats.focus,
         stats.energy, stats.wisdom, stats.mind, stats.spirit]
    }

    private func maxStat(_ stats: Stats) -> Int {
        allStatValues(stats).max() ?? 0
    }

    private func minStat(_ stats: Stats) -> Int {
        allStatValues(stats).min() ?? 0
    }

    // MARK: - Local Persistence

    private func loadLocal() {
        let rawChapter = userDefaults.integer(forKey: Self.currentChapterKey)
        if rawChapter > 0, let chapter = Chapter(rawValue: rawChapter) {
            currentChapter = chapter
        }

        if let data = userDefaults.data(forKey: Self.chapterHistoryKey),
           let history = try? JSONDecoder().decode([ChapterProgress].self, from: data) {
            chapterHistory = history
        }
    }

    private func saveLocal() {
        userDefaults.set(currentChapter.rawValue, forKey: Self.currentChapterKey)
        if let data = try? JSONEncoder().encode(chapterHistory) {
            userDefaults.set(data, forKey: Self.chapterHistoryKey)
        }
    }

    // MARK: - Remote Sync

    private func syncToRemote() {
        guard let client = supabase.client else { return }

        Task {
            do {
                let formatter = ISO8601DateFormatter()

                struct ChapterUpsert: Encodable {
                    let chapter_number: Int
                    let started_at: String
                    let completed_at: String?
                    let updated_at: String
                }

                for entry in chapterHistory {
                    let upsert = ChapterUpsert(
                        chapter_number: entry.chapter.rawValue,
                        started_at: formatter.string(from: entry.startedAt),
                        completed_at: entry.completedAt.map { formatter.string(from: $0) },
                        updated_at: formatter.string(from: Date())
                    )

                    try await client
                        .from("chapters")
                        .upsert(upsert)
                        .execute()
                }
            } catch {
                RNFLogger.challenge.error("ChapterService: syncToRemote failed — \(error.localizedDescription)")
            }
        }
    }
}
