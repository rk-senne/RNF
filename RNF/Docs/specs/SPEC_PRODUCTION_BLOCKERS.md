# SPEC: Production Blockers

**Priority:** P0 — Ship-blocking  
**Status:** Draft  
**Created:** 2026-07-03  
**Owner:** Engineering

## Overview

This specification documents seven critical issues that **must** be resolved before any App Store release. Each item either causes crashes, data loss, policy violations, or renders core features non-functional.

Items are ordered by implementation dependency — later items may depend on earlier ones being complete.

---

## Implementation Order

| # | ID | Title | Est. Effort | Depends On |
|---|-----|-------|-------------|------------|
| 1 | C1 | SupabaseService Guaranteed Crash | 2h | — |
| 2 | C2 | FocusCompletionHandler XP Data Loss | 1h | — |
| 3 | C3 | SubscriptionService Empty Stub | 6h | C1 |
| 4 | C5 | Watch Missing Incoming Message Handler | 2h | — |
| 5 | C4 | Watch Complication Shows 0/0 | 2h | C5 |
| 6 | C7 | Sign in with Apple | 8h | C1 |
| 7 | C6 | Account Deletion | 8h | C1, C7 |

**Total estimated effort:** ~29 engineering hours

---

## C1. SupabaseService Guaranteed Crash

### Problem Statement

In RELEASE builds, if `SUPABASE_URL` or `SUPABASE_ANON_KEY` are missing from Info.plist, `AppConfig` returns an empty string. `URL(string: "")` returns `nil`, and `SupabaseService.init()` calls `fatalError()` — guaranteeing a crash on launch for any build where plist keys are misconfigured.

### Root Cause

**File:** `Core/AppConfig.swift:17`, `Services/SupabaseService.swift:10`

```swift
// AppConfig.swift — RELEASE path returns empty string
#else
return ""
#endif

// SupabaseService.swift — fatalError on nil URL
guard let url = URL(string: AppConfig.supabaseURL) else {
    fatalError("Invalid Supabase URL in AppConfig: '\(AppConfig.supabaseURL)'")
}
```

The `#if DEBUG` / `#else` split correctly crashes in DEBUG but silently returns empty strings in RELEASE, which then fail at the URL parse in `SupabaseService`.

### Impact

- **Severity:** App crashes on launch — 100% of RELEASE users affected
- **Scope:** Every code path that touches `SupabaseService.shared` (auth, sync, habits, daily logs, subscriptions)
- **App Review:** Instant rejection

### Solution Design

#### 1. Build-Phase Validation Script

Add a Run Script phase in Xcode (before Compile Sources) that fails the build if keys are missing:

```bash
#!/bin/bash
# Validate Supabase keys exist in Info.plist
PLIST="${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"

check_key() {
    VALUE=$(/usr/libexec/PlistBuddy -c "Print :$1" "$PLIST" 2>/dev/null)
    if [ -z "$VALUE" ]; then
        echo "error: Missing required Info.plist key: $1"
        exit 1
    fi
}

check_key "SUPABASE_URL"
check_key "SUPABASE_ANON_KEY"
```

#### 2. AppConfig → Optional with validation

```swift
enum AppConfig {
    enum ConfigError: Error, LocalizedError {
        case missingKey(String)
        case invalidURL(String)
        
        var errorDescription: String? {
            switch self {
            case .missingKey(let key): return "Missing configuration: \(key)"
            case .invalidURL(let raw): return "Invalid URL: \(raw)"
            }
        }
    }
    
    static func supabaseURL() throws -> URL {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !raw.isEmpty else {
            throw ConfigError.missingKey("SUPABASE_URL")
        }
        guard let url = URL(string: raw) else {
            throw ConfigError.invalidURL(raw)
        }
        return url
    }
    
    static func supabaseAnonKey() throws -> String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty else {
            throw ConfigError.missingKey("SUPABASE_ANON_KEY")
        }
        return key
    }
}
```

#### 3. SupabaseService → Failable initialization with error state

```swift
final class SupabaseService {
    static let shared: SupabaseService = {
        do {
            return try SupabaseService()
        } catch {
            return SupabaseService(error: error)
        }
    }()
    
    private(set) var client: SupabaseClient?
    private(set) var configError: Error?
    
    var isConfigured: Bool { client != nil }
    
    private init() throws {
        let url = try AppConfig.supabaseURL()
        let key = try AppConfig.supabaseAnonKey()
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: key)
        self.configError = nil
    }
    
    private init(error: Error) {
        self.client = nil
        self.configError = error
    }
    
    init(client: SupabaseClient) {
        self.client = client
        self.configError = nil
    }
    
    func requireClient() throws -> SupabaseClient {
        guard let client else {
            throw configError ?? AppConfig.ConfigError.missingKey("SUPABASE_URL")
        }
        return client
    }
}
```

