# RNF Comprehensive Code Audit Report

**Date:** 2026-07-03  
**Scope:** Full codebase — architecture, source code, UX, infrastructure, tests, database  
**Project State:** 374/377 tasks complete (99.2%)

---

## Executive Summary

RNF is a well-architected SwiftUI gamification app with solid foundations: clean MVVM, proper dependency injection, comprehensive game systems, and good test coverage. However, several **production-blocking issues** exist that must be fixed before any public release, alongside UX gaps that would significantly harm user retention.

**Critical count:** 5 production blockers | 18 high-priority issues | 26 medium issues | 15 low-priority polish items

---

## 🔴 CRITICAL — Production Blockers (Fix Immediately)

### C1. Guaranteed Production Crash in SupabaseService
**Files:** `Core/AppConfig.swift:17`, `Services/SupabaseService.swift:10`  
**Problem:** In RELEASE builds, if `SUPABASE_URL` or `SUPABASE_ANON_KEY` are missing from Info.plist, `AppConfig` returns empty string `""`. Then `URL(string: "")` returns `nil`, triggering `fatalError()` in `SupabaseService.init()`. This is a guaranteed crash on first launch.  
**Fix:** Replace `fatalError` with a graceful degradation path — present an error state to the user or fail the auth flow. Add a build-phase script that validates presence of keys.

### C2. FocusCompletionHandler Bypasses State Pattern — Causes XP Data Loss
**File:** `Core/FocusCompletionHandler.swift:4-9`  
**Problem:** Directly mutates `gameState.xp`, `gameState.level`, etc. without updating the backing `Profile` object. Any subsequent profile save will persist **stale** XP data, permanently losing focus session XP.  
**Fix:** Route through `gameState.apply(updatedProfile:)` like all other engines, or update the Profile object in sync.

### C3. SubscriptionService is an Empty Stub
**File:** `Services/SubscriptionService.swift:32`  
**Problem:** `getSubscriptionState()` does nothing — `{ _ = supabase; _ = productIDs }`. Subscription features (Perk System gating, skill tree access) will always report "not subscribed," blocking premium feature access.  
**Fix:** Implement full StoreKit 2 integration or remove subscription gates from the feature flags.

### C4. Watch Complication Shows Hardcoded 0/0
**File:** `RNFWatch/RNFWatchComplication.swift`  
**Problem:** `WatchComplicationProvider` returns hardcoded placeholder values in timeline entries. Users see "0/0" on their watch face permanently.  
**Fix:** Read actual data from `WatchAppState` or the companion app's last-synced snapshot.

### C5. No Watch Incoming Message Handler
**File:** `RNFWatch/` (missing)  
**Problem:** The Watch app sends messages to the phone but has no `WCSessionDelegate` to receive snapshot updates FROM the phone. The Watch can never get fresh data after initial launch.  
**Fix:** Add `WCSessionDelegate` implementation on the Watch side that calls `WatchAppState.update(from:)`.

---

## 🟠 HIGH PRIORITY — Fix Before Private Alpha

### H1. No Navigation Paths to Many Screens
**Impact:** Users can never reach `ProfileView`, `SkillTreeView`, `EvolutionView`, `DiscoveryLogView`, `ArcArchiveView`, `SocialTabView`, `AchievementsGalleryView`, `FocusTimerView`, or `JourneyMapView`  
**File:** `Navigation/RootView.swift`, `Components/RNFTabBar.swift`  
**Fix:** Add a 5th tab (Profile/Menu) or a navigation menu that surfaces these screens.

### H2. Dynamic Type Not Supported
**File:** `DesignSystem/Typography.swift`  
**Impact:** Accessibility failure — users with visual impairments cannot scale text. App Store rejection risk.  
**Fix:** Replace `Font.system(size:)` with `@ScaledMetric` or `.relativeTo:` text styles for all RNFFont tokens.

