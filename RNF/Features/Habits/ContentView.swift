import SwiftUI

struct ContentView: View {

    @EnvironmentObject private var game: GameState
    @StateObject private var viewModel = HabitsViewModel()
    @State private var activeChallenge: Challenge?
    private let challengeEngine = ChallengeEngine()

    var body: some View {

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                VStack(alignment: .leading, spacing: 18) {

                    HStack(alignment: .top) {

                        VStack(alignment: .leading, spacing: 6) {

                            Text("TODAY'S FORGE")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(Color.secondary)

                            Text("Show up. Stack wins. Keep the chain alive.")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.primary)
                                .fixedSize(horizontal: false, vertical: true)

                        }

                        Spacer(minLength: 16)

                        VStack(alignment: .trailing, spacing: 10) {
                            statPill(
                                title: "Streak",
                                value: "\(game.streak) days",
                                tint: Color(red: 0.82, green: 0.39, blue: 0.15)
                            )

                            statPill(
                                title: "Quests",
                                value: "\(game.quests.count) live",
                                tint: Color(red: 0.3, green: 0.43, blue: 0.86)
                            )
                        }

                    }

                    DailyMissionBar(
                        completed: game.dailyCompleted,
                        goal: game.dailyGoal
                    )

                    XPBar(
                        xp: game.xp,
                        levelXP: game.xpToNext,
                        level: game.level
                    )

                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 24, x: 0, y: 12)

                challengeSummary

                Text("Today's Quests")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)

                VStack(spacing: 14) {

                    ForEach(game.quests) { habit in

                        HabitRow(
                            habit: habit,
                            completed: game.completedHabitIDs.contains(habit.id),
                            animated: viewModel.animatedHabit == habit.id,
                            action: {
                                Task {
                                    await viewModel.completeHabit(habit)
                                }
                            }
                        )

                    }

                }
                .padding(.bottom, 24)

            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("RNF Quests")
        .navigationBarTitleDisplayMode(.large)

        .overlay(XPGainOverlay)
        .overlay(LevelUpOverlay)
        .overlay(MissionCompleteOverlay)
        .overlay(BadgeUnlockedOverlay)

        .task {
            await viewModel.load(gameState: game)
            await loadChallengeSummary()
        }

        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.willEnterForegroundNotification
        )) { _ in

            viewModel.handleForegroundTransition()

        }

    }

    private var challengeSummary: some View {

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("90 DAY CHALLENGE")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Color.secondary)

                Spacer(minLength: 12)

                Text(challengeDayText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.3, green: 0.43, blue: 0.86))
            }

            ProgressView(value: challengeProgress)
                .tint(Color(red: 0.3, green: 0.43, blue: 0.86))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)

            Text(challengeStatusText)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
        )

    }

    private var challengeDayText: String {
        guard let activeChallenge else {
            return "Not started"
        }

        return "Day \(activeChallenge.normalizedCurrentDay) / \(Challenge.totalDays)"
    }

    private var challengeProgress: Double {
        activeChallenge?.progress ?? 0
    }

    private var challengeStatusText: String {
        guard activeChallenge != nil else {
            return "Commit to the 90-day path to begin tracking challenge progress."
        }

        return "Complete today's habits, workout, and reading proof to advance."
    }

    private func loadChallengeSummary() async {
        guard !game.profile.isPlaceholder else {
            activeChallenge = nil
            return
        }

        activeChallenge = await challengeEngine.loadActiveChallenge(userId: game.profile.id)
    }

    private func statPill(title: String, value: String, tint: Color) -> some View {

        VStack(alignment: .trailing, spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(tint.opacity(0.75))

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(tint.opacity(0.12))
        )
    }

    // MARK: - Overlays

    var XPGainOverlay: some View {

        Group {

            if let xp = viewModel.xpGained {

                Text("+\(xp) XP")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .transition(.scale)
                    .onAppear {

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            viewModel.xpGained = nil
                        }

                    }

            }

        }

    }

    var LevelUpOverlay: some View {

        Group {

            if viewModel.showLevelUp {

                VStack(spacing: 16) {

                    Text("LEVEL UP")
                        .font(.largeTitle)
                        .fontWeight(.black)

                    Text("LEVEL \(game.level)")
                        .font(.title)

                }
                .padding(40)
                .background(Color.yellow)
                .cornerRadius(20)
                .shadow(radius: 20)
                    .transition(.scale)
                    .onAppear {

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            viewModel.showLevelUp = false
                        }

                }

            }

        }

    }

    var MissionCompleteOverlay: some View {

        Group {

            if viewModel.showMissionComplete {

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
                            viewModel.showMissionComplete = false
                        }

                }

            }

        }

    }

    var BadgeUnlockedOverlay: some View {

        Group {

            if viewModel.showBadgeUnlocked {

                VStack(spacing: 16) {

                    Text("BADGE UNLOCKED")
                        .font(.largeTitle)
                        .fontWeight(.black)

                    Text(viewModel.unlockedBadge)
                        .font(.title)

                }
                .padding(40)
                .background(Color.purple)
                .cornerRadius(20)
                .shadow(radius: 20)
                    .transition(.scale)
                    .onAppear {

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            viewModel.showBadgeUnlocked = false
                        }

                }

            }

        }

    }

}
