# RNF UX Polish Specification

Version: 1.0  
Status: APPROVED FOR IMPLEMENTATION  
Priority: P0 (Ship-blocking)  
Owner: Design Systems Team  
Last Updated: 2026-06-29

---

## Executive Summary

This specification defines 15 discrete UX improvement workstreams that elevate RNF from a functional product to a premium discipline platform. Each issue is scoped with acceptance criteria, implementation guidance, affected files, dependencies, risk assessment, and rollback strategy.

The improvements are ordered by criticality: visual defects first, foundational system gaps second, experiential enhancements third.

---

## Guiding Principles

All work in this spec must adhere to the RNF Design Philosophy:

- **Calm command center** — never a toy
- **Minimal, focused, premium, structured**
- **Discipline reinforcement through interaction design**
- **Accessibility is non-negotiable** (WCAG AA, Dynamic Type, VoiceOver, Reduce Motion)

---

## Issue Severity Classification

| Severity | Definition | SLA |
|----------|-----------|-----|
| SEV-1 | Visual defect visible to all users in a supported mode | Must fix before release |
| SEV-2 | Missing foundational system causing inconsistency debt | Fix within current sprint |
| SEV-3 | Experience gap reducing perceived quality | Fix within 2 sprints |
| SEV-4 | Enhancement elevating premium positioning | Scheduled by priority |

---

## Phase 19 – UX Polish

### UX-01: Dark Mode Surface Treatment Fix

**Severity:** SEV-1  
**Impact:** Every dark mode user sees broken card surfaces  
**Root Cause:** Hardcoded `Color.white.opacity(0.88)` and `Color.white.opacity(0.72)` used as card fills instead of semantic tokens

#### Problem Statement

The following views use white-based opacities that render as near-invisible or washed-out panels in dark mode:

- `AscensionView.swift` — `surfaceFill`, `surfaceBorder`, forgiveness row, titles section
- `ContentView.swift` — header card background
- `EvolutionView.swift` — outer container
- `SkillTreeView.swift` — perk metric chips

#### Acceptance Criteria

- AC-1: All card surfaces MUST use semantic color tokens that adapt to light/dark appearance
- AC-2: No hardcoded `Color.white` or `Color.black` opacity values remain in any view file
- AC-3: Visual parity between light and dark mode confirmed on iPhone 15 Pro simulator
- AC-4: Existing shadow and border treatments remain visible in both modes

#### Implementation Plan

1. Expand `RNF/DesignSystem/Colors.swift`:

```swift
struct RNFColors {
    // Existing
    static let primary = Color(hex: "#7C3AED")
    static let success = Color(hex: "#22A559")
    static let warning = Color(hex: "#D4940F")
    static let backgroundLight = Color(hex: "#F4F5F7")
    static let backgroundDark = Color(hex: "#121212")
    static let secondaryText = Color(hex: "#6B7280")

    // NEW — Adaptive surfaces
    static let surface = Color(.secondarySystemBackground)
    static let surfaceElevated = Color(.tertiarySystemBackground)
    static let surfaceOverlay = Color(.systemBackground).opacity(0.88)
    static let border = Color(.separator)
    static let borderSubtle = Color(.separator).opacity(0.5)
}
```

2. Replace in `AscensionView.swift`:
   - `Color.white.opacity(0.88)` → `RNFColors.surface`
   - `Color.white.opacity(0.72)` → `RNFColors.surfaceElevated`
   - `Color.black.opacity(0.05)` → `RNFColors.borderSubtle`

3. Replace in `ContentView.swift`:
   - Header card fill → `RNFColors.surface`

4. Replace in `EvolutionView.swift`:
   - Container fill → `RNFColors.surface`

5. Audit pass: `grep -r "Color.white.opacity\|Color.black.opacity" RNF/Features/ RNF/Components/`

#### Files Changed

- `RNF/DesignSystem/Colors.swift`
- `RNF/Features/Ascension/AscensionView.swift`
- `RNF/Features/Habits/ContentView.swift`
- `RNF/Features/Profile/EvolutionView.swift`
- `RNF/Features/Profile/SkillTreeView.swift`

#### Dependencies

- None (standalone fix)

#### Risk Assessment

- Risk: LOW
- Blast radius: Visual only, no logic changes
- Rollback: Revert color token additions and restore hardcoded values

#### Verification

- Toggle Appearance in Simulator (Dark/Light) across all 4 tabs
- Screenshot comparison at each breakpoint
- No contrast violations below 4.5:1 for body text on new surfaces

---

### UX-02: Typography System Consolidation

**Severity:** SEV-2  
**Impact:** Inconsistent font declarations across 30+ views; `RNFFont` tokens exist but are unused  
**Root Cause:** Original views were built with inline `.font(.system(size:weight:design:))` before design tokens were established

#### Problem Statement

The codebase has a `RNFFont` struct with 4 tokens (`title`, `section`, `body`, `caption`) but every view ignores them, using inline font declarations. This causes:

- Inconsistent sizing (section headers range from 12pt to 22pt)
- Duplicated patterns (the "overline" style `.font(.system(size: 12, weight: .black, design: .rounded)).tracking(1.2)` appears 20+ times)
- No monospaced variant for numeric displays (timers, XP counts)

#### Acceptance Criteria

- AC-1: `RNFFont` SHALL define at minimum: `display`, `title`, `section`, `body`, `caption`, `overline`, `metric`
- AC-2: The overline pattern (12pt black rounded + 1.2 tracking) SHALL be a single reusable modifier
- AC-3: All numeric/counter displays (timer, XP, level) SHALL use the `metric` token (monospaced digit rounded)
- AC-4: No inline `.font(.system(size:` declarations remain in view files after migration
- AC-5: Dynamic Type scaling MUST be preserved (no fixed frame sizes blocking text growth)

#### Implementation Plan

1. Expand `RNF/DesignSystem/Typography.swift`:

```swift
struct RNFFont {
    static let display = Font.system(size: 42, weight: .black, design: .rounded)
    static let title = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let section = Font.system(size: 18, weight: .bold, design: .rounded)
    static let body = Font.system(.body, design: .rounded)
    static let bodyBold = Font.system(.body, design: .rounded).weight(.bold)
    static let caption = Font.system(.caption, design: .rounded)
    static let overline = Font.system(size: 12, weight: .black, design: .rounded)
    static let metric = Font.system(size: 64, weight: .black, design: .rounded).monospacedDigit()
    static let metricSmall = Font.system(size: 20, weight: .bold, design: .rounded).monospacedDigit()
    static let pill = Font.system(size: 11, weight: .black, design: .rounded)
}
```

2. Create `View+Overline` modifier:

```swift
extension View {
    func overlineStyle() -> some View {
        self.font(RNFFont.overline).tracking(1.2).foregroundStyle(.secondary)
    }
}
```

3. Migration order (by usage frequency):
   - Phase A: Replace all overline patterns (20+ occurrences)
   - Phase B: Replace section headers (15+ occurrences)
   - Phase C: Replace pill/badge fonts (12+ occurrences)
   - Phase D: Replace metric displays (timer, XP, level)
   - Phase E: Replace body and caption

#### Files Changed

- `RNF/DesignSystem/Typography.swift`
- All files in `RNF/Features/` (incremental, no logic changes)
- All files in `RNF/Components/`

#### Dependencies

- None (pure refactor)

#### Risk Assessment

- Risk: LOW
- This is a visual refactor with zero logic impact
- Rollback: Git revert on typography file and view changes

#### Verification

- Visual regression: compare screenshots before/after across all screens
- Dynamic Type test at AX5 size
- No layout breakage at standard or accessibility sizes

---

### UX-03: Celebration Animation System Redesign

**Severity:** SEV-3  
**Impact:** Reward moments feel jarring — abrupt appearance, no choreography, `DispatchQueue` timing  
**Root Cause:** Overlays were built as MVP placeholders with hard-coded colors and no animation curves

#### Problem Statement

`ContentView.swift` has 4 celebration overlays (XP Gain, Level Up, Mission Complete, Badge Unlocked) that:

- Use `DispatchQueue.main.asyncAfter` instead of structured concurrency
- Have no entry/exit animation (just `.transition(.scale)`)
- Use flat colored backgrounds (`Color.yellow`, `Color.green`, `Color.purple`)
- Block interaction without proper dimming
- Don't respect Reduce Motion

#### Acceptance Criteria

- AC-1: XP gain SHALL use a top-anchored slide-in toast (non-blocking)
- AC-2: Level Up and Badge Unlocked SHALL use full-screen takeover with dimmed backdrop
- AC-3: Entry animation SHALL be spring with scale(0.8→1.0) + opacity(0→1) + vertical offset
- AC-4: Exit animation SHALL be opacity(1→0) + scale(1.0→0.95) over 0.3s ease-out
- AC-5: All animations SHALL respect `UIAccessibility.isReduceMotionEnabled` — instant show/hide when enabled
- AC-6: Timing SHALL use `Task.sleep` instead of `DispatchQueue.main.asyncAfter`
- AC-7: Mission Complete overlay SHALL trigger a subtle confetti particle effect (max 40 particles, 1.5s duration)

#### Implementation Plan

1. Create `RNF/Components/Overlays/XPGainToast.swift`:
   - Top-anchored HStack with icon + text
   - Slide in from top with spring, auto-dismiss after 1.5s
   - Does NOT block interaction

2. Create `RNF/Components/Overlays/CelebrationOverlay.swift`:
   - Reusable full-screen overlay with:
     - Background dim (Color.black.opacity(0.4))
     - Content card with blur material
     - Entry/exit transitions
     - Auto-dismiss with Task.sleep
   - Variants: `.levelUp`, `.missionComplete`, `.badgeUnlocked`

3. Create `RNF/Components/Overlays/ConfettiView.swift`:
   - Canvas-based particle system
   - 40 particles, physics-based fall
   - Respects Reduce Motion (skip entirely)

4. Refactor `ContentView.swift`:
   - Remove 4 inline overlay computed properties
   - Replace with `XPGainToast` and `CelebrationOverlay` components
   - Remove all `DispatchQueue.main.asyncAfter` calls

#### Files Changed

- `RNF/Components/Overlays/XPGainToast.swift` (new)
- `RNF/Components/Overlays/CelebrationOverlay.swift` (new)
- `RNF/Components/Overlays/ConfettiView.swift` (new)
- `RNF/Features/Habits/ContentView.swift`

#### Dependencies

- UX-01 (surface colors for overlay card background)

#### Risk Assessment

- Risk: LOW
- Visual-only change; ViewModel state transitions unchanged
- Rollback: Restore inline overlays from git history

#### Verification

- Trigger each overlay type in debug/preview
- Verify Reduce Motion path (Settings → Accessibility → Motion → Reduce Motion)
- Verify overlays dismiss correctly and don't stack
- Memory profile: confirm particles don't leak

---

### UX-04: Loading States & Skeleton Screens

**Severity:** SEV-2  
**Impact:** Data appears from nothing — no progressive disclosure, perceived slowness  
**Root Cause:** Views jump from empty to loaded with no intermediate state

#### Problem Statement

`AscensionView` loads 3 async data sources (challenge, perks, calendar). During loading:
- Cards show "No active perks" / "Not started" — looks like actual empty state
- No visual indication that data is being fetched
- User may interact with stale/empty UI thinking it's final state

Similar gaps in: `ContentView` (challenge summary), `SkillTreeView` (nodes), `ReadView` (on initial load).

#### Acceptance Criteria

- AC-1: A reusable `ShimmerModifier` SHALL be available in the design system
- AC-2: `AscensionView` MUST show shimmer placeholders for challenge, perks, and calendar sections while loading
- AC-3: `ContentView` MUST show shimmer for the challenge summary card while loading
- AC-4: Shimmer animation SHALL respect Reduce Motion (static grey placeholder when enabled)
- AC-5: Loading state SHALL be visually distinct from empty state (different copy, different appearance)
- AC-6: Maximum shimmer duration before timeout error: 10 seconds