#### 4. App-level error state

In `RNFApp.swift` or `RootView`, check `SupabaseService.shared.isConfigured` on launch. If `false`, show a non-interactive error screen with the message and a "Retry" button (for hot-config scenarios) instead of crashing.

### Acceptance Criteria

- [ ] Build fails in CI if Info.plist keys are missing
- [ ] App does NOT crash in RELEASE when keys are absent — shows error state
- [ ] All services that consume `SupabaseService` handle the `requireClient()` throw path
- [ ] DEBUG builds still `fatalError` immediately for fast developer feedback
- [ ] Existing unit tests with injected `SupabaseClient` continue to pass

### Dependencies

- None (foundation for C3, C6, C7)


---

## C2. FocusCompletionHandler XP Data Loss

### Problem Statement

`FocusCompletionHandler.complete()` directly mutates individual `GameState` properties (`xp`, `xpToNext`, `level`, `stats`) without updating the underlying `Profile` object. This means:
1. XP gained during focus sessions is never persisted to the database
2. The `Profile` object diverges from displayed state
3. Any subsequent `gameState.apply()` call (e.g., from habit completion or daily sync) overwrites the focus XP with stale `Profile` data

### Root Cause

**File:** `Core/FocusCompletionHandler.swift:4-9`

```swift
struct FocusCompletionHandler {
    static func complete(xp: Int, gameState: GameState) {
        let applied = XPSystem.applyXP(totalXP: gameState.xp, gainedXP: xp)
        gameState.xp = applied.xpIntoLevel
        gameState.xpToNext = applied.xpToNext
        if applied.leveledUp { gameState.level = applied.level }
        gameState.stats.focus += 1
        gameState.stats.mind += 1
    }
}
```

The handler bypasses the `gameState.apply()` pattern used by all other engines (ChallengeEngine, WorkoutEngine, ReadingEngine, ProgressionEngine). It also uses `gameState.xp` (which is `xpIntoLevel`, not `xp_total`) as the base for `XPSystem.applyXP`, which expects total XP — producing incorrect level calculations.

### Impact

- **Severity:** Silent data loss — users lose focus XP on next sync
- **Scope:** Every focus session completion (core feature)
- **User perception:** "I completed a focus session but my XP didn't stick"

### Solution Design

#### 1. Route through Profile mutation + persist

```swift
struct FocusCompletionHandler {
    static func complete(
        xp: Int,
        gameState: GameState,
        userService: UserService
    ) async {
        // Use profile.xp_total as the source of truth
        var profile = gameState.profile
        let applied = XPSystem.applyXP(totalXP: profile.xp_total, gainedXP: xp)
        
        // Mutate the profile
        profile.xp_total = applied.totalXP
        profile.level = applied.level
        profile.focus += 1
        profile.mind += 1
        
        // Apply through the canonical path
        gameState.apply(
            profile: profile,
            levelState: applied,
            titles: gameState.titles,
            quests: gameState.quests,
            dailyGoal: gameState.dailyGoal,
            dailyCompleted: gameState.dailyCompleted,
            completedHabitIDs: gameState.completedHabitIDs,
            dailyLog: gameState.dailyLog
        )
        
        // Persist to Supabase
        try? await userService.updateProfile(profile)
    }
}
```

#### 2. Update call sites

The `FocusTimerView` (or its ViewModel) must pass `UserService` to the handler. Match the pattern used in `WorkoutEngine` and `ReadingEngine`.

#### 3. XP base correction

The current code passes `gameState.xp` (which is `xpIntoLevel`) to `XPSystem.applyXP(totalXP:gainedXP:)`. The fix uses `profile.xp_total` which is the actual cumulative XP — the correct input for the XP system.

### Acceptance Criteria

- [ ] Focus XP persists across app restart
- [ ] `gameState.profile.xp_total` reflects focus XP immediately after completion
- [ ] Subsequent `gameState.apply()` calls do not overwrite focus XP
- [ ] Stats (focus +1, mind +1) are reflected in Profile and persisted
- [ ] Level-up from focus session triggers the same celebration as other XP sources
- [ ] Unit test: complete focus → verify `profile.xp_total` increased by expected amount

