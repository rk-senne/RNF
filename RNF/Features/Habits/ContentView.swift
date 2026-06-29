import SwiftUI

struct ContentView: View {

    @EnvironmentObject private var game: GameState
    @EnvironmentObject private var notifications: NotificationManager
    @StateObject private var viewModel = HabitsViewModel()
    @StateObject private var socialPresence = SocialPresenceProvider()
    @State private var activeChallenge: Challenge?
    @State private var isLoadingChallenge = true
    @State private var streakBounce = false
    private let challengeEngine = ChallengeEngine()

    var body: some View {

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Hero Section (one clear focal point)
                heroSection

                // MARK: - Today's Quests (the ONLY thing that matters)
                QuestScreenContent(
                    dailyQuests: game.quests,
                    weeklyQuest: viewModel.weeklyHabit,
                    completedHabitIDs: game.completedHabitIDs,
                    animatedHabit: viewModel.animatedHabit,
                    completeDailyQuest: { habit in
                        Task {
                            await viewModel.completeHabit(habit, notifications: notifications)
                        }
                    }
                )

                // MARK: - Secondary Context (below the fold, discoverable)
                secondarySection
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("RNF")
        .navigationBarTitleDisplayMode(.large)
        .overlay(alignment: .top) {
            if viewModel.persistenceError != nil {
                ErrorBanner(
                    message: "Save failed",
                    retryAction: nil,
                    dismissAction: { viewModel.persistenceError = nil }
                )
            }
        }
        .task {
            await viewModel.load(gameState: game)
            await loadChallengeSummary()
            await socialPresence.refresh(userId: game.profile.id)
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.willEnterForegroundNotification
        )) { _ in
            viewModel.handleForegroundTransition()
        }
        .onChange(of: game.streak) { _, _ in
            streakBounce = true
            RNFHaptics.impact(.light)
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                streakBounce = false
            }
        }
    }

    // MARK: - Hero Section
    // Rule: One clear message. User knows their state in <2 seconds.

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Narrative — the soul of the screen
            Text(narrativeText)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .italic()
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Key stats — only streak + progress. Nothing else.
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(game.streak)d streak")
                        .font(RNFFont.title)
                        .foregroundStyle(.primary)
                        .scaleEffect(streakBounce ? 1.05 : 1.0)
                        .animationIfAllowed(.spring(response: 0.3), value: streakBounce)

                    Text(StreakTierSystem.tier(for: game.streak).rawValue)
                        .font(RNFFont.pill)
                        .foregroundStyle(RNFColors.streak)
                }

                Spacer()

                // Daily progress ring (compact, immediate understanding)
                ZStack {
                    Circle()
                        .stroke(RNFColors.borderSubtle, lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: dailyProgress)
                        .stroke(RNFColors.success, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(game.dailyCompleted)/\(game.dailyGoal)")
                        .font(RNFFont.caption)
                        .foregroundStyle(.primary)
                }
                .frame(width: 52, height: 52)
            }

            // XP bar — thin, unobtrusive
            XPBar(xp: game.xp, levelXP: game.xpToNext, level: game.level)

            PillarStreakRow(streaks: PillarStreakService.load())
            GuildPulseBar(membersActive: socialPresence.guildMembersCompletedToday)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                .fill(RNFColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RNFRadius.card, style: .continuous)
                .strokeBorder(RNFColors.borderSubtle, lineWidth: 1)
        )
        .rnfShadow()
        .evolvingSurface()
    }

    // MARK: - Secondary Section
    // Below the fold. User scrolls here when they WANT more info.

    private var secondarySection: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Challenge progress — only if active
            if activeChallenge != nil {
                NavigationLink {
                    JourneyMapView(currentDay: activeChallenge?.normalizedCurrentDay ?? 1, onMilestoneTapped: { _ in })
                } label: {
                    challengeSummary
                }
                .buttonStyle(RNFCardButtonStyle())
                .shimmer(active: isLoadingChallenge)
            }

            // Seasonal arc — only if one is active and not yet complete
            if let arc = SeasonalArc.current, !SeasonalArcService.isCompleted() {
                seasonalArcCard(arc: arc)
            }
        }
    }

    // MARK: - Challenge Summary

    private var challengeSummary: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("90-Day Challenge")
                    .font(RNFFont.bodyBold)
                    .foregroundStyle(.primary)
                Text(challengeDayText)
                    .font(RNFFont.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            CircularProgressRing(progress: challengeProgress, lineWidth: 4)
                .frame(width: 36, height: 36)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.lg, style: .continuous)
                .fill(RNFColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RNFRadius.lg, style: .continuous)
                .strokeBorder(RNFColors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Seasonal Arc

    private func seasonalArcCard(arc: SeasonalArc) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(arc.name)
                    .font(RNFFont.bodyBold)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(Int(SeasonalArcService.progress() * 100))%")
                    .font(RNFFont.pill)
                    .foregroundStyle(RNFColors.primary)
            }
            ProgressView(value: SeasonalArcService.progress())
                .tint(RNFColors.primary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.lg, style: .continuous)
                .fill(RNFColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RNFRadius.lg, style: .continuous)
                .strokeBorder(RNFColors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Data

    private var dailyProgress: CGFloat {
        guard game.dailyGoal > 0 else { return 0 }
        return CGFloat(game.dailyCompleted) / CGFloat(game.dailyGoal)
    }

    private var challengeDayText: String {
        guard let activeChallenge else { return "Not started" }
        return "Day \(activeChallenge.normalizedCurrentDay) of \(Challenge.totalDays)"
    }

    private var challengeProgress: Double {
        activeChallenge?.progress ?? 0
    }

    private func loadChallengeSummary() async {
        guard !game.profile.isPlaceholder else {
            activeChallenge = nil
            isLoadingChallenge = false
            return
        }
        activeChallenge = await challengeEngine.loadActiveChallenge(userId: game.profile.id)
        isLoadingChallenge = false
    }

    private var narrativeText: String {
        let stats = game.stats
        let pairs: [(String, Int)] = [
            ("Strength", stats.strength), ("Discipline", stats.discipline),
            ("Focus", stats.focus), ("Energy", stats.energy),
            ("Wisdom", stats.wisdom), ("Mind", stats.mind), ("Spirit", stats.spirit)
        ]
        let weakest = pairs.min(by: { $0.1 < $1.1 })?.0 ?? "Discipline"
        let strongest = pairs.max(by: { $0.1 < $1.1 })?.0 ?? "Strength"
        let daysSinceStart: Int = {
            guard let created = game.profile.created_at else { return 1 }
            return max(1, Calendar.current.dateComponents([.day], from: created, to: .now).day ?? 1)
        }()
        return NarrativeEngine.narrative(
            level: game.level,
            streak: game.streak,
            tier: EvolutionSystem.currentTier(for: game.profile).name,
            weakestStat: weakest,
            strongestStat: strongest,
            daysSinceStart: daysSinceStart,
            yesterdayMissed: game.streak == 0 && daysSinceStart > 1
        )
    }
}