#### Implementation Plan

1. Create `RNF/DesignSystem/ShimmerModifier.swift`:

```swift
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .overlay(shimmerGradient)
            .onAppear { if !reduceMotion { startAnimation() } }
    }
}

extension View {
    func shimmer(active: Bool) -> some View { ... }
}
```

2. Create placeholder shapes for each section:
   - `ChallengeSummaryPlaceholder` — matches challenge card dimensions
   - `PerkGridPlaceholder` — matches 2x2 grid layout
   - `CalendarPlaceholder` — matches grid height

3. Add loading booleans to `AscensionView`:
   - `isLoadingChallenge`, `isLoadingPerks` (already exists), `isLoadingCalendar`

4. Conditional render: `if isLoading { placeholder.shimmer(active: true) } else { actualContent }`

#### Files Changed

- `RNF/DesignSystem/ShimmerModifier.swift` (new)
- `RNF/Features/Ascension/AscensionView.swift`
- `RNF/Features/Habits/ContentView.swift`

#### Dependencies

- UX-01 (placeholder colors must adapt to dark mode)

#### Risk Assessment

- Risk: LOW
- Additive change; existing view logic unchanged
- Rollback: Remove shimmer modifier and conditional wrappers

#### Verification

- Simulate slow network (Network Link Conditioner: "Very Bad Network")
- Confirm shimmer appears, then transitions to real content
- Confirm Reduce Motion shows static placeholder (no animation)
- Confirm empty state copy differs from loading state copy

---

### UX-05: Design System Token Expansion

**Severity:** SEV-2  
**Impact:** 6 color tokens and 5 spacing tokens cannot support 30+ views consistently  
**Root Cause:** Design system was scaffolded early and never expanded alongside feature development

#### Problem Statement

Current `RNFColors` has 6 tokens. Views use 40+ unique inline colors. Current `RNFSpacing` has 5 values but views hardcode 14, 18, 20, 28 directly. This makes global theme changes impossible and dark mode fixes one-off.

#### Acceptance Criteria

- AC-1: `RNFColors` SHALL define semantic tokens for all surface, text, border, status, and stat categories
- AC-2: `RNFSpacing` SHALL cover all spacing values used in the codebase (no inline CGFloat literals)
- AC-3: A new `RNFRadius` constant set SHALL define all corner radii
- AC-4: A new `RNFShadow` utility SHALL define elevation levels
- AC-5: All tokens SHALL adapt to `ColorScheme` (light/dark)
- AC-6: Documentation SHALL list each token with usage guidance

#### Implementation Plan

1. Expand `RNF/DesignSystem/Colors.swift`:

```swift
struct RNFColors {
    // Brand
    static let primary = Color(hex: "#7C3AED")
    static let primaryLight = Color(hex: "#9B6BF7")

    // Status
    static let success = Color(hex: "#22A559")
    static let warning = Color(hex: "#D4940F")
    static let destructive = Color(hex: "#DC2626")

    // Surfaces (adaptive)
    static let surface = Color(.secondarySystemBackground)
    static let surfaceElevated = Color(.tertiarySystemBackground)
    static let surfacePressed = Color(.quaternarySystemFill)

    // Text (adaptive)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)

    // Borders (adaptive)
    static let border = Color(.separator)
    static let borderSubtle = Color(.separator).opacity(0.5)

    // Stats
    static let statStrength = Color(hex: "#D4940F")
    static let statDiscipline = Color(hex: "#7C3AED")
    static let statFocus = Color(hex: "#2563EB")
    static let statEnergy = Color(hex: "#DC2626")
    static let statWisdom = Color(hex: "#059669")
    static let statMind = Color(hex: "#7C3AED")
    static let statSpirit = Color(hex: "#8B5CF6")

    // Tints
    static let streak = Color(red: 0.9, green: 0.46, blue: 0.18)
    static let quest = Color(red: 0.3, green: 0.43, blue: 0.86)
    static let reading = Color(red: 0.73, green: 0.36, blue: 0.18)
}
```

2. Expand `RNF/DesignSystem/Spacing.swift`:

```swift
struct RNFSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48

    // Semantic
    static let cardPadding: CGFloat = 20
    static let cardSpacing: CGFloat = 14
    static let sectionSpacing: CGFloat = 18
}
```

3. Create `RNF/DesignSystem/Radius.swift`:

```swift
struct RNFRadius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let card: CGFloat = 28
}
```

4. Create `RNF/DesignSystem/Elevation.swift`:

```swift
struct RNFShadow {
    static func card() -> some View { ... }
    static func elevated() -> some View { ... }
}
```

#### Files Changed

- `RNF/DesignSystem/Colors.swift`
- `RNF/DesignSystem/Spacing.swift`
- `RNF/DesignSystem/Radius.swift` (new)
- `RNF/DesignSystem/Elevation.swift` (new)

#### Dependencies

- None (foundation for all other UX issues)

#### Risk Assessment

- Risk: LOW
- Purely additive; existing tokens unchanged
- Rollback: Delete new files, revert expansions

#### Verification

- Build succeeds with no unused variable warnings
- Existing views unchanged until migration (separate tasks)
- Token values match design system documentation


---

### UX-06: Workout Timer Experience Upgrade

**Severity:** SEV-3  
**Impact:** Timer screen is the longest single-screen session in the app — sterile experience reduces completion rate  
**Root Cause:** Timer was built as functional MVP with ProgressView and text — no immersive design

#### Problem Statement

`ActiveWorkoutTimerView.swift` displays a countdown timer with:
- Linear ProgressView (thin bar)
- Plain numeric display
- No ambient feedback as workout progresses
- No visual milestone at 80% threshold (the XP qualifying point)
- Completion state is a simple checkmark swap

Users spend 1-15 minutes staring at this screen. It must feel rewarding and immersive.

#### Acceptance Criteria