### H3. Data Race in WatchSyncService
**File:** `Services/WatchSyncService.swift:27`  
**Problem:** `WCSession` callbacks arrive on arbitrary threads. Closure properties (`onHabitCompletion`, `onWorkoutAction`) are accessed without isolation.  
**Fix:** Mark closures as `@Sendable` or gate access behind `@MainActor`.

### H4. CI Builds Likely Fail — No Secret Injection
**File:** `.github/workflows/ios-build.yml`  
**Problem:** No mechanism to generate `Secrets.xcconfig` in CI. Builds will fail on Supabase initialization.  
**Fix:** Add CI step to generate xcconfig from GitHub Secrets.

### H5. Offline Support Only Covers Habit Completions
**Files:** `Services/OfflineWriteQueue.swift`, `Services/SyncFlushService.swift`  
**Impact:** Workouts, reading uploads, boss damage, daily log updates — all lost if network drops mid-action.  
**Fix:** Extend `OfflineWriteQueue` to support generic write operations, or queue at the service layer.

### H6. No LoginView → SignUpView Navigation
**File:** `Features/Onboarding/LoginView.swift`  
**Impact:** New users arriving at the login screen have no way to create an account.  
**Fix:** Add "Create Account" button/link routing to `SignUpView`.

### H7. Widget Never Refreshed by App
**Impact:** Widget shows stale data for up to 30 minutes after habit completions.  
**Fix:** Call `WidgetCenter.shared.reloadAllTimelines()` after any state-changing action in `ProgressionEngine`.

### H8. No Release/Deployment Pipeline
**Impact:** No path from code → TestFlight → App Store. Manual process only.  
**Fix:** Add `ios-deploy.yml` workflow with Fastlane for signing, archiving, and uploading.

### H9. Load Error Not Displayed to Users
**File:** `Features/Habits/ContentView.swift`  
**Problem:** `viewModel.loadErrorMessage` is set on failure but never shown in UI. `ErrorBanner` only watches `persistenceError`.  
**Fix:** Display `loadErrorMessage` in the view body (e.g., as a full-screen error state with retry).

### H10. SyncFlushService Silently Discards Failures
**File:** `Services/SyncFlushService.swift:24`  
**Problem:** `_ = try? await dailyLogService.recordHabitCompletion(completion)` — if flush fails, data is lost permanently.  
**Fix:** Implement retry with exponential backoff, or re-queue failed items.

### H11. WorkoutSession Model ↔ DB Schema Mismatch
**Impact:** Swift `WorkoutSession` model has fields not present in the `workouts` DB table (and vice versa). Service layer must do translation or writes will fail.  
**Fix:** Align model fields with DB columns, or add explicit DTO mapping in `WorkoutService`.

### H12. Custom Habits Only in UserDefaults — Not Synced
**File:** `Core/HabitAgencyService.swift`  
**Impact:** Custom habits lost on reinstall/new device. Watch and Widget can't see them.  
**Fix:** Add a `custom_habits` table or store in user profile JSON column.

### H13. Discoveries Not Persisted Server-Side
**File:** `Systems/PassiveDiscoverySystem.swift`, `Core/DiscoveryService.swift`  
**Impact:** All earned discoveries lost on reinstall. Years of progress vanished.  
**Fix:** Add `discoveries` table or store in user profile.

### H14. No Pull-to-Refresh
**Impact:** Users expect pull-to-refresh in scrollable views. Without it, stale data persists until app restart.  
**Fix:** Add `.refreshable {}` to `ContentView`, `AscensionView`, `WorkoutListView`, `ReadView`.

### H15. PageTabView Gesture Conflicts
**File:** `Navigation/RootView.swift`  
**Problem:** `.tabViewStyle(.page)` makes tabs swipeable, conflicting with NavigationStack back gestures inside tabs.  
**Fix:** Use `.tabViewStyle(.automatic)` or disable swipe via `UIScrollView.appearance().isScrollEnabled = false` on the TabView's internal scroll.

