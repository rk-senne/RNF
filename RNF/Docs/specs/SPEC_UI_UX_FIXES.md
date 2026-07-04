# SPEC: UI/UX Technical Fixes

**Status:** Draft  
**Created:** 2026-07-03  
**Category:** UI/UX, Accessibility, Architecture Hygiene  
**Priority:** High — these fixes address navigation gaps, accessibility violations, memory leaks, and design system drift.

---

## Overview

This specification documents 14 UI/UX technical fixes identified during code audit. Each fix is scoped, actionable, and independently implementable. Fixes are ordered by user-facing impact.

---

## 1. Navigation Paths to All Screens

### Problem

ProfileView, SkillTreeView, EvolutionView, DiscoveryLogView, ArcArchiveView, SocialTabView, AchievementsGalleryView, FocusTimerView, and JourneyMapView are unreachable from the current 4-tab UI. Users have no path to these features after they are built.

### Files Affected

- `Navigation/RootView.swift`
- `Navigation/RNFTabBar.swift`
- New file: `Features/Profile/ProfileMenuView.swift`

### Fix Description

Add a 5th "Profile/Menu" tab containing a `NavigationStack` with a sectioned list linking to all feature screens.

**Navigation hierarchy:**

| Section    | Screens                                      |
|------------|----------------------------------------------|
| Identity   | ProfileView, DisciplineCardView, EvolutionView |
| Progress   | SkillTreeView, AchievementsGalleryView, JourneyMapView |
| Social     | GuildView, LeaderboardView, SocialTabView (Challenges) |
| Tools      | FocusTimerView, DiscoveryLogView, ArcArchiveView |
| Settings   | (future)                                     |

### Code Guidance

```swift
// RootView.swift — add 5th tab case
enum AppTab: Int, CaseIterable {
    case habits, ascension, workouts, reading, profile
}

// ProfileMenuView.swift
struct ProfileMenuView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Identity") {
                    NavigationLink("Profile", destination: ProfileView())
                    NavigationLink("Discipline Card", destination: DisciplineCardView())
                    NavigationLink("Evolution", destination: EvolutionView())
                }
                Section("Progress") {
                    NavigationLink("Skill Tree", destination: SkillTreeView())
                    NavigationLink("Achievements", destination: AchievementsGalleryView())
                    NavigationLink("Journey Map", destination: JourneyMapView())
                }
                Section("Social") {
                    NavigationLink("Guilds", destination: GuildView())
                    NavigationLink("Leaderboard", destination: LeaderboardView())
                    NavigationLink("Challenges", destination: SocialTabView())
                }
                Section("Tools") {
                    NavigationLink("Focus Timer", destination: FocusTimerView())
                    NavigationLink("Discovery Log", destination: DiscoveryLogView())
                    NavigationLink("Arc Archive", destination: ArcArchiveView())
                }
            }
            .navigationTitle("Profile")
        }
    }
}
```

Update `RNFTabBar` to include the 5th tab icon (`person.circle` or `line.3.horizontal`).

### Acceptance Criteria

- [ ] All 9 previously-unreachable screens are accessible within 2 taps from root.
- [ ] Tab bar shows 5 tabs with appropriate SF Symbols.
- [ ] NavigationStack back-swipe works correctly from each destination.
- [ ] Deep-linking via tab selection works (select profile tab -> navigate -> switch tabs -> return preserves stack).

---

## 2. Dynamic Type Support

### Problem

`Typography.swift` uses fixed `Font.system(size:)` calls that do not scale with the user's Dynamic Type accessibility settings. This violates iOS HIG and WCAG 1.4.4.

### Files Affected

- `DesignSystem/Typography.swift` (primary)
- All views consuming Typography tokens (secondary — no changes needed if Typography is fixed)

### Fix Description

Replace all fixed font sizes with `@ScaledMetric` wrappers or `.relativeTo:` text style relationships. Add a `dynamicTypeSize` range cap to prevent extreme sizes from breaking layout.