### Dependencies

- None (independent fix)


---

## C3. SubscriptionService Empty Stub

### Problem Statement

`getSubscriptionState()` is a no-op stub that references its dependencies but performs no work. The app has a full `SubscriptionManagementView` UI that calls this method — users see a subscription screen that cannot actually determine or display their subscription status.

### Root Cause

**File:** `Services/SubscriptionService.swift:32`

```swift
func getSubscriptionState() async {
    _ = supabase
    _ = productIDs
}
```

The method was stubbed during initial development. While `validateEntitlement()` and `syncSubscription()` have implementations, nothing ties them together into a cohesive state that the UI can observe.

### Impact

- **Severity:** Core monetization feature non-functional
- **Scope:** Subscription state display, feature gating, trial management
- **Revenue:** Cannot enforce premium features without knowing subscription state

### Solution Design

#### 1. Add observable subscription state

```swift
enum SubscriptionTier: String, Codable {
    case free
    case trial
    case premium
}

@MainActor
final class SubscriptionState: ObservableObject {
    @Published var tier: SubscriptionTier = .free
    @Published var activeProduct: Product?
    @Published var entitlement: SubscriptionEntitlement?
    @Published var availableProducts: [Product] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
}
```

#### 2. Implement `getSubscriptionState()` fully

```swift
func getSubscriptionState() async -> SubscriptionState {
    let state = SubscriptionState()
    await MainActor.run { state.isLoading = true }
    
    do {
        // 1. Load available products from App Store
        let products = try await Product.products(for: productIDs)
        await MainActor.run { state.availableProducts = products }
        
        // 2. Check current entitlements
        let entitlement = await validateEntitlement()
        await MainActor.run { state.entitlement = entitlement }
        
        // 3. Determine tier
        if let entitlement {
            let product = products.first { $0.id == entitlement.productID }
            await MainActor.run {
                state.activeProduct = product
                state.tier = .premium
            }
        } else {
            // Check trial status from Supabase
            let hasTrial = await checkTrialStatus()
            await MainActor.run {
                state.tier = hasTrial ? .trial : .free
            }
        }
        
        // 4. Sync to backend
        try? await syncSubscription()
        
    } catch {
        await MainActor.run { state.error = error }
    }
    
    await MainActor.run { state.isLoading = false }
    return state
}
```

#### 3. Add Transaction listener for real-time updates

```swift
func listenForTransactions() -> Task<Void, Never> {
    Task.detached {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            await transaction.finish()
            try? await self.syncSubscription()
            // Notify UI via SubscriptionState update
        }
    }
}
```

#### 4. Add trial status check

```swift
private func checkTrialStatus() async -> Bool {
    guard let userId = await authProvider.currentUserID else { return false }
    
    do {
        let client = try supabase.requireClient()
        struct SubscriptionRow: Decodable { let status: String; let plan_type: String }
        let rows: [SubscriptionRow] = try await client
            .from("subscriptions")
            .select("status, plan_type")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        return rows.contains { $0.status == "active" }
    } catch {
        return false
    }
}
```

#### 5. Wire into FeatureGate

Ensure `FeatureGate` reads from `SubscriptionState.tier` to gate premium features.

### Acceptance Criteria

- [ ] `getSubscriptionState()` returns a populated `SubscriptionState` object
- [ ] `SubscriptionManagementView` displays correct current tier (free/trial/premium)
- [ ] Available products load from App Store Connect (requires configured product IDs)
- [ ] Transaction.updates listener auto-syncs state changes
- [ ] Renewal info displays expiration date when available
- [ ] Feature gate correctly restricts premium features for free users
- [ ] Offline: gracefully falls back to last-known state
- [ ] Unit test: mock `Transaction.currentEntitlements` → verify tier resolution

### Dependencies

- C1 (SupabaseService must not crash — uses `requireClient()`)
- App Store Connect product configuration (product IDs in `productIDs` set)


---

## C4. Watch Complication Shows 0/0

### Problem Statement

The Watch complication always displays streak = 0 and progress = 0.0. The `WatchComplicationProvider` returns hardcoded placeholder values in all three methods (`placeholder`, `getSnapshot`, `getTimeline`) and never reads actual user data.

### Root Cause

**File:** `RNFWatch/RNFWatchComplication.swift`