- AC-1: Timer SHALL display inside a circular progress ring (stroke width 12pt, rounded caps)
- AC-2: Ring color SHALL transition from `RNFColors.quest` (blue) at 0% to `RNFColors.success` (green) at 100%
- AC-3: At 80% completion threshold, ring SHALL pulse once (scale 1.0→1.05→1.0, 0.4s spring)
- AC-4: Background SHALL use a subtle radial gradient that intensifies (opacity 0.05→0.12) as timer progresses
- AC-5: Completion state SHALL show checkmark with scale-in spring animation + haptic `.success`
- AC-6: All animations SHALL respect Reduce Motion
- AC-7: Timer text SHALL use `RNFFont.metric` (monospaced digit)

#### Implementation Plan

1. Create `RNF/Components/CircularProgressRing.swift`:

```swift
struct CircularProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat = 12

    var body: some View {
        Circle()
            .stroke(trackColor, lineWidth: lineWidth)
            .overlay(
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            )
    }

    private var progressColor: Color {
        Color.interpolate(from: RNFColors.quest, to: RNFColors.success, progress: progress)
    }
}
```

2. Refactor `ActiveWorkoutTimerView.swift`:
   - Replace `ProgressView` with `CircularProgressRing`
   - Place timer text centered inside the ring
   - Add ambient radial gradient behind ring
   - Add 80% threshold pulse state
   - Replace completion content with animated entry

3. Add color interpolation extension:

```swift
extension Color {
    static func interpolate(from: Color, to: Color, progress: Double) -> Color { ... }
}
```

#### Files Changed

- `RNF/Components/CircularProgressRing.swift` (new)
- `RNF/Features/Workouts/ActiveWorkoutTimerView.swift`
- `RNF/Extensions/Color+Hex.swift` (add interpolation)

#### Dependencies

- UX-02 (metric font token)
- UX-05 (color tokens)

#### Risk Assessment

- Risk: LOW
- Visual change only; timer logic, completion detection, XP award unchanged
- Rollback: Restore original ProgressView layout

#### Verification

- Run timer to completion in simulator
- Verify ring fills smoothly without jank
- Verify 80% pulse fires exactly once
- Verify Reduce Motion skips pulse and gradient animation
- Verify completion haptic fires on device

---

### UX-07: Tab Bar Premium Elevation

**Severity:** SEV-3  
**Impact:** Default system TabView lacks premium feel; no active state differentiation  
**Root Cause:** `RootView.swift` uses stock TabView with no customization beyond toolbar background

#### Problem Statement

The tab bar is the persistent navigation frame. Users see it on every screen. Currently:
- Stock iOS TabView appearance
- No active indicator beyond tint color
- No badge for incomplete daily habits
- No animation on selection

#### Acceptance Criteria

- AC-1: Active tab SHALL have a subtle pill indicator (capsule background behind icon+label)
- AC-2: Tab selection SHALL animate with a gentle scale bounce (1.0→1.08→1.0, 0.2s spring)
- AC-3: Habits tab SHALL show a badge with remaining incomplete habit count (red dot if >0)
- AC-4: Tab bar background SHALL use `.ultraThinMaterial` for depth
- AC-5: All animations SHALL respect Reduce Motion
- AC-6: Tab bar MUST remain accessible (44pt tap targets, VoiceOver labels)

#### Implementation Plan

1. Create `RNF/Components/RNFTabBar.swift`:
   - Custom tab bar using `TabView` with `.tabViewStyle` or manual implementation
   - Each tab item: icon + label + conditional badge
   - Active state: capsule fill behind selected item
   - Selection change: withAnimation spring

2. Update `RNF/Navigation/RootView.swift`:
   - Replace stock TabView tab items with custom tab bar
   - Wire badge count from `GameState.dailyGoal - GameState.dailyCompleted`

3. Badge component:

```swift
struct TabBadge: View {
    let count: Int
    var body: some View {
        if count > 0 {
            Circle()
                .fill(RNFColors.destructive)
                .frame(width: 8, height: 8)
                .offset(x: 10, y: -8)
        }
    }
}
```

#### Files Changed

- `RNF/Components/RNFTabBar.swift` (new)
- `RNF/Navigation/RootView.swift`

#### Dependencies

- UX-05 (color tokens for badge and active indicator)

#### Risk Assessment

- Risk: MEDIUM
- Custom tab bar may have edge cases with NavigationStack interaction
- Must preserve existing tab routing behavior exactly
- Rollback: Revert to stock TabView (single file revert)

#### Verification

- Navigate to each tab — verify correct view displays
- Verify badge count updates live on habit completion
- Verify tab bar remains visible during NavigationLink push/pop
- VoiceOver: verify each tab announces name + badge count
- Landscape and iPad: verify layout doesn't break

---

### UX-08: Scroll Feedback & Depth

**Severity:** SEV-4  
**Impact:** Flat scrolling with no depth cues reduces premium perception  
**Root Cause:** Standard ScrollView with no scroll-position-aware effects

#### Problem Statement

All main screens (ContentView, AscensionView, WorkoutListView, ReadView) use plain ScrollView. The content scrolls uniformly with no:
- Header collapse/parallax
- Card entrance stagger
- Depth differentiation between hero section and list content

#### Acceptance Criteria

