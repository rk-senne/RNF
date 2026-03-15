import SwiftUI
import Supabase

struct ContentView: View {

    // MARK: - Habit Data

    @State private var habits: [Habit] = [
        Habit(id: UUID(), name: "Drink Water", description: nil, xpReward: 10),
        Habit(id: UUID(), name: "Read 10 Pages", description: nil, xpReward: 15),
        Habit(id: UUID(), name: "Workout", description: nil, xpReward: 20),
        Habit(id: UUID(), name: "Meditate", description: nil, xpReward: 10),
        Habit(id: UUID(), name: "Stretch", description: nil, xpReward: 10),
        Habit(id: UUID(), name: "Journal", description: nil, xpReward: 15),
        Habit(id: UUID(), name: "Cold Shower", description: nil, xpReward: 20),
        Habit(id: UUID(), name: "Walk 10 Minutes", description: nil, xpReward: 10)
    ]

    @State private var completedHabits: Set<UUID> = []

    // MARK: - XP System

    @State private var xpGained: Int? = nil
    @State private var totalXP: Int = 120
    @State private var levelXP: Int = 200
    @State private var level: Int = 1
    @State private var showLevelUp: Bool = false

    // MARK: - Daily Mission System

    @State private var dailyCompleted: Int = 0
    @State private var dailyGoal: Int = 4
    @State private var showMissionComplete: Bool = false

    // MARK: - Streak & Badge System

    @State private var streakDays: Int = 0
    @State private var showBadgeUnlocked: Bool = false
    @State private var unlockedBadge: String = ""

    // MARK: - Profile

    @State private var profile: Profile?

    // MARK: - Player Stats

    @State private var stats = Stats(
        strength: 2,
        discipline: 2,
        focus: 2,
        energy: 2,
        wisdom: 2,
        mind: 2,
        spirit: 2
    )

    // MARK: - Animation

    @State private var animatedHabit: UUID?

    // MARK: - Data Persistence

    @AppStorage("lastResetDate") private var lastResetDate: String = ""
    
    

    // MARK: - UI

    var body: some View {

        NavigationView {

            VStack(spacing: 16) {

                DailyMissionBar(
                    completed: dailyCompleted,
                    goal: dailyGoal
                )

                XPBar(
                    xp: totalXP,
                    levelXP: levelXP,
                    level: level
                )

                ScrollView {

                    VStack(spacing: 12) {

                        ForEach(habits) { habit in

                            HabitRow(
                                habit: habit,
                                completed: completedHabits.contains(habit.id),
                                animated: animatedHabit == habit.id,
                                action: {
                                    Task {
                                        await completeHabit(habit)
                                    }
                                }
                            )

                        }

                    }
                    .padding()

                }

            }
            .navigationTitle("RNF Quests")

        }

        .overlay(XPGainOverlay)
        .overlay(LevelUpOverlay)
        .overlay(MissionCompleteOverlay)
        .overlay(BadgeUnlockedOverlay)

        .task {

            checkDailyReset()

            dailyGoal = QuestDifficultySystem.questsPerDay(for: level)

            let generated = QuestGenerator.generateDailyQuests(
                profile: profile ?? Profile.placeholder,
                quests: QuestRepository.all
            )

            let quests = [generated.main].compactMap { $0 } + generated.side
            habits = QuestMapper.toHabits(quests)
            await loadProfile()
        }

        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.willEnterForegroundNotification
        )) { _ in

            checkDailyReset()

        }

    }

    // MARK: - Overlays

    var XPGainOverlay: some View {

        Group {

            if let xp = xpGained {

                Text("+\(xp) XP")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .transition(.scale)
                    .onAppear {

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            xpGained = nil
                        }

                    }

            }

        }

    }

    var LevelUpOverlay: some View {

        Group {

            if showLevelUp {

                VStack(spacing: 16) {

                    Text("LEVEL UP")
                        .font(.largeTitle)
                        .fontWeight(.black)

                    Text("LEVEL \(level)")
                        .font(.title)

                }
                .padding(40)
                .background(Color.yellow)
                .cornerRadius(20)
                .shadow(radius: 20)
                .transition(.scale)
                .onAppear {

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showLevelUp = false
                    }

                }

            }

        }

    }

    var MissionCompleteOverlay: some View {

        Group {

            if showMissionComplete {

                VStack(spacing: 16) {

                    Text("MISSION COMPLETE")
                        .font(.largeTitle)
                        .fontWeight(.black)

                    Text("+50 XP BONUS")

                }
                .padding(40)
                .background(Color.green)
                .cornerRadius(20)
                .shadow(radius: 20)
                .transition(.scale)
                .onAppear {

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showMissionComplete = false
                    }

                }

            }

        }

    }

    var BadgeUnlockedOverlay: some View {

        Group {

            if showBadgeUnlocked {

                VStack(spacing: 16) {

                    Text("BADGE UNLOCKED")
                        .font(.largeTitle)
                        .fontWeight(.black)

                    Text(unlockedBadge)
                        .font(.title)

                }
                .padding(40)
                .background(Color.purple)
                .cornerRadius(20)
                .shadow(radius: 20)
                .transition(.scale)
                .onAppear {

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showBadgeUnlocked = false
                    }

                }

            }

        }

    }

    // MARK: - Supabase

    func loadProfile() async {

        do {

            let profiles: [Profile] = try await SupabaseManager.shared.client
                .from("profiles")
                .select()
                .limit(1)
                .execute()
                .value

            profile = profiles.first

        } catch {

            print("Error loading profile:", error)

        }

    }

    // MARK: - Daily Reset

    func checkDailyReset() {

        let today = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .short,
            timeStyle: .none
        )

        if lastResetDate != today {

            lastResetDate = today

            completedHabits.removeAll()
            dailyCompleted = 0

            print("Daily quests reset")

        }

    }

    // MARK: - Habit Completion

    func completeHabit(_ habit: Habit) async {

        print("Habit tapped:", habit.name)

        await MainActor.run {

            animatedHabit = habit.id

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animatedHabit = nil
            }

            completedHabits.insert(habit.id)

            xpGained = habit.xpReward
            totalXP += habit.xpReward
            dailyCompleted += 1

            StatSystem.applyReward(stats: &stats, for: habit.name)

            if dailyCompleted == dailyGoal {

                showMissionComplete = true

                streakDays = StreakSystem.updateStreak(
                    currentStreak: streakDays,
                    dailyCompleted: dailyCompleted,
                    dailyGoal: dailyGoal
                )

                if let badge = BadgeSystem.badge(for: streakDays) {
                    unlockedBadge = badge
                    showBadgeUnlocked = true
                }
            }

            let result = XPSystem.applyXP(
                currentXP: totalXP,
                gainedXP: habit.xpReward,
                levelXP: levelXP,
                currentLevel: level
            )

            totalXP = result.xp
            level = result.level
            dailyGoal = QuestDifficultySystem.questsPerDay(for: level)

            if result.leveledUp {
                showLevelUp = true
            }

        }

    }

}