```swift
struct WatchComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchComplicationEntry {
        WatchComplicationEntry(date: Date(), streak: 0, progress: 0)
    }
    func getSnapshot(in context: Context, completion: @escaping (WatchComplicationEntry) -> Void) {
        completion(WatchComplicationEntry(date: Date(), streak: 0, progress: 0))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchComplicationEntry>) -> Void) {
        let entry = WatchComplicationEntry(date: Date(), streak: 0, progress: 0)
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800))))
    }
}
```

There is no mechanism to read from `WatchAppState.snapshot` or any persisted data store.

### Impact

- **Severity:** Core Watch feature non-functional — complication is the primary Watch surface
- **Scope:** All users who add the RNF complication to their watch face
- **User perception:** App appears broken/empty on Watch face

### Solution Design

#### 1. Persist snapshot data to UserDefaults (App Group)

Since WidgetKit complications cannot access `@StateObject` directly, data must be shared via an App Group `UserDefaults`:

```swift
// Shared constants
enum WatchStorage {
    static let suiteName = "group.com.rnf.watch"
    static let streakKey = "complication_streak"
    static let progressKey = "complication_progress"
    static let lastUpdateKey = "complication_last_update"
    
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
}
```

#### 2. Update WatchAppState to persist on receive

```swift
@MainActor
final class WatchAppState: ObservableObject {
    @Published var snapshot: WatchDailySnapshot = /* ... */

    func update(from data: Data) {
        guard let decoded = try? JSONDecoder().decode(WatchDailySnapshot.self, from: data) else { return }
        snapshot = decoded
        persistForComplication()
    }
    
    private func persistForComplication() {
        let progress = snapshot.dailyGoal > 0
            ? Double(snapshot.dailyCompleted) / Double(snapshot.dailyGoal)
            : 0
        
        WatchStorage.defaults?.set(snapshot.streak, forKey: WatchStorage.streakKey)
        WatchStorage.defaults?.set(progress, forKey: WatchStorage.progressKey)
        WatchStorage.defaults?.set(Date().timeIntervalSince1970, forKey: WatchStorage.lastUpdateKey)
        
        // Trigger complication refresh
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```

#### 3. Update WatchComplicationProvider to read persisted data

```swift
struct WatchComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchComplicationEntry {
        WatchComplicationEntry(date: Date(), streak: 7, progress: 0.5) // Meaningful placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WatchComplicationEntry) -> Void) {
        completion(currentEntry())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchComplicationEntry>) -> Void) {
        let entry = currentEntry()
        // Refresh every 30 minutes or when data changes
        let nextUpdate = Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    
    private func currentEntry() -> WatchComplicationEntry {
        let defaults = WatchStorage.defaults
        let streak = defaults?.integer(forKey: WatchStorage.streakKey) ?? 0
        let progress = defaults?.double(forKey: WatchStorage.progressKey) ?? 0
        return WatchComplicationEntry(date: Date(), streak: streak, progress: progress)
    }
}
```

#### 4. App Group configuration

- Add App Group `group.com.rnf.watch` to both the Watch app target and the Watch complication/widget extension target in Signing & Capabilities.

### Acceptance Criteria

- [ ] Complication displays actual streak count after first phone sync
- [ ] Complication displays actual daily progress (dailyCompleted / dailyGoal)
- [ ] Data persists across Watch app termination
- [ ] Complication refreshes within 30 minutes of phone sync
- [ ] Placeholder shows meaningful sample data (not 0/0) in complication gallery
- [ ] Falls back to last-known data if no sync has occurred today

### Dependencies

- C5 (Watch must actually receive messages from phone for data to flow)
- App Group entitlement configured for Watch targets


---

## C5. Watch Missing Incoming Message Handler

### Problem Statement

The Watch app has no `WCSessionDelegate` to receive messages from the iPhone. The phone-side `WatchSyncService` calls `sendSnapshot()` which uses `session.sendMessageData()`, but the Watch side never registers a delegate to receive this data. Messages are silently dropped.

### Root Cause

**File:** `RNFWatch/RNFWatchApp.swift`

The `WatchAppState` has an `update(from:)` method but nothing calls it. The Watch app does not activate a `WCSession` or implement `WCSessionDelegate`. The phone side (`WatchSyncService`) is fully implemented as both sender and receiver (for habit completions from Watch → Phone), but the reverse channel (Phone → Watch) has no listener.

### Impact

- **Severity:** Watch app never receives updated data from phone
- **Scope:** All Watch features — habit list shows stale data, complication shows 0/0
- **Cascading:** Blocks C4 fix from being effective

### Solution Design

#### 1. Create WatchConnectivityManager for Watch side

