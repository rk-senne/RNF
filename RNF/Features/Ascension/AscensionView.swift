import SwiftUI

struct AscensionView: View {

    @EnvironmentObject private var game: GameState
    private let viewModel = AscensionViewModel()
    private let challengeEngine = ChallengeEngine()
    private let calendarService = CalendarService()
    private let skillTreeService = SkillTreeService()
    @State private var glow = false
    @State private var activeChallenge: Challenge?
    @State private var activePerks: ActivePerkSummary = .empty
    @State private var activePerksLoadFailed = false
    @State private var isLoadingActivePerks = false
    @State private var calendarMonth = Date()
    @State private var calendarStatuses: [Date: DailyLogStatus] = [:]
    @State private var calendarLoadFailed = false
    @State private var forgivenessMessage: String?
    @State private var isUsingForgiveness = false

    var body: some View {

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                VStack(spacing: 18) {

                    ZStack {

                        Circle()
                            .fill(viewModel.levelColor(for: game.level).opacity(0.18))
                            .frame(width: glow ? 232 : 208)
                            .blur(radius: glow ? 48 : 28)
                            .animation(
                                .easeInOut(duration: 2.2)
                                .repeatForever(autoreverses: true),
                                value: glow
                            )

                        VStack(spacing: 10) {

                            Text("LEVEL \(game.level)")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .foregroundStyle(Color.primary)

                            Text(viewModel.rankTitle(for: game.level))
                                .font(.system(size: 22, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.secondary)

                        }

                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                    .onAppear { glow.toggle() }

                    HStack(spacing: 12) {
                        summaryChip(
                            title: "Streak",
                            value: "\(game.streak) days",
                            tint: Color(red: 0.9, green: 0.46, blue: 0.18)
                        )

                        summaryChip(
                            title: "Titles",
                            value: "\(game.titles.count) earned",
                            tint: viewModel.levelColor(for: game.level)
                        )
                    }

                }
                .padding(24)
                .background { surfaceFill }
                .overlay(surfaceBorder)
                .shadow(color: Color.black.opacity(0.06), radius: 24, x: 0, y: 12)

                challengeSummary

                EvolutionView()

                activePerkSummary

                engagementEntryPoints

                calendarSummary

                VStack(alignment: .leading, spacing: 18) {

                    Text("XP PROGRESS")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)

                    ProgressView(value: Double(game.xp), total: Double(max(game.xpToNext, 1)))
                        .tint(viewModel.levelColor(for: game.level))
                        .scaleEffect(x: 1, y: 1.8, anchor: .center)

                    Text("\(game.xp) / \(game.xpToNext) XP")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background { surfaceFill }
                .overlay(surfaceBorder)

                VStack(alignment: .leading, spacing: 18) {

                    Text("CHARACTER STATS")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)

                    DisciplineRadarChart(
                        stats: viewModel.radarValues(for: game.stats)
                    )
                    .frame(height: 240)

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background { surfaceFill }
                .overlay(surfaceBorder)

                VStack(alignment: .leading, spacing: 14) {

                    Text("TITLES")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)

                    ForEach(game.titles, id: \.self) { title in
                        HStack(spacing: 12) {
                            Image(systemName: "seal.fill")
                                .foregroundStyle(viewModel.levelColor(for: game.level))
                            Text(title)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.72))
                        )
                    }

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background { surfaceFill }
                .overlay(surfaceBorder)

            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("Ascension")
        .navigationBarTitleDisplayMode(.large)
        .task(id: game.profile.id) {
            await loadChallengeSummary()
            await loadActivePerkSummary()
            await loadCalendarSummary()
        }

    }

    private var activePerkSummary: some View {

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("ACTIVE PERKS")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 12)

                Text(activePerkStatusText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(viewModel.levelColor(for: game.level))
            }