**Mapping:**

| Current Token | Current Size | New Approach |
|---------------|-------------|--------------|
| `display`     | 42pt fixed  | `@ScaledMetric(relativeTo: .largeTitle)` base 42 |
| `metric`      | 64pt fixed  | `@ScaledMetric(relativeTo: .largeTitle)` base 64 |
| `section`     | 20pt fixed  | `.font(.system(.title3))` or `@ScaledMetric(relativeTo: .title3)` base 20 |
| `caption`     | 12pt fixed  | `.font(.system(.caption))` or `@ScaledMetric(relativeTo: .caption)` base 12 |
| `pill`        | 11pt fixed  | `@ScaledMetric(relativeTo: .caption2)` base 11 |

### Code Guidance

```swift
// Typography.swift — revised approach
struct RNFTypography {
    // Option A: ScaledMetric in a container (requires View context)
    // Option B: Relative font constructors (works anywhere)
    
    static let display = Font.system(size: 42, weight: .bold, design: .rounded)
        // Replace with:
    static func display() -> Font {
        .system(.largeTitle, design: .rounded).weight(.bold)
    }
    
    // For precise control, use ScaledMetric in views:
    @ScaledMetric(relativeTo: .largeTitle) private var displaySize: CGFloat = 42
    @ScaledMetric(relativeTo: .largeTitle) private var metricSize: CGFloat = 64
    @ScaledMetric(relativeTo: .title3) private var sectionSize: CGFloat = 20
    @ScaledMetric(relativeTo: .caption) private var captionSize: CGFloat = 12
    @ScaledMetric(relativeTo: .caption2) private var pillSize: CGFloat = 11
}

// Apply range cap at view level:
.dynamicTypeSize(...DynamicTypeSize.accessibility3)
```

### Acceptance Criteria

- [ ] All text scales when Dynamic Type is changed in Settings > Accessibility > Display & Text Size.
- [ ] Layout does not break at `.accessibility3` (largest supported size).
- [ ] Layout does not break at `.xSmall` (smallest size).
- [ ] No remaining `Font.system(size:)` calls in Typography.swift.
- [ ] VoiceOver reads all text correctly at all sizes.

---

## 3. Pull-to-Refresh

### Problem

No scrollable view implements `.refreshable{}`. Users cannot manually reload data after network issues or background changes.

### Files Affected

- `Features/Habits/ContentView.swift`
- `Features/Ascension/AscensionView.swift`
- `Features/Workouts/WorkoutListView.swift`
- `Features/Read/ReadView.swift`

### Fix Description

Add `.refreshable` modifier to the primary `ScrollView` or `List` in each view. Wire to the existing data loading logic.

### Code Guidance

```swift
// ContentView.swift (has ViewModel)
ScrollView {
    // ... content
}
.refreshable {
    await viewModel.load(gameState: game)
}

// AscensionView.swift (no ViewModel — extract load function)
@State private var ascensionData: AscensionData?

var body: some View {
    ScrollView { /* ... */ }
        .refreshable { await loadAscensionData() }
        .task { await loadAscensionData() }
}

private func loadAscensionData() async {
    // Extract current inline load logic here
}
```

### Acceptance Criteria

- [ ] Pull-to-refresh gesture triggers data reload on all 4 views.
- [ ] Loading indicator appears during refresh.
- [ ] UI updates reflect fresh data after refresh completes.
- [ ] No duplicate network requests from rapid pull-to-refresh.


---

## 4. PageTabView Gesture Conflicts

### Problem

`.tabViewStyle(.page)` on the root `TabView` makes tabs horizontally swipeable. This conflicts with `NavigationStack` edge-swipe-to-go-back gesture, causing unreliable navigation and frustrated users.

### Files Affected

- `Navigation/RootView.swift`

### Fix Description

Replace `.tabViewStyle(.page(indexDisplayMode: .never))` with `.tabViewStyle(.automatic)`. The custom `RNFTabBar` already handles tab selection programmatically, so native page-swiping adds no value and only creates gesture ambiguity.