- AC-1: `ContentView` hero card ("TODAY'S FORGE") SHALL have subtle parallax (moves at 0.7x scroll speed)
- AC-2: `AscensionView` level badge glow SHALL scale down subtly as user scrolls past
- AC-3: Cards entering the viewport SHALL have a subtle opacity+offset entrance (iOS 17 `.scrollTransition`)
- AC-4: All scroll effects SHALL respect Reduce Motion (disabled when active)
- AC-5: Scroll effects MUST NOT impact scroll performance (no heavy redraws per frame)
- AC-6: Graceful degradation on iOS 16 (effects simply don't apply)

#### Implementation Plan

1. Create `RNF/DesignSystem/ScrollEffects.swift`:

```swift
extension View {
    @ViewBuilder
    func cardScrollEntrance() -> some View {
        if #available(iOS 17.0, *) {
            self.scrollTransition { content, phase in
                content
                    .opacity(phase.isIdentity ? 1 : 0.85)
                    .offset(y: phase.isIdentity ? 0 : 8)
            }
        } else {
            self
        }
    }
}
```

2. Add `GeometryReader` scroll offset tracking to hero sections:
   - ContentView: offset-based parallax on header card
   - AscensionView: scale glow circle based on scroll position

3. Apply `.cardScrollEntrance()` to list items in all scroll views

#### Files Changed

- `RNF/DesignSystem/ScrollEffects.swift` (new)
- `RNF/Features/Habits/ContentView.swift`
- `RNF/Features/Ascension/AscensionView.swift`
- `RNF/Features/Workouts/WorkoutListView.swift`
- `RNF/Features/Read/ReadView.swift`

#### Dependencies

- None (additive)

#### Risk Assessment

- Risk: LOW
- Purely visual; no logic changes
- iOS 16 fallback is identity (no-op)
- Rollback: Remove modifier calls and delete ScrollEffects.swift

#### Verification

- Scroll each screen smoothly — no frame drops (Instruments: Core Animation FPS)
- Verify parallax feels subtle (not nauseating)
- Verify Reduce Motion disables all scroll effects
- Verify iOS 16 simulator builds without error

---

### UX-09: Card Press Interaction Depth

**Severity:** SEV-4  
**Impact:** Workout cards and reading articles feel flat/static compared to habit rows  
**Root Cause:** `HabitRow` has scale animation + gradient but `WorkoutListView` and `ReadView` cards use plain `NavigationLink` with no press feedback

#### Problem Statement

`HabitRow` provides excellent press feedback:
- Scale effect on animation
- Gradient background shift on completion
- Shadow depth change

But tappable cards elsewhere have no press state:
- Workout buttons in `WorkoutListView`
- Reading article cards in `ReadView`
- Engagement links in `AscensionView`

This inconsistency breaks the premium feel.

#### Acceptance Criteria

- AC-1: All tappable cards SHALL use a shared `RNFCardButtonStyle` that provides press feedback
- AC-2: Press state SHALL scale to 0.97 with spring animation
- AC-3: Press state SHALL slightly reduce shadow radius (depth push effect)
- AC-4: Release SHALL spring back to 1.0
- AC-5: All animations SHALL respect Reduce Motion (instant state change)
- AC-6: ButtonStyle MUST NOT interfere with NavigationLink routing

#### Implementation Plan

1. Create `RNF/DesignSystem/RNFCardButtonStyle.swift`:

```swift
struct RNFCardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(
                reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7),
                value: configuration.isPressed
            )
    }
}
```

2. Apply to:
   - `WorkoutListView.workoutButton(for:compact:)` — replace `.buttonStyle(.plain)`
   - `ReadView` article cards — wrap in Button with RNFCardButtonStyle
   - `AscensionView.engagementLink` — replace `.buttonStyle(.plain)`

#### Files Changed

- `RNF/DesignSystem/RNFCardButtonStyle.swift` (new)
- `RNF/Features/Workouts/WorkoutListView.swift`
- `RNF/Features/Read/ReadView.swift`
- `RNF/Features/Ascension/AscensionView.swift`

#### Dependencies

- None

#### Risk Assessment

- Risk: LOW
- ButtonStyle is non-destructive; NavigationLink routing unaffected
- Rollback: Revert to `.buttonStyle(.plain)`

#### Verification

- Long-press each card — confirm scale down
- Release — confirm spring back
- Confirm NavigationLink still pushes correctly
- Confirm Reduce Motion skips animation

---

### UX-10: Onboarding Emotional Warmth

**Severity:** SEV-3  
**Impact:** Onboarding flow is the first impression — currently functional but emotionally flat  
**Root Cause:** Screens prioritized shipping over emotional design; no ambient motion or narrative progression

#### Problem Statement

The onboarding sequence (Splash → Login/Signup → Notifications → Commitment) is:
- Visually static (no motion on splash)
- No progress indicator across steps
- Commitment screen (the emotional peak) has no ambient warmth
- Login screen has no personality beyond "Welcome Back"

For a discipline/transformation app, the onboarding must feel like the beginning of a journey.

#### Acceptance Criteria

- AC-1: `SplashView` flame icon SHALL have a gentle breathing glow animation (scale 1.0→1.06, opacity cycle)
- AC-2: `CommitmentView` SHALL have a subtle warm gradient background pulse (amber→purple, 4s cycle)
- AC-3: Onboarding flow SHALL show step progress dots (current step highlighted) in a consistent position
- AC-4: All ambient animations SHALL respect Reduce Motion
- AC-5: Login/Signup screens SHALL show a subtle motivational subtext below the form (static, rotates per session)
- AC-6: Step indicator MUST be accessible (VoiceOver: "Step 2 of 4")

#### Implementation Plan

1. Create `RNF/Components/StepIndicator.swift`:

```swift
struct StepIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i == current ? RNFColors.primary : RNFColors.borderSubtle)
                    .frame(width: i == current ? 10 : 6, height: i == current ? 10 : 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }
}
```

2. Update `SplashView.swift`:
   - Add breathing animation to flame icon (scale + opacity with repeatForever)
   - Guard with Reduce Motion

3. Update `CommitmentView.swift`:
   - Add animated radial gradient background (warm amber center → deep purple edges)
   - Subtle opacity oscillation (0.08→0.15, 4s easeInOut)

4. Update `LoginView.swift` and `SignUpView.swift`:
   - Add motivational line array, select by hash of date
   - Display below form fields in caption style

5. Wire `StepIndicator` into onboarding navigation (Splash=0, Auth=1, Notifications=2, Commitment=3)

#### Files Changed

- `RNF/Components/StepIndicator.swift` (new)
- `RNF/Features/Onboarding/SplashView.swift`
- `RNF/Features/Onboarding/CommitmentView.swift`
- `RNF/Features/Onboarding/LoginView.swift`
- `RNF/Features/Onboarding/SignUpView.swift`

#### Dependencies

- UX-05 (color tokens)
- UX-01 (dark mode safe gradients)

#### Risk Assessment

- Risk: LOW
- Additive visual changes; onboarding routing logic unchanged
- Rollback: Remove animation modifiers and step indicator

#### Verification

- Walk through full onboarding flow in simulator
- Verify step dots advance correctly
- Verify breathing animation on splash (and absence with Reduce Motion)
- Verify commitment gradient doesn't obscure text readability (contrast check)
- Verify motivational text doesn't overflow at AX5 Dynamic Type


---

### UX-11: Calendar Interactivity & Streak Visualization

**Severity:** SEV-3  
**Impact:** Calendar is display-only; users can't explore their history or feel streak momentum  
**Root Cause:** `CalendarGridView` was built as a read-only status display with no tap handlers or visual streak continuity

#### Problem Statement

The calendar grid shows colored day cells but:
- Cells are not tappable (no day detail exploration)
- No visual continuity between consecutive completed days (streak trail)
- Current day has a border but no animation drawing attention
- No "personal best week" or achievement highlight

For a discipline app, the calendar IS the trophy case. It should feel alive.

#### Acceptance Criteria

- AC-1: Day cells SHALL be tappable — tap reveals a bottom sheet with that day's summary (habits completed, XP earned, status)
- AC-2: Consecutive completed days SHALL show a connecting visual (horizontal bar between cells, or continuous background highlight on the row)
- AC-3: Current day cell SHALL have a subtle pulse animation (border opacity cycle, 2s)
- AC-4: The week with most completions SHALL have a subtle gold accent (border or background tint)
- AC-5: All animations SHALL respect Reduce Motion
- AC-6: Day detail sheet SHALL be accessible (VoiceOver reads full day summary)
- AC-7: Tap target for day cells MUST meet 44pt minimum (cells may need padding adjustment)

#### Implementation Plan

1. Add tap handler to `CalendarDayCell`:
   - Wrap in `Button` with action callback passing the date
   - Parent view handles sheet presentation

2. Create `RNF/Components/DayDetailSheet.swift`:
   - Shows date, status, habits completed that day, XP earned
   - Data source: `CalendarService.getMonthLogs` (already loaded)
   - Presentable as `.sheet` from `AscensionView`

3. Add streak connector visual:
   - After rendering day cells, overlay horizontal connector bars between consecutive `.complete`/`.forgiven` days
   - Use `Color.green.opacity(0.3)` capsule between adjacent cells

4. Add today pulse:
   - `CalendarDayCell` detects `isToday` and applies repeating border opacity animation

5. Add best-week highlight:
   - Compute per-row completion count
   - Row with highest count gets a subtle gold background (`RNFColors.streak.opacity(0.08)`)

#### Files Changed

- `RNF/Components/CalendarGridView.swift`
- `RNF/Components/DayDetailSheet.swift` (new)
- `RNF/Features/Ascension/AscensionView.swift` (sheet binding)

#### Dependencies

- UX-01 (dark mode safe colors)
- UX-05 (color tokens)
- Existing `CalendarService` data (no new backend calls needed for basic detail)

#### Risk Assessment

- Risk: LOW-MEDIUM
- Adding tap handlers to grid items may need careful hit testing
- Sheet presentation adds state management
- Rollback: Remove button wrappers and sheet, restore static cells

#### Verification

- Tap each day cell — verify sheet appears with correct date
- Verify streak connector shows between consecutive green days
- Verify today pulse animates (and doesn't when Reduce Motion on)
- Verify 44pt tap targets with Accessibility Inspector
- Verify sheet dismisses cleanly without state corruption

---

### UX-12: Radar Chart Enhancement

**Severity:** SEV-4  
**Impact:** Radar chart is the primary stat visualization — currently minimal and static  
**Root Cause:** `DisciplineRadarChart` uses basic Path fill with no labels, data points, or animation

#### Problem Statement

The radar chart shows 7 stats but:
- No axis labels visible on the chart (labels exist in code but aren't rendered)
- No data point dots at vertices
- No entry animation when chart appears
- No comparison state (previous values as ghost shape)
- Flat opacity fill with no gradient

#### Acceptance Criteria

- AC-1: Axis labels SHALL be rendered at each vertex outside the chart radius
- AC-2: Data point dots (6pt circles) SHALL appear at each vertex on the shape edge
- AC-3: Chart shape SHALL animate from center (all zeros) to actual values on appear (0.5s spring)
- AC-4: Fill SHALL use a radial gradient (center: primary.opacity(0.15), edge: primary.opacity(0.4))
- AC-5: `Animatable` conformance on `RadarShape` SHALL enable smooth morphing when stats update
- AC-6: Animation SHALL respect Reduce Motion (instant render when enabled)
- AC-7: VoiceOver accessibility label SHALL list all stat names and values

#### Implementation Plan

1. Add `Animatable` to `RadarShape`:

```swift
struct RadarShape: Shape {
    var values: [Double]
    var animatableData: AnimatablePair<...> { ... }
    // Use AnimatableVector or manual pairs for 7 values
}
```

2. Render labels at vertex positions:
   - Calculate label position at 1.15x radius from center
   - Align text toward center
   - Use `RNFFont.caption`

3. Add data point overlay:
   - ForEach over vertices, place Circle at calculated point

4. Replace `.fill(Color.purple.opacity(0.4))` with radial gradient

5. Add `.onAppear` animation from zero values to actual (with Reduce Motion guard)

#### Files Changed

- `RNF/Components/DisciplineRadarChart.swift`

#### Dependencies

- UX-02 (font tokens for labels)
- UX-05 (color tokens)

#### Risk Assessment

- Risk: LOW
- Self-contained component; no external dependencies
- `Animatable` for 7 values requires custom AnimatableVector (known pattern)
- Rollback: Restore original RadarShape implementation

#### Verification

- Preview with test stat values — labels visible and correctly positioned
- Change stat values — verify smooth morph animation
- Verify Reduce Motion shows instant render
- Verify VoiceOver reads all 7 stats with values
- Verify chart renders correctly at small sizes (240pt frame)

---

### UX-13: Toast & Notification System Redesign

**Severity:** SEV-3  
**Impact:** Reward notifications block interaction and feel like error alerts, not celebrations  
**Root Cause:** Overlays are full-screen VStacks with solid color backgrounds, no layered design

#### Problem Statement

Current celebration overlays:
- Block all interaction (full-screen Group)
- Look like system alerts (solid yellow/green/purple rectangles)
- All use the same visual treatment regardless of importance
- No notification hierarchy (XP gain same prominence as level-up)

A premium app needs tiered notifications:
- **Passive:** XP gains, stat changes — non-blocking toast
- **Celebratory:** Level up, badge unlock — full-screen takeover (rare)
- **Informational:** Errors, offline, forgiveness — banner

#### Acceptance Criteria

- AC-1: `RNFToast` component for passive notifications (top-anchored, auto-dismiss, non-blocking)
- AC-2: `RNFCelebration` component for rare milestone events (full-screen, dimmed backdrop, auto-dismiss)
- AC-3: `RNFBanner` component for informational messages (existing ErrorBanner already covers this)
- AC-4: Toast queue SHALL prevent stacking — max 1 visible, queue subsequent with 0.5s gap
- AC-5: Celebration SHALL have material blur backdrop (not solid color)
- AC-6: All components SHALL have coordinated entry/exit animations
- AC-7: A single `NotificationManager` ObservableObject SHALL manage the queue

#### Implementation Plan

1. Create `RNF/Core/NotificationManager.swift`:

```swift
@MainActor
final class NotificationManager: ObservableObject {
    enum Notification {
        case toast(icon: String, message: String, tint: Color)
        case celebration(title: String, subtitle: String, type: CelebrationType)
    }

    enum CelebrationType { case levelUp, missionComplete, badgeUnlocked }

    @Published var currentToast: Notification?
    @Published var currentCelebration: Notification?

    func show(_ notification: Notification) { ... }
}
```

2. Create `RNF/Components/Overlays/RNFToast.swift`:
   - Top-anchored HStack: icon + message + XP amount
   - Slide in from top, auto-dismiss 2s
   - Non-blocking (no background dim)
   - Capsule shape with material background

3. Create `RNF/Components/Overlays/RNFCelebration.swift`:
   - Full-screen ZStack with `.ultraThinMaterial` dim
   - Content card with:
     - Type-specific icon (large, colored)
     - Title + subtitle
     - Auto-dismiss 3s or tap to dismiss
   - Entry: scale(0.85→1.0) + opacity spring
   - Exit: opacity fade 0.3s

4. Attach overlays at `RootView` level (not per-screen):

```swift
struct RootView: View {
    @StateObject private var notifications = NotificationManager()

    var body: some View {
        TabView { ... }
            .overlay(alignment: .top) { RNFToast(...) }
            .overlay { RNFCelebration(...) }
            .environmentObject(notifications)
    }
}
```

5. Refactor `HabitsViewModel` to fire notifications through `NotificationManager` instead of local state

#### Files Changed

- `RNF/Core/NotificationManager.swift` (new)
- `RNF/Components/Overlays/RNFToast.swift` (new)
- `RNF/Components/Overlays/RNFCelebration.swift` (new)
- `RNF/Navigation/RootView.swift`
- `RNF/ViewModels/HabitsViewModel.swift`
- `RNF/Features/Habits/ContentView.swift` (remove inline overlays)

#### Dependencies

- UX-03 (celebration animations defined there; this issue is the system architecture)
- UX-05 (color tokens)

#### Risk Assessment

- Risk: MEDIUM
- Moving notification state from ViewModel to shared manager changes data flow
- Must ensure no race conditions with rapid completions
- Rollback: Restore inline overlays in ContentView, remove NotificationManager

#### Verification

- Complete 3 habits rapidly — verify toasts queue (no overlap)
- Trigger level-up — verify full-screen celebration appears
- Verify celebration doesn't block tab bar interaction after dismiss
- Verify notifications fire correctly from any tab (workout XP, reading XP)
- Memory: no retained overlays after dismiss

---

### UX-14: Micro-Interaction Polish

**Severity:** SEV-4  
**Impact:** Missing feedback at key moments reduces sense of progress  
**Root Cause:** State changes happen without corresponding visual acknowledgment

#### Problem Statement

Several high-impact moments have no micro-feedback:

1. **Daily mission bar completes** — fills to 100% but no flash/shimmer
2. **XP bar gains XP** — jumps to new value, no smooth fill animation
3. **Forgiveness used** — message appears but calendar cell doesn't visually update in real-time
4. **All daily quests completed** — no special visual beyond mission complete overlay
5. **Streak increments** — number changes but no pulse

#### Acceptance Criteria

- AC-1: `DailyMissionBar` SHALL shimmer/flash when progress reaches 1.0 (100%)
- AC-2: `XPBar` progress fill SHALL animate smoothly with `.spring()` when XP value changes
- AC-3: Forgiveness calendar cell SHALL flash green briefly when status changes to `.forgiven`
- AC-4: Streak pill SHALL briefly scale(1.12) + haptic when value increments
- AC-5: All micro-interactions SHALL respect Reduce Motion
- AC-6: Animations SHALL be < 0.5s duration (subtle, not distracting)

#### Implementation Plan

1. `DailyMissionBar.swift`:
   - Add `@State private var isComplete` derived from `completed >= goal`
   - When transitions to true: overlay shimmer gradient sweep (left→right, 0.4s)
   - Guard with Reduce Motion

2. `XPBar.swift`:
   - Add `.animation(.spring(response: 0.4), value: xp)` to the progress Capsule frame width
   - Already uses GeometryReader — animation will smoothly interpolate

3. `CalendarGridView.swift`:
   - Add flash overlay on cell when status changes (use `.onChange(of: statusesByDay)`)
   - Brief green opacity pulse (0→0.4→0, 0.3s)

4. `ContentView.swift` streak pill:
   - Add `.onChange(of: game.streak)` → set `streakBumped = true` → scale 1.12 → reset after 0.3s
   - Add haptic `.impact(.light)` on increment

#### Files Changed

- `RNF/Components/DailyMissionBar.swift`
- `RNF/Components/XPBar.swift`
- `RNF/Components/CalendarGridView.swift`
- `RNF/Features/Habits/ContentView.swift`

#### Dependencies

- UX-05 (color tokens for flash colors)

#### Risk Assessment

- Risk: LOW
- All changes are additive view modifiers
- No logic changes
- Rollback: Remove animation modifiers

#### Verification

- Complete final habit → mission bar shimmer fires
- Award XP → bar animates smoothly (not jumping)
- Use forgiveness → calendar cell flashes
- Streak increment → pill bounces
- All disabled cleanly with Reduce Motion on

---

### UX-15: Haptic Feedback Expansion

**Severity:** SEV-4  
**Impact:** Limited haptic vocabulary reduces tactile premium feel  
**Root Cause:** Only habit completion, level-up, and streak milestone have haptics (P15-UX-01/02/03)

#### Problem Statement

Haptics currently fire for:
- Habit completion (success)
- Level-up (notification success)
- Streak milestone (notification success)

Missing haptic moments:
- Workout timer start/pause/resume (no tactile acknowledgment)
- Workout timer 80% threshold reached
- Workout completion
- Reading proof submission
- Forgiveness token used
- Tab switching
- Boss damage dealt
- Button presses on primary actions

#### Acceptance Criteria

- AC-1: Create a centralized `RNFHaptics` utility with semantic methods
- AC-2: Workout start SHALL fire `.impact(.medium)`
- AC-3: Workout pause/resume SHALL fire `.impact(.light)`
- AC-4: Workout 80% threshold SHALL fire `.impact(.rigid)` once
- AC-5: Workout/reading completion SHALL fire `.notification(.success)`
- AC-6: Forgiveness use SHALL fire `.notification(.warning)`
- AC-7: Boss damage dealt SHALL fire `.impact(.heavy)`
- AC-8: Primary button actions (Begin Day 1, Submit, Continue) SHALL fire `.impact(.soft)`
- AC-9: All haptics SHALL be no-ops on simulator and when system haptics are disabled

#### Implementation Plan

1. Create `RNF/Core/RNFHaptics.swift`:

```swift
import UIKit

enum RNFHaptics {
    static func buttonTap() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func threshold() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
}
```

2. Wire into views:
   - `ActiveWorkoutTimerView`: start/pause/resume/80%/completion
   - `ReadView.submitProof()`: on success
   - `AscensionView.useForgiveness()`: on use
   - `CommitmentView.onBegin`: button tap
   - `LoginView.login()`: button tap
   - `BossBattleView`: on damage

#### Files Changed

- `RNF/Core/RNFHaptics.swift` (new)
- `RNF/Features/Workouts/ActiveWorkoutTimerView.swift`
- `RNF/Features/Read/ReadView.swift`
- `RNF/Features/Ascension/AscensionView.swift`
- `RNF/Features/Onboarding/CommitmentView.swift`
- `RNF/Features/Onboarding/LoginView.swift`
- `RNF/Features/Boss/BossBattleView.swift`

#### Dependencies

- None

#### Risk Assessment

- Risk: LOW
- Single-line additions at trigger points
- No logic changes
- Rollback: Remove haptic calls or delete RNFHaptics.swift

#### Verification

- Test on physical device (haptics don't fire on simulator)
- Verify each trigger point fires correct haptic type
- Verify no double-fires on rapid interaction
- Verify no haptics fire when system haptics are disabled (Settings → Sounds & Haptics)

---

## Dependency Graph

```
UX-05 (Design System Tokens)
├── UX-01 (Dark Mode Fix) ← HIGHEST PRIORITY
│   ├── UX-04 (Loading Skeletons)
│   ├── UX-10 (Onboarding Warmth)
│   └── UX-11 (Calendar Interactivity)
├── UX-02 (Typography)
│   ├── UX-06 (Workout Timer Ring)
│   └── UX-12 (Radar Chart)
├── UX-07 (Tab Bar)
├── UX-09 (Card Press)
├── UX-13 (Toast System)
│   └── UX-03 (Celebration Animations)
└── UX-14 (Micro-Interactions)

UX-08 (Scroll Effects) ← Independent
UX-15 (Haptics) ← Independent
```

## Execution Order

Based on dependencies and priority:

| Sprint | Issues | Rationale |
|--------|--------|-----------|
| Sprint 1 | UX-05, UX-01 | Foundation + ship-blocking bug |
| Sprint 2 | UX-02, UX-15 | Typography system + quick haptic wins |
| Sprint 3 | UX-04, UX-09 | Loading states + press feedback |
| Sprint 4 | UX-03, UX-13 | Celebration + notification architecture |
| Sprint 5 | UX-06, UX-14 | Timer upgrade + micro-interactions |
| Sprint 6 | UX-07, UX-10 | Tab bar + onboarding |
| Sprint 7 | UX-08, UX-11, UX-12 | Scroll effects + calendar + radar |

## Definition of Done (per issue)

- [ ] All acceptance criteria pass
- [ ] Build succeeds on Xcode with zero warnings
- [ ] Dark mode visual verification (screenshot)
- [ ] Light mode visual verification (screenshot)
- [ ] Reduce Motion path verified
- [ ] VoiceOver tested on affected screens
- [ ] Dynamic Type AX3 tested
- [ ] No performance regression (60fps scroll maintained)
- [ ] Code reviewed by at least 1 peer
- [ ] PR description references this spec and issue number

## Task Graph Integration

These issues should be added to `task_graph.md` as Phase 19 with proper dependency notation following the established `[x]`/`[ ]` format and ID scheme `P19-UX-XX`.