            if activePerkMetricCount == 0 {
                Text(activePerksLoadFailed ? "Perks unavailable" : "No active perks")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ],
                    spacing: 10
                ) {
                    if activePerks.xpMultiplierPercent > 0 {
                        perkMetricChip(
                            title: "XP",
                            value: "+\(activePerks.xpMultiplierPercent)%",
                            icon: "arrow.up.circle.fill"
                        )
                    }

                    if totalStatBonus > 0 {
                        perkMetricChip(
                            title: "Stats",
                            value: "+\(totalStatBonus)",
                            icon: "chart.bar.fill"
                        )
                    }

                    if activePerks.questRewardBonus > 0 {
                        perkMetricChip(
                            title: "Quest XP",
                            value: "+\(activePerks.questRewardBonus)",
                            icon: "gift.fill"
                        )
                    }

                    if activePerks.streakProtectionCount > 0 {
                        perkMetricChip(
                            title: "Protection",
                            value: "\(activePerks.streakProtectionCount)",
                            icon: "shield.fill"
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background { surfaceFill }
        .overlay(surfaceBorder)

    }

    private var activePerkStatusText: String {
        if isLoadingActivePerks {
            return "Syncing"
        }

        if activePerksLoadFailed {
            return "Offline"
        }

        return "\(activePerks.effects.count) active"
    }

    private var totalStatBonus: Int {
        activePerks.statBonuses.values.reduce(0, +)
    }

    private var activePerkMetricCount: Int {
        [
            activePerks.xpMultiplierPercent,
            totalStatBonus,
            activePerks.questRewardBonus,
            activePerks.streakProtectionCount
        ]
        .filter { $0 > 0 }
        .count
    }

    private var engagementEntryPoints: some View {

        VStack(alignment: .leading, spacing: 14) {
            Text("ENGAGEMENT")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                engagementLink(
                    title: "Quests",
                    subtitle: "Daily and weekly focus",
                    icon: "checkmark.circle.fill",
                    tint: Color(red: 0.3, green: 0.43, blue: 0.86)
                ) {
                    ContentView()
                }

                engagementLink(
                    title: "Skill Tree",
                    subtitle: "Mastery paths",
                    icon: "point.3.connected.trianglepath.dotted",
                    tint: viewModel.levelColor(for: game.level)
                ) {
                    SkillTreeView()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background { surfaceFill }
        .overlay(surfaceBorder)

    }

    private func engagementLink<Destination: View>(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        @ViewBuilder destination: () -> Destination
    ) -> some View {

        NavigationLink(destination: destination()) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(tint)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tint.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(tint.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)

    }

    private var challengeSummary: some View {

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("CHALLENGE ARC")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 12)

                Text(challengeDayText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(viewModel.levelColor(for: game.level))
            }

            ProgressView(value: challengeProgress)
                .tint(viewModel.levelColor(for: game.level))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)

            Text(challengeStatusText)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background { surfaceFill }
        .overlay(surfaceBorder)

    }

    private var calendarSummary: some View {

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("CALENDAR")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 12)

                Text(calendarLoadFailed ? "Offline" : "\(game.streak) day streak")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(viewModel.levelColor(for: game.level))
            }

            CalendarGridView(
                month: calendarMonth,
                statusesByDay: calendarStatuses
            )

            forgivenessRecoveryAction
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background { surfaceFill }
        .overlay(surfaceBorder)

    }

    private var forgivenessRecoveryAction: some View {

        HStack(spacing: 12) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 26))
                .foregroundStyle(viewModel.levelColor(for: game.level))

            VStack(alignment: .leading, spacing: 4) {
                Text("\(game.profile.forgiveness_tokens) forgiveness tokens")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(forgivenessMessage ?? forgivenessStatusText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Button {
                Task { await useForgiveness() }
            } label: {
                if isUsingForgiveness {
                    ProgressView()
                } else {
                    Image(systemName: "checkmark.shield.fill")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.levelColor(for: game.level))
            .disabled(!canUseForgiveness || isUsingForgiveness)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )

    }

    private var canUseForgiveness: Bool {
        !game.profile.isPlaceholder
            && game.profile.forgiveness_tokens > 0
            && game.dailyLog.status == .missed
            && !game.dailyLog.forgiveness_used
    }

    private var forgivenessStatusText: String {
        if game.dailyLog.forgiveness_used {
            return "Today is protected"
        }

        if game.profile.forgiveness_tokens <= 0 {
            return "No recovery available"
        }

        if game.dailyLog.status == .missed {
            return "Recovery available"
        }

        return "No recovery needed"
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
            return "Begin the 90-day challenge to track your transformation arc."
        }

        return "Your challenge progress is advancing with each completed day."
    }

    private func loadChallengeSummary() async {
        guard !game.profile.isPlaceholder else {
            activeChallenge = nil
            return
        }

        activeChallenge = await challengeEngine.loadActiveChallenge(userId: game.profile.id)
    }

    private func loadActivePerkSummary() async {
        isLoadingActivePerks = true
        activePerksLoadFailed = false

        do {
            activePerks = try await skillTreeService.activePerks(for: game.profile)
        } catch {
            activePerks = .empty
            activePerksLoadFailed = true
        }

        isLoadingActivePerks = false
    }

    private func loadCalendarSummary() async {
        calendarMonth = Date()

        guard !game.profile.isPlaceholder else {
            calendarLoadFailed = false
            calendarStatuses = [
                Calendar.current.startOfDay(for: game.dailyLog.date): calendarService.mapLogToCalendarStatus(game.dailyLog)
            ]
            return
        }

        do {
            let logs = try await calendarService.getMonthLogs(
                userId: game.profile.id,
                month: calendarMonth
            )
            let logsByDay = calendarService.groupMonthLogsByDay(logs)

            calendarStatuses = logsByDay.reduce(into: [:]) { statuses, item in
                statuses[item.key] = calendarService.calendarStatus(
                    for: item.key,
                    logsByDay: logsByDay
                )
            }
            calendarLoadFailed = false
        } catch {
            calendarLoadFailed = true
        }
    }

    private func useForgiveness() async {
        guard canUseForgiveness else {
            return
        }

        isUsingForgiveness = true
        defer { isUsingForgiveness = false }

        guard let result = await challengeEngine.useForgiveness(
            userId: game.profile.id,
            currentStreak: game.streak
        ) else {
            forgivenessMessage = "Recovery failed"
            return
        }

        game.dailyLog = result.dailyLog
        game.profile.forgiveness_tokens = result.remainingTokens
        game.streak = result.preservedStreak
        calendarStatuses[Calendar.current.startOfDay(for: result.dailyLog.date)] = .forgiven
        forgivenessMessage = "Streak protected"
    }

    private var surfaceFill: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white.opacity(0.88))
    }

    private var surfaceBorder: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
    }

    private func summaryChip(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(tint.opacity(0.75))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(tint.opacity(0.12))
        )
    }

    private func perkMetricChip(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(viewModel.levelColor(for: game.level))
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
    }

}