**Alternative (if swipe-between-tabs is desired):** Keep `.page` style but add `.scrollDisabled(true)` to the TabView, relying solely on the custom tab bar for switching.

### Code Guidance

```swift
// RootView.swift — Option A (recommended)
TabView(selection: $selectedTab) {
    // tab content...
}
.tabViewStyle(.automatic)  // was: .tabViewStyle(.page(indexDisplayMode: .never))

// RootView.swift — Option B (preserves page container)
TabView(selection: $selectedTab) {
    // tab content...
}
.tabViewStyle(.page(indexDisplayMode: .never))
.scrollDisabled(true)  // prevents swipe gesture conflict
```

### Acceptance Criteria

- [ ] NavigationStack back-swipe works reliably on all screens.
- [ ] Tab switching works exclusively via custom RNFTabBar taps.
- [ ] No horizontal swipe intercept on root TabView.
- [ ] Animations between tab switches remain smooth.

---

## 5. Empty States

### Problem

Social, Achievements, and Discovery screens render blank/empty space when no data exists. New users see nothing, with no guidance on what to do.

### Files Affected

- `Features/Social/SocialTabView.swift`
- `Features/Social/GuildView.swift`
- `Features/Social/LeaderboardView.swift`
- `Features/Achievements/AchievementsGalleryView.swift`
- `Features/Journey/DiscoveryLogView.swift`

### Fix Description

Add `ContentUnavailableView` (iOS 17+) or a custom `EmptyStateView` component when the primary data collection is empty. Each empty state should include an icon, descriptive text, and an action button where applicable.

### Code Guidance

```swift
// Reusable component
struct RNFEmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(description)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

// Usage in AchievementsGalleryView:
if achievements.isEmpty {
    RNFEmptyStateView(
        icon: "trophy",
        title: "No Achievements Yet",
        description: "Complete habits to earn your first badge.",
        actionTitle: "View Habits",
        action: { /* navigate to habits */ }
    )
} else {
    // existing grid/list
}
```

**Empty state copy per screen:**

| Screen | Icon | Title | Description | Action |
|--------|------|-------|-------------|--------|
| Achievements | `trophy` | No Achievements Yet | Complete habits to earn your first badge. | View Habits |
| Guild | `person.3` | No Guild Yet | Join or create a guild to compete together. | Join a Guild |
| Leaderboard | `chart.bar` | Leaderboard Empty | Complete challenges to appear here. | — |
| Discovery Log | `book.closed` | Nothing Discovered | Your insights will appear here as you progress. | — |
| Social/Challenges | `flag.2.crossed` | No Active Challenges | Start a challenge to compete with friends. | Start a Challenge |

### Acceptance Criteria

- [ ] Each listed screen shows an informative empty state when data is empty.
- [ ] Empty states include icon, title, and description at minimum.
- [ ] Action buttons navigate to relevant screens or trigger relevant actions.
- [ ] Empty states disappear when data is loaded/added.
- [ ] VoiceOver reads empty state content correctly.

---

## 6. Hardcoded Colors

### Problem

Multiple views use `Color(red:green:blue:)` or `Color(hex:)` literals instead of design system tokens. This breaks dark mode consistency and makes theming impossible.

### Files Affected

- `Components/HabitRow.swift` (4 instances)
- `Components/DailyMissionBar.swift` (3 instances)
- `Features/Focus/FocusTimerView.swift`
- `Features/Workouts/ActiveWorkoutTimerView.swift`

### Fix Description

1. Audit all `Color(red:` and `Color(hex:` usages.
2. Map each to an existing `RNFColors` token or create new semantic tokens.
3. Define new tokens in the Asset Catalog with light/dark variants.

**New tokens to add:**

