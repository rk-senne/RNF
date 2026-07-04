# SPEC: Onboarding Redesign — First-Session Experience

Version: 1.0  
Status: DRAFT  
Priority: P0  
Date: 2026-07-03  
Owner: RNF Core Team

---

## Problem Statement

RNF's current onboarding flow asks users to commit to a 90-day discipline challenge before they have experienced any reward, progression, or identity formation. The commitment screen (checkbox + legal language) feels like signing a contract rather than beginning a journey.

Current failure points:

- Users encounter the "Commit to 90 Days" screen within seconds of installing the app.
- No XP, no level, no character feedback has occurred before this moment.
- Users who have tried and quit other habit apps see "90 days" and immediately bounce.
- The login/signup flow lacks clear navigation between states.
- There is no progressive disclosure — all systems are introduced simultaneously.

The result: high drop-off at commitment, low Day 0→1 retention, and no psychological hook anchoring users to the app.

---

## Design Philosophy

RNF's onboarding must follow these principles:

**1. Reward before commitment.**  
The user must feel the RPG loop (action → XP → progression) before being asked to invest time or identity.

**2. Identity before registration.**  
By the time the user creates an account, they should already feel like "this app understands me." Psychological ownership precedes technical ownership.

**3. Game moment, not form submission.**  
Every onboarding step should feel like a scene in a game, not a step in a signup wizard. Replace forms with forge moments.

**4. Progressive complexity.**  
Day 1 is radically simple. Features unlock over days, not during onboarding. Complexity is earned.

**5. Multiple entry ramps.**  
Not everyone is ready for 90 days. Provide 7-day and 3-day tryout modes that ladder into the full commitment.

**6. Calm discipline aesthetic.**  
Animations exist to reinforce identity ("I am leveling up"), not to entertain. The Forge ignites — it does not celebrate with confetti.

---

## User Journey Overview

```
Install → Splash → Try 1 Habit (Guest) → XP Animation → Archetype Quiz
→ Commitment Reframe (Forge Ignition) → Account Creation → First-Session Victory
→ Day 1 Complete Screen → Progressive Feature Unlock (Days 3, 7, 14)
```

Alternative paths:

```
[Returning user] → Splash → Login → Home
[Low-commitment user] → Splash → Try 1 Habit → 7-Day Mode → (Day 7 upsell) → 90-Day Commit
[Guest tryout] → Splash → Try 1 Habit → Use app 3 days → Account prompt with data preservation
```

---

## Section 1: Try-Before-Commit Flow

### Problem

Users are asked to commit to 90 days of daily discipline before experiencing any reward. This is the equivalent of asking someone to sign a gym contract before letting them touch a weight. The result is immediate bounce from users who have been burned by other habit apps.

### Solution

Let the user complete 1 habit and experience the core RPG loop (action → XP → feedback) BEFORE creating an account or making any commitment.

### Detailed Flow

#### Screen 1A: Splash (Existing — Modified)

- Duration: 1.5s
- Display: RNF logo + tagline "Turn daily habits into lasting discipline."
- Modification: After splash, route NEW users to Try-Before-Commit flow instead of Login.
- Returning users with stored session → Home.

#### Screen 1B: Choose Your First Action

- Header: "Choose one habit to try right now."
- Subtext: "No account needed. Just try it."
- Display 3–4 simple habits as tappable cards:
  - 💧 Drink a glass of water
  - 🧘 Take 3 deep breaths
  - 📖 Read 1 page of anything
  - 💪 Do 5 push-ups
- Each card shows: habit name, emoji icon, "+10 XP" badge
- Single-select. User taps one.
- Bottom CTA: "Complete It" (disabled until selection made)