```swift
import WatchConnectivity

final class WatchConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    
    static let shared = WatchConnectivityManager()
    
    private var session: WCSession?
    weak var watchState: WatchAppState?
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - WCSessionDelegate (required)
    
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if activationState == .activated {
            // Request fresh data from phone if reachable
            requestSnapshotFromPhone()
        }
    }
    
    // MARK: - Receive snapshot from phone
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        Task { @MainActor in
            watchState?.update(from: messageData)
        }
    }
    
    // Also handle application context for background updates
    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        guard let data = applicationContext["snapshot"] as? Data else { return }
        Task { @MainActor in
            watchState?.update(from: data)
        }
    }
    
    // MARK: - Outgoing (habit completions from Watch → Phone)
    
    func sendHabitCompletion(_ message: WatchHabitCompletionMessage) {
        guard let session, session.isReachable else { return }
        guard let data = try? JSONEncoder().encode(message) else { return }
        session.sendMessageData(data, replyHandler: nil, errorHandler: nil)
    }
    
    func sendWorkoutAction(_ message: WatchWorkoutMessage) {
        guard let session, session.isReachable else { return }
        guard let data = try? JSONEncoder().encode(message) else { return }
        session.sendMessageData(data, replyHandler: nil, errorHandler: nil)
    }
    
    // MARK: - Request fresh snapshot
    
    private func requestSnapshotFromPhone() {
        guard let session, session.isReachable else { return }
        // Send an empty message as a "ping" — phone responds with snapshot
        session.sendMessage(["request": "snapshot"], replyHandler: nil, errorHandler: nil)
    }
}
```

#### 2. Wire into RNFWatchApp

```swift
@main
struct RNFWatchApp: App {
    @StateObject private var watchState = WatchAppState()
    @StateObject private var connectivity = WatchConnectivityManager.shared
    
    var body: some Scene {
        WindowGroup {
            WatchHabitListView(state: watchState)
                .onAppear {
                    connectivity.watchState = watchState
                }
        }
    }
}
```

#### 3. Update phone-side WatchSyncService to also use applicationContext

For reliability when Watch is not reachable (background transfers):

```swift
// In WatchSyncService.sendSnapshot(_:)
func sendSnapshot(_ snapshot: WatchDailySnapshot) {
    guard let session else { return }
    guard let data = try? JSONEncoder().encode(snapshot) else { return }
    
    if session.isReachable {
        session.sendMessageData(data, replyHandler: nil, errorHandler: nil)
    }
    
    // Always update application context for background delivery
    try? session.updateApplicationContext(["snapshot": data])
}
```

#### 4. Handle "ping" requests from Watch

Add to phone-side `WatchSyncService`:

```swift
func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    if message["request"] as? String == "snapshot" {
        // Regenerate and send current snapshot
        Task { @MainActor in
            // Access gameState to generate fresh snapshot
            guard let gameState = self.gameStateRef else { return }
            let snapshot = WatchSnapshotGenerator.generate(from: gameState)
            self.sendSnapshot(snapshot)
        }
    }
}
```

### Acceptance Criteria

- [ ] Watch app activates `WCSession` on launch
- [ ] `didReceiveMessageData` calls `WatchAppState.update(from:)`
- [ ] `didReceiveApplicationContext` handles background snapshot delivery
- [ ] Watch requests fresh snapshot on activation (handles app-was-killed scenarios)
- [ ] Phone responds to "ping" with current snapshot
- [ ] Habit list on Watch updates within seconds of phone sync
- [ ] Works when Watch wakes from background (applicationContext path)
- [ ] Unit test: encode snapshot → deliver to delegate → verify WatchAppState updated

### Dependencies

- None (independent, but must ship before C4 to make complication useful)


---

## C6. Account Deletion (App Store Requirement)

### Problem Statement

The app has no account deletion functionality. Apple requires all apps that offer account creation to also offer account deletion (App Store Review Guideline 5.1.1(v), enforced since June 30, 2022). Submission will be rejected without this.

### Root Cause

No implementation exists anywhere in the codebase. `ProfileView` has no deletion option, `AuthService` has no delete method, and there is no backend cascade logic.

### Impact

- **Severity:** App Store rejection — hard policy requirement
- **Scope:** Entire user lifecycle
- **Legal:** GDPR/privacy compliance also requires data deletion capability

### Solution Design

#### 1. UI Flow — Profile → Delete Account

Add to `ProfileView`:

```swift
Section("Danger Zone") {
    Button(role: .destructive) {
        showDeleteConfirmation = true
    } label: {
        Label("Delete Account", systemImage: "trash")
            .foregroundColor(.red)
    }
}
.confirmationDialog(
    "Delete Account",
    isPresented: $showDeleteConfirmation,
    titleVisibility: .visible
) {
    Button("Delete in 7 days", role: .destructive) {
        Task { await initiateAccountDeletion() }
    }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("Your account and all data will be permanently deleted after a 7-day grace period. You can cancel during this time by logging back in.")
}
```

#### 2. Grace Period Model

```swift
// Services/AccountDeletionService.swift
final class AccountDeletionService {
    private let supabase: SupabaseService
    private let authProvider: AuthProviding
    
    struct DeletionRequest: Codable {
        let user_id: UUID
        let requested_at: Date
        let scheduled_deletion_at: Date
        let status: String // "pending", "cancelled", "completed"
    }
    
    func initiateDeletion() async throws {
        let userId = try await authProvider.requireCurrentUserID()
        let client = try supabase.requireClient()
        
        let request = DeletionRequest(
            user_id: userId,
            requested_at: Date(),
            scheduled_deletion_at: Date().addingTimeInterval(7 * 24 * 60 * 60),
            status: "pending"
        )
        
        try await client
            .from("deletion_requests")
            .upsert(request)
            .execute()
        
        // Sign out immediately
        try await client.auth.signOut()
    }
    
    func cancelDeletion() async throws {
        let userId = try await authProvider.requireCurrentUserID()
        let client = try supabase.requireClient()
        
        try await client
            .from("deletion_requests")
            .update(["status": "cancelled"])
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: "pending")
            .execute()
    }
}
```

#### 3. Database: New table `deletion_requests`

```sql
CREATE TABLE deletion_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    scheduled_deletion_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'cancelled', 'completed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id)
);

-- RLS: users can only see/modify their own
ALTER TABLE deletion_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own deletion" ON deletion_requests
    USING (auth.uid() = user_id);
```

#### 4. Supabase Edge Function: Cascade Delete

Create `supabase/functions/delete-user/index.ts`:

```typescript
import { createClient } from '@supabase/supabase-js'

// Runs on a cron schedule (daily) or triggered manually
Deno.serve(async () => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )
  
  // Find expired pending deletions
  const { data: pendingDeletions } = await supabase
    .from('deletion_requests')
    .select('user_id')
    .eq('status', 'pending')
    .lte('scheduled_deletion_at', new Date().toISOString())
  
  for (const request of pendingDeletions ?? []) {
    const userId = request.user_id
    
    // Cascade delete all user data (order matters for FK constraints)
    const tables = [
      'analytics_events',
      'health_imports',
      'user_skills',
      'user_achievements',
      'mastery_paths',
      'guild_members',
      'habit_completions',
      'reading_uploads',
      'workouts',
      'daily_logs',
      'challenges',
      'subscriptions',
      'deletion_requests',
      'users'
    ]
    
    for (const table of tables) {
      await supabase.from(table).delete().eq('user_id', userId)
    }
    
    // Delete storage objects (reading proofs)
    const { data: files } = await supabase.storage
      .from('reading-proof')
      .list(userId)
    
    if (files?.length) {
      const paths = files.map(f => `${userId}/${f.name}`)
      await supabase.storage.from('reading-proof').remove(paths)
    }
    
    // Delete auth user last
    await supabase.auth.admin.deleteUser(userId)
    
    // Mark deletion as completed
    await supabase
      .from('deletion_requests')
      .update({ status: 'completed' })
      .eq('user_id', userId)
  }
  
  return new Response(JSON.stringify({ processed: pendingDeletions?.length ?? 0 }))
})
```

#### 5. Cron trigger

Configure Supabase pg_cron or external scheduler to invoke the edge function daily:

```sql
SELECT cron.schedule(
    'process-account-deletions',
    '0 3 * * *',  -- 3 AM daily
    $$SELECT net.http_post(
        url := 'https://<project>.supabase.co/functions/v1/delete-user',
        headers := '{"Authorization": "Bearer <service_role_key>"}'::jsonb
    )$$
);
```

#### 6. Login re-activation

In `AuthService.login()`, after successful login, check for pending deletion and cancel:

```swift
func login(email: String, password: String) async throws -> Session {
    let session = try await supabase.client.auth.signIn(email: email, password: password)
    // Cancel any pending deletion (user logged back in during grace period)
    try? await AccountDeletionService(supabase: supabase, authProvider: self)
        .cancelDeletion()
    return session
}
```