| Token Name | Usage | Light | Dark |
|-----------|-------|-------|------|
| `RNFColors.habitGold` | Gold habit indicator | `#FFD700` | `#FFC107` |
| `RNFColors.habitGreen` | Green habit indicator | `#4CAF50` | `#66BB6A` |
| `RNFColors.habitBlue` | Blue habit indicator | `#2196F3` | `#42A5F5` |
| `RNFColors.timerGradientStart` | Timer ring start | Design-defined | Design-defined |
| `RNFColors.timerGradientEnd` | Timer ring end | Design-defined | Design-defined |

### Code Guidance

```swift
// Before:
.foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))

// After:
.foregroundColor(RNFColors.habitGold)

// RNFColors.swift — add tokens:
extension RNFColors {
    static let habitGold = Color("habitGold")      // Asset Catalog
    static let habitGreen = Color("habitGreen")
    static let habitBlue = Color("habitBlue")
    static let timerGradientStart = Color("timerGradientStart")
    static let timerGradientEnd = Color("timerGradientEnd")
}
```

### Acceptance Criteria

- [ ] Zero `Color(red:green:blue:)` or `Color(hex:)` literals remain in production views.
- [ ] All new tokens defined in Asset Catalog with light and dark variants.
- [ ] Dark mode renders correctly on all affected views.
- [ ] No visual regression in light mode.

---

## 7. Task Leaks in Particle Views

### Problem

`AmbientParticleView` creates an infinite `Task` loop with no cancellation handle. When the view disappears and reappears, new tasks spawn without cancelling old ones, leading to memory leaks and increasing CPU usage.

### Files Affected

- `Components/AmbientParticleView.swift`
- `Components/Overlays/ConfettiView.swift`

### Fix Description

Store the `Task` handle in a `@State` property. Cancel on `.onDisappear`. Check `Task.isCancelled` inside the loop body.

### Code Guidance

```swift
// AmbientParticleView.swift
struct AmbientParticleView: View {
    @State private var driftTask: Task<Void, Never>?
    @State private var particles: [Particle] = []
    
    var body: some View {
        Canvas { context, size in
            // draw particles...
        }
        .onAppear {
            driftTask = Task {
                while !Task.isCancelled {
                    await updateParticles()
                    try? await Task.sleep(for: .milliseconds(16))
                }
            }
        }
        .onDisappear {
            driftTask?.cancel()
            driftTask = nil
        }
    }
}

// ConfettiView.swift — same pattern
@State private var animationTask: Task<Void, Never>?

// .onAppear: create task
// .onDisappear: cancel task
// Loop: check Task.isCancelled
```

### Acceptance Criteria

- [ ] Navigating away from particle views stops all background tasks.
- [ ] Returning to particle views starts exactly one new task.
- [ ] Instruments shows no task accumulation after repeated appear/disappear cycles.
- [ ] Memory usage remains stable after 20+ navigation cycles.
- [ ] Particle animation renders identically to current behavior.


---

## 8. Accessibility Labels for Timers

### Problem

`FocusTimerView` and `ActiveWorkoutTimerView` display countdown timers visually but provide no semantic information to VoiceOver users. Screen reader users cannot determine remaining time.

### Files Affected

- `Features/Focus/FocusTimerView.swift`
- `Features/Workouts/ActiveWorkoutTimerView.swift`

### Fix Description

Add `.accessibilityLabel` to the timer display text with a human-readable time string. Use `.accessibilityValue` for dynamic updates so VoiceOver announces changes. Consider `@AccessibilityFocusState` for critical announcements (timer complete).

### Code Guidance

```swift
// FocusTimerView.swift
Text(timerDisplay) // e.g., "12:34"
    .font(RNFTypography.metric)
    .accessibilityLabel("\(minutes) minutes and \(seconds) seconds remaining")
    .accessibilityValue("\(minutes):\(String(format: "%02d", seconds))")
    .accessibilityAddTraits(.updatesFrequently)

// Announce timer completion:
@AccessibilityFocusState private var isTimerFocused: Bool

// When timer completes:
func timerDidComplete() {
    // Post announcement
    AccessibilityNotification.Announcement("Focus session complete. Great work!")
        .post()
}

// ActiveWorkoutTimerView.swift — same pattern
Text(workoutTimerDisplay)
    .accessibilityLabel("\(minutes) minutes and \(seconds) seconds elapsed")
    .accessibilityAddTraits(.updatesFrequently)
```