### H16. No Deep Linking Support
**Impact:** Notification taps, widget taps, and URL schemes can't route to specific screens.  
**Fix:** Implement `onOpenURL` handler and `WidgetURL` for widget deep links.

### H17. WeeklyReportService Shows Fake Data
**File:** `Core/WeeklyReportService.swift:24`  
**Problem:** Uses `min(streak, 7) * 4` and `min(streak, 7) * 80` — hardcoded approximations, not actual completion data.  
**Fix:** Query real completion history from DailyLogService.

### H18. Pillar Streaks Not Synced
**File:** `Services/PillarStreakService.swift`  
**Impact:** Independent per-pillar streaks stored only in UserDefaults — lost on reinstall.  
**Fix:** Either sync to Supabase or derive from server-side daily log data.

---

## 🟡 MEDIUM PRIORITY — Fix Before Public Beta

### M1. Service Objects Instantiated in View Structs
**Files:** `AscensionView`, `ContentView`, `MissedDayView`, `ReadView`, `DiscoveryLogView`  
**Problem:** Engine/service instances created as view stored properties — recreated on every SwiftUI redraw.  
**Fix:** Move to `@StateObject` ViewModels or `@Environment`.

### M2. Task Leak in AmbientParticleView
**Problem:** Infinite `Task` loop with no cancellation handle. New tasks spawn on view reappear without old ones dying.  
**Fix:** Store Task handle in `@State` and cancel in `.onDisappear`.

### M3. Hardcoded Colors Bypass Design System
**Files:** `HabitRow.swift`, `DailyMissionBar.swift`, `FocusTimerView.swift`, `ActiveWorkoutTimerView.swift`  
**Fix:** Replace with `RNFColors` tokens or Asset Catalog colors that adapt to dark/light mode.

### M4. Timer Displays Missing VoiceOver Labels
**Files:** `FocusTimerView.swift`, `ActiveWorkoutTimerView.swift`  
**Fix:** Add `.accessibilityLabel("X minutes Y seconds remaining")` with live value updates.

### M5. ProgressionEngine Inconsistency
**Problem:** Returns `ProgressionResult` for caller to apply, unlike `ReadingEngine`/`WorkoutEngine` which call `gameState.apply()` directly.  
**Fix:** Standardize — either all engines call `apply()` or none do.

### M6. `social_challenges` Has No UPDATE RLS Policy
**Impact:** Once created, social challenge progress can't be updated by participants — only service_role.  
**Fix:** Add UPDATE policy scoped to challenge participants.

### M7. No Empty States in Social/Achievement Views
**Impact:** Blank screens with no explanation when data hasn't loaded or doesn't exist.  
**Fix:** Add empty state illustrations with context text.

### M8. DiscoveryLogView Loads Data at View Init
**Problem:** `DiscoveryService.loadHistory()` runs during struct initialization — executes on every view reconstruction.  
**Fix:** Move to `.task {}` modifier with `@State` storage.

### M9. `Array: VectorArithmetic` Global Retroactive Conformance
**File:** `Components/DisciplineRadarChart.swift`  
**Problem:** Global conformance on `[Double]` risks collision with other libraries.  
**Fix:** Use a dedicated `AnimatableVector` wrapper type.

### M10. `analytics_events` INSERT Too Permissive
**Problem:** `WITH CHECK (true)` allows any authenticated user to insert arbitrary analytics events with no user scoping.  
**Fix:** Add `user_id` column and scope INSERT policy.

### M11. Stats Baseline Mismatch
**Problem:** DB defaults stats to 0, Swift `Stats.baseline` is 2. New users see different values until first save.  
**Fix:** Align DB defaults with Swift defaults, or apply baseline transform on profile fetch.

### M12. Bundle ID Inconsistency
**Problem:** App is `com.regosenne.rnf`, tests are `com.riseandforge.RNFTests`.  
**Fix:** Unify to one organization prefix.

### M13. No SPM Package Monitoring
**Problem:** Dependabot only monitors GitHub Actions, not Swift packages.  
**Fix:** Add `package-ecosystem: swift` to `.github/dependabot.yml`.

