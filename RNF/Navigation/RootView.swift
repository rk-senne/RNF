import SwiftUI

struct RootView: View {

    @StateObject private var notifications = NotificationManager()
    @StateObject private var ritualManager = RitualManager()
    @StateObject private var evolution = UIEvolutionProvider() // P20-EXP-06c
    @EnvironmentObject private var game: GameState
    @State private var selectedTab = 0
    @State private var showWeeklyReport = false

    var body: some View {

        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    ContentView()
                }
                .tag(0)

                NavigationStack {
                    WorkoutListView()
                }
                .tag(1)

                NavigationStack {
                    ReadView()
                }
                .tag(2)

                NavigationStack {
                    AscensionView()
                }
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            RNFTabBar(
                selection: $selectedTab,
                incompleteCount: max(game.dailyGoal - game.dailyCompleted, 0)
            )
        }
        .ignoresSafeArea(.keyboard)
        .background(
            Color(.systemBackground)
                .ignoresSafeArea()
        )
        .overlay(alignment: .top) {
            RNFToast(toast: notifications.currentToast)
                .animationIfAllowed(.spring(response: 0.35), value: notifications.currentToast)
        }
        .overlay {
            RNFCelebration(
                celebration: notifications.currentCelebration,
                onDismiss: { notifications.dismissCelebration() }
            )
            .animationIfAllowed(.spring(response: 0.4, dampingFraction: 0.8), value: notifications.currentCelebration)
        }
        .overlay {
            if notifications.currentCelebration == .missionComplete {
                ConfettiView()
            }
        }
        .environmentObject(notifications)
        .environmentObject(ritualManager)
        .environmentObject(evolution) // P20-EXP-06c
        .fullScreenCover(isPresented: $ritualManager.showMorningIntention) {
            MorningIntentionView()
        }
        .sheet(isPresented: $ritualManager.showEveningReflection) {
            EveningReflectionView()
        }
        .onAppear {
            ritualManager.checkMorningIntention()
            evolution.update(level: game.level) // P20-EXP-06c
            if WeeklyReportService.shouldShow() { showWeeklyReport = true }
            // P20-EXP-19c: Start Live Activity on app open
            if #available(iOS 16.2, *) {
                LiveActivityManager.start(
                    challengeDay: 1,
                    habitsCompleted: game.dailyCompleted,
                    habitsGoal: game.dailyGoal,
                    streak: game.streak,
                    tierName: StreakTierSystem.tier(for: game.streak).rawValue
                )
            }
        }
        .onChange(of: game.level) { _, newLevel in
            evolution.update(level: newLevel) // P20-EXP-06c
        }
        // P20-EXP-14e: Discovery evaluation on foreground
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await checkDiscoveries() }
        }
        .fullScreenCover(isPresented: $showWeeklyReport) {
            WeeklyReportView(
                report: WeeklyReportService.generate(profile: game.profile, streak: game.streak),
                onDismiss: {
                    WeeklyReportService.markShown()
                    showWeeklyReport = false
                }
            )
        }
    }

    // P20-EXP-14e: Evaluate passive discoveries on foreground
    private func checkDiscoveries() async {
        await DiscoveryService.evaluateOnForeground(game: game, notifications: notifications)
    }

}
