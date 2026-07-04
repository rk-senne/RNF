# SPEC: Apple Platform Integrations

**Priority:** P1 — Platform Excellence  
**Status:** Draft  
**Created:** 2026-07-03  
**Owner:** Engineering  
**iOS Target:** 17.0+ (Control Center Controls require iOS 18+)

## Overview

This specification documents all Apple platform integrations for RNF. These features leverage iOS-native capabilities to reduce friction, increase engagement surface area, and create a "feels native" experience that differentiates RNF from cross-platform competitors.

Each integration is designed to meet users where they already are — Lock Screen, Siri, Control Center, StandBy, Apple Health — rather than requiring them to open the app.

---

## Table of Contents

1. [App Intents / Siri Shortcuts](#1-app-intents--siri-shortcuts)
2. [Background App Refresh](#2-background-app-refresh)
3. [iCloud/Local Offline Fallback](#3-icloudlocal-offline-fallback)
4. [StandBy Mode Widgets](#4-standby-mode-widgets)
5. [Control Center Controls](#5-control-center-controls-ios-18)
6. [Interactive Widgets](#6-interactive-widgets-ios-17)
7. [HealthKit Auto-Tracking](#7-healthkit-auto-tracking)
8. [HealthKit Write-Back](#8-healthkit-write-back)
9. [App Attest](#9-app-attest)
10. [Live Activities Expansion](#10-live-activities-expansion)
11. [Sign in with Apple](#11-sign-in-with-apple)
12. [Dependency Matrix](#dependency-matrix)

---

## 1. App Intents / Siri Shortcuts

### What It Is

A suite of App Intents that expose RNF's core actions to Siri, Shortcuts app, Spotlight, and the Action Button. Users can complete habits, start sessions, and check progress entirely by voice or automation.

### Why RNF Needs It

- Voice-first habit completion removes all friction ("Hey Siri, log my habits")
- Shortcuts integration enables power-user automations (e.g., "Morning Routine" shortcut that logs wake time + starts focus)
- Spotlight donations surface recently completed habits in search, reinforcing progress
- Action Button mapping on iPhone 15 Pro+ gives physical one-tap access

### Priority

**P1** — High engagement multiplier with moderate implementation effort.

### Implementation Design

#### Intent Definitions

```swift
// MARK: - CompleteHabitIntent

struct CompleteHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Habit"
    static var description = IntentDescription("Mark a habit as complete for today")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Habit", description: "The habit to complete")
    var habit: HabitEntity
    
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Bool> {
        let service = DailyLogService.shared
        let today = Date()
        try await service.recordHabitCompletion(habitId: habit.id, date: today)
        
        // Donate to Spotlight
        let interaction = INInteraction(intent: self, response: nil)
        interaction.donate()
        
        return .result(
            value: true,
            dialog: "Done! \(habit.name) completed. 💪"
        )
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Complete \(\.$habit)")
    }
}

// MARK: - StartFocusIntent

struct StartFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Focus Session"
    static var description = IntentDescription("Begin a timed focus session")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Duration", default: 25)
    var durationMinutes: Int
    
    @Parameter(title: "Session Name", default: "Focus")
    var sessionName: String
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let focusManager = FocusSessionManager.shared
        try await focusManager.startSession(
            name: sessionName,
            duration: TimeInterval(durationMinutes * 60)
        )
        return .result(dialog: "Starting \(sessionName) for \(durationMinutes) minutes. Let's go! 🎯")
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Start \(\.$sessionName) for \(\.$durationMinutes) minutes")
    }
}

// MARK: - StartWorkoutIntent

struct StartWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Workout"
    static var description = IntentDescription("Begin tracking a workout session")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Workout Type")
    var workoutType: WorkoutTypeEntity
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let workoutManager = WorkoutManager.shared
        try await workoutManager.startWorkout(type: workoutType.rawType)
        return .result(dialog: "Workout started! Let's crush it. 🏋️")
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Start \(\.$workoutType) workout")
    }
}

// MARK: - CheckStreakIntent

struct CheckStreakIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Streak"
    static var description = IntentDescription("Check your current streak count")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Int> {
        let profile = try await ProfileService.shared.getCurrentProfile()
        let streak = profile.currentStreak
        let message = streak > 0
            ? "You're on a \(streak)-day streak! 🔥 Keep it going!"
            : "No active streak yet. Complete today's habits to start one!"
        return .result(value: streak, dialog: "\(message)")
    }
}

// MARK: - LogDailyHabitsIntent

struct LogDailyHabitsIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Daily Habits"
    static var description = IntentDescription("Mark all of today's habits as complete")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Confirm", default: true)
    var confirmAll: Bool
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard confirmAll else {
            return .result(dialog: "Cancelled. Open the app to select individual habits.")
        }
        let service = DailyLogService.shared
        let habits = try await HabitService.shared.getActiveHabits()
        let today = Date()
        
        for habit in habits {
            try await service.recordHabitCompletion(habitId: habit.id, date: today)
        }
        
        return .result(dialog: "All \(habits.count) habits logged for today! 🎉")
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Log all daily habits") {
            \.$confirmAll
        }
    }
}
```

#### ShortcutsProvider

```swift
struct RNFShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CompleteHabitIntent(),
            phrases: [
                "Complete \(\.$habit) in \(.applicationName)",
                "Mark \(\.$habit) done in \(.applicationName)",
                "Log \(\.$habit) in \(.applicationName)"
            ],
            shortTitle: "Complete Habit",
            systemImageName: "checkmark.circle.fill"
        )
        
        AppShortcut(
            intent: StartFocusIntent(),
            phrases: [
                "Start focus in \(.applicationName)",
                "Begin focus session in \(.applicationName)",
                "Focus mode in \(.applicationName)"
            ],
            shortTitle: "Start Focus",
            systemImageName: "brain.head.profile"
        )
        
        AppShortcut(
            intent: StartWorkoutIntent(),
            phrases: [
                "Start workout in \(.applicationName)",
                "Begin exercise in \(.applicationName)"
            ],
            shortTitle: "Start Workout",
            systemImageName: "figure.run"
        )
        
        AppShortcut(
            intent: CheckStreakIntent(),
            phrases: [
                "Check my streak in \(.applicationName)",
                "How's my streak in \(.applicationName)",
                "What's my streak in \(.applicationName)"
            ],
            shortTitle: "Check Streak",
            systemImageName: "flame.fill"
        )
        
        AppShortcut(
            intent: LogDailyHabitsIntent(),
            phrases: [
                "Log all habits in \(.applicationName)",
                "Complete all habits in \(.applicationName)"
            ],
            shortTitle: "Log All Habits",
            systemImageName: "checklist"
        )
    }
}
```

#### Spotlight Donations

```swift
// Called after each habit completion
func donateToSpotlight(habit: Habit) {
    let attributes = CSSearchableItemAttributeSet(contentType: .item)
    attributes.title = "Completed: \(habit.name)"
    attributes.contentDescription = "Tap to complete again tomorrow"
    attributes.thumbnailData = habit.iconImageData
    
    let item = CSSearchableItem(
        uniqueIdentifier: "habit-\(habit.id)",
        domainIdentifier: "com.rnf.habits",
        attributeSet: attributes
    )
    item.expirationDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
    
    CSSearchableIndex.default().indexSearchableItems([item])
}
```

### API/Framework References

- `AppIntents` framework (iOS 16+)
- `IntentKit` for legacy Siri support fallback
- `CoreSpotlight` for search donations
- `ASAuthorizationController` for parameterized entity queries

### Acceptance Criteria

- [ ] All 5 intents compile and appear in Shortcuts app
- [ ] "Hey Siri, complete [habit] in RNF" works end-to-end
- [ ] ShortcutsProvider surfaces suggested shortcuts on install
- [ ] Spotlight shows recently completed habits within 30 seconds of completion
- [ ] Intents work without opening the app (except StartFocus and StartWorkout)
- [ ] Parameter resolution uses dynamic entity queries (not hardcoded lists)
- [ ] Siri dialog responses are grammatically correct and include emoji

---

## 2. Background App Refresh

### What It Is

Scheduled background tasks that keep widget data fresh, flush offline writes, and maintain subscription state — all without user interaction.

### Why RNF Needs It

- Widgets showing stale data erode trust ("It says 0/4 but I completed 2 habits an hour ago")
- Offline writes must eventually sync to prevent data loss
- Subscription status needs periodic refresh to enforce entitlements
- Daily analytics batch reduces API calls during active use

### Priority

**P1** — Required for widget reliability and offline-first architecture.

### Implementation Design

#### BackgroundTaskManager

```swift
import BackgroundTasks

final class BackgroundTaskManager {
    
    static let shared = BackgroundTaskManager()
    
    // Task identifiers (must match Info.plist BGTaskSchedulerPermittedIdentifiers)
    enum TaskID {
        static let widgetRefresh = "com.rnf.widget-refresh"
        static let analyticsBatch = "com.rnf.analytics-batch"
        static let syncFlush = "com.rnf.sync-flush"
    }
    
    func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskID.widgetRefresh,
            using: nil
        ) { task in
            self.handleWidgetRefresh(task: task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskID.analyticsBatch,
            using: nil
        ) { task in
            self.handleAnalyticsBatch(task: task as! BGProcessingTask)
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskID.syncFlush,
            using: nil
        ) { task in
            self.handleSyncFlush(task: task as! BGProcessingTask)
        }
    }
    
    // MARK: - Scheduling
    
    func scheduleWidgetRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: TaskID.widgetRefresh)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            Logger.background.error("Failed to schedule widget refresh: \(error)")
        }
    }
    
    func scheduleDailyProcessing() {
        // Analytics batch — daily at 3 AM
        let analyticsRequest = BGProcessingTaskRequest(identifier: TaskID.analyticsBatch)
        analyticsRequest.earliestBeginDate = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 3),
            matchingPolicy: .nextTime
        )
        analyticsRequest.requiresNetworkConnectivity = true
        analyticsRequest.requiresExternalPower = false
        
        // Sync flush — every 4 hours
        let syncRequest = BGProcessingTaskRequest(identifier: TaskID.syncFlush)
        syncRequest.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60)
        syncRequest.requiresNetworkConnectivity = true
        
        do {
            try BGTaskScheduler.shared.submit(analyticsRequest)
            try BGTaskScheduler.shared.submit(syncRequest)
        } catch {
            Logger.background.error("Failed to schedule processing: \(error)")
        }
    }
    
    // MARK: - Handlers
    
    private func handleWidgetRefresh(task: BGAppRefreshTask) {
        scheduleWidgetRefresh() // Re-schedule for next hour
        
        let operation = Task {
            do {
                let profile = try await ProfileService.shared.getCurrentProfile()
                let todayLog = try await DailyLogService.shared.getTodayLog()
                WidgetDataStore.shared.update(profile: profile, dailyLog: todayLog)
                WidgetCenter.shared.reloadAllTimelines()
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
        
        task.expirationHandler = { operation.cancel() }
    }
    
    private func handleAnalyticsBatch(task: BGProcessingTask) {
        scheduleDailyProcessing() // Re-schedule
        
        let operation = Task {
            do {
                try await AnalyticsService.shared.flushBatch()
                try await SubscriptionService.shared.refreshStatus()
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
        
        task.expirationHandler = { operation.cancel() }
    }
    
    private func handleSyncFlush(task: BGProcessingTask) {
        scheduleDailyProcessing() // Re-schedule
        
        let operation = Task {
            do {
                let queue = OfflineWriteQueue.shared
                try await queue.flushAll()
                
                // Pre-fetch tomorrow's daily log template
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                try await DailyLogService.shared.prefetch(date: tomorrow)
                
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
        
        task.expirationHandler = { operation.cancel() }
    }
}
```

#### Info.plist Registration

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.rnf.widget-refresh</string>
    <string>com.rnf.analytics-batch</string>
    <string>com.rnf.sync-flush</string>
</array>
```

#### App Delegate Integration

```swift
// In App init or AppDelegate
func application(_ application: UIApplication, didFinishLaunchingWithOptions ...) {
    BackgroundTaskManager.shared.registerTasks()
    BackgroundTaskManager.shared.scheduleWidgetRefresh()
    BackgroundTaskManager.shared.scheduleDailyProcessing()
}
```

### API/Framework References

- `BackgroundTasks` framework
- `BGTaskScheduler`, `BGAppRefreshTask`, `BGProcessingTask`
- `WidgetKit` → `WidgetCenter.shared.reloadAllTimelines()`

### Acceptance Criteria

- [ ] All 3 task identifiers registered in Info.plist
- [ ] Tasks register on app launch without errors
- [ ] Widget data refreshes within ~1 hour of habit completion (background)
- [ ] OfflineWriteQueue flushes completely during sync task
- [ ] Tasks re-schedule themselves after completion
- [ ] Expiration handlers properly cancel in-flight work
- [ ] No background task exceeds 30 seconds (refresh) or 5 minutes (processing)
- [ ] Subscription status is current within 24 hours

---

## 3. iCloud/Local Offline Fallback

### What It Is

A local-first data architecture where SwiftData serves as the primary read/write cache, with Supabase as the cross-device sync target and source of truth. The app works fully offline and syncs opportunistically.

### Why RNF Needs It

- Habit apps must work on the subway, in airplane mode, in rural areas — anywhere
- Users who can't log a habit due to connectivity will skip it and break their streak
- Local-first eliminates loading spinners for all read operations
- Cross-device sync (iPhone ↔ iPad ↔ Watch) requires a remote source of truth
- Prevents data loss when the app is force-quit mid-operation

### Priority

**P0** — Foundational architecture. Many other features depend on this.

### Implementation Design

#### Architecture: Repository Pattern

```
┌─────────────────────────────────────────────┐
│               ViewModel                      │
├─────────────────────────────────────────────┤
│            Repository Layer                   │
│  ┌──────────────┐    ┌───────────────────┐  │
│  │ LocalStore   │    │  RemoteStore      │  │
│  │ (SwiftData)  │    │  (Supabase)       │  │
│  └──────────────┘    └───────────────────┘  │
│         │                      │             │
│         ▼                      ▼             │
│  ┌──────────────┐    ┌───────────────────┐  │
│  │ ModelContext  │    │ OfflineWriteQueue │  │
│  └──────────────┘    └───────────────────┘  │
└─────────────────────────────────────────────┘
```

#### Repository Protocol

```swift
protocol Repository {
    associatedtype Entity: PersistentModel & Sendable
    
    /// Read from local store (instant, never throws for connectivity)
    func fetchLocal(predicate: Predicate<Entity>?) async -> [Entity]
    
    /// Write to local store + enqueue remote sync
    func save(_ entity: Entity) async throws
    
    /// Delete from local + enqueue remote deletion
    func delete(_ entity: Entity) async throws
    
    /// Pull latest from remote → merge into local
    func syncFromRemote() async throws
    
    /// Push pending local changes → remote
    func flushToRemote() async throws
}
```

#### Concrete Implementation: HabitRepository

```swift
final class HabitRepository: Repository {
    typealias Entity = HabitLocal
    
    private let context: ModelContext
    private let remote: SupabaseService
    private let writeQueue: OfflineWriteQueue
    
    init(
        context: ModelContext = .shared,
        remote: SupabaseService = .shared,
        writeQueue: OfflineWriteQueue = .shared
    ) {
        self.context = context
        self.remote = remote
        self.writeQueue = writeQueue
    }
    
    func fetchLocal(predicate: Predicate<HabitLocal>? = nil) async -> [HabitLocal] {
        let descriptor = FetchDescriptor<HabitLocal>(predicate: predicate)
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func save(_ entity: HabitLocal) async throws {
        // 1. Write locally (immediate)
        context.insert(entity)
        try context.save()
        
        // 2. Enqueue remote write
        writeQueue.enqueue(.upsert(
            table: "habits",
            id: entity.id.uuidString,
            payload: entity.toRemotePayload(),
            timestamp: Date()
        ))
    }
    
    func syncFromRemote() async throws {
        let lastSync = UserDefaults.standard.object(forKey: "habits_last_sync") as? Date
            ?? Date.distantPast
        
        let remoteHabits: [HabitRemote] = try await remote.client
            .from("habits")
            .select()
            .gt("updated_at", value: lastSync.iso8601String)
            .execute()
            .value
        
        for remoteHabit in remoteHabits {
            let local = try? context.fetch(
                FetchDescriptor<HabitLocal>(predicate: #Predicate { $0.id == remoteHabit.id })
            ).first
            
            if let local {
                // Conflict resolution: last-write-wins
                if remoteHabit.updatedAt > local.updatedAt {
                    local.merge(from: remoteHabit)
                }
            } else {
                context.insert(HabitLocal(from: remoteHabit))
            }
        }
        
        try context.save()
        UserDefaults.standard.set(Date(), forKey: "habits_last_sync")
    }
}
```

#### OfflineWriteQueue

```swift
@Model
final class PendingWrite {
    var id: UUID
    var operation: WriteOperation  // .upsert, .delete
    var table: String
    var entityId: String
    var payload: Data?  // JSON-encoded
    var timestamp: Date
    var retryCount: Int
    var maxRetries: Int = 5
    
    var isRetryable: Bool { retryCount < maxRetries }
}

actor OfflineWriteQueue {
    static let shared = OfflineWriteQueue()
    
    private let context: ModelContext
    
    func enqueue(_ write: PendingWrite) {
        context.insert(write)
        try? context.save()
        
        // Attempt immediate flush if online
        Task { try? await flushNext() }
    }
    
    func flushAll() async throws {
        let descriptor = FetchDescriptor<PendingWrite>(
            sortBy: [SortDescriptor(\.timestamp)]
        )
        let pending = try context.fetch(descriptor)
        
        for write in pending {
            do {
                try await execute(write)
                context.delete(write)
            } catch {
                write.retryCount += 1
                if !write.isRetryable {
                    Logger.sync.error("Write permanently failed: \(write.id)")
                    context.delete(write) // Dead-letter; log for investigation
                }
            }
        }
        try context.save()
    }
}
```

#### Conflict Resolution: Last-Write-Wins

```swift
extension Mergeable {
    /// Server timestamp is authoritative.
    /// If local.updatedAt > remote.updatedAt, local wins (remote will get overwritten on flush).
    /// If remote.updatedAt > local.updatedAt, remote wins (local gets overwritten).
    func resolveConflict(local: Self, remote: Self) -> Self {
        return local.updatedAt > remote.updatedAt ? local : remote
    }
}
```

#### What to Cache Locally

| Data | Retention | Reason |
|------|-----------|--------|
| `habits` | All active | Core app function |
| `daily_logs` | Last 90 days | Calendar view, streak calc |
| `profile` | Current | Displayed everywhere |
| `streak_data` | Current + history | Widget, intents |
| `skill_tree_state` | Full tree | Offline progression view |
| `challenges` | Active only | Quest tracking |
| `completions` | Last 90 days | Calendar dots |

#### SwiftData Model Container

```swift
@main
struct RNFApp: App {
    let container: ModelContainer
    
    init() {
        let schema = Schema([
            HabitLocal.self,
            DailyLogLocal.self,
            ProfileLocal.self,
            StreakLocal.self,
            SkillTreeLocal.self,
            PendingWrite.self
        ])
        
        let config = ModelConfiguration(
            "RNFLocal",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        container = try! ModelContainer(for: schema, configurations: [config])
    }
}
```

### API/Framework References

- `SwiftData` framework (iOS 17+)
- `@Model`, `ModelContext`, `ModelContainer`, `FetchDescriptor`
- `Supabase Swift SDK` for remote operations
- `Network` framework → `NWPathMonitor` for connectivity detection

### Acceptance Criteria

- [ ] App launches and displays habits with zero network connectivity
- [ ] Habit completion while offline is stored locally and syncs on reconnection
- [ ] Conflict resolution correctly applies last-write-wins using server timestamps
- [ ] OfflineWriteQueue retries up to 5 times with exponential backoff
- [ ] Local cache holds 90 days of daily logs without exceeding 50 MB
- [ ] Sync-from-remote only pulls records newer than last sync timestamp
- [ ] Watch app reads from shared App Group container
- [ ] No loading spinners for any read operation from local store

---

## 4. StandBy Mode Widgets

### What It Is

Widget families optimized for iPhone StandBy mode (iOS 17+) — the always-on bedside/desk display. Adds `.accessoryRectangular` and `.accessoryCircular` families that render well on dark backgrounds.

### Why RNF Needs It

- StandBy mode is high-visibility ambient surface (users see it every time they glance at their phone on a charger)
- Streak visibility during nighttime reinforces commitment ("I can't break this")
- Zero-effort engagement — user does nothing, RNF is just there
- Competitive differentiation: most habit apps ignore this surface entirely

### Priority

**P2** — Low effort, high ambient engagement value.

### Implementation Design

#### Rectangular Widget (`.accessoryRectangular`)

Displays: `"Day 47 | 🔥 Streak 23 | 2/4 today"`

```swift
struct StandByRectangularView: View {
    let entry: RNFWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Day \(entry.totalDays)")
                .font(.headline)
                .widgetAccentable()
            
            HStack(spacing: 8) {
                Label("\(entry.currentStreak)", systemImage: "flame.fill")
                    .foregroundStyle(.orange)
                
                Text("•")
                
                Text("\(entry.completedToday)/\(entry.totalToday) today")
            }
            .font(.caption)
        }
        .containerBackground(.clear, for: .widget)
    }
}
```

#### Circular Widget (`.accessoryCircular`)

Displays: Streak flame icon with day count overlay.

```swift
struct StandByCircularView: View {
    let entry: RNFWidgetEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            VStack(spacing: 0) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .widgetAccentable()
                
                Text("\(entry.currentStreak)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}
```

#### Widget Configuration

```swift
struct RNFWidget: Widget {
    let kind: String = "RNFWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RNFTimelineProvider()) { entry in
            RNFWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("RNF Progress")
        .description("Track your daily habits and streak")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,  // StandBy + Lock Screen
            .accessoryCircular,     // StandBy + Lock Screen
            .accessoryInline        // Lock Screen inline
        ])
    }
}
```

#### Dark Background Considerations

```swift
// StandBy is always dark mode — ensure contrast
extension View {
    @ViewBuilder
    func standByOptimized() -> some View {
        self
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
    }
}
```

### API/Framework References

- `WidgetKit` → `AccessoryWidgetBackground`, `.accessoryRectangular`, `.accessoryCircular`
- `SwiftUI` → `.widgetAccentable()`, `.containerBackground()`
- iOS 17+ StandBy API (no special entitlement needed; just support the widget families)

### Acceptance Criteria

- [ ] Rectangular widget displays day count, streak, and today's progress
- [ ] Circular widget displays flame icon with streak number
- [ ] Both widgets render legibly on dark StandBy backgrounds
- [ ] Widgets update within 1 hour via timeline provider
- [ ] No truncation on any iPhone screen size
- [ ] `.widgetAccentable()` applied to key elements for tint customization
- [ ] Preview renders correctly in Xcode canvas for all StandBy sizes

---

## 5. Control Center Controls (iOS 18+)

### What It Is

A Control Center widget (iOS 18+) that shows the next uncompleted habit and allows one-tap completion directly from Control Center — no app launch required.

### Why RNF Needs It

- Control Center is the fastest system UI to access (single swipe)
- One-tap habit completion is the lowest-friction interaction possible
- iOS 18 Control Center customization means users can place RNF controls prominently
- Removes the "open app → find habit → tap complete" funnel entirely

### Priority

**P2** — iOS 18+ only, but extremely high engagement value for supported users.

### Implementation Design

#### ControlWidget Definition

```swift
import WidgetKit
import AppIntents

struct CompleteHabitControl: ControlWidget {
    static let kind = "com.rnf.control.complete-habit"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: CompleteNextHabitIntent()) {
                Label {
                    Text(WidgetDataStore.shared.nextHabitName ?? "All Done!")
                } icon: {
                    Image(systemName: WidgetDataStore.shared.nextHabitName != nil
                        ? "circle"
                        : "checkmark.circle.fill")
                }
            }
        }
        .displayName("Complete Habit")
        .description("Complete your next pending habit")
    }
}
```

#### Supporting Intent

```swift
struct CompleteNextHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Next Habit"
    static var description = IntentDescription("Marks the next uncompleted habit as done")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult {
        guard let nextHabit = try await HabitService.shared.getNextUncompleted() else {
            return .result()
        }
        
        try await DailyLogService.shared.recordHabitCompletion(
            habitId: nextHabit.id,
            date: Date()
        )
        
        // Update widget data for next refresh
        WidgetDataStore.shared.markCompleted(nextHabit.id)
        ControlCenter.shared.reloadControls(ofKind: CompleteHabitControl.kind)
        
        return .result()
    }
}
```

#### Registration

```swift
// In Widget bundle
@main
struct RNFWidgetBundle: WidgetBundle {
    var body: some Widget {
        RNFWidget()
        CompleteHabitControl()  // iOS 18+
    }
}
```

### API/Framework References

- `WidgetKit` → `ControlWidget`, `ControlWidgetButton`, `StaticControlConfiguration`
- `AppIntents` framework for action binding
- iOS 18+ only (guard with `#available(iOS 18.0, *)`)

### Acceptance Criteria

- [ ] Control appears in Control Center customization gallery
- [ ] Displays name of next uncompleted habit
- [ ] Shows "All Done!" with checkmark when all habits complete
- [ ] Tap completes habit without launching app
- [ ] Control updates after completion to show next habit
- [ ] Graceful unavailability on iOS 17 and below
- [ ] Works correctly when no habits exist (shows empty state)

---

## 6. Interactive Widgets (iOS 17+)

### What It Is

Home screen and Lock Screen widgets with tappable checkboxes that complete habits directly from the widget surface. Uses App Intents for interaction and optimistic UI updates.

### Why RNF Needs It

- Home screen is the most-viewed surface on iOS (50+ views/day average)
- Interactive widgets eliminate the need to open the app for the primary action
- Progress ring provides continuous visual motivation
- Competitive parity: Streaks, Habitify already offer interactive widgets

### Priority

**P1** — Primary engagement surface outside the app.

### Implementation Design

#### Medium Widget (up to 4 habits + progress ring)

```swift
struct MediumHabitWidget: View {
    let entry: RNFWidgetEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Progress ring
            CircularProgressView(
                progress: entry.completionRatio,
                lineWidth: 6
            )
            .frame(width: 50, height: 50)
            .overlay {
                Text("\(entry.completedToday)/\(entry.totalToday)")
                    .font(.caption2.bold())
            }
            
            // Habit checklist
            VStack(alignment: .leading, spacing: 6) {
                ForEach(entry.habits.prefix(4)) { habit in
                    Button(intent: CompleteSpecificHabitIntent(habitId: habit.id)) {
                        HStack(spacing: 8) {
                            Image(systemName: habit.isCompleted
                                ? "checkmark.circle.fill"
                                : "circle")
                                .foregroundStyle(habit.isCompleted ? .green : .secondary)
                            
                            Text(habit.name)
                                .font(.caption)
                                .strikethrough(habit.isCompleted)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(habit.isCompleted)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
```

#### Large Widget (habits + quest + streak)

```swift
struct LargeHabitWidget: View {
    let entry: RNFWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: streak + day
            HStack {
                Label("\(entry.currentStreak) day streak", systemImage: "flame.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                
                Spacer()
                
                Text("Day \(entry.totalDays)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            // Habits (up to 6)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(entry.habits.prefix(6)) { habit in
                    Button(intent: CompleteSpecificHabitIntent(habitId: habit.id)) {
                        HStack(spacing: 8) {
                            Image(systemName: habit.isCompleted
                                ? "checkmark.circle.fill"
                                : "circle")
                                .foregroundStyle(habit.isCompleted ? .green : .secondary)
                                .font(.body)
                            
                            Text(habit.name)
                                .font(.subheadline)
                                .strikethrough(habit.isCompleted)
                            
                            Spacer()
                            
                            if habit.isCompleted {
                                Text("+\(habit.xpReward) XP")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(habit.isCompleted)
                }
            }
            
            Spacer()
            
            // Active quest progress
            if let quest = entry.activeQuest {
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundStyle(.purple)
                    Text(quest.name)
                        .font(.caption)
                    Spacer()
                    Text("\(quest.progress)/\(quest.goal)")
                        .font(.caption.bold())
                }
                .padding(8)
                .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
```

#### Intent for Specific Habit Completion

```swift
struct CompleteSpecificHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Specific Habit"
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Habit ID")
    var habitId: String
    
    init() {}
    
    init(habitId: String) {
        self.habitId = habitId
    }
    
    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: habitId) else { return .result() }
        
        try await DailyLogService.shared.recordHabitCompletion(
            habitId: uuid,
            date: Date()
        )
        
        // Optimistic: update shared data store immediately
        WidgetDataStore.shared.markCompleted(uuid)
        
        return .result()
    }
}
```

#### Timeline Provider with Optimistic Updates

```swift
struct RNFTimelineProvider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<RNFWidgetEntry>) -> Void) {
        Task {
            let store = WidgetDataStore.shared
            let entry = RNFWidgetEntry(
                date: Date(),
                habits: store.todayHabits,
                currentStreak: store.streak,
                totalDays: store.totalDays,
                activeQuest: store.activeQuest,
                completedToday: store.completedCount,
                totalToday: store.totalCount
            )
            
            // Refresh every 30 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}
```

### API/Framework References

- `WidgetKit` → `Button(intent:)` for interactive widgets (iOS 17+)
- `AppIntents` → Intent execution without app launch
- `SwiftUI` → `.containerBackground()`, widget families
- `WidgetCenter.shared.reloadTimelines(ofKind:)` for forced refresh

### Acceptance Criteria

- [ ] Medium widget shows up to 4 habits with checkboxes and progress ring
- [ ] Large widget shows up to 6 habits, quest progress, and streak
- [ ] Tapping uncompleted habit checkbox marks it complete without app launch
- [ ] Widget updates optimistically (checkbox fills immediately)
- [ ] Completed habits show strikethrough and green checkmark
- [ ] XP reward displayed next to completed habits (large widget)
- [ ] Progress ring animates to new value after completion
- [ ] Widget handles edge case of 0 habits gracefully
- [ ] Already-completed habits have disabled (non-tappable) checkboxes

---

## 7. HealthKit Auto-Tracking

### What It Is

Automatic habit completion based on HealthKit data. When a user's step count, exercise minutes, sleep hours, or mindfulness minutes reach a configured threshold, the corresponding habit is automatically marked complete.

### Why RNF Needs It

- Eliminates manual logging for fitness-related habits (biggest friction point for fitness goals)
- Apple Watch users already track this data — RNF should consume it, not duplicate it
- "Walk 10,000 steps" completing itself is a magical moment that builds trust
- Background delivery means habits complete even if the app isn't open
- Differentiator vs. generic habit apps that require manual input for everything

### Priority

**P1** — Major friction reducer for fitness-oriented users (estimated 40%+ of target audience).

### Implementation Design

#### Supported Auto-Track Mappings

| Habit Goal | HealthKit Type | Type Category | Example |
|-----------|---------------|---------------|---------|
| Walk X steps | `HKQuantityType.stepCount` | Quantity | "Walk 10,000 steps" |
| Exercise X minutes | `HKQuantityType.appleExerciseTime` | Quantity | "Exercise 30 minutes" |
| Sleep X hours | `HKCategoryType.sleepAnalysis` | Category | "Sleep 7 hours" |
| Mindfulness X minutes | `HKCategoryType.mindfulSession` | Category | "Meditate 10 minutes" |

#### HealthKitManager

```swift
import HealthKit

final class HealthKitManager: ObservableObject {
    
    static let shared = HealthKitManager()
    
    private let store = HKHealthStore()
    private var observerQueries: [HKObserverQuery] = []
    private var anchors: [String: HKQueryAnchor] = [:]
    
    // MARK: - Authorization
    
    var readTypes: Set<HKObjectType> {
        [
            HKQuantityType(.stepCount),
            HKQuantityType(.appleExerciseTime),
            HKCategoryType(.sleepAnalysis),
            HKCategoryType(.mindfulSession)
        ]
    }
    
    var writeTypes: Set<HKSampleType> {
        [
            HKWorkoutType.workoutType(),
            HKCategoryType(.mindfulSession)
        ]
    }
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
    }
    
    // MARK: - Observer Queries (Background Delivery)
    
    func enableBackgroundDelivery() async {
        let types: [(HKObjectType, HKUpdateFrequency)] = [
            (HKQuantityType(.stepCount), .hourly),
            (HKQuantityType(.appleExerciseTime), .hourly),
            (HKCategoryType(.sleepAnalysis), .daily),
            (HKCategoryType(.mindfulSession), .immediate)
        ]
        
        for (type, frequency) in types {
            do {
                try await store.enableBackgroundDelivery(for: type, frequency: frequency)
                startObserverQuery(for: type)
            } catch {
                Logger.healthKit.error("Background delivery failed for \(type): \(error)")
            }
        }
    }
    
    private func startObserverQuery(for type: HKObjectType) {
        let query = HKObserverQuery(sampleType: type as! HKSampleType, predicate: nil) {
            [weak self] _, completionHandler, error in
            
            guard error == nil else {
                completionHandler()
                return
            }
            
            Task {
                await self?.handleNewData(for: type)
                completionHandler()
            }
        }
        
        store.execute(query)
        observerQueries.append(query)
    }
    
    // MARK: - Anchor-Based Queries (Efficient Reads)
    
    private func handleNewData(for type: HKObjectType) async {
        guard let sampleType = type as? HKSampleType else { return }
        
        let anchor = anchors[type.identifier]
        let today = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: today,
            end: nil,
            options: .strictStartDate
        )
        
        let descriptor = HKAnchoredObjectQueryDescriptor(
            predicates: [.sample(type: sampleType, predicate: predicate)],
            anchor: anchor
        )
        
        do {
            let results = try await descriptor.result(for: store)
            anchors[type.identifier] = results.newAnchor
            
            // Calculate cumulative value for today
            let todayTotal = try await fetchTodayTotal(for: sampleType)
            await checkAutoComplete(type: sampleType, todayValue: todayTotal)
        } catch {
            Logger.healthKit.error("Anchor query failed: \(error)")
        }
    }
    
    private func fetchTodayTotal(for type: HKSampleType) async throws -> Double {
        let today = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: today, end: nil, options: .strictStartDate
        )
        
        switch type {
        case let quantityType as HKQuantityType:
            let descriptor = HKStatisticsQueryDescriptor(
                predicate: .quantitySample(type: quantityType, predicate: predicate),
                options: .cumulativeSum
            )
            let result = try await descriptor.result(for: store)
            let unit: HKUnit = quantityType == HKQuantityType(.stepCount) ? .count() : .minute()
            return result?.sumQuantity()?.doubleValue(for: unit) ?? 0
            
        case let categoryType as HKCategoryType:
            let descriptor = HKSampleQueryDescriptor(
                predicates: [.categorySample(type: categoryType, predicate: predicate)],
                sortDescriptors: []
            )
            let samples = try await descriptor.result(for: store)
            // Sum duration of all samples
            let totalMinutes = samples.reduce(0.0) { sum, sample in
                sum + sample.endDate.timeIntervalSince(sample.startDate) / 60.0
            }
            return categoryType == HKCategoryType(.sleepAnalysis)
                ? totalMinutes / 60.0  // Convert to hours for sleep
                : totalMinutes
            
        default:
            return 0
        }
    }
    
    // MARK: - Auto-Complete Logic
    
    private func checkAutoComplete(type: HKSampleType, todayValue: Double) async {
        let autoTrackHabits = await HabitRepository.shared.fetchLocal(
            predicate: #Predicate<HabitLocal> { $0.healthKitType == type.identifier && $0.isActive }
        )
        
        for habit in autoTrackHabits {
            guard !habit.isCompletedToday else { continue }
            guard todayValue >= habit.healthKitThreshold else { continue }
            
            // Auto-complete!
            do {
                try await DailyLogService.shared.recordHabitCompletion(
                    habitId: habit.id,
                    date: Date(),
                    source: .healthKit
                )
                
                // Notify user
                await NotificationManager.shared.sendAutoCompleteNotification(
                    habitName: habit.name,
                    value: todayValue,
                    threshold: habit.healthKitThreshold
                )
                
                Logger.healthKit.info("Auto-completed: \(habit.name) (\(todayValue)/\(habit.healthKitThreshold))")
            } catch {
                Logger.healthKit.error("Auto-complete failed for \(habit.name): \(error)")
            }
        }
    }
}
```

#### Habit Model Extension

```swift
extension HabitLocal {
    /// HealthKit type identifier (nil if not auto-tracked)
    var healthKitType: String? { ... }
    
    /// Threshold value for auto-completion
    var healthKitThreshold: Double { ... }
    
    /// Unit display string
    var healthKitUnit: String {
        switch healthKitType {
        case HKQuantityType(.stepCount).identifier: return "steps"
        case HKQuantityType(.appleExerciseTime).identifier: return "minutes"
        case HKCategoryType(.sleepAnalysis).identifier: return "hours"
        case HKCategoryType(.mindfulSession).identifier: return "minutes"
        default: return ""
        }
    }
}
```

### API/Framework References

- `HealthKit` → `HKHealthStore`, `HKObserverQuery`, `HKAnchoredObjectQueryDescriptor`
- `HKStatisticsQueryDescriptor` for cumulative sums
- Background delivery: `enableBackgroundDelivery(for:frequency:)`
- Required entitlement: `com.apple.developer.healthkit`
- Required `Info.plist` keys: `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`

### Acceptance Criteria

- [ ] HealthKit authorization requested on first auto-track habit creation
- [ ] Step count auto-completes "Walk X steps" habit when threshold reached
- [ ] Exercise minutes auto-completes within 1 hour of reaching threshold
- [ ] Sleep auto-completes by morning (daily frequency)
- [ ] Mindfulness auto-completes immediately after session ends
- [ ] User receives notification when habit auto-completes
- [ ] Anchor-based queries only process new data (no re-processing)
- [ ] Background delivery works when app is not running
- [ ] Habits already completed today are not re-completed
- [ ] Auto-tracked habits show HealthKit icon and live progress in habit list

---

## 8. HealthKit Write-Back

### What It Is

Writing RNF-generated health data back to Apple Health — specifically workouts and mindfulness sessions — so the user's health record is complete regardless of which app they check.

### Why RNF Needs It

- Users expect their workout data to appear in Apple Health / Fitness app
- Focus sessions are conceptually equivalent to mindfulness — Health should reflect them
- Bidirectional HealthKit integration signals "premium native app" quality
- Prevents double-counting if user also uses Apple Fitness+

### Priority

**P2** — Nice-to-have for launch; important for fitness-focused users.

### Implementation Design

#### Write Service

```swift
extension HealthKitManager {
    
    // MARK: - Write Workouts
    
    func writeWorkout(
        type: HKWorkoutActivityType,
        start: Date,
        end: Date,
        energyBurned: Double? = nil,
        metadata: [String: Any]? = nil
    ) async throws {
        guard isWriteEnabled else { return }
        
        let config = HKWorkoutConfiguration()
        config.activityType = type
        
        var samples: [HKSample] = []
        
        let workout = HKWorkout(
            activityType: type,
            start: start,
            end: end,
            workoutEvents: nil,
            totalEnergyBurned: energyBurned.map {
                HKQuantity(unit: .kilocalorie(), doubleValue: $0)
            },
            totalDistance: nil,
            metadata: mergeMeta(metadata)
        )
        
        try await store.save(workout)
        Logger.healthKit.info("Wrote workout: \(type.rawValue), duration: \(end.timeIntervalSince(start))s")
    }
    
    // MARK: - Write Mindfulness Sessions
    
    func writeMindfulnessSession(start: Date, end: Date) async throws {
        guard isWriteEnabled else { return }
        
        let type = HKCategoryType(.mindfulSession)
        let sample = HKCategorySample(
            type: type,
            value: HKCategoryValue.notApplicable.rawValue,
            start: start,
            end: end,
            metadata: [
                HKMetadataKeyExternalUUID: UUID().uuidString,
                "source": "RNF Focus Session"
            ]
        )
        
        try await store.save(sample)
        Logger.healthKit.info("Wrote mindfulness session: \(end.timeIntervalSince(start))s")
    }
    
    // MARK: - User Preference
    
    private var isWriteEnabled: Bool {
        UserDefaults.standard.bool(forKey: "healthkit_write_enabled")
    }
    
    private func mergeMeta(_ custom: [String: Any]?) -> [String: Any] {
        var meta: [String: Any] = [
            HKMetadataKeyExternalUUID: UUID().uuidString,
            "app": "RNF"
        ]
        if let custom { meta.merge(custom) { _, new in new } }
        return meta
    }
}
```

#### First-Time Write Prompt

```swift
struct HealthKitWritePromptView: View {
    @AppStorage("healthkit_write_enabled") private var writeEnabled = false
    @AppStorage("healthkit_write_asked") private var hasAsked = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)
            
            Text("Sync to Apple Health?")
                .font(.title2.bold())
            
            Text("Your RNF workouts and focus sessions can appear in Apple Health so everything's in one place.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                Button("Enable Sync") {
                    writeEnabled = true
                    hasAsked = true
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Not Now") {
                    writeEnabled = false
                    hasAsked = true
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(32)
    }
}
```

#### Integration Points

```swift
// In WorkoutManager, after workout completion:
func completeWorkout() async {
    // ... existing completion logic ...
    
    if !UserDefaults.standard.bool(forKey: "healthkit_write_asked") {
        // Show prompt (via notification or sheet)
        await MainActor.run { showHealthKitPrompt = true }
    } else if UserDefaults.standard.bool(forKey: "healthkit_write_enabled") {
        try? await HealthKitManager.shared.writeWorkout(
            type: currentWorkout.hkActivityType,
            start: currentWorkout.startDate,
            end: Date(),
            energyBurned: currentWorkout.estimatedCalories
        )
    }
}

// In FocusSessionManager, after session completion:
func completeSession() async {
    // ... existing completion logic ...
    
    if UserDefaults.standard.bool(forKey: "healthkit_write_enabled") {
        try? await HealthKitManager.shared.writeMindfulnessSession(
            start: currentSession.startDate,
            end: Date()
        )
    }
}
```

### API/Framework References

- `HealthKit` → `HKHealthStore.save(_:)`, `HKWorkout`, `HKCategorySample`
- `HKWorkoutActivityType` for workout classification
- `HKMetadataKeyExternalUUID` to prevent duplicate writes
- Write authorization: separate from read (user can grant read-only)

### Acceptance Criteria

- [ ] First workout completion triggers "Sync to Apple Health?" prompt
- [ ] User can enable/disable write-back in Settings
- [ ] Default is OFF (opt-in, not opt-out)
- [ ] Completed RNF workouts appear in Apple Health → Workouts
- [ ] Completed focus sessions appear in Apple Health → Mindfulness
- [ ] Duplicate prevention via external UUID metadata
- [ ] Write failures are logged but don't block app flow (fire-and-forget)
- [ ] Settings toggle clearly states what data is written
- [ ] No writes occur if user declined or hasn't been asked

---

## 9. App Attest

### What It Is

Device attestation using Apple's `DCAppAttestService` to cryptographically verify that XP submissions, leaderboard entries, and achievement claims originate from a genuine RNF app running on a real Apple device.

### Why RNF Needs It

- Leaderboards without attestation are trivially gameable (HTTP replay, modified clients)
- XP inflation undermines the entire progression system for legitimate users
- App Attest is the only reliable way to verify client authenticity on iOS
- Required for any competitive/social feature with integrity requirements
- Free to use (no per-call cost from Apple)

### Priority

**P2** — Required before public leaderboard launch. Not needed for core habit tracking.

### Implementation Design

#### Attestation Flow

```
┌──────────┐         ┌──────────┐         ┌─────────────────┐
│  Device  │         │  Apple   │         │ Supabase Edge   │
│  (RNF)   │         │  Server  │         │   Function      │
└────┬─────┘         └────┬─────┘         └───────┬─────────┘
     │                     │                       │
     │ 1. generateKey()    │                       │
     │────────────────────>│                       │
     │                     │                       │
     │ 2. keyId            │                       │
     │<────────────────────│                       │
     │                     │                       │
     │ 3. Request challenge│                       │
     │─────────────────────────────────────────────>
     │                     │                       │
     │ 4. challenge (nonce)│                       │
     │<─────────────────────────────────────────────
     │                     │                       │
     │ 5. attestKey(keyId, │                       │
     │    clientDataHash)  │                       │
     │────────────────────>│                       │
     │                     │                       │
     │ 6. attestation obj  │                       │
     │<────────────────────│                       │
     │                     │                       │
     │ 7. Send attestation │                       │
     │    to server        │                       │
     │─────────────────────────────────────────────>
     │                     │               8. Validate with
     │                     │               Apple's servers
     │                     │                       │
     │ 9. Verified ✓       │                       │
     │<─────────────────────────────────────────────
```

#### AppAttestService

```swift
import DeviceCheck

actor AppAttestManager {
    
    static let shared = AppAttestManager()
    
    private let service = DCAppAttestService.shared
    private var keyId: String?
    private var isAttested = false
    
    // MARK: - Key Generation (one-time)
    
    func generateKeyIfNeeded() async throws -> String {
        if let existing = Keychain.shared.get("app_attest_key_id") {
            self.keyId = existing
            return existing
        }
        
        guard service.isSupported else {
            throw AppAttestError.notSupported
        }
        
        let newKeyId = try await service.generateKey()
        Keychain.shared.set(newKeyId, forKey: "app_attest_key_id")
        self.keyId = newKeyId
        return newKeyId
    }
    
    // MARK: - Attestation (one-time per key)
    
    func attestKeyIfNeeded() async throws {
        guard !isAttested else { return }
        guard let keyId else { throw AppAttestError.noKey }
        
        // 1. Get challenge from server
        let challenge = try await SupabaseService.shared.client
            .functions.invoke("attest-challenge", invoke: .init(method: .post))
            .decode(as: AttestChallenge.self)
        
        // 2. Create client data hash
        let clientData = Data(challenge.nonce.utf8)
        let clientDataHash = SHA256.hash(data: clientData)
        
        // 3. Attest with Apple
        let attestation = try await service.attestKey(
            keyId,
            clientDataHash: Data(clientDataHash)
        )
        
        // 4. Send attestation to server for validation
        let response = try await SupabaseService.shared.client
            .functions.invoke("attest-verify", invoke: .init(
                method: .post,
                body: AttestVerifyRequest(
                    keyId: keyId,
                    attestation: attestation.base64EncodedString(),
                    challenge: challenge.nonce
                )
            ))
        
        isAttested = true
    }
    
    // MARK: - Assertions (per-request)
    
    func generateAssertion(for payload: Data) async throws -> Data {
        guard let keyId else { throw AppAttestError.noKey }
        
        // Assertion proves this request came from the attested device
        let clientDataHash = Data(SHA256.hash(data: payload))
        return try await service.generateAssertion(keyId, clientDataHash: clientDataHash)
    }
}
```

#### Protected Request Wrapper

```swift
extension SupabaseService {
    
    /// Send a request with App Attest assertion attached
    func attestedRequest<T: Codable>(
        function: String,
        payload: T
    ) async throws -> Data {
        let payloadData = try JSONEncoder().encode(payload)
        
        do {
            // Try to get assertion
            try await AppAttestManager.shared.attestKeyIfNeeded()
            let assertion = try await AppAttestManager.shared.generateAssertion(for: payloadData)
            
            return try await client.functions.invoke(function, invoke: .init(
                method: .post,
                body: AttestedPayload(
                    data: payloadData.base64EncodedString(),
                    assertion: assertion.base64EncodedString(),
                    verified: true
                )
            )).data
        } catch {
            // Graceful degradation: submit as unverified
            Logger.attest.warning("Attestation failed, submitting unverified: \(error)")
            return try await client.functions.invoke(function, invoke: .init(
                method: .post,
                body: AttestedPayload(
                    data: payloadData.base64EncodedString(),
                    assertion: nil,
                    verified: false
                )
            )).data
        }
    }
}
```

#### Server-Side Validation (Supabase Edge Function)

```typescript
// supabase/functions/attest-verify/index.ts
import { serve } from "https://deno.land/std/http/server.ts";
import { verifyAttestation } from "./apple-attest.ts";

serve(async (req) => {
  const { keyId, attestation, challenge } = await req.json();
  
  const result = await verifyAttestation({
    attestation: Buffer.from(attestation, 'base64'),
    challenge: challenge,
    keyId: keyId,
    teamId: Deno.env.get("APPLE_TEAM_ID")!,
    bundleId: Deno.env.get("BUNDLE_ID")!,
    // Use production environment for App Store builds
    environment: Deno.env.get("ATTEST_ENV") === "production" 
      ? "production" 
      : "development"
  });
  
  if (result.valid) {
    // Store public key for future assertion verification
    await supabase.from("device_attestations").upsert({
      key_id: keyId,
      public_key: result.publicKey,
      user_id: req.headers.get("x-user-id"),
      attested_at: new Date().toISOString()
    });
  }
  
  return new Response(JSON.stringify({ valid: result.valid }));
});
```

#### Graceful Degradation

| Scenario | Behavior |
|----------|----------|
| Device supports App Attest | Full attestation + assertion |
| Simulator / unsupported device | Submit as "unverified" |
| Attestation fails (network) | Retry once, then submit unverified |
| Server validation fails | Reject submission, ask user to retry |
| Unverified submissions | Accepted but flagged; shown with ⚠️ on leaderboard |

### API/Framework References

- `DeviceCheck` → `DCAppAttestService`
- `CryptoKit` → `SHA256` for client data hashing
- `Security` → Keychain for key ID storage
- Apple documentation: [Validating Apps That Connect to Your Server](https://developer.apple.com/documentation/devicecheck/validating-apps-that-connect-to-your-server)

### Acceptance Criteria

- [ ] Key generated and stored in Keychain on first leaderboard interaction
- [ ] Attestation completes successfully on real devices
- [ ] Assertions attached to all XP submission and leaderboard requests
- [ ] Server validates attestation against Apple's root certificate
- [ ] Unverified submissions are accepted but marked with flag
- [ ] Leaderboard shows verified badge (✓) vs unverified indicator (⚠️)
- [ ] Simulator builds gracefully degrade without crashes
- [ ] Key rotation handled (re-attest if key becomes invalid)
- [ ] No user-facing errors from attestation failures

---

## 10. Live Activities Expansion

### What It Is

Expansion of the existing daily progress Live Activity to include dedicated Workout Timer and Focus Session Live Activities with Dynamic Island support.

### Why RNF Needs It

- Current: only daily progress Live Activity exists
- Workout timer on Lock Screen / Dynamic Island keeps users motivated mid-workout
- Focus session countdown creates accountability ("12 minutes left — keep going")
- Dynamic Island presence means RNF is visible even while using other apps
- Prevents users from needing to open RNF to check timer status

### Priority

**P2** — Enhances existing active sessions; not blocking for core functionality.

### Implementation Design

#### Workout Timer Live Activity

```swift
// MARK: - Activity Attributes

struct WorkoutActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var elapsedSeconds: Int
        var targetSeconds: Int
        var progressPercentage: Double
        var isComplete: Bool
    }
    
    let workoutName: String
    let workoutType: String  // SF Symbol name
    let startedAt: Date
}

// MARK: - Live Activity Views

struct WorkoutLiveActivityView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    
    var body: some View {
        HStack(spacing: 16) {
            // Workout type icon
            Image(systemName: context.attributes.workoutType)
                .font(.title2)
                .foregroundStyle(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.workoutName)
                    .font(.headline)
                
                // Elapsed time
                Text(timerInterval: context.attributes.startedAt...Date.distantFuture,
                     countsDown: false)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Progress ring
            CircularProgressView(progress: context.state.progressPercentage)
                .frame(width: 44, height: 44)
                .overlay {
                    Text("\(Int(context.state.progressPercentage * 100))%")
                        .font(.caption2.bold())
                }
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.8))
    }
}

// MARK: - Dynamic Island

struct WorkoutDynamicIslandView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    
    // Compact Leading
    var compactLeading: some View {
        Image(systemName: context.attributes.workoutType)
            .foregroundStyle(.green)
    }
    
    // Compact Trailing
    var compactTrailing: some View {
        Text(timerInterval: context.attributes.startedAt...Date.distantFuture,
             countsDown: false)
            .font(.system(.caption, design: .monospaced))
            .frame(width: 52)
    }
    
    // Expanded
    var expanded: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(context.attributes.workoutName)
                    .font(.headline)
                Text(timerInterval: context.attributes.startedAt...Date.distantFuture,
                     countsDown: false)
                    .font(.system(.title3, design: .monospaced))
            }
            
            Spacer()
            
            CircularProgressView(progress: context.state.progressPercentage)
                .frame(width: 50, height: 50)
        }
        .padding()
    }
}
```

#### Focus Session Live Activity

```swift
struct FocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
        var isComplete: Bool
    }
    
    let sessionName: String
    let totalDuration: TimeInterval
    let endTime: Date
}

struct FocusLiveActivityView: View {
    let context: ActivityViewContext<FocusActivityAttributes>
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundStyle(.purple)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.sessionName)
                    .font(.headline)
                
                // Countdown timer
                Text(timerInterval: Date()...context.attributes.endTime,
                     countsDown: true)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.purple)
            }
            
            Spacer()
            
            // Remaining time indicator
            Text("\(context.state.remainingSeconds / 60)m")
                .font(.title3.bold())
                .foregroundStyle(.purple)
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.8))
    }
}

// Dynamic Island - Compact
struct FocusDynamicIslandCompact: View {
    let context: ActivityViewContext<FocusActivityAttributes>
    
    var compactLeading: some View {
        Image(systemName: "brain.head.profile")
            .foregroundStyle(.purple)
    }
    
    var compactTrailing: some View {
        Text(timerInterval: Date()...context.attributes.endTime, countsDown: true)
            .font(.system(.caption, design: .monospaced))
            .frame(width: 52)
            .foregroundStyle(.purple)
    }
}
```

#### Activity Lifecycle Management

```swift
extension LiveActivityManager {
    
    // MARK: - Workout Activity
    
    func startWorkoutActivity(
        name: String,
        type: String,
        targetDuration: TimeInterval
    ) throws -> Activity<WorkoutActivityAttributes> {
        let attributes = WorkoutActivityAttributes(
            workoutName: name,
            workoutType: type,
            startedAt: Date()
        )
        
        let initialState = WorkoutActivityAttributes.ContentState(
            elapsedSeconds: 0,
            targetSeconds: Int(targetDuration),
            progressPercentage: 0,
            isComplete: false
        )
        
        let content = ActivityContent(state: initialState, staleDate: nil)
        return try Activity.request(
            attributes: attributes,
            content: content,
            pushType: nil
        )
    }
    
    func updateWorkoutActivity(
        _ activity: Activity<WorkoutActivityAttributes>,
        elapsed: Int,
        target: Int
    ) async {
        let progress = min(Double(elapsed) / Double(target), 1.0)
        let state = WorkoutActivityAttributes.ContentState(
            elapsedSeconds: elapsed,
            targetSeconds: target,
            progressPercentage: progress,
            isComplete: progress >= 0.8  // 80% = complete
        )
        
        await activity.update(ActivityContent(state: state, staleDate: nil))
    }
    
    func endWorkoutActivity(
        _ activity: Activity<WorkoutActivityAttributes>,
        completed: Bool
    ) async {
        let finalState = WorkoutActivityAttributes.ContentState(
            elapsedSeconds: 0,
            targetSeconds: 0,
            progressPercentage: completed ? 1.0 : 0,
            isComplete: completed
        )
        
        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: .after(.now + 300)  // Dismiss after 5 min
        )
    }
    
    // MARK: - Focus Activity
    
    func startFocusActivity(
        name: String,
        duration: TimeInterval
    ) throws -> Activity<FocusActivityAttributes> {
        let endTime = Date().addingTimeInterval(duration)
        
        let attributes = FocusActivityAttributes(
            sessionName: name,
            totalDuration: duration,
            endTime: endTime
        )
        
        let initialState = FocusActivityAttributes.ContentState(
            remainingSeconds: Int(duration),
            isComplete: false
        )
        
        return try Activity.request(
            attributes: attributes,
            content: ActivityContent(state: initialState, staleDate: endTime),
            pushType: nil
        )
    }
    
    func endFocusActivity(
        _ activity: Activity<FocusActivityAttributes>,
        completed: Bool
    ) async {
        let finalState = FocusActivityAttributes.ContentState(
            remainingSeconds: 0,
            isComplete: completed
        )
        
        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: .default
        )
    }
}
```

#### End Conditions

| Activity | End Trigger | Behavior |
|----------|-------------|----------|
| Workout Timer | Progress ≥ 80% | Mark complete, show celebration state |
| Workout Timer | User cancels | End immediately, no XP |
| Workout Timer | 4 hours elapsed | Force end (safety timeout) |
| Focus Session | Timer expires | End with completion, award XP |
| Focus Session | User cancels | End early, partial credit if >50% |
| Focus Session | App terminated | Activity persists, ends at scheduled time |

### API/Framework References

- `ActivityKit` → `Activity`, `ActivityAttributes`, `ActivityContent`
- `WidgetKit` → Live Activity widget views
- `SwiftUI` → `Text(timerInterval:countsDown:)` for live countdown
- Dynamic Island: compact leading/trailing + expanded regions

### Acceptance Criteria

- [ ] Workout timer appears on Lock Screen when workout starts
- [ ] Focus countdown appears on Lock Screen when session starts
- [ ] Dynamic Island shows compact view (icon + time) in both activities
- [ ] Dynamic Island expanded view shows full progress details
- [ ] Workout ends automatically at 80%+ completion
- [ ] Focus session ends when countdown reaches zero
- [ ] User can end either activity early via the app
- [ ] Activities dismissed from Lock Screen after 5 minutes post-completion
- [ ] No more than one Live Activity of each type active simultaneously
- [ ] Timer continues accurately even when phone is locked

---

## 11. Sign in with Apple

### What It Is

Apple's native authentication flow integrated as a primary sign-in option.

### Why RNF Needs It

See **[SPEC_PRODUCTION_BLOCKERS.md → C7](./SPEC_PRODUCTION_BLOCKERS.md#c7-sign-in-with-apple)** for full specification.

### Priority

**P0** — App Store policy requirement (Guideline 4.8). Fully specced in production blockers document.

### Cross-Reference Summary

- Full implementation design: `SPEC_PRODUCTION_BLOCKERS.md` § C7
- Includes: `AppleAuthService`, nonce generation, Supabase OAuth integration
- Depends on: C1 (SupabaseService fix)
- Depended on by: C6 (Account Deletion)

### Acceptance Criteria

See SPEC_PRODUCTION_BLOCKERS.md § C7 acceptance criteria.

---

## Dependency Matrix

### Feature Dependencies

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEPENDENCY GRAPH                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────┐                                         │
│  │ 3. Offline Fallback │ ◄── FOUNDATION                         │
│  └──────────┬──────────┘                                         │
│             │                                                     │
│     ┌───────┼───────────────────────┐                            │
│     │       │                       │                            │
│     ▼       ▼                       ▼                            │
│  ┌──────┐ ┌──────┐           ┌───────────┐                      │
│  │ 1.   │ │ 2.   │           │ 6. Inter- │                      │
│  │Intents│ │BG    │           │active     │                      │
│  │      │ │Refresh│           │Widgets    │                      │
│  └──┬───┘ └──┬───┘           └─────┬─────┘                      │
│     │        │                      │                            │
│     │        │               ┌──────┼──────┐                     │
│     ▼        ▼               ▼      │      ▼                    │
│  ┌──────┐ ┌──────┐    ┌──────┐     │  ┌──────┐                 │
│  │ 5.   │ │ 4.   │    │ 7.   │     │  │ 10.  │                 │
│  │Ctrl  │ │StandBy│   │HK    │     │  │Live  │                 │
│  │Center│ │Widget │    │Auto  │     │  │Activ.│                 │
│  └──────┘ └──────┘    └──┬───┘     │  └──────┘                 │
│                           │         │                            │
│                           ▼         │                            │
│                     ┌──────┐        │                            │
│                     │ 8.   │        │                            │
│                     │HK    │        │                            │
│                     │Write │        │                            │
│                     └──────┘        │                            │
│                                     │                            │
│  ┌──────┐                           │                            │
│  │ 11.  │ (see SPEC_PRODUCTION_BLOCKERS)                         │
│  │SIWA  │                           │                            │
│  └──┬───┘                           │                            │
│     │                               │                            │
│     ▼                               │                            │
│  ┌──────┐                    ┌──────┘                            │
│  │ 9.   │ ◄─────────────────┘                                   │
│  │App   │  (needs user identity for attestation)                 │
│  │Attest│                                                        │
│  └──────┘                                                        │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Dependency Table

| # | Feature | Depends On | Blocks |
|---|---------|-----------|--------|
| 1 | App Intents / Siri | 3 (Offline Fallback) | 5 (Control Center), 6 (Interactive Widgets) |
| 2 | Background App Refresh | 3 (Offline Fallback) | 4 (StandBy — data freshness) |
| 3 | Offline Fallback | None | 1, 2, 6, 7 |
| 4 | StandBy Widgets | 2 (Background Refresh — for data) | None |
| 5 | Control Center Controls | 1 (App Intents) | None |
| 6 | Interactive Widgets | 1 (App Intents), 3 (Offline Fallback) | None |
| 7 | HealthKit Auto-Tracking | 3 (Offline Fallback) | 8 (HealthKit Write-Back) |
| 8 | HealthKit Write-Back | 7 (HealthKit Manager setup) | None |
| 9 | App Attest | 11 (Sign in with Apple — user identity) | None |
| 10 | Live Activities Expansion | None (existing infra) | None |
| 11 | Sign in with Apple | C1 from SPEC_PRODUCTION_BLOCKERS | 9 (App Attest) |

### Implementation Order (Recommended)

| Phase | Features | Rationale |
|-------|----------|-----------|
| **Phase A** | 3 (Offline), 11 (SIWA), 10 (Live Activities) | Foundation + independent |
| **Phase B** | 1 (Intents), 2 (BG Refresh), 7 (HK Auto) | Depend on Phase A |
| **Phase C** | 4 (StandBy), 5 (Control Center), 6 (Interactive), 8 (HK Write) | Depend on Phase B |
| **Phase D** | 9 (App Attest) | Depends on auth being stable |

### Priority Summary

| Priority | Features |
|----------|----------|
| **P0** | 3 (Offline Fallback), 11 (Sign in with Apple) |
| **P1** | 1 (App Intents), 2 (BG Refresh), 6 (Interactive Widgets), 7 (HealthKit Auto) |
| **P2** | 4 (StandBy), 5 (Control Center), 8 (HK Write-Back), 9 (App Attest), 10 (Live Activities) |

---

## Appendix: Required Entitlements & Info.plist Keys

| Feature | Entitlement / Key |
|---------|-------------------|
| HealthKit | `com.apple.developer.healthkit` |
| HealthKit | `NSHealthShareUsageDescription` |
| HealthKit | `NSHealthUpdateUsageDescription` |
| Background Refresh | `BGTaskSchedulerPermittedIdentifiers` |
| App Attest | `com.apple.developer.devicecheck.appattest-environment` |
| Sign in with Apple | `com.apple.developer.applesignin` |
| Siri | `com.apple.developer.siri` |
| WidgetKit | Widget extension target |
| Live Activities | `NSSupportsLiveActivities = YES` |
| Live Activities | `NSSupportsLiveActivitiesFrequentUpdates = YES` |

---

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-07-03 | Engineering | Initial draft — all 11 features specced |