### M14. `MockURLProtocol` Duplicated in 6+ Test Files
**Fix:** Extract to a shared `TestUtilities/` folder.

### M15. No Version Automation
**Problem:** `CURRENT_PROJECT_VERSION = 1` and `MARKETING_VERSION = 1.0` are static.  
**Fix:** Use `agvtool` or CI-driven build number from `github.run_number`.

### M16. Daily XP Cap Mismatch
**Problem:** `PerkSystem.defaultDailyXPCap = 100` but DB CHECK constraint allows up to 500.  
**Fix:** Document intentional difference or align values.

### M17. Quest Side Selection is Non-Deterministic
**Problem:** `.shuffled()` produces different side quests each call. UI inconsistency if called multiple times.  
**Fix:** Seed RNG with date to make daily quests deterministic.

### M18. OfflineWriteQueue Has No Max Size or TTL
**Problem:** Could grow unbounded if user stays offline for days.  
**Fix:** Add a 30-day TTL and 500-item cap with oldest-first eviction.

### M19. `rnf_cycle.sh` Has Hardcoded Paths
**Problem:** `ROOT_DIR="/Users/regosenne/Desktop/Dev/RNF"` — won't work for other contributors.  
**Fix:** `ROOT_DIR="${RNF_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"`.

### M20. No SPM Package Caching in CI
**Problem:** Every CI build resolves packages fresh.  
**Fix:** Add `actions/cache` for SPM resolved packages.

### M21. iOS 26.2 Target — CI Runner Compatibility
**Problem:** CI runners must have Xcode 26+ which may not be available on `macos-latest`.  
**Fix:** Explicitly specify runner with required Xcode version.

### M22. No Error Recovery for Skill Tree Load Failure
**File:** `Features/Mastery/SkillTreeView.swift`  
**Problem:** Shows "Perks unavailable" with no retry action.  
**Fix:** Add retry button.

### M23. ReadingProfileService Timezone Edge Case
**Problem:** Streak logic uses date string comparison — midnight crossing could cause false breaks.  
**Fix:** Use `Calendar.isDate(_:inSameDayAs:)` instead of string comparison.

### M24. ForgeVoice Daily Limit Increments Before Playback
**Problem:** If audio playback fails after the limit check, the user loses a voice slot without hearing anything.  
**Fix:** Increment after successful playback, or decrement on failure.

### M25. LiveActivityManager Empty Catch Block
**File:** `Core/LiveActivityManager.swift:19`  
**Fix:** Log the error at minimum.

### M26. No Conflict Resolution for Watch ↔ Phone Sync
**Problem:** If both Watch and phone complete the same habit, idempotency prevents duplicates but no UI reconciliation.  
**Fix:** Add last-write-wins timestamp or show sync status.

---

## 🟢 LOW PRIORITY — Polish for v1.1+

| # | Issue | Fix |
|---|-------|-----|
| L1 | Inconsistent corner radius (hardcoded vs tokens) | Replace literals with `RNFRadius.*` tokens |
| L2 | No Lock Screen widgets (iOS) | Add `accessoryCircular`/`accessoryInline` families |
| L3 | No large widget size | Add `.systemLarge` family |
| L4 | `RNFWidgetData` duplicated between targets | Use shared framework or single source file with target membership |
| L5 | No UITest workflow in CI | Add `ios-uitests.yml` |
| L6 | No SwiftLint in CI | Add lint step for style consistency |
| L7 | No `SECURITY.md` or `CONTRIBUTING.md` | Add community docs |
| L8 | No search/filter in achievement gallery | Add `.searchable()` |
| L9 | No undo for habit completion | Add confirmation dialog or 5-second undo toast |
| L10 | No past weekly reports view | Store and list historical reports |
| L11 | No focus session history | Persist completed sessions for review |
| L12 | BossBattleView has no explicit damage button | Damage comes from habit completion — consider adding direct interaction |
| L13 | BreathingPacer not accessible to screen reader | Add audio cues or accessibility announcements |
| L14 | `GuildPulseBar` missing accessibility label | Add descriptive label |
| L15 | No log rotation in `rnf_cycle.sh` | Keep last 50 cycles |