### Acceptance Criteria

- [ ] "Delete Account" button visible in Profile settings
- [ ] Confirmation dialog explains 7-day grace period
- [ ] After confirmation: deletion request created, user signed out
- [ ] Logging back in within 7 days cancels the deletion
- [ ] After 7 days: all user data deleted from all tables (14 tables listed)
- [ ] Storage objects (reading-proof bucket) cleaned up
- [ ] Auth user deleted from Supabase Auth
- [ ] Edge function handles FK constraint ordering correctly
- [ ] RLS prevents users from seeing other users' deletion requests
- [ ] Unit test: initiate → cancel flow
- [ ] Integration test: initiate → wait → verify cascade

### Dependencies

- C1 (SupabaseService graceful init)
- C7 (Must also handle Apple credential revocation on deletion)
- New `deletion_requests` table migration
- Supabase Edge Function deployment
- pg_cron or equivalent scheduler


---

## C7. Sign in with Apple

### Problem Statement

The app only supports email/password authentication. Sign in with Apple is required by App Store Review Guideline 4.8 for apps that offer third-party social login — and even without other social logins, it's a major source of signup friction for iOS users. Most competitors offer it as the primary auth method.

### Root Cause

`AuthService` only implements `signUp(email:password:)` and `login(email:password:)`. No Apple OAuth flow exists. `LoginView` and `SignUpView` only show email/password fields.

### Impact

- **Severity:** Policy risk + high signup friction
- **Scope:** All new users at onboarding
- **Conversion:** Industry data shows 20-40% higher signup rates with Sign in with Apple vs email/password alone

### Solution Design

#### 1. Add Sign in with Apple capability

- Enable "Sign in with Apple" in Signing & Capabilities for the main target
- Register the App ID with Apple Developer portal if not already done

#### 2. Create AppleAuthService

```swift
import AuthenticationServices
import Supabase

final class AppleAuthService: NSObject {
    
    private let supabase: SupabaseService
    private var continuation: CheckedContinuation<Session, Error>?
    
    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }
    
    func signInWithApple() async throws -> Session {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.email, .fullName]
            
            // Generate nonce for Supabase PKCE flow
            let nonce = generateNonce()
            request.nonce = sha256(nonce)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
            
            // Store raw nonce for Supabase verification
            UserDefaults.standard.set(nonce, forKey: "apple_auth_nonce")
        }
    }
    
    private func generateNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                guard status == errSecSuccess else { return 0 }
                return random
            }
            for random in randoms {
                if remainingLength == 0 { break }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        import CryptoKit
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

extension AppleAuthService: ASAuthorizationControllerDelegate {
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            continuation?.resume(throwing: AuthError.invalidCredential)
            return
        }
        
        let nonce = UserDefaults.standard.string(forKey: "apple_auth_nonce") ?? ""
        
        Task {
            do {
                let client = try supabase.requireClient()
                let session = try await client.auth.signInWithIdToken(
                    credentials: .init(
                        provider: .apple,
                        idToken: tokenString,
                        nonce: nonce
                    )
                )
                
                // Bootstrap profile if first sign-in
                await bootstrapIfNeeded(
                    userId: session.user.id,
                    email: credential.email ?? session.user.email,
                    fullName: credential.fullName
                )
                
                continuation?.resume(returning: session)
            } catch {
                continuation?.resume(throwing: error)
            }
        }
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        continuation?.resume(throwing: error)
    }
    
    private func bootstrapIfNeeded(userId: UUID, email: String?, fullName: PersonNameComponents?) async {
        let client = try? supabase.requireClient()
        
        // Check if profile exists
        let existing: [Profile]? = try? await client?
            .from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .execute()
            .value
        
        guard existing?.isEmpty ?? true else { return }
        
        // Create new profile
        let profile = Profile(
            id: userId,
            email: email,
            xp_total: 0,
            level: 1,
            streak: 0,
            forgiveness_tokens: 0,
            morning_notification_time: nil,
            evening_notification_time: nil,
            strength: Stats.baseline.strength,
            discipline: Stats.baseline.discipline,
            focus: Stats.baseline.focus,
            energy: Stats.baseline.energy,
            wisdom: Stats.baseline.wisdom,
            mind: Stats.baseline.mind,
            spirit: Stats.baseline.spirit,
            created_at: nil
        )
        
        try? await client?
            .from("users")
            .upsert(profile)
            .execute()
    }
}

enum AuthError: Error {
    case invalidCredential
    case appleSignInCancelled
}
```