### Acceptance Criteria

- [ ] VoiceOver reads timer values as "X minutes and Y seconds remaining/elapsed".
- [ ] Timer completion triggers an accessibility announcement.
- [ ] `.updatesFrequently` trait is applied so VoiceOver doesn't over-announce.
- [ ] Start/pause/reset buttons have descriptive accessibility labels.
- [ ] Timer is usable end-to-end with VoiceOver enabled.

---

## 9. Design System Consistency (Corner Radius)

### Problem

Approximately 15 views use hardcoded `cornerRadius` values (12, 16, 18, 20, 24, 28) instead of `RNFRadius` design tokens. This creates visual inconsistency and makes system-wide radius changes impossible.

### Files Affected

- ~15 views across `Features/` and `Components/` directories
- `DesignSystem/Radius.swift` (may need new token)

### Fix Description

Global find-and-replace of hardcoded corner radius values with design system tokens.

**Mapping:**

| Hardcoded Value | Design Token | Notes |
|----------------|--------------|-------|
| `cornerRadius: 12` | `RNFRadius.sm` | Small cards, pills |
| `cornerRadius: 16` | `RNFRadius.md` | Standard cards |
| `cornerRadius: 18` | `RNFRadius.mlg` | Add new token if needed, or use `.lg` |
| `cornerRadius: 20` | `RNFRadius.lg` | Large cards |
| `cornerRadius: 24` | `RNFRadius.xl` | Modal sheets |
| `cornerRadius: 28` | `RNFRadius.card` | Feature cards |

### Code Guidance

```swift
// DesignSystem/Radius.swift — add missing token if needed:
enum RNFRadius {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let mlg: CGFloat = 18  // NEW — only if 18pt is semantically distinct
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let card: CGFloat = 28
}

// Before:
.clipShape(RoundedRectangle(cornerRadius: 16))

// After:
.clipShape(RoundedRectangle(cornerRadius: RNFRadius.md))
```

**Search regex for audit:** `cornerRadius:\s*\d+` across all `.swift` files.

### Acceptance Criteria

- [ ] Zero hardcoded `cornerRadius` numeric literals in view files.
- [ ] All radius usage references `RNFRadius` tokens.
- [ ] Visual appearance unchanged (same numeric values, just tokenized).
- [ ] Changing a single `RNFRadius` value updates all views consistently.

---

## 10. Service Objects in View Structs

### Problem

`ChallengeEngine()`, `CalendarService()`, and `ReadingEngine()` are instantiated as stored properties of view structs. SwiftUI recreates view structs frequently, causing unnecessary allocations and potential state loss.

### Files Affected

- `Features/Ascension/AscensionView.swift`
- `Features/Habits/ContentView.swift`
- `Features/Habits/MissedDayView.swift`
- `Features/Read/ReadView.swift`
- `Features/Journey/DiscoveryLogView.swift`

### Fix Description

Move service instantiation out of view struct stored properties using one of these strategies:

1. **For stateful services:** Wrap in `@StateObject` ViewModel that owns the service.
2. **For shared services:** Inject via `.environment()` from a parent.
3. **For stateless/lightweight structs:** Make a `static let` on the view or a dedicated container.

### Code Guidance

```swift
// BEFORE (problematic):
struct AscensionView: View {
    let challengeEngine = ChallengeEngine()  // recreated on every view init
    // ...
}

// AFTER — Option A: ViewModel owns service
class AscensionViewModel: ObservableObject {
    let challengeEngine = ChallengeEngine()
    // ...
}

struct AscensionView: View {
    @StateObject private var viewModel = AscensionViewModel()
    // use viewModel.challengeEngine
}

// AFTER — Option B: Static (for truly stateless services)
struct AscensionView: View {
    private static let challengeEngine = ChallengeEngine()
    // use Self.challengeEngine
}

// AFTER — Option C: Environment injection
struct AscensionView: View {
    @Environment(\.challengeEngine) private var challengeEngine
    // ...
}
```