**Design notes:**
- Cards use standard RNF card style (16pt radius, subtle shadow)
- Background: dark mode default (#121212)
- Accent on selected card: RNF Purple border glow (#6E2BD9)
- No account creation, no email field, no password — zero friction

#### Screen 1C: Habit Completion Confirmation

- After tapping "Complete It":
  - Brief haptic: `.success` feedback
  - Card animates to "completed" state (green check, slight scale pulse)
  - Prompt: "Did you do it?" → "Yes, I did" button
  - This is an honor-system confirmation (consistent with RNF's existing habit model)

#### Screen 1D: XP Reward Animation

- Full-screen moment. This is the hook.
- Animation sequence (1.5–2s total):
  1. "+10 XP" floats up from center with spring animation
  2. XP bar appears at top, fills from 0 to 10/200 (Level 1 progress)
  3. Subtle purple aura pulse behind the XP text
  4. Haptic: medium impact feedback on XP bar fill
  5. Text fades in below: **"That's what leveling up feels like."**
- Pause 1s, then:
  - CTA: "Ready to forge your discipline?" → proceeds to Archetype Quiz
  - Secondary link: "Just exploring" → enters Guest Tryout Mode

**Design notes:**
- XP animation uses `easeInOut` spring curve
- Purple glow matches RNF accent (#6E2BD9, 40% opacity radial)
- No confetti. No sound effects. Calm power.
- The XP bar is a preview of the real XP bar they'll use daily

### Guest Tryout Mode (3-Day Trial)

If user taps "Just exploring":

- App enters Guest Mode with local-only data storage
- User can complete habits, earn XP, see levels — all stored in UserDefaults/local Core Data
- After 3 days of use OR when user attempts to access a gated feature:
  - Prompt: "Your progress is real. Create an account to keep it."
  - All local data (XP, completions, streak) is preserved and synced to Supabase on account creation
- Guest mode limitations:
  - No cloud sync
  - No social features (future)
  - No subscription access
  - Calendar shows only local data
  - Banner at top of Home: "Guest Mode — [Create Account] to save your progress"

**Data preservation contract:**
- `GuestDataStore` holds: habits completed, XP earned, streak count, archetype answers
- On account creation: `GuestMigrationService.migrateToAccount(userId:)` syncs all local data to Supabase
- If user uninstalls without creating account: data is lost (acceptable — they weren't committed)

### Technical Implementation

| Component | File | Responsibility |
|-----------|------|----------------|
| `TryBeforeCommitView` | `Views/Onboarding/TryBeforeCommitView.swift` | Habit selection + completion |
| `XPRewardAnimationView` | `Views/Onboarding/XPRewardAnimationView.swift` | XP animation moment |
| `GuestDataStore` | `Services/GuestDataStore.swift` | Local guest data persistence |
| `GuestMigrationService` | `Services/GuestMigrationService.swift` | Migrate guest → authenticated |
| `OnboardingCoordinator` | `ViewModels/OnboardingCoordinator.swift` | Flow state machine |

### Acceptance Criteria

- AC-1.1: New user sees habit selection within 3 seconds of splash completing
- AC-1.2: No account creation required before experiencing XP reward
- AC-1.3: XP animation includes haptic feedback (UIImpactFeedbackGenerator)
- AC-1.4: XP bar visually fills from 0 to earned amount
- AC-1.5: Guest mode persists data locally for up to 3 days
- AC-1.6: Account creation preserves all guest data (XP, streak, completions)
- AC-1.7: Guest mode banner is visible on Home screen
- AC-1.8: "Just exploring" path does not dead-end — user can always reach account creation

---

## Section 2: Identity Seed / Archetype Quiz

### Problem

Generic onboarding creates no psychological ownership. Users feel like they downloaded another generic habit tracker. There is no moment where the app demonstrates it understands who they are.

### Solution

A 3-question rapid archetype quiz that generates a personalized starting identity. The quiz takes <30 seconds and produces a unique archetype name + stat distribution hint. The user immediately feels: "this app gets me."

### Detailed Flow

#### Screen 2A: Quiz Introduction

- Header: "Before we forge, let's find your shape."
- Subtext: "3 quick questions. No wrong answers."
- Visual: Subtle radar chart outline (empty) pulses in background
- CTA: "Begin" → first question

#### Screen 2B: Question 1 — Core Struggle

- Text: "What holds you back most?"
- Options (large tappable cards, single-select):
  - 🔄 **Consistency** — "I start strong but fade"
  - 🔥 **Motivation** — "I can't find the spark"
  - 🎯 **Focus** — "I get pulled in every direction"
- Selection triggers subtle haptic (`.light`)
- Auto-advances after 0.5s delay

#### Screen 2C: Question 2 — Rhythm

- Text: "When are you at your sharpest?"
- Options:
  - 🌅 **Morning** — "I conquer the day early"
  - 🌙 **Night** — "I come alive after dark"
  - ⚖️ **Balanced** — "Depends on the day"
- Same interaction pattern as Q1

#### Screen 2D: Question 3 — Priority

- Text: "What do you want to build first?"
- Options:
  - 💪 **Body** — Physical strength and endurance
  - 🧠 **Mind** — Mental clarity and focus
  - 🕊️ **Spirit** — Inner peace and discipline
- Same interaction pattern

#### Screen 2E: Archetype Reveal

- Dramatic pause (0.8s dark screen)
- Archetype name fades in with purple glow:
  - Example: **"Dawn Striker"** or **"Shadow Scholar"** or **"Iron Monk"**
- Below name: stat hint visualization (mini radar chart with 2–3 stats highlighted)
- Text: "Your forge has a shape. Now let's ignite it."
- CTA: "Continue" → proceeds to Commitment Reframe

### Archetype Generation Logic

Archetypes are determined by the combination of answers:

| Struggle | Rhythm | Priority | Archetype | Primary Stats |
|----------|--------|----------|-----------|---------------|
| Consistency | Morning | Body | Dawn Striker | Strength, Discipline |
| Consistency | Morning | Mind | Dawn Scholar | Focus, Discipline |
| Consistency | Morning | Spirit | Dawn Monk | Wisdom, Discipline |
| Consistency | Night | Body | Shadow Warrior | Strength, Energy |
| Consistency | Night | Mind | Shadow Strategist | Focus, Energy |
| Consistency | Night | Spirit | Shadow Sage | Wisdom, Spirit |
| Consistency | Balanced | Body | Iron Titan | Strength, Discipline |
| Consistency | Balanced | Mind | Iron Analyst | Focus, Mind |
| Consistency | Balanced | Spirit | Iron Monk | Spirit, Discipline |
| Motivation | Morning | Body | Flame Striker | Strength, Energy |
| Motivation | Morning | Mind | Flame Seeker | Focus, Energy |
| Motivation | Morning | Spirit | Flame Pilgrim | Spirit, Energy |
| Motivation | Night | Body | Ember Warrior | Strength, Mind |
| Motivation | Night | Mind | Ember Architect | Mind, Focus |
| Motivation | Night | Spirit | Ember Mystic | Spirit, Wisdom |
| Motivation | Balanced | Body | Rising Titan | Strength, Energy |
| Motivation | Balanced | Mind | Rising Mind | Mind, Focus |
| Motivation | Balanced | Spirit | Rising Soul | Spirit, Wisdom |
| Focus | Morning | Body | Precision Striker | Discipline, Strength |
| Focus | Morning | Mind | Precision Scholar | Discipline, Focus |
| Focus | Morning | Spirit | Precision Ascetic | Discipline, Wisdom |
| Focus | Night | Body | Silent Warrior | Focus, Strength |
| Focus | Night | Mind | Silent Thinker | Focus, Mind |
| Focus | Night | Spirit | Silent Wanderer | Focus, Spirit |
| Focus | Balanced | Body | Steady Titan | Discipline, Strength |
| Focus | Balanced | Mind | Steady Sage | Discipline, Mind |
| Focus | Balanced | Spirit | Steady Ascendant | Discipline, Spirit |

Total: 27 archetypes covering all combinations.

### Stat Distribution Hint

The archetype does NOT mechanically change starting stats (all users start at 0). It provides:

- A **visual hint** showing which stats will grow fastest based on recommended habits
- Suggested habit focus during first week (e.g., "Your path favors morning workouts and reading")
- The archetype name appears in the user's profile as their "Forge Identity"

### Technical Implementation

| Component | File | Responsibility |
|-----------|------|----------------|
| `ArchetypeQuizView` | `Views/Onboarding/ArchetypeQuizView.swift` | Quiz flow UI |
| `ArchetypeRevealView` | `Views/Onboarding/ArchetypeRevealView.swift` | Reveal animation |
| `ArchetypeSystem` | `Systems/ArchetypeSystem.swift` | Answer → archetype mapping |
| `Archetype.swift` | `Models/Archetype.swift` | Archetype model |

### Data Model

```swift
struct Archetype: Codable {
    let name: String              // "Dawn Striker"
    let primaryStats: [String]    // ["strength", "discipline"]
    let struggle: Struggle
    let rhythm: Rhythm
    let priority: Priority
}

enum Struggle: String, Codable {
    case consistency, motivation, focus
}

enum Rhythm: String, Codable {
    case morning, night, balanced
}

enum Priority: String, Codable {
    case body, mind, spirit
}
```

Database: stored in `profiles.archetype_name` and `profiles.archetype_data` (JSONB).

### Acceptance Criteria

- AC-2.1: Quiz completes in ≤30 seconds for average user
- AC-2.2: Exactly 3 questions, each with exactly 3 options
- AC-2.3: All 27 answer combinations produce a unique archetype name
- AC-2.4: Archetype reveal includes animation (fade + glow)
- AC-2.5: Archetype name persists to user profile
- AC-2.6: Stat hint visualization uses mini radar chart
- AC-2.7: Quiz answers are preserved in guest mode for later sync
- AC-2.8: Back navigation allowed between questions (swipe back)

---

## Section 3: Commitment Reframe

### Problem

The current commitment screen uses a checkbox and legal-style language: "I understand this requires daily consistency." This reads like a terms-of-service agreement, not the beginning of a transformative journey. It creates anxiety rather than excitement.

### Solution

Replace the form-style commitment with a game moment — the Forge Ignition. The user chooses their forge name, the forge ignites, and Day 1 begins. No checkbox. No legal language. A ritual.

### Detailed Flow

#### Screen 3A: Choose Your Forge Name

- Header: "Choose your forge name."
- Subtext: "This is how The Forge will address you."
- Input field: username/display name (text field, max 20 characters)
  - Placeholder: "Enter your name..."
  - Validation: alphanumeric + spaces, 2–20 chars, no profanity filter needed (personal app)
- Below input: Archetype displayed: "Dawn Striker" (from quiz)
- Visual: The forge (represented as a stylized anvil/flame icon) sits dormant in background, dim purple
- CTA: "Ignite The Forge" (enabled when name is valid)

**Design notes:**
- Input field uses RNF styling: dark background, purple accent underline on focus
- The forge icon is a custom asset — a minimalist anvil with a dormant ember
- No "terms and conditions" language anywhere

#### Screen 3B: Forge Ignition (The Commitment Moment)

This is the emotional peak of onboarding. This replaces the checkbox.

- Triggered when user taps "Ignite The Forge"
- Animation sequence (2.5–3s):
  1. Screen dims to near-black (0.3s)
  2. Forge icon in center begins to glow (ember → orange → purple flame) (1s)
  3. Haptic: heavy impact at ignition peak
  4. Radial purple light expands outward from forge (0.5s)
  5. Text appears letter by letter: **"The Forge activates for 90 days."** (0.8s)
  6. Below, smaller: **"Day 1 begins now."**
  7. Haptic: soft success feedback
- After animation completes (hold 1.5s):
  - Transition to account creation OR first-session victory (if already authenticated)

**Design notes:**
- Animation uses Core Animation / SwiftUI `.animation(.spring())` combinations
- The forge glow is a radial gradient: center `#6E2BD9` → transparent
- Support `Reduce Motion`: if enabled, skip animation → display static ignited forge + text immediately
- The forge ignition moment is screenshot-worthy — users should want to share this

#### Screen 3C: Commitment Mode Selection (Branching)

For users who came through the standard path:
- Proceed to account creation (Section 7)

For users who chose "7-Day Mode" (Section 6):
- Same forge ignition but text reads: **"The Forge sparks for 7 days. Prove yourself."**
- Visually: smaller flame, amber instead of full purple

### Commitment Data

On forge ignition, the system records:

```swift
struct ForgeCommitment {
    let forgeName: String           // User-chosen name
    let archetypeName: String       // From quiz
    let commitmentDays: Int         // 90 or 7
    let ignitedAt: Date             // Timestamp
    let mode: CommitmentMode        // .full90 or .trial7
}

enum CommitmentMode: String, Codable {
    case full90 = "90_day"
    case trial7 = "7_day"
}
```

### Technical Implementation

| Component | File | Responsibility |
|-----------|------|----------------|
| `ForgeNameView` | `Views/Onboarding/ForgeNameView.swift` | Name input |
| `ForgeIgnitionView` | `Views/Onboarding/ForgeIgnitionView.swift` | Ignition animation |
| `ForgeIgnitionAnimation` | `Components/Animations/ForgeIgnitionAnimation.swift` | Reusable animation component |
| `CommitmentMode.swift` | `Models/CommitmentMode.swift` | Commitment data model |

### Acceptance Criteria

- AC-3.1: No checkbox or legal language in commitment flow
- AC-3.2: Forge name input validates 2–20 alphanumeric characters
- AC-3.3: Forge ignition animation runs 2.5–3 seconds
- AC-3.4: Haptic feedback fires at ignition peak and text reveal
- AC-3.5: `Reduce Motion` preference skips animation gracefully
- AC-3.6: Commitment timestamp and mode are persisted
- AC-3.7: Forge name appears throughout app (Home greeting, profile, end-of-day screen)
- AC-3.8: 7-Day mode uses distinct visual treatment (amber flame vs purple)

---

## Section 4: First-Session Victory

### Problem

Users can currently close the app after onboarding without having accomplished anything. They leave with a commitment but no reward, no identity marker, and no reason to feel good about their first interaction.

### Solution

The user MUST complete at least 1 habit in their first session. They earn real XP, see their actual level, receive their first title ("Spark Initiate"), and end with a shareable milestone card.

### Detailed Flow

#### Screen 4A: Your First Day (Simplified Home)

After forge ignition + account creation:

- Header: "Day 1 — [Forge Name]"
- Subtext: "Complete your first habit to earn your title."
- Display: 3–4 starter habits (personalized from archetype):
  - Body archetype: 💧 Drink Water, 💪 5 Push-ups, 🚶 Walk 5 minutes
  - Mind archetype: 📖 Read 1 page, 🧘 Meditate 1 minute, ✍️ Write 1 sentence
  - Spirit archetype: 🧘 3 Deep Breaths, 🙏 Gratitude (think of 1 thing), 🌿 5 minutes outside
- Habits are pre-loaded (not requiring setup). User can customize later.
- At least 1 must be completed before the app presents the "Day Complete" screen.

**Design notes:**
- This is a simplified version of the Home screen — no tab bar yet, no calendar, no quests
- Single focused column of habits
- Each habit card has a tap-to-complete interaction (same as production Home)
- XP reward shown inline on completion: "+10 XP" float animation

#### Screen 4B: First Title Unlock

Triggered when user completes their first habit:

- Overlay animation (doesn't leave the screen):
  1. Purple pulse from completed habit card
  2. XP bar at top fills (matching Try-Before-Commit animation, but now it's real)
  3. After XP bar settles:
    - Title card slides up from bottom:
    - **"SPARK INITIATE"**
    - Subtext: "Every forge begins with a single spark."
    - Haptic: `.success`
  4. Card holds for 2s, then can be dismissed by tap or swipe

**Design notes:**
- Title card uses frosted glass background (`.ultraThinMaterial`)
- Title text in SF Pro Bold, 24pt, RNF Purple
- The title "Spark Initiate" is the first in the title progression (matches existing title system)

#### Screen 4C: Continue or Complete Day

After first title unlock:
- User returns to simplified Home
- They can complete more habits (optional) or tap "Finish Day"
- If more habits completed: additional XP, no additional title (next title at 3-day streak)
- "Finish Day" appears after ≥1 habit completion

#### Screen 4D: Day 1 Complete Screen

The session-ending moment. Must feel like an achievement.

- Full screen dark background
- Content (center-aligned, stacked):
  1. Day badge: "DAY 1" in large text with subtle ember glow
  2. Stats summary:
     - XP earned today: "+XX XP"
     - Level: "Level 1"
     - Title: "Spark Initiate"
     - Archetype: "[Archetype Name]"
  3. Text: **"Day 1 complete. See you tomorrow, [Forge Name]."**
  4. Share button: "Share Your Start" → generates milestone card
  5. CTA: "Close" → navigates to Home (with tab bar now visible)

**Design notes:**
- This screen is designed to be screenshot-worthy
- The "DAY 1" text uses the same ember glow as the forge ignition
- Stats are in a clean card layout
- Share button is secondary (not pushy), but prominent enough to find

#### Milestone Share Card

Generated image for sharing (rendered as a SwiftUI view → UIImage):

```
┌─────────────────────────────┐
│                             │
│         RNF                 │
│    Rise and Forge           │
│                             │
│      ── DAY 1 ──           │
│                             │
│    [Forge Name]             │
│    Spark Initiate           │
│    [Archetype Name]         │
│                             │
│    +XX XP earned            │
│                             │
│    "The Forge ignites."     │
│                             │
│         rnf.app             │
└─────────────────────────────┘
```

- Dark background, purple accent elements
- Optimized for Instagram Stories aspect ratio (9:16) and Twitter/X (16:9 crop-safe)
- Uses `ImageRenderer` (iOS 16+) to generate shareable image

### Preventing Early Exit

To ensure first-session victory:

- "Close" / swipe-to-dismiss is not available until ≥1 habit is completed
- If user backgrounds the app before completing: next foreground returns to the simplified Home
- If user force-quits: next launch shows simplified Home (state persisted)
- The tab bar and full navigation only unlock after first habit completion
- This is NOT a hard block (no modal prison) — the Home IS the first screen, it just has a simplified state

### Technical Implementation

| Component | File | Responsibility |
|-----------|------|----------------|
| `FirstDayView` | `Views/Onboarding/FirstDayView.swift` | Simplified first-day Home |
| `TitleUnlockOverlay` | `Components/TitleUnlockOverlay.swift` | Title unlock animation |
| `DayCompleteView` | `Views/Onboarding/DayCompleteView.swift` | End-of-day screen |
| `MilestoneCardView` | `Components/MilestoneCardView.swift` | Shareable card renderer |
| `ShareService` | `Services/ShareService.swift` | Image generation + share sheet |
| `OnboardingState` | `ViewModels/OnboardingState.swift` | Tracks first-session progress |

### Acceptance Criteria

- AC-4.1: User cannot access full app navigation until ≥1 habit completed in first session
- AC-4.2: First habit completion triggers "Spark Initiate" title unlock
- AC-4.3: Title unlock includes animation + haptic feedback
- AC-4.4: Day 1 Complete screen shows XP earned, level, title, and archetype
- AC-4.5: "See you tomorrow, [Forge Name]" uses the user's chosen forge name
- AC-4.6: Share card generates a properly formatted image
- AC-4.7: Share card is optimized for Stories (9:16) and feed (16:9 safe area)
- AC-4.8: If user force-quits before first completion, state is preserved on relaunch
- AC-4.9: Starter habits are personalized based on archetype priority (body/mind/spirit)

---

## Section 5: Progressive Onboarding (Not All At Once)

### Problem

Current onboarding dumps all features on users simultaneously: habits, workouts, reading, calendar, streaks, stats, quests. Cognitive overload causes users to feel overwhelmed before they've built any habit momentum.

### Solution

Progressively unlock features over the first 14 days. Day 1 is radically simple. Each unlock feels like a reward, not additional complexity.

### Unlock Schedule

| Day | Feature Unlocked | Discovery Mechanism |
|-----|-----------------|---------------------|
| Day 1 | Habits only | Immediate (first-session) |
| Day 2 | Workouts tab | Tab appears + TipKit tooltip |
| Day 3 | Streaks + Calendar | Calendar tab reveals + streak counter appears on Home |
| Day 5 | Reading tab | Tab appears + TipKit tooltip |
| Day 7 | Quests | Quest section appears on Home |
| Day 10 | Stats radar chart | Profile section expands |
| Day 14 | Skill tree preview (locked) | Teaser card in Profile: "Unlocks at Level 5" |

### Day-by-Day Detail

#### Day 1: Habits Only

- Home shows: Day counter, habit list, XP bar
- Tab bar: Home only (or Home + Profile with minimal profile)
- No calendar, no streaks display, no quests, no workouts tab
- Philosophy: "Just do your habits. That's all."

#### Day 2: Workouts Unlock

- On app open, Day 2:
  - TipKit tooltip on new Workouts tab: "Ready for movement? Quick challenges await."
  - Tab appears with subtle entrance animation (slide up + fade)
  - Haptic: `.light` on first appearance
- Workouts tab shows Quick Challenges grid (existing design)

#### Day 3: Streaks + Calendar

- On app open, Day 3:
  - Streak counter appears on Home screen with animation
  - TipKit tooltip: "🔥 Your streak grows every day you show up. Don't break it."
  - Calendar view becomes accessible (Profile → Calendar or dedicated tab)
  - Calendar shows Days 1–3 filled in (green squares)
- This is the first "loss aversion" hook — now they have something to protect

#### Day 5: Reading Unlock

- On app open, Day 5:
  - Reading tab appears
  - TipKit tooltip: "Feed your mind. Upload proof of daily reading."
  - Habit list may also expand to include reading-related habits

#### Day 7: Quests Unlock

- On app open, Day 7:
  - Quest section appears on Home (below habits)
  - TipKit tooltip: "Quests target your weakest stats. Complete them to grow faster."
  - First quest is generated based on weakest stat from first 7 days of activity
  - This is a major engagement moment — introduces the adaptive challenge system

#### Day 10: Stats Radar Chart

- On Profile view, Day 10:
  - Radar chart section appears with animation
  - TipKit tooltip: "Your character is taking shape. Each habit builds different stats."
  - Chart shows accumulated stats from 10 days of activity
  - Users see their archetype prediction manifesting in actual stat growth

#### Day 14: Skill Tree Teaser

- On Profile view, Day 14:
  - Locked preview card appears: "Skill Tree — Unlocks at Level 5"
  - Shows a blurred/greyed-out skill tree preview
  - Tap on it: "Keep forging. You'll unlock specialization paths soon."
  - Purpose: creates anticipation for long-term engagement

### TipKit Integration

RNF uses Apple's TipKit framework (iOS 17+) for contextual feature discovery:

```swift
struct WorkoutUnlockTip: Tip {
    var title: Text { Text("Movement Unlocked") }
    var message: Text? { Text("Quick challenges to build your body.") }
    var image: Image? { Image(systemName: "flame.fill") }
    
    var rules: [Rule] {
        #Rule(Self.dayCount) { $0 >= 2 }
    }
    
    @Parameter
    static var dayCount: Int = 0
}
```

- Each feature unlock has a corresponding Tip
- Tips dismiss after user interacts with the new feature
- Tips respect the "Don't show tips" system setting
- Fallback for iOS 16: use custom tooltip overlay (`.overlay` modifier with conditional display)

### Feature Gating Logic

```swift
struct FeatureGate {
    static func isUnlocked(_ feature: Feature, currentDay: Int, level: Int) -> Bool {
        switch feature {
        case .habits:       return true  // Always available
        case .workouts:     return currentDay >= 2
        case .streaks:      return currentDay >= 3
        case .calendar:     return currentDay >= 3
        case .reading:      return currentDay >= 5
        case .quests:       return currentDay >= 7
        case .statsChart:   return currentDay >= 10
        case .skillTree:    return level >= 5
        }
    }
}
```

- Feature gates are checked on app launch and view appearance
- Unlocked features are persisted (once unlocked, never re-locked)
- `currentDay` is derived from challenge start date, not login count

### Technical Implementation

| Component | File | Responsibility |
|-----------|------|----------------|
| `FeatureGate` | `Systems/FeatureGate.swift` | Day/level-based feature gating |
| `FeatureUnlockTips` | `Systems/FeatureUnlockTips.swift` | TipKit tip definitions |
| `ProgressiveTabBar` | `Components/ProgressiveTabBar.swift` | Tab bar that shows/hides tabs |
| `UnlockAnimationModifier` | `Components/UnlockAnimationModifier.swift` | Reusable unlock entrance |

### Acceptance Criteria

- AC-5.1: Day 1 shows ONLY habits and XP bar — no other features visible
- AC-5.2: Each feature unlocks on the specified day with animation
- AC-5.3: TipKit tooltips appear on first view of newly unlocked features
- AC-5.4: Once a feature is unlocked, it remains permanently accessible
- AC-5.5: Feature gate uses challenge start date (not login count)
- AC-5.6: Reduce Motion preference suppresses unlock animations (feature still appears)
- AC-5.7: iOS 16 fallback exists for TipKit tooltips
- AC-5.8: Tab bar dynamically shows/hides tabs based on unlock state
- AC-5.9: Skill tree teaser at Day 14 shows locked preview with clear unlock criteria

---

## Section 6: Low-Commitment Entry (7-Day Mode)

### Problem

A significant segment of potential users have tried multiple habit apps and quit them all. When these users see "90-day commitment," they immediately think "I'll fail again" and uninstall. RNF loses users who might have succeeded if given a lower barrier to entry.

### Solution

Offer a 7-day trial mode that removes commitment pressure. Users can build real data and momentum over 7 days, then receive a personalized upsell to the full 90-day commitment — using their own proof of consistency as the sales pitch.

### Entry Points

The 7-Day Mode is accessible from two places:

1. **During Commitment Reframe** (Screen 3B): Secondary option below "Ignite The Forge":
   - Link text: "Not ready for 90 days? Try 7 days first."
   
2. **On Try-Before-Commit screen** (Screen 1D): After XP animation:
   - If user seems hesitant (tapped "Just exploring" previously), offer:
   - "Try 7 days. No commitment. No pressure."

### Detailed Flow

#### Screen 6A: 7-Day Mode Introduction

- Header: "7 Days. No Pressure."
- Subtext: "You don't need to commit to anything right now. Just show up for a week."
- Visual: Smaller forge flame (amber, not full purple) — indicates trial/partial ignition
- Tone: empathetic, not salesy. This is for people who are tired of failing.
- Content:
  - "✓ Full habit tracking"
  - "✓ XP and leveling"
  - "✓ Your progress is saved"
  - "✗ No 90-day pressure"
- CTA: "Start 7 Days" → Forge Ignition (amber variant)
- Secondary: "Actually, I'm ready for 90 days" → Full commitment flow

#### Screen 6B: 7-Day Forge Ignition (Amber Variant)

- Same animation as Section 3, Screen 3B but:
  - Flame color: amber/orange (#F4B400) instead of purple
  - Text: **"The Forge sparks for 7 days. Prove yourself."**
  - Subtext: **"Day 1 begins now."**
  - Smaller flame scale (75% of full ignition)
- Haptic: medium (not heavy) impact
- Data: `CommitmentMode.trial7`, `commitmentDays: 7`

#### Screen 6C: Day 7 Upsell Moment

Triggered on Day 7 app open (AFTER the user completes their Day 7 habits):

- Full screen overlay (not interruptive — appears after daily completion)
- Header: **"You've been consistent for a week."**
- Content:
  - Show user's own data as proof:
    - "7 days active"
    - "X habits completed"
    - "X XP earned"
    - "Level [N]"
    - "Current streak: 🔥 7"
  - Radar chart preview showing their stat growth
- Text: **"Ready to go deeper?"**
- CTA: "Ignite the Full Forge — 90 Days" → Full forge ignition (purple, with their existing data intact)
- Secondary: "Keep going at my own pace" → continues without 90-day structure
- Tertiary: "Maybe later" → dismisses, can be re-triggered from Profile settings

**Design notes:**
- The upsell uses the user's OWN data as social proof. This is more powerful than any marketing copy.
- The transition from amber flame to purple flame is a visual upgrade they can feel.
- No urgency tactics. No "limited time." Just presenting their own evidence.

#### Data Continuity

Critical: 7-day mode data MUST seamlessly continue into 90-day mode:

- XP earned during 7 days: preserved
- Habits completed: preserved
- Streak: preserved (7-day streak continues into 90-day count)
- Level: preserved
- Day count: resets to Day 1 of the 90-day challenge (but historical data remains)
- Calendar: 7-day entries remain visible in history

```swift
func upgradeToFull90(userId: String) async throws {
    // Preserve all existing data
    // Create new 90-day challenge record
    // Start date = today (not original 7-day start)
    // XP, level, stats, streak all carry forward
    // Mark 7-day trial as completed/upgraded
    
    let challenge = Challenge(
        userId: userId,
        startDate: .now,
        commitmentDays: 90,
        mode: .full90,
        upgradedFrom7Day: true,
        originalTrialStart: existingTrial.startDate
    )
    try await ChallengeService.shared.create(challenge)
}
```

### Users Who Don't Upgrade

If a user completes 7 days and does NOT upgrade:

- They can continue using the app indefinitely in "freeform" mode
- No 90-day structure (no day counter, no end date)
- They still earn XP, level up, complete habits
- Periodic gentle prompts (every 7 days): "Ready for the full forge?"
- These prompts can be permanently dismissed from Settings
- They are NOT second-class users. The app remains fully functional.

### Technical Implementation

| Component | File | Responsibility |
|-----------|------|----------------|
| `SevenDayModeView` | `Views/Onboarding/SevenDayModeView.swift` | 7-day intro screen |
| `SevenDayUpsellView` | `Views/Milestones/SevenDayUpsellView.swift` | Day 7 upsell moment |
| `CommitmentUpgradeService` | `Services/CommitmentUpgradeService.swift` | Trial → full upgrade logic |
| `TrialState` | `Models/TrialState.swift` | Trial tracking |

### Acceptance Criteria

- AC-6.1: 7-Day Mode is accessible from commitment screen as secondary option
- AC-6.2: 7-Day forge ignition uses amber color, not purple
- AC-6.3: All data (XP, streaks, habits) earned in 7-day mode preserves on upgrade
- AC-6.4: Day 7 upsell shows the user's own data as proof of consistency
- AC-6.5: User can dismiss upsell without penalty ("Maybe later")
- AC-6.6: Non-upgrading users retain full app functionality
- AC-6.7: Periodic re-prompts can be permanently silenced
- AC-6.8: Upgrade to 90-day resets day counter but preserves XP/level/streak
- AC-6.9: 7-Day Mode does NOT require subscription (free tier)

---

## Section 7: Login ↔ SignUp Navigation

### Problem

The current auth flow lacks clear bidirectional navigation between Login and SignUp states. Users who have accounts cannot easily find the login from the signup flow, and new users cannot easily find signup from login. Sign in with Apple is not prominently placed despite being the lowest-friction auth method on iOS.

### Solution

Both LoginView and SignUpView must have clear, prominent navigation to each other. Sign in with Apple must be the primary CTA on both screens, with email/password as the secondary option.

### Screen Designs

#### LoginView (Returning Users)

```
┌─────────────────────────────────────┐
│                                     │
│            [RNF Logo]               │
│       Rise and Forge                │
│                                     │
│   ┌─────────────────────────────┐   │
│   │  ◉ Sign in with Apple      │   │  ← Primary CTA (black, full-width)
│   └─────────────────────────────┘   │
│                                     │
│          ─── or ───                 │
│                                     │
│   Email                             │
│   ┌─────────────────────────────┐   │
│   │ email@example.com           │   │
│   └─────────────────────────────┘   │
│                                     │
│   Password                          │
│   ┌─────────────────────────────┐   │
│   │ ••••••••                    │   │
│   └─────────────────────────────┘   │
│                                     │
│   [Forgot Password?]                │  ← Text button, right-aligned
│                                     │
│   ┌─────────────────────────────┐   │
│   │       Log In                │   │  ← Secondary CTA (purple)
│   └─────────────────────────────┘   │
│                                     │
│                                     │
│   Don't have an account?            │
│   [Create Account]                  │  ← Navigation to SignUpView
│                                     │
└─────────────────────────────────────┘
```

#### SignUpView (New Users)

```
┌─────────────────────────────────────┐
│                                     │
│            [RNF Logo]               │
│       Begin Your Forge              │
│                                     │
│   ┌─────────────────────────────┐   │
│   │  ◉ Sign up with Apple      │   │  ← Primary CTA (black, full-width)
│   └─────────────────────────────┘   │
│                                     │
│          ─── or ───                 │
│                                     │
│   Email                             │
│   ┌─────────────────────────────┐   │
│   │ email@example.com           │   │
│   └─────────────────────────────┘   │
│                                     │
│   Password                          │
│   ┌─────────────────────────────┐   │
│   │ ••••••••                    │   │
│   └─────────────────────────────┘   │
│                                     │
│   Confirm Password                  │
│   ┌─────────────────────────────┐   │
│   │ ••••••••                    │   │
│   └─────────────────────────────┘   │
│                                     │
│   ┌─────────────────────────────┐   │
│   │     Create Account          │   │  ← Secondary CTA (purple)
│   └─────────────────────────────┘   │
│                                     │
│                                     │
│   Already have an account?          │
│   [Log In]                          │  ← Navigation to LoginView
│                                     │
└─────────────────────────────────────┘
```

### Navigation Rules

| From | Action | Destination |
|------|--------|-------------|
| LoginView | Tap "Create Account" | SignUpView |
| SignUpView | Tap "Log In" | LoginView |
| LoginView | Sign in with Apple (success) | Home |
| SignUpView | Sign up with Apple (success) | Archetype Quiz (if new) or Home (if returning) |
| LoginView | Email login (success) | Home |
| SignUpView | Email signup (success) | Archetype Quiz → Forge Ignition → First Day |
| Either | Swipe back | Previous screen in nav stack |

### Sign in with Apple Implementation

```swift
struct AppleSignInButton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: handleResult
        )
        .signInWithAppleButtonStyle(
            colorScheme == .dark ? .white : .black
        )
        .frame(height: 50)
        .cornerRadius(12)
    }
}
```

- Uses ASAuthorizationAppleIDProvider
- Supabase handles Apple token → session conversion
- On first Apple sign-in: create profile + route to Archetype Quiz
- On returning Apple sign-in: route directly to Home
- Store Apple user identifier for session restoration

### Auth State Machine

```
┌──────────┐    Apple/Email     ┌──────────────┐
│  Splash  │ ──────────────────→│ Authenticated │
└──────────┘                    └──────────────┘
     │                                 │
     │ New user                        │ Has profile?
     ▼                                 │
┌──────────────┐                  Yes──→ Home
│ Try-Before-  │                       │
│ Commit Flow  │                  No───→ Archetype Quiz
└──────────────┘
     │
     │ Create account
     ▼
┌──────────────┐
│  SignUpView   │ ←──→ LoginView
└──────────────┘
     │
     │ Success
     ▼
┌──────────────────┐
│ Archetype Quiz   │
│ → Forge Ignition │
│ → First Day      │
└──────────────────┘
```

### Where Auth Screens Appear in the Flow

For NEW users (standard path):
1. Splash → Try-Before-Commit → XP Animation → Archetype Quiz → Forge Name → **SignUpView** → Forge Ignition → First Day

For NEW users (guest → convert):
1. Splash → Try-Before-Commit → Guest Mode → (3 days) → **SignUpView** → Data Migration → Home

For RETURNING users:
1. Splash → **LoginView** → Home

The auth screens appear AFTER the user has already experienced value (XP animation, archetype quiz, forge name). By the time they hit SignUpView, they have psychological investment.

### Password Requirements

- Minimum 8 characters
- At least 1 letter and 1 number
- Real-time validation feedback below field
- Show/hide password toggle (eye icon)

### Error Handling

| Error | Display |
|-------|---------|
| Invalid email format | Inline: "Enter a valid email" |
| Email already registered | Inline: "This email already has an account. [Log In]" |
| Wrong password | Inline: "Incorrect password. [Forgot Password?]" |
| Apple sign-in cancelled | No error shown (user-initiated) |
| Apple sign-in failed | Alert: "Sign in failed. Try again or use email." |
| Network error | Alert: "No connection. Check your network and try again." |

### Technical Implementation

| Component | File | Responsibility |
|-----------|------|----------------|
| `LoginView` | `Views/Auth/LoginView.swift` | Login screen |
| `SignUpView` | `Views/Auth/SignUpView.swift` | Registration screen |
| `AppleSignInButton` | `Components/AppleSignInButton.swift` | Apple auth button |
| `AuthViewModel` | `ViewModels/AuthViewModel.swift` | Auth state + validation |
| `AuthCoordinator` | `ViewModels/AuthCoordinator.swift` | Auth flow navigation |

### Acceptance Criteria

- AC-7.1: LoginView has a visible "Create Account" button/link
- AC-7.2: SignUpView has a visible "Already have an account? Log In" button/link
- AC-7.3: Sign in with Apple is the PRIMARY (topmost, largest) CTA on both screens
- AC-7.4: Email/password is the SECONDARY option (below Apple sign-in)
- AC-7.5: Navigation between Login ↔ SignUp is instant (no loading, no animation delay)
- AC-7.6: Successful Apple sign-up routes to Archetype Quiz (first time) or Home (returning)
- AC-7.7: Password validation shows real-time feedback
- AC-7.8: Error messages are inline and actionable (include links to relevant action)
- AC-7.9: Auth screens appear AFTER Try-Before-Commit flow (not as first interaction)

---

## Metrics to Track

### Primary Metrics (North Stars)

| Metric | Definition | Target |
|--------|-----------|--------|
| Day 0→1 Retention | % of installers who open app on Day 2 | ≥ 50% |
| First-Session Completion | % who complete ≥1 habit in first session | ≥ 80% |
| Onboarding Completion Rate | % who reach Home screen with full account | ≥ 60% |

### Funnel Metrics (Drop-off Tracking)

| Step | Event | Track |
|------|-------|-------|
| Splash shown | `onboarding_splash` | Timestamp |
| Habit selected (try-before-commit) | `onboarding_habit_selected` | Which habit |
| Habit completed (try-before-commit) | `onboarding_habit_completed` | Which habit |
| XP animation viewed | `onboarding_xp_shown` | — |
| Archetype quiz started | `onboarding_quiz_started` | — |
| Archetype quiz completed | `onboarding_quiz_completed` | Answers + archetype |
| Forge name entered | `onboarding_name_entered` | — |
| Forge ignited | `onboarding_forge_ignited` | Mode (90/7) |
| Account created | `onboarding_account_created` | Method (apple/email) |
| First-session habit completed | `onboarding_first_habit` | Which habit |
| Day 1 complete screen shown | `onboarding_day1_complete` | XP earned |
| Share card generated | `onboarding_share_generated` | — |
| Share card shared | `onboarding_share_completed` | Platform |

### Engagement Metrics

| Metric | Definition | Target |
|--------|-----------|--------|
| Time to first XP | Seconds from splash to first XP animation | < 30s |
| Quiz completion rate | % who finish all 3 questions | ≥ 95% |
| 7-Day Mode adoption | % of new users choosing 7-day over 90-day | Track (no target) |
| 7-Day → 90-Day conversion | % of 7-day users who upgrade | ≥ 40% |
| Guest → Account conversion | % of guests who create account within 3 days | ≥ 30% |
| Feature unlock engagement | % who interact with feature within 24h of unlock | ≥ 60% |

### Retention Metrics

| Metric | Definition | Target |
|--------|-----------|--------|
| Day 1 retention | Open on Day 2 | ≥ 50% |
| Day 3 retention | Open on Day 4 | ≥ 40% |
| Day 7 retention | Open on Day 8 | ≥ 35% |
| Day 14 retention | Open on Day 15 | ≥ 25% |
| Day 30 retention | Open on Day 31 | ≥ 20% |

### Anti-Metrics (What We DON'T Optimize For)

- Time spent in onboarding (shorter is not always better — the quiz creates investment)
- Number of accounts created (quality over quantity — invested users > drive-by signups)
- Share rate (nice-to-have but not a success criterion)

---

## Dependencies & Prerequisites

### Technical Dependencies

| Dependency | Required For | Status |
|------------|-------------|--------|
| Supabase Auth (Apple sign-in) | Section 7 | Existing |
| Local data persistence (UserDefaults / SwiftData) | Guest mode (Section 1) | New |
| TipKit (iOS 17+) | Section 5 | New import |
| ImageRenderer (iOS 16+) | Share card (Section 4) | Available |
| Core Animation | Forge ignition (Section 3) | Available |
| UIImpactFeedbackGenerator | All haptics | Available |

### Design Assets Required

| Asset | Used In | Format |
|-------|---------|--------|
| Forge icon (dormant state) | Section 3 | SVG/PDF |
| Forge icon (ignited state) | Section 3 | SVG/PDF + animation frames |
| Archetype badge icons (27) | Section 2 | SVG/PDF |
| Milestone card template | Section 4 | SwiftUI view |
| Tab bar icons (workout, reading, calendar) | Section 5 | SF Symbols preferred |
| 7-Day amber flame variant | Section 6 | SVG/PDF |

### Database Schema Changes

```sql
-- Add to profiles table
ALTER TABLE profiles ADD COLUMN forge_name TEXT;
ALTER TABLE profiles ADD COLUMN archetype_name TEXT;
ALTER TABLE profiles ADD COLUMN archetype_data JSONB;
ALTER TABLE profiles ADD COLUMN onboarding_completed_at TIMESTAMPTZ;

-- Add to challenges table
ALTER TABLE challenges ADD COLUMN mode TEXT DEFAULT '90_day';  -- '90_day' | '7_day'
ALTER TABLE challenges ADD COLUMN upgraded_from_trial BOOLEAN DEFAULT FALSE;
ALTER TABLE challenges ADD COLUMN original_trial_start TIMESTAMPTZ;

-- New table for feature unlock tracking
CREATE TABLE feature_unlocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    feature TEXT NOT NULL,
    unlocked_at TIMESTAMPTZ DEFAULT now(),
    interacted_at TIMESTAMPTZ
);

-- New table for onboarding analytics
CREATE TABLE onboarding_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,  -- nullable for guest events
    device_id TEXT,
    event_name TEXT NOT NULL,
    event_data JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

---

## Implementation Priority

| Phase | Sections | Effort | Impact |
|-------|----------|--------|--------|
| Phase A | Section 1 (Try-Before-Commit) + Section 4 (First Victory) | 2 weeks | Highest — directly addresses Day 0→1 drop-off |
| Phase B | Section 3 (Commitment Reframe) + Section 7 (Login ↔ SignUp) | 1 week | High — replaces broken commitment UX |
| Phase C | Section 2 (Archetype Quiz) | 1 week | Medium-High — creates identity hook |
| Phase D | Section 5 (Progressive Onboarding) | 2 weeks | Medium — reduces overwhelm |
| Phase E | Section 6 (7-Day Mode) | 1 week | Medium — captures hesitant users |

Total estimated effort: 7 weeks of engineering + 2 weeks of design.

---

## Open Questions

1. **Guest mode duration:** Is 3 days the right window, or should it be unlimited until a gated feature is hit?
2. **Archetype permanence:** Can users retake the quiz, or is the archetype permanent? (Recommendation: allow retake from Profile settings, but make it feel weighty.)
3. **7-Day mode and subscriptions:** Is 7-Day mode available on free tier only, or also for subscribers?
4. **Forge Voice during onboarding:** Should the Forge Voice say "Activated." during the ignition moment? (Recommendation: No — voice is off by default per spec, and onboarding should work without it.)
5. **Progressive onboarding for 7-Day users:** Do they get the same Day 3/5/7 unlocks, or accelerated?

---

## Appendix A: Onboarding State Machine

```
States:
  .splash
  .tryBeforeCommit
  .habitSelection
  .habitCompletion
  .xpReward
  .archetypeQuiz
  .forgeName
  .commitmentChoice (90-day vs 7-day)
  .forgeIgnition
  .accountCreation
  .firstDay
  .dayComplete
  .home

Transitions:
  .splash → .tryBeforeCommit (new user)
  .splash → .home (returning authenticated user)
  .splash → .loginView (returning unauthenticated user)
  .tryBeforeCommit → .habitSelection
  .habitSelection → .habitCompletion
  .habitCompletion → .xpReward
  .xpReward → .archetypeQuiz (standard path)
  .xpReward → .guestMode (exploring path)
  .archetypeQuiz → .forgeName
  .forgeName → .commitmentChoice
  .commitmentChoice → .forgeIgnition
  .forgeIgnition → .accountCreation
  .accountCreation → .firstDay
  .firstDay → .dayComplete (after ≥1 habit)
  .dayComplete → .home
```

---

## Appendix B: Copy / Microcopy Reference

| Screen | Element | Copy |
|--------|---------|------|
| Try-Before-Commit | Header | "Choose one habit to try right now." |
| Try-Before-Commit | Subtext | "No account needed. Just try it." |
| XP Reward | Hook text | "That's what leveling up feels like." |
| XP Reward | CTA | "Ready to forge your discipline?" |
| XP Reward | Secondary | "Just exploring" |
| Archetype Quiz | Intro | "Before we forge, let's find your shape." |
| Archetype Quiz | Subtext | "3 quick questions. No wrong answers." |
| Q1 | Question | "What holds you back most?" |
| Q2 | Question | "When are you at your sharpest?" |
| Q3 | Question | "What do you want to build first?" |
| Archetype Reveal | CTA | "Your forge has a shape. Now let's ignite it." |
| Forge Name | Header | "Choose your forge name." |
| Forge Name | Subtext | "This is how The Forge will address you." |
| Forge Ignition | Ignition text | "The Forge activates for 90 days." |
| Forge Ignition | Subtext | "Day 1 begins now." |
| Forge Ignition (7-day) | Text | "The Forge sparks for 7 days. Prove yourself." |
| First Day | Header | "Day 1 — [Forge Name]" |
| First Day | Subtext | "Complete your first habit to earn your title." |
| Title Unlock | Title | "SPARK INITIATE" |
| Title Unlock | Subtext | "Every forge begins with a single spark." |
| Day Complete | Main text | "Day 1 complete. See you tomorrow, [Forge Name]." |
| 7-Day Intro | Header | "7 Days. No Pressure." |
| 7-Day Intro | Subtext | "You don't need to commit to anything right now. Just show up for a week." |
| 7-Day Upsell | Header | "You've been consistent for a week." |
| 7-Day Upsell | CTA | "Ready to go deeper?" |
| Guest Banner | Text | "Guest Mode — Create Account to save your progress" |

---

*End of specification.*
