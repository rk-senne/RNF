# SPEC: Personas & Inclusivity

**Status:** Draft  
**Created:** 2026-07-03  
**Last Updated:** 2026-07-03  
**Priority:** High  
**Dependencies:** SPEC_UI_UX_FIXES (Dynamic Type), SPEC_GROWTH_VIRALITY (Buddy System)

---

## Overview

RNF's current design optimizes for a single persona: young male gamers who resonate with combat metaphors, high-intensity progression, and discipline-through-pain framing. This alienates the majority of the wellness market.

This specification defines how RNF serves underserved user personas through alternative emotional framing, adaptive difficulty, progressive commitment, and inclusive design — without changing core mechanics.

**Core Principle:** Same game, different wrapper. Mechanics stay identical. Emotional framing adapts to the user.

---

## Table of Contents

1. [Alternative Themes (Garden / Scholar / Warrior)](#1-alternative-themes)
2. [ADHD / Neurodivergent Adaptive Mode](#2-adhd--neurodivergent-adaptive-mode)
3. [Couples / Accountability Partners](#3-couples--accountability-partners)
4. [Progressive Commitment for Burned-Out Users](#4-progressive-commitment-for-burned-out-users)
5. [Age-Inclusive Design](#5-age-inclusive-design)
6. [Cultural Sensitivity](#6-cultural-sensitivity)
7. [Persona Profiles (Internal Design Reference)](#7-persona-profiles)
8. [Inclusive Language Guidelines](#8-inclusive-language-guidelines)

---

## 1. Alternative Themes

### Persona Description

Women, non-gamers, wellness-focused users, and anyone who finds combat/forge metaphors off-putting. Represents ~60% of the addressable wellness app market.

### Why They Won't Use RNF Today

- "Warlord," "forge," "blaze," and "inferno" feel aggressive and masculine-coded
- Combat metaphors signal "this app isn't for me" within 10 seconds of onboarding
- Users who want growth, peace, or wisdom framing bounce immediately
- The entire emotional layer assumes the user fantasizes about being a warrior

### Design Changes Needed

A **theme selector** during onboarding (Screen 2, after name entry) that reframes all emotional copy, icons, and accent colors. Changeable anytime in Settings.

#### Theme Definitions

| Element | Warrior (Default) | Garden | Scholar |
|---------|-------------------|--------|---------|
| **Metaphor** | Combat / Forge | Growth / Nature | Wisdom / Mastery |
| **Streak term** | Blaze | Bloom | Illuminated |
| **Tier 1** | Spark | Seedling | Novice |
| **Tier 2** | Flame | Sprout | Apprentice |
| **Tier 3** | Blaze | Bloom | Illuminated |
| **Tier 4** | Inferno | Flourish | Enlightened |
| **Tier 5** | Warlord | Cultivator | Sage |
| **Tier 6** | Apex | Evergreen | Transcendent |
| **Streak icon** | 🔥 Flame | 🌱 Growing plant | 📖 Book/scroll |
| **Boss names** | Combat-themed | Nature challenges | Knowledge trials |
| **Accent colors** | Orange, red, dark | Green, earth tones | Deep blue, gold |
| **Narrative voice** | Intense, commanding | Nurturing, patient | Calm, wise |

#### What Theme Affects

- ✅ Streak icon and animation
- ✅ Evolution tier names
- ✅ Boss/challenge names
- ✅ All narrative copy (ForgeVoice output)
- ✅ Accent colors and gradients
- ✅ Onboarding framing
- ❌ Layout and component structure
- ❌ Mechanics (XP, streaks, quests)
- ❌ XP values or progression speed
- ❌ Game rules or challenge logic

### Implementation

```swift
// ThemeProvider.swift
enum AppTheme: String, Codable, CaseIterable {
    case warrior
    case garden
    case scholar
    
    var displayName: String {
        switch self {
        case .warrior: return "Warrior"
        case .garden: return "Garden"
        case .scholar: return "Scholar"
        }
    }
    
    var tagline: String {
        switch self {
        case .warrior: return "Forge yourself through fire"
        case .garden: return "Grow through patience and care"
        case .scholar: return "Master yourself through wisdom"
        }
    }
}

// ThemeCopyProvider.swift
struct ThemeCopyProvider {
    let theme: AppTheme
    
    func tierName(for tier: EvolutionTier) -> String {
        // Returns theme-appropriate tier name
        ThemeDictionary.tierNames[theme]?[tier] ?? tier.rawValue
    }
    
    func streakLabel(count: Int) -> String {
        switch theme {
        case .warrior: return "\(count)-day Blaze"
        case .garden: return "\(count)-day Bloom"
        case .scholar: return "\(count)-day Illumination"
        }
    }
    
    func narrativeCopy(for event: NarrativeEvent) -> String {
        ThemeDictionary.narratives[theme]?[event] ?? ""
    }
}
```

**Data model:**

```swift
// Profile extension
extension Profile {
    var themePreference: AppTheme // stored as String in SwiftData
}
```

**Integration points:**
- `NarrativeEngine` reads `ThemeCopyProvider` for all display strings
- `ForgeVoice` delegates to theme-aware copy
- `EvolutionView` uses themed tier names and icons
- `StreakView` uses themed streak icon
- Onboarding Screen 2 presents theme picker (3 cards with preview)
- Settings > Appearance > Theme (full picker with live preview)

### Acceptance Criteria

- [ ] Theme selector appears during onboarding after name entry
- [ ] All three themes are selectable and preview correctly
- [ ] Changing theme updates ALL narrative copy app-wide immediately
- [ ] Streak icon changes per theme
- [ ] Evolution tier names display per theme
- [ ] Accent colors update per theme
- [ ] Theme is changeable in Settings > Appearance
- [ ] Theme preference persists across app launches
- [ ] No XP, streak, or mechanical values change between themes
- [ ] ForgeVoice/NarrativeEngine output is fully theme-aware
- [ ] Boss names and challenge framing adapt to theme

---

## 2. ADHD / Neurodivergent Adaptive Mode

### Persona Description

Users with ADHD, executive dysfunction, anxiety disorders, or any condition that makes rigid daily systems overwhelming. Also includes neurotypical users going through high-stress periods who need temporary relief.

### Why They Won't Use RNF Today

- 4 habits/day minimum feels like an impossible mountain on bad executive function days
- Long workout requirements (20+ min) trigger avoidance behavior
- Streak pressure creates anxiety → missed day → shame spiral → uninstall
- Multi-day quests require sustained attention that ADHD brains struggle to maintain
- Infrequent rewards mean the dopamine feedback loop is too slow
- Binary "did it / didn't" with no partial credit punishes inconsistency

### Design Changes Needed

An **"Adaptive Difficulty"** setting (deliberately NOT labeled "ADHD mode" — inclusive, non-stigmatizing framing). Presented as difficulty preference, similar to game difficulty settings.

#### Behavioral Changes When Adaptive Mode Is Enabled

| System | Standard Mode | Adaptive Mode |
|--------|--------------|---------------|
| **Daily habits** | 4 minimum | 2 minimum |
| **Workout options** | 15, 20, 30 min | 5, 10, 15, 20, 30 min |
| **Micro-rewards** | XP on completion | XP + small celebration animation on EVERY completion |
| **Forgiveness tokens** | 1/month | 2/month |
| **Streak calculation** | All habits required | 1+ habit completion = streak day maintained |
| **Quest length** | Multi-day (3-7 days) | Daily quests (fresh start each day) |
| **Notifications** | Standard intervals | More frequent, shorter ("5 min check-in" style) |
| **Partial credit** | None | Completing 1 of 2 habits still earns proportional XP |

#### Key Design Principle

> Adaptive mode is **EASIER** but not **LESS REWARDING**. XP per individual completion is identical. The user simply has fewer required actions to maintain progress. This prevents "easy mode guilt."

#### Framing in UI

- Settings label: "Difficulty" with options "Standard" / "Adaptive"
- Description: "Adaptive mode adjusts daily targets and streak rules for a more flexible experience. Same rewards, fewer requirements."
- No mention of ADHD, neurodivergence, or disability
- Tone: "Choose your pace" not "This is for people who struggle"

### Implementation

```swift
// DifficultyMode.swift
enum DifficultyMode: String, Codable {
    case standard
    case adaptive
    
    var dailyHabitMinimum: Int {
        switch self {
        case .standard: return 4
        case .adaptive: return 2
        }
    }
    
    var forgivenessTokensPerMonth: Int {
        switch self {
        case .standard: return 1
        case .adaptive: return 2
        }
    }
    
    var streakRequirement: StreakRequirement {
        switch self {
        case .standard: return .allHabits
        case .adaptive: return .anyOneHabit
        }
    }
    
    var questDuration: QuestDuration {
        switch self {
        case .standard: return .multiDay
        case .adaptive: return .daily
        }
    }
    
    var showMicroRewardAnimations: Bool {
        switch self {
        case .standard: return false
        case .adaptive: return true
        }
    }
    
    var workoutDurations: [Int] {
        switch self {
        case .standard: return [15, 20, 30]
        case .adaptive: return [5, 10, 15, 20, 30]
        }
    }
}

// Profile extension
extension Profile {
    var difficultyMode: DifficultyMode // .standard default
}
```

**Integration points:**
- `StreakEngine` checks `difficultyMode` for streak day qualification
- `QuestGenerator` checks mode for quest duration
- `HabitCompletionView` triggers micro-reward animation when adaptive
- `WorkoutPickerView` shows duration options based on mode
- `NotificationScheduler` adjusts cadence for adaptive users
- `ForgivenessSystem` reads token allocation from mode
- Onboarding: Optional "Choose your pace" screen (after habits, before commitment)
- Settings > Game > Difficulty

### Acceptance Criteria

- [ ] Adaptive mode selectable during onboarding and in Settings
- [ ] Daily habit minimum reduces to 2 in adaptive mode
- [ ] 5-min and 10-min workout options appear in adaptive mode
- [ ] Every completion triggers a micro-reward animation in adaptive mode
- [ ] Forgiveness tokens increase to 2/month in adaptive mode
- [ ] Streak counts as maintained with 1+ completion in adaptive mode
- [ ] Quests are daily (not multi-day) in adaptive mode
- [ ] XP per individual completion is IDENTICAL between modes
- [ ] No UI copy references ADHD, disability, or neurodivergence
- [ ] Mode is changeable at any time without losing progress
- [ ] Notification frequency adjusts appropriately for adaptive mode

---

## 3. Couples / Accountability Partners (Buddy System)

### Persona Description

Couples, roommates, close friends, or family members who want gentle mutual accountability without the pressure of social media or public leaderboards. Typically 25-40, in committed relationships, wanting to build habits together.

### Why They Won't Use RNF Today

- RNF is entirely single-player — no way to share progress with a partner
- No accountability mechanism beyond self-discipline
- Couples who habit-track together have 40% higher retention (industry data)
- "Just text me" breaks down within a week — needs to be in-app and low-friction

### Design Changes Needed

A lightweight **buddy system** that shares completion status (checkmark only) without exposing habit details. Privacy-preserving by default.

#### Key Design Constraints

- Privacy-first: partner sees ✅ or ❌ for the day, NOT which habits or details
- Gentle: no shaming, no "your partner missed today" push notifications by default
- Optional: fully opt-in, can disconnect anytime
- Reciprocal: both parties must accept the connection

### Implementation

> **Full specification in [SPEC_GROWTH_VIRALITY.md, Section 4: Buddy System](./SPEC_GROWTH_VIRALITY.md)**

Cross-referenced here for persona completeness. Key points:

```swift
// BuddyConnection.swift
struct BuddyConnection {
    let userId: UUID
    let buddyId: UUID
    let status: ConnectionStatus // .pending, .active, .disconnected
    let privacyLevel: PrivacyLevel // .checkmarkOnly, .habitNames, .full
    let createdAt: Date
}
```

**Persona-specific considerations:**
- Couples should be able to set up during onboarding ("Doing this with someone?")
- Gentle nudge option: "Send encouragement" button (pre-written messages, no custom text initially)
- Shared milestone celebrations when both complete a day
- No competitive framing — collaborative language only ("Growing together")

### Acceptance Criteria

- [ ] See SPEC_GROWTH_VIRALITY.md for full acceptance criteria
- [ ] Buddy setup option available during onboarding
- [ ] Default privacy level is checkmark-only
- [ ] No habit details exposed without explicit opt-in from both parties
- [ ] Disconnect is instant and permanent (no "are you sure" guilt)
- [ ] Language is collaborative, never competitive

---

## 4. Progressive Commitment for Burned-Out Users

### Persona Description

"I've downloaded 7 habit apps and quit them all." Users with app fatigue, commitment anxiety, and a history of starting strong then abandoning. They want to change but are terrified of another failure. Often 25-35, self-aware about their pattern, skeptical of promises.

### Why They Won't Use RNF Today

- The 90-day commitment presented on onboarding Screen 4 is an immediate wall
- "90 days" triggers past failure memories → defense mechanism → close app
- These users need proof the app works BEFORE they'll commit
- Any upfront commitment feels like a trap ("what if I fail again on day 3?")
- The all-or-nothing framing ("forge yourself or don't") has no middle ground

### Design Changes Needed

A **multi-stage commitment ladder** that earns trust incrementally instead of demanding it upfront.

#### Commitment Stages

| Stage | Name | Duration | Trigger | Narrative |
|-------|------|----------|---------|-----------|
| 1 | Exploration | 7 days | Default for anxious users | "No pressure. Just see what this feels like." |
| 2 | Foundation | 30 days | Completing Stage 1 | "You proved you can show up. Let's build on it." |
| 3 | Full Commitment | 90 days | Completing Stage 2 | "You're ready. The forge recognizes consistency." |

#### Stage Behaviors

**Stage 1: Exploration (7 days)**
- No streak counter visible (removes anxiety entirely)
- No penalty for missed days
- Daily "how did that feel?" micro-reflection
- Gentle opt-in: "Want to keep going?" on Day 7
- If user doesn't complete 7 days, no shame — "Come back anytime"
- XP still earned (progress isn't wasted)

**Stage 2: Foundation (30 days)**
- Streak introduced with EXTRA forgiveness (3 tokens for this stage)
- Shorter challenge framing: "30 days of showing up"
- Weekly check-ins: "Week 2 done. How's it going?"
- At Day 30: celebration + "Ready for the full journey?"
- Can stay in Stage 2 indefinitely (repeat 30-day cycles)

**Stage 3: Full Commitment (90 days)**
- Normal streak behavior
- Normal forgiveness tokens (1-2/month based on difficulty mode)
- Full narrative arc, boss battles, evolution tiers
- This is current RNF behavior

#### Stage Transition UX

```
Day 7 completion:
┌─────────────────────────────────────┐
│  🎉 7 days. You showed up.         │
│                                     │
│  "You proved something to yourself. │
│   Ready to build on it?"            │
│                                     │
│  [Start 30-Day Foundation]          │
│  [Keep exploring — no pressure]     │
└─────────────────────────────────────┘
```

### Implementation

```swift
// CommitmentStage.swift
enum CommitmentStage: String, Codable {
    case exploration  // 7-day trial, no streak
    case foundation   // 30-day intermediate
    case full         // 90-day standard
    
    var durationDays: Int {
        switch self {
        case .exploration: return 7
        case .foundation: return 30
        case .full: return 90
        }
    }
    
    var streakVisible: Bool {
        switch self {
        case .exploration: return false
        case .foundation: return true
        case .full: return true
        }
    }
    
    var forgivenessBonus: Int {
        switch self {
        case .exploration: return 0 // no streak = no forgiveness needed
        case .foundation: return 3  // extra generous
        case .full: return 0        // standard allocation from DifficultyMode
        }
    }
    
    var narrativeIntro: String {
        switch self {
        case .exploration: return "No pressure. Just see what this feels like."
        case .foundation: return "You proved you can show up. Let's build on it."
        case .full: return "You're ready. The forge recognizes consistency."
        }
    }
}

// Profile extension
extension Profile {
    var commitmentStage: CommitmentStage // .exploration default for new users
    var stageStartDate: Date
}
```

**Integration points:**
- Onboarding Screen 4 rewritten: instead of "90-day commitment," offers stage choice
- Anxious users can select "Just try 7 days" — no shame, no upsell pressure
- `StreakEngine` hides streak UI entirely during exploration stage
- `ChallengeSystem` adapts counter display to current stage duration
- Stage transitions are CELEBRATIONS, not obligations
- User can decline upgrade and stay in current stage indefinitely
- `NarrativeEngine` adjusts voice intensity per stage (gentler in exploration)

### Acceptance Criteria

- [ ] Onboarding offers "7-day exploration" as a low-pressure entry
- [ ] No streak is visible or calculated during Stage 1
- [ ] XP is still earned during Stage 1 (progress preserved)
- [ ] Day 7 triggers celebration + optional Stage 2 upgrade prompt
- [ ] User can decline upgrade and remain in exploration
- [ ] Stage 2 introduces streak with 3 forgiveness tokens
- [ ] Day 30 triggers celebration + optional Stage 3 upgrade prompt
- [ ] User can stay in Stage 2 indefinitely (repeating 30-day cycles)
- [ ] Stage 3 is full RNF experience (current behavior)
- [ ] Stage transitions never use shame, pressure, or guilt language
- [ ] Progress (XP, habits, data) carries across all stage transitions
- [ ] Current users default to Stage 3 (no regression)

---

## 5. Age-Inclusive Design

### Persona Description

Users aged 40+, less familiar with gesture-heavy mobile UX, potentially with vision changes, slower reading speed, or preference for straightforward navigation. Also benefits users with motor impairments or anyone who prefers simplicity.

### Why They Won't Use RNF Today

- Small text sizes assume young eyes (even with Dynamic Type, defaults matter)
- Rapid animations and transitions can feel disorienting
- Swipe-based page navigation is non-obvious (no visible affordance)
- Complex layered navigation requires mental model that casual users don't build
- Onboarding moves too fast — screens auto-advance before older users finish reading
- Tap targets may be smaller than the 44pt minimum for comfortable use

### Design Changes Needed

Accessibility-first defaults that improve the experience for EVERYONE, plus an optional "Classic Mode" for navigation simplicity.

#### Universal Improvements (Default for All Users)

| Area | Current | Improved |
|------|---------|----------|
| **Tap targets** | Variable (some < 44pt) | 44pt minimum everywhere |
| **Dynamic Type** | Partial support | Full support (see SPEC_UI_UX_FIXES) |
| **Reduced Motion** | Partially respected | Fully respected system-wide |
| **Contrast** | Good | WCAG AA minimum, AAA where possible |
| **Onboarding pacing** | Fixed timing | User-controlled (tap to advance, no auto-advance) |

#### Optional: Classic Navigation Mode

- Toggle in Settings > Accessibility > "Classic Navigation"
- Replaces swipe-paging TabView with standard bottom TabBar
- Each tab is a clear, labeled destination
- No horizontal swipe gestures required
- Back buttons always visible (no swipe-to-go-back dependency)

### Implementation

```swift
// AccessibilitySettings.swift (extension on Profile or AppSettings)
struct AccessibilityPreferences: Codable {
    var classicNavigationEnabled: Bool = false
    var reducedAnimations: Bool = false // mirrors system setting but can be forced
    var largerTextDefault: Bool = false
}

// Navigation switch
struct MainTabView: View {
    @AppStorage("classicNavigation") var classicMode: Bool = false
    
    var body: some View {
        if classicMode {
            ClassicTabView() // Standard TabView with labeled tabs
        } else {
            PageStyleTabView() // Current swipe-paging implementation
        }
    }
}
```

**Integration points:**
- All tap targets audited and enforced at 44pt minimum via `.frame(minWidth: 44, minHeight: 44)`
- Onboarding removes any auto-advance timers; user taps "Next" explicitly
- Onboarding text appears with slightly longer fade-in for readability
- `@Environment(\.dynamicTypeSize)` checked in all text-heavy views
- Settings > Accessibility section added with Classic Navigation toggle
- Respect `UIAccessibility.isReduceMotionEnabled` globally

### Acceptance Criteria

- [ ] All interactive elements have minimum 44×44pt tap targets
- [ ] Dynamic Type fully supported in all views (no truncation, proper reflow)
- [ ] System Reduce Motion setting is fully respected (no residual animations)
- [ ] Onboarding is user-paced (manual "Next" tap, no auto-advance)
- [ ] Classic Navigation toggle exists in Settings > Accessibility
- [ ] Classic Mode provides standard TabBar navigation (no swipe required)
- [ ] All text meets WCAG AA contrast ratios
- [ ] VoiceOver labels present on all interactive elements
- [ ] No feature requires a swipe gesture as the ONLY input method
- [ ] Font sizes respect user's system Dynamic Type preference

---

## 6. Cultural Sensitivity

### Persona Description

Users from diverse cultural backgrounds where Western self-improvement language ("discipline," "grind," "hustle," "master yourself") doesn't resonate or actively conflicts with cultural values. Includes users in collectivist cultures, users for whom English isn't a first language, and users whose spiritual/contemplative traditions differ from Western mindfulness.

### Why They Won't Use RNF Today

- "Discipline" and "mastery" carry connotations of control/domination in some cultures
- Quotes assume Western philosophical tradition (Stoicism, individualism)
- "Meditation" as a preset habit assumes a specific practice tradition
- Time-of-day greetings may not match cultural norms (e.g., "Good morning" at prayer time)
- Motivational language is heavily Anglo-American self-help coded
- No localization pathway exists for future translation

### Design Changes Needed

#### Quote Pool Curation

- Review all quotes for cultural neutrality
- Remove culture-specific proverbs presented as universal truths
- Include wisdom traditions from multiple cultures (with attribution)
- Avoid quotes that require cultural context to understand
- No religious quotes unless from a clearly multi-tradition pool

#### Habit Preset Adjustments

| Current | Issue | Alternative |
|---------|-------|-------------|
| "Meditation" | Assumes specific tradition | "Quiet reflection" (with meditation as one option) |
| "Journal" | Assumes literacy-first | "Daily reflection" (journal, voice note, or mental review) |
| "Cold shower" | Western biohacker coded | Keep but don't feature prominently |
| "Read 10 pages" | Assumes book access | "Learn something new" (read, listen, watch) |

#### Time-of-Day Awareness

- Greetings adapt to user's actual timezone
- Avoid assumptions about daily schedule (not everyone works 9-5)
- "Morning routine" framing becomes "Start-of-day routine" (configurable)

#### Localization Architecture

- All user-facing strings extracted to Swift String Catalogs (.xcstrings)
- ThemeProvider handles cultural variants alongside emotional themes
- String keys are semantic, not literal (e.g., `greeting.morning` not `"Good morning"`)
- Pluralization rules follow CLDR standards
- Date/time formatting respects locale

### Implementation

```swift
// LocalizedCopy.swift
// All user-facing strings use String Catalogs
// Example structure:

// Localizable.xcstrings keys:
// "streak.label.\(theme)" -> themed streak text
// "greeting.timeOfDay.\(period)" -> time-appropriate greeting
// "habit.preset.\(id).name" -> habit preset display name
// "habit.preset.\(id).description" -> habit preset description
// "narrative.\(event).\(theme)" -> narrative copy per theme

// CulturalContext.swift
struct CulturalContext {
    let locale: Locale
    let timezone: TimeZone
    let calendar: Calendar
    
    var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return String(localized: "greeting.morning")
        case 12..<17: return String(localized: "greeting.afternoon")
        case 17..<21: return String(localized: "greeting.evening")
        default: return String(localized: "greeting.night")
        }
    }
}

// QuotePool.swift
struct Quote: Codable {
    let text: String
    let attribution: String
    let tradition: String? // "Stoic", "Buddhist", "African proverb", etc.
    let culturalContext: [String]? // regions where this resonates
    let isUniversal: Bool // safe for all audiences
}
```

**Integration points:**
- `QuoteEngine` filters by `isUniversal: true` by default; expanded pools opt-in
- Habit presets use inclusive language in names and descriptions
- `NarrativeEngine` and `ThemeCopyProvider` both read from String Catalogs
- All date/time display uses `DateFormatter` with user locale
- Future: language selector in settings for full localization

### Acceptance Criteria

- [ ] All user-facing strings extracted to String Catalog format
- [ ] Quote pool reviewed: no culture-specific quotes presented as universal
- [ ] Habit presets use culturally neutral language
- [ ] Time-of-day greetings respect user's actual timezone
- [ ] No single cultural tradition assumed as default
- [ ] String keys are semantic (not hardcoded English)
- [ ] Date and time formatting respects user locale
- [ ] App functions correctly in RTL layout direction (future-proofing)
- [ ] Quote attributions include tradition/origin where appropriate
- [ ] "Meditation" preset renamed or reframed as inclusive alternative

---

## 7. Persona Profiles (Internal Design Reference)

These personas guide all design decisions. Every feature, flow, and copy choice should be tested against: **"Would this work for each persona?"**

---

### Persona 1: The Gamer

| Attribute | Detail |
|-----------|--------|
| **Demo** | 22M, university student, plays gacha games and reads Solo Leveling |
| **Daily routine** | Wakes at 10am, gym at night, irregular schedule |
| **Why RNF** | Wants life to feel like a game. XP, levels, progression = dopamine |
| **Theme** | Warrior (default) |
| **Difficulty** | Standard |
| **Pain points** | Gets bored without new content; needs endgame |
| **Feature priorities** | Evolution tiers, boss battles, leaderboards, prestige system |
| **Churn triggers** | Runs out of content, hits tier ceiling, no social competition |
| **Delight moments** | Tier evolution animation, defeating a boss, hitting a new high |
| **Design test** | "Is the progression system deep enough for The Gamer?" |

---

### Persona 2: The Optimizer

| Attribute | Detail |
|-----------|--------|
| **Demo** | 30F, product manager, uses spreadsheets for everything |
| **Daily routine** | 5:30am wake, structured day, evening wind-down ritual |
| **Why RNF** | Wants data on her habits. Trends, correlations, insights. |
| **Theme** | Scholar |
| **Difficulty** | Standard |
| **Pain points** | Not enough data visualization; can't export; wants custom metrics |
| **Feature priorities** | Analytics dashboard, habit correlations, streak insights, CSV export |
| **Churn triggers** | Feels the app is "too gamey" without substance, lack of insights |
| **Delight moments** | Seeing a trend line go up, weekly summary insights, personal records |
| **Design test** | "Does The Optimizer get actionable data from this?" |

---

### Persona 3: The Recoverer

| Attribute | Detail |
|-----------|--------|
| **Demo** | 28NB, freelance designer, anxiety + ADHD diagnosis |
| **Daily routine** | Inconsistent — some days productive, some days paralyzed |
| **Why RNF** | Desperate to build consistency but terrified of another failure |
| **Theme** | Garden |
| **Difficulty** | Adaptive |
| **Commitment** | Exploration (Stage 1) |
| **Pain points** | Shame from past failures; overwhelmed by requirements; streak anxiety |
| **Feature priorities** | Adaptive mode, no-streak exploration, gentle language, flexible goals |
| **Churn triggers** | Missed a day and feels judged, too many required habits, shame spiral |
| **Delight moments** | Completing even one habit and being celebrated, "you showed up" message |
| **Design test** | "Would The Recoverer survive this flow without feeling shame?" |

---

### Persona 4: The Couple

| Attribute | Detail |
|-----------|--------|
| **Demo** | 32M + 30F, married, trying to get healthier together |
| **Daily routine** | Coordinated schedules, cook together, shared goals |
| **Why RNF** | Want gentle mutual accountability without nagging each other |
| **Theme** | Garden (her) / Warrior (him) |
| **Difficulty** | Standard (both) |
| **Pain points** | No way to see partner's progress, purely solo experience |
| **Feature priorities** | Buddy system, shared milestones, gentle nudges, privacy-preserving |
| **Churn triggers** | One quits and the other follows, no shared experience |
| **Delight moments** | Both completing a day, shared celebration, encouraging each other |
| **Design test** | "Can The Couple use this together without it becoming stressful?" |

---

### Persona 5: The Veteran

| Attribute | Detail |
|-----------|--------|
| **Demo** | 45M, operations director, 6 months into RNF, running out of content |
| **Daily routine** | 5am wake, disciplined schedule, habits are automatic now |
| **Why RNF** | Habits are built — needs reason to stay. Wants endgame. |
| **Theme** | Warrior |
| **Difficulty** | Standard |
| **Commitment** | Full (Stage 3) |
| **Pain points** | Hit max tier, no new challenges, feels like app served its purpose |
| **Feature priorities** | Prestige/chapters, harder challenges, mentor role, legacy content |
| **Churn triggers** | Nothing new to achieve, app feels stale, "I don't need this anymore" |
| **Delight moments** | Prestige reset with permanent badge, mentoring newer users, yearly stats |
| **Design test** | "Does The Veteran have a reason to open the app on month 7?" |

---

### Using Personas in Design Reviews

For every new feature, screen, or copy change, ask:

1. ✅ Does The Gamer find this engaging?
2. ✅ Does The Optimizer find this useful?
3. ✅ Would The Recoverer survive this without shame?
4. ✅ Can The Couple use this together?
5. ✅ Does The Veteran have something new here?

If a feature fails for 2+ personas, redesign before shipping.

---

## 8. Inclusive Language Guidelines

These guidelines apply to ALL user-facing copy in RNF — narrative, UI labels, notifications, onboarding, error messages, and marketing.

### Core Principles

1. **Empowerment over shame.** Never imply the user is broken, lazy, or failing.
2. **Invitation over demand.** Frame actions as opportunities, not obligations.
3. **Growth over perfection.** Celebrate progress, not just completion.
4. **Universal over cultural.** Avoid idioms, metaphors, or references that require specific cultural knowledge.
5. **Neutral over gendered.** Use "you/your" — avoid "guys," "man up," "warrior princess."

### Language Patterns to Use

| Instead of... | Use... | Why |
|---------------|--------|-----|
| "You failed" | "Tomorrow's a fresh start" | Removes shame |
| "Don't break your streak" | "Keep your momentum going" | Positive framing |
| "You must complete..." | "Your goal for today:" | Invitation vs. demand |
| "Discipline is everything" | "Consistency builds strength" | Less militaristic |
| "Crush your goals" | "Move toward your goals" | Less violent |
| "No excuses" | "Every day is different" | Acknowledges reality |
| "Grind harder" | "Show up again" | Sustainable framing |
| "Master yourself" | "Grow into who you want to be" | Less controlling |
| "Weak/strong" | "Building/built" | Non-judgmental |
| "Punishment" (for missed days) | "Reset" or "fresh start" | No negative framing |

### Notification Copy Guidelines

- **Morning:** Energizing but not demanding. "Ready when you are" > "Time to work"
- **Reminder:** Gentle nudge, not guilt. "Still time today" > "You haven't done anything"
- **Missed day:** Compassionate. "See you tomorrow" > "You broke your streak"
- **Return:** Welcoming. "Welcome back" > "Where have you been?"

### Theme-Specific Language Boundaries

| Theme | Can use | Avoid |
|-------|---------|-------|
| Warrior | "forge," "battle," "conquer" | "kill," "destroy," "dominate," "punish" |
| Garden | "grow," "bloom," "nurture" | "weed out" (negative), "prune" (cutting) |
| Scholar | "learn," "discover," "illuminate" | "ignorant," "fail," "test" (exam anxiety) |

### Copy Review Checklist

Before any user-facing text ships:

- [ ] Would The Recoverer feel safe reading this?
- [ ] Is this copy functional in all three themes?
- [ ] Does it work without cultural context?
- [ ] Is it gender-neutral?
- [ ] Does it avoid shame, guilt, or fear as motivators?
- [ ] Would it translate well to another language? (No idioms, puns, or slang)
- [ ] Is the tone consistent with the selected theme?

### Forbidden Patterns

These should NEVER appear in user-facing copy:

- ❌ Body shaming or weight-related language
- ❌ Comparison to other users without consent (leaderboards are opt-in)
- ❌ Time-pressure manipulation ("Only 2 hours left!")
- ❌ Loss aversion framing ("You'll lose everything!")
- ❌ Gendered assumptions ("As a man/woman...")
- ❌ Ableist language ("crazy," "lame," "blind spot")
- ❌ Mental health diagnoses as labels ("Your ADHD mode")
- ❌ Religious/spiritual assumptions ("Blessed," "prayer," "universe")

---

## Cross-References

| Topic | Spec |
|-------|------|
| Dynamic Type & Accessibility | SPEC_UI_UX_FIXES |
| Buddy System (full) | SPEC_GROWTH_VIRALITY, Section 4 |
| Endgame / Prestige | SPEC_ENGAGEMENT_ENDGAME |
| Analytics & Insights | SPEC_ENGAGEMENT_ENDGAME |
| Onboarding Flow | SPEC_ONBOARDING_MONETIZATION |

---

## Implementation Priority

| Section | Priority | Effort | Impact |
|---------|----------|--------|--------|
| 1. Alternative Themes | P1 | High | Unlocks 60% more market |
| 2. Adaptive Mode | P1 | Medium | Retention for ND users |
| 4. Progressive Commitment | P1 | Medium | Reduces Day 1 churn |
| 5. Age-Inclusive Design | P2 | Low | Mostly covered by a11y fixes |
| 6. Cultural Sensitivity | P2 | Medium | Enables future localization |
| 3. Buddy System | P2 | High | See SPEC_GROWTH_VIRALITY |
| 7. Persona Profiles | P0 (Reference) | None | Guides all decisions |
| 8. Language Guidelines | P0 (Reference) | None | Applies to all copy |

---

*End of specification.*