### Acceptance Criteria

- [ ] No service class/struct instantiated as a view stored property (non-static, non-@StateObject).
- [ ] Services persist correctly across view re-renders.
- [ ] No behavioral changes — all features work identically.
- [ ] Memory profile shows stable allocations during rapid navigation.

---

## 11. DiscoveryLogView Loads at Init Time

### Problem

`DiscoveryService.loadHistory()` is called during view struct initialization (stored property default). This blocks the main thread during view creation and violates SwiftUI's expectation that view init is cheap.

### Files Affected

- `Features/Journey/DiscoveryLogView.swift`

### Fix Description

Move the load call into `.task {}` modifier. Use `@State` for the history array initialized to empty.

### Code Guidance

```swift
// BEFORE:
struct DiscoveryLogView: View {
    let history = DiscoveryService.loadHistory()  // blocks init
    // ...
}

// AFTER:
struct DiscoveryLogView: View {
    @State private var history: [DiscoveryRecord] = []
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if history.isEmpty {
                RNFEmptyStateView(
                    icon: "book.closed",
                    title: "Nothing Discovered",
                    description: "Your insights will appear here as you progress."
                )
            } else {
                // existing list/grid of history
            }
        }
        .task {
            history = DiscoveryService.loadHistory()
            isLoading = false
        }
    }
}
```

### Acceptance Criteria

- [ ] `DiscoveryService.loadHistory()` is not called during view struct init.
- [ ] Loading indicator shows while data loads.
- [ ] History displays correctly after async load.
- [ ] View appears instantly (no main thread blocking on navigation).


---

## 12. LoginView ↔ SignUpView Navigation

### Problem

There is no navigation path between `LoginView` and `SignUpView`. Users who land on login cannot create an account, and users on sign-up cannot switch to login.

### Files Affected

- `Features/Onboarding/LoginView.swift`
- `Features/Onboarding/SignUpView.swift`

### Fix Description

Add cross-navigation buttons:
- LoginView: "Don't have an account? **Create Account**" → navigates to SignUpView.
- SignUpView: "Already have an account? **Log in**" → navigates to LoginView.

Use `NavigationLink` if within a `NavigationStack`, or sheet presentation if onboarding uses a flat structure.

### Code Guidance

```swift
// LoginView.swift — add at bottom of form:
VStack(spacing: 8) {
    // ... existing login fields and button
    
    Divider()
        .padding(.vertical)
    
    HStack {
        Text("Don't have an account?")
            .foregroundColor(RNFColors.textSecondary)
        NavigationLink("Create Account") {
            SignUpView()
        }
        .fontWeight(.semibold)
    }
    .font(RNFTypography.caption)
}

// SignUpView.swift — add at bottom of form:
HStack {
    Text("Already have an account?")
        .foregroundColor(RNFColors.textSecondary)
    NavigationLink("Log in") {
        LoginView()
    }
    .fontWeight(.semibold)
}
.font(RNFTypography.caption)
```

**Important:** Ensure the parent provides a `NavigationStack`. If the onboarding flow doesn't have one, wrap it:

```swift
// OnboardingContainerView or similar:
NavigationStack {
    LoginView()
}
```

### Acceptance Criteria