---

## 📈 Upgrades & Modernization Opportunities

### Swift/SwiftUI Modernization

| Opportunity | Current State | Recommended |
|-------------|--------------|-------------|
| Observation framework | `ObservableObject` + `@Published` | Migrate to `@Observable` macro (iOS 17+) for cleaner reactivity, less boilerplate |
| Swift Testing | XCTest | Adopt `swift-testing` framework alongside XCTest for new tests — cleaner syntax, better parameterization |
| SwiftData | Raw Supabase queries + UserDefaults | Consider SwiftData for local cache layer (offline habits, discoveries, pillar streaks) |
| Structured Concurrency | Mix of Task{}, DispatchQueue, Timer | Standardize on AsyncStream/AsyncSequence for all reactive patterns |
| TipKit | No onboarding tips | Add contextual tips for feature discovery as users level up |
| App Intents | No Shortcuts support | Add "Complete Habit," "Start Focus," "Log Workout" as App Intents/Shortcuts |
| Interactive Widgets | Static widgets only | Make habit completion checkboxes interactive (iOS 17+) |
| StoreKit 2 Views | Empty subscription stub | Use `SubscriptionStoreView` for built-in subscription UI |
| String Catalogs | No localization | Add `.xcstrings` for eventual i18n |

### Architecture Enhancements

| Enhancement | Impact | Effort |
|-------------|--------|--------|
| Protocol abstractions for all services | Enables proper unit testing without subclassing | Medium |
| Repository pattern for local caching | Offline-first for all data, not just habits | High |
| Dependency injection container | Replace singletons with a DI container (e.g., Factory) | Medium |
| Feature flags service | Remote feature gating for A/B testing and staged rollout | Medium |
| Crash reporting (Sentry/Firebase) | Know about production crashes immediately | Low |
| Analytics pipeline (PostHog) | Understand user behavior and retention | Medium |
| Performance monitoring | Track cold start time, frame drops, network latency | Medium |

### User Experience Enhancements

| Enhancement | User Impact | Rationale |
|-------------|-------------|-----------|
| Haptic patterns per achievement type | Higher dopamine, better reward differentiation | RPG games differentiate reward tiers with distinct feedback |
| Animated transitions between evolution tiers | "Wow" moment on tier-up | This is the game's signature progression event |
| Daily summary notification with stats | Re-engagement, streak awareness | Users forget to open the app — remind them of progress |
| Photo proof for workouts | Accountability, shareable content | Community engagement feature |
| Dark mode exclusive themes for high tiers | Status symbol, premium feel | Rewards long-term players visually |
| Weekly challenge leaderboard | Social motivation | Competition drives engagement |
| Export to Apple Health | Data portability, user trust | Users expect health apps to share data |
| Siri voice commands | "Hey Siri, mark my workout as done" | Friction reduction for busy users |

---

## 🎯 End-User Needs Analysis

### Who is the RNF User?

The target user is a **disciplined self-improver who loves RPG progression systems**. They:
- Are frustrated by generic habit apps that feel like todo lists
- Want to feel like they're "leveling up" in real life
- Value aesthetic quality and premium feel
- Will abandon the app if it feels empty or directionless in the first 3 days
- Need **daily micro-rewards** to maintain engagement
- Want **visible proof of growth** over weeks and months

### Critical User Journey Gaps

1. **Day 1 Experience is Incomplete**
   - No guest/try-before-signup mode visible
   - No login → signup navigation
   - If profile fetch fails, user sees blank screen with no explanation
   
2. **Daily Loop Has Dead Ends**
   - Habit completion is satisfying (XP animation, streak) ✅
   - But then what? No "next quest" nudge, no "explore skill tree" prompt
   - 4-tab layout hides the most engaging features (Profile, Skills, Evolution, Boss)
   