#### 3. Configure Supabase Apple OAuth

In Supabase Dashboard → Authentication → Providers → Apple:
- Enable Apple provider
- Add Service ID, Team ID, Key ID, and private key from Apple Developer
- Configure redirect URL

#### 4. Update LoginView and SignUpView

Add Apple button above email fields:

```swift
// In LoginView / SignUpView
SignInWithAppleButton(.signIn, onRequest: { request in
    request.requestedScopes = [.email, .fullName]
}, onCompletion: { result in
    // Handled by AppleAuthService
})
.signInWithAppleButtonStyle(.white)
.frame(height: 50)
.cornerRadius(Radius.medium)

// Or use custom button that triggers:
Button {
    Task {
        do {
            let session = try await appleAuth.signInWithApple()
            // Navigate to main app
        } catch {
            // Handle error (user cancelled, etc.)
        }
    }
} label: {
    HStack {
        Image(systemName: "apple.logo")
        Text("Sign in with Apple")
    }
}
```

#### 5. Credential Revocation Handler

Apple can revoke credentials (user disables app in Settings → Apple ID). Handle this:

```swift
// In RNFApp.swift or AppStateManager
func setupAppleCredentialRevocationListener() {
    NotificationCenter.default.addObserver(
        forName: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
        object: nil,
        queue: .main
    ) { _ in
        Task {
            // Force sign out
            try? await AuthService().logout()
            // Reset app state to signed-out
            AppStateManager.shared.transition(to: .signedOut)
        }
    }
}

// Also check credential state on app launch
func verifyAppleCredential() async {
    guard let userId = UserDefaults.standard.string(forKey: "apple_user_id") else { return }
    
    let provider = ASAuthorizationAppleIDProvider()
    let state = try? await provider.credentialState(forUserID: userId)
    
    if state == .revoked || state == .notFound {
        try? await AuthService().logout()
        AppStateManager.shared.transition(to: .signedOut)
    }
}
```

#### 6. Email Relay Handling

Apple's private email relay (e.g., `xyz@privaterelay.appleid.com`):
- Store the relay email as the user's email — it forwards to their real address
- Do NOT require email verification for Apple sign-in users (Apple already verified)
- Outbound emails (notifications, weekly reports) work normally through the relay

#### 7. Migration Path for Existing Email Users

If a user has an existing email/password account and later signs in with Apple using the same email:
- Supabase will link the identities automatically if emails match
- For mismatched emails: provide "Link Account" flow in Profile settings

```swift
func linkAppleIdentity() async throws {
    let client = try supabase.requireClient()
    // Supabase handles identity linking
    try await client.auth.linkIdentity(provider: .apple)
}
```

### Acceptance Criteria

- [ ] "Sign in with Apple" button visible on Login and SignUp screens
- [ ] Tapping initiates ASAuthorizationController flow
- [ ] Successful Apple auth creates Supabase session
- [ ] New Apple users get bootstrapped Profile (same as email signup)
- [ ] Existing users with matching email see their existing data
- [ ] Credential revocation signs user out immediately
- [ ] Private relay emails work for all outbound communication
- [ ] Profile shows "Linked with Apple" indicator when applicable
- [ ] "Link Apple Account" option available for existing email users in Profile
- [ ] Unit test: mock Apple credential → verify Supabase signInWithIdToken called
- [ ] UI test: Apple button visible and tappable on auth screens

### Dependencies

- C1 (SupabaseService graceful init — uses `requireClient()`)
- Apple Developer portal: App ID + Sign in with Apple capability
- Supabase Dashboard: Apple provider configuration
- `CryptoKit` framework (already available in iOS 13+)

---

## Appendix: Shared Migration Checklist

Before deploying these fixes:

1. **Database migrations** (run in order):
   - `deletion_requests` table (C6)
   - RLS policies on `deletion_requests`

2. **Supabase configuration**:
   - Enable Apple OAuth provider (C7)
   - Deploy `delete-user` edge function (C6)
   - Configure pg_cron for deletion scheduler (C6)

3. **Xcode project**:
   - Add "Sign in with Apple" capability (C7)
   - Add App Group `group.com.rnf.watch` to Watch targets (C4)
   - Add build-phase validation script (C1)
   - Configure product IDs for StoreKit (C3)

4. **App Store Connect**:
   - Configure in-app purchase products (C3)
   - Prepare deletion disclosure for App Review (C6)