- [ ] User can navigate from LoginView to SignUpView.
- [ ] User can navigate from SignUpView to LoginView.
- [ ] Back button/swipe returns to previous screen.
- [ ] No infinite navigation loop (Login → SignUp → Login doesn't stack infinitely). Consider `.navigationBarBackButtonHidden` + custom back if needed.
- [ ] Both views remain functional after navigation.

---

## 13. Error Display for Load Failures

### Problem

`ContentView`'s ViewModel sets `loadErrorMessage` on failure, but the view never reads or displays it. Users see an empty screen with no explanation or retry option.

### Files Affected

- `Features/Habits/ContentView.swift`
- New component (optional): `Components/ErrorStateView.swift`

### Fix Description

Add conditional error UI that shows when `loadErrorMessage` is non-nil AND the habit list is empty. Include a retry button.

### Code Guidance

```swift
// ContentView.swift — add within the body:
if viewModel.habits.isEmpty {
    if let error = viewModel.loadErrorMessage {
        ErrorStateView(
            message: error,
            retryAction: {
                Task { await viewModel.load(gameState: game) }
            }
        )
    } else if viewModel.isLoading {
        ProgressView()
    }
} else {
    // existing habit list
}

// Components/ErrorStateView.swift (reusable)
struct ErrorStateView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(RNFColors.warning)
            
            Text("Something went wrong")
                .font(RNFTypography.section)
            
            Text(message)
                .font(RNFTypography.caption)
                .foregroundColor(RNFColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

### Acceptance Criteria

- [ ] Error message displays when load fails and habit list is empty.
- [ ] Retry button triggers a new load attempt.
- [ ] Error state disappears on successful retry.
- [ ] Error state does NOT show over existing data (only when list is empty).
- [ ] VoiceOver reads error message and retry button.

---

## 14. Array VectorArithmetic Conformance Risk

### Problem

`DisciplineRadarChart.swift` adds a global `@retroactive VectorArithmetic` conformance to `[Double]`. This is fragile — any other library or future Swift version adding the same conformance will cause a compile error.

### Files Affected

- `Components/DisciplineRadarChart.swift`

### Fix Description

Create a dedicated `AnimatableVector` struct that wraps `[Double]` and provides `VectorArithmetic` conformance locally. Replace `[Double]` usage in the chart's `Animatable` conformance.

### Code Guidance

```swift
// AnimatableVector.swift (new file in Components/ or DesignSystem/)
struct AnimatableVector: VectorArithmetic {
    var values: [Double]
    
    static var zero: AnimatableVector {
        AnimatableVector(values: [])
    }
    
    static func + (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        let count = max(lhs.values.count, rhs.values.count)
        var result = [Double](repeating: 0, count: count)
        for i in 0..<count {
            let l = i < lhs.values.count ? lhs.values[i] : 0
            let r = i < rhs.values.count ? rhs.values[i] : 0
            result[i] = l + r
        }
        return AnimatableVector(values: result)
    }
    
    static func - (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        let count = max(lhs.values.count, rhs.values.count)
        var result = [Double](repeating: 0, count: count)
        for i in 0..<count {
            let l = i < lhs.values.count ? lhs.values[i] : 0
            let r = i < rhs.values.count ? rhs.values[i] : 0
            result[i] = l - r
        }
        return AnimatableVector(values: result)
    }
    
    mutating func scale(by rhs: Double) {
        for i in values.indices {
            values[i] *= rhs
        }
    }
    
    var magnitudeSquared: Double {
        values.reduce(0) { $0 + $1 * $1 }
    }
}

// DisciplineRadarChart.swift — replace usage:
struct RadarChartShape: Shape {
    var animatableData: AnimatableVector  // was: [Double]
    
    init(values: [Double]) {
        self.animatableData = AnimatableVector(values: values)
    }
    
    func path(in rect: CGRect) -> Path {
        let values = animatableData.values
        // ... existing path logic
    }
}

// REMOVE the global extension:
// extension Array: @retroactive VectorArithmetic where Element == Double { ... }
```

### Acceptance Criteria

- [ ] Global `@retroactive VectorArithmetic` extension on `[Double]` is removed.
- [ ] `AnimatableVector` struct provides identical animation behavior.
- [ ] Radar chart animates smoothly between value changes.
- [ ] No compile warnings about retroactive conformances.
- [ ] Chart renders identically to current implementation.

---

## Testing Checklist

### Manual Testing

| # | Fix | Test Procedure | Pass Criteria |
|---|-----|---------------|---------------|
| 1 | Navigation | From root, navigate to all 9 screens via Profile tab | All screens reachable within 2 taps |
| 2 | Dynamic Type | Settings > Accessibility > Larger Text → max size | All text scales, no truncation, no layout break |
| 3 | Pull-to-Refresh | Pull down on each scrollable view | Refresh indicator + data reloads |
| 4 | Gesture Conflicts | Push a detail view, swipe back from left edge | Back gesture works reliably, no tab switch |
| 5 | Empty States | View Social/Achievements with empty data | Informative empty state with icon + text |
| 6 | Colors (Dark Mode) | Toggle dark mode in Settings | All colors adapt, no white/black blobs |
| 7 | Task Leaks | Navigate to/from particle views 20 times | Instruments: no task accumulation, stable memory |
| 8 | Timer Accessibility | Enable VoiceOver, start a focus session | Timer value announced, completion announced |
| 9 | Corner Radius | Visual regression comparison | No pixel-level differences |
| 10 | Service Objects | Profile Instruments allocations during rapid nav | No repeated service allocations |
| 11 | Discovery Load | Navigate to DiscoveryLogView | Instant nav, loading spinner, then content |
| 12 | Login ↔ SignUp | Tap "Create Account" / "Log in" | Correct navigation, no infinite stack |
| 13 | Error Display | Simulate network failure on habits load | Error message + retry button shown |
| 14 | VectorArithmetic | View discipline radar chart, trigger animation | Smooth animation, no compile warnings |

### Automated Testing

```swift
// Suggested XCTest targets:

// test_navigationAllScreensReachable()
// - Verify ProfileMenuView contains NavigationLinks to all 9 screens.

// test_dynamicTypeFontScaling()
// - Set DynamicTypeSize in environment, verify fonts respond.

// test_emptyStateShows()
// - Render AchievementsGalleryView with empty data, assert ContentUnavailableView present.

// test_errorStateDisplays()
// - Set viewModel.loadErrorMessage, assert ErrorStateView visible.

// test_animatableVectorArithmetic()
// - Test AnimatableVector +, -, scale, magnitudeSquared operations.

// test_taskCancellationOnDisappear()
// - Trigger onDisappear, assert driftTask is nil.
```

### Accessibility Audit

- [ ] Run Xcode Accessibility Inspector on all modified screens.
- [ ] Verify VoiceOver navigation order is logical.
- [ ] Confirm no elements are invisible to assistive technology.
- [ ] Test with Switch Control for button hit targets (minimum 44×44pt).

### Performance Validation

- [ ] Profile with Instruments → Allocations: no leaks from fixes 7, 10, 11.
- [ ] Profile with Instruments → Time Profiler: fix 11 removes main-thread blocking.
- [ ] Profile with Instruments → Energy Log: fix 7 reduces background CPU.

---

## Implementation Order (Suggested)

Priority is based on user impact and dependency relationships:

1. **Fix 4** — Gesture conflicts (unblocks usability of all navigation)
2. **Fix 1** — Navigation paths (unblocks access to all features)
3. **Fix 12** — Login ↔ SignUp (critical onboarding flow)
4. **Fix 13** — Error display (users currently stuck on failures)
5. **Fix 11** — Init-time loading (perf regression)
6. **Fix 10** — Service objects (perf/correctness)
7. **Fix 7** — Task leaks (memory/battery)
8. **Fix 3** — Pull-to-refresh (quality of life)
9. **Fix 5** — Empty states (UX polish)
10. **Fix 2** — Dynamic Type (accessibility compliance)
11. **Fix 8** — Timer accessibility (accessibility compliance)
12. **Fix 6** — Hardcoded colors (design system hygiene)
13. **Fix 9** — Corner radius tokens (design system hygiene)
14. **Fix 14** — VectorArithmetic (future-proofing)

---

*End of specification.*