3. **Progress Visibility is Fragmented**
   - XP and level shown in tabs ✅
   - But stats growth, skill tree progress, evolution tier, boss damage — all in screens users can't find
   - Weekly report shows fake data
   
4. **Social Features are Orphaned**
   - Guild, leaderboard, social challenges exist but have no navigation path
   - Social proof is the #1 retention driver for habit apps — it's unreachable
   
5. **Watch Experience is Broken**
   - Can't receive updates from phone
   - Complication shows 0/0
   - No offline habit completion queue
   - Users who bought the Watch expect it to work

6. **Offline Experience is Brittle**
   - Only habit completions survive network loss
   - A user who completes a workout on airplane mode loses that progress permanently

---

## 📋 Prioritized Action Plan

### Phase A: Production Blockers (Week 1)
1. Fix SupabaseService crash path (C1)
2. Fix FocusCompletionHandler XP data loss (C2)
3. Fix LoginView → SignUpView navigation (H6)
4. Fix Watch message handler (C5)
5. Fix Watch complication (C4)
6. Display load errors to users (H9)

### Phase B: Core UX (Week 2)
7. Add navigation to all screens (H1) — Profile/Menu tab
8. Add pull-to-refresh (H14)
9. Fix PageTabView gesture conflicts (H15)
10. Implement SubscriptionService or remove gates (C3)
11. Add widget refresh calls (H7)
12. Fix WeeklyReportService to use real data (H17)

### Phase C: Data Integrity (Week 3)
13. Extend offline queue beyond habits (H5)
14. Fix SyncFlushService retry logic (H10)
15. Persist discoveries server-side (H13)
16. Persist custom habits server-side (H12)
17. Persist pillar streaks server-side (H18)
18. Align WorkoutSession model with DB (H11)

### Phase D: Accessibility & Polish (Week 4)
19. Dynamic Type support (H2)
20. Fix WatchSyncService data race (H3)
21. Timer accessibility labels (M4)
22. Replace hardcoded colors (M3)
23. Fix Task leaks (M2)
24. Add empty states (M7)

### Phase E: Infrastructure (Week 5)
25. CI secret injection (H4)
26. Release pipeline + TestFlight (H8)
27. Version automation (M15)
28. SPM caching (M20)
29. Deep linking (H16)
30. Crash reporting integration

---

## 📊 Health Metrics

| Metric | Score | Notes |
|--------|-------|-------|
| Architecture Quality | 8/10 | Clean MVVM, good DI, consistent patterns |
| Code Safety | 5/10 | 1 guaranteed crash path, 2 data loss scenarios |
| Test Coverage | 7/10 | 31 test files, good integration tests, some gaps |
| Accessibility | 4/10 | Reduce motion ✅, Dynamic Type ❌, VoiceOver partial |
| Offline Resilience | 3/10 | Only habits queued, everything else lost |
| DevOps Maturity | 4/10 | Good CI validation, no deployment |
| UX Completeness | 5/10 | Screens exist but many unreachable |
| Data Integrity | 6/10 | RLS good, but local-only data at risk |
| Watch/Widget | 3/10 | Exists but broken/incomplete |
| Production Readiness | 4/10 | Not shippable without Phase A fixes |

---

## Conclusion

RNF has an **exceptional game design** and **solid architectural foundations**. The gamification systems (XP, evolution, perks, quests, bosses) are well-thought-out and correctly implemented. The main barriers to launch are:

1. **Safety** — One crash path and one data loss path must be fixed immediately
2. **Discoverability** — Most of the app's best features are unreachable from the UI
3. **Reliability** — Offline, Watch, and Widget experiences are incomplete
4. **Infrastructure** — No path from code to users' phones

Fix the 5 critical items and 6 highest-priority UX issues, and you have a compelling alpha-ready product. The game systems are the hard part — and they're already done.
