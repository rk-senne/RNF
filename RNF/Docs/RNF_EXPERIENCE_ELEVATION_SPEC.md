# RNF Phase 20 — Soul & Experience Elevation

Version: 1.0  
Status: APPROVED  
Priority: P0 — This is the difference between "used" and "loved"  
Last Updated: 2026-06-29

---

## Objective

Elevate RNF from a 7/10 technical achievement to a 9-10/10 holistic experience. Every interaction must create emotional resonance. The app should feel like a living discipline companion, not a task manager with RPG paint.

---

## Design North Star

> "Opening RNF should feel like stepping into your personal dojo. Completing a habit should feel like landing a punch. Closing the day should feel like sheathing your sword."

---

## EXP-01: Dynamic Daily Narrative

**Problem:** The app opens to a static task list. No greeting, no context, no emotional hook. Day 1 and day 60 look identical.

**Vision:** Every day opens with a 2-line narrative that makes the user feel *seen*. The narrative acknowledges where they are, what they've done, and what's ahead.

### Examples by State

**New user, day 1:**
> "The forge awaits its first spark. Today you begin."

**7-day streak:**
> "Seven days. Most quit by now. You didn't. The Disciple sharpens."

**Missed yesterday, came back:**
> "You stumbled. You returned. That IS discipline."

**Day 45, high Focus stat:**
> "The mind is your strongest blade now. 45 days of proof."

**Day 90, challenge complete:**
> "Ninety days ago, you made a promise. Today, you kept it."

### Implementation

- `NarrativeEngine.swift` — pure function: `(Profile, GameState, DailyLog, Date) → String`
- Input signals: streak length, evolution tier, weakest stat, strongest stat, days since start, yesterday's status, current quest theme
- 50+ narrative templates organized by state bucket
- Displayed in a dedicated section above quests in ContentView
- Typography: italic, slightly larger, `.secondary` color — feels like inner monologue
- Fades in on appear (0.4s opacity, respects Reduce Motion)
- Changes at midnight (cached per day)

### Acceptance Criteria

- AC-1: Narrative MUST be contextually relevant (never generic)
- AC-2: Narrative MUST change daily (never repeat on consecutive days)
- AC-3: Narrative MUST acknowledge missed days without guilt (growth framing)
- AC-4: Narrative MUST scale from day 1 to day 365+
- AC-5: At least 50 unique templates covering all state combinations

### Files

- `RNF/Systems/NarrativeEngine.swift` (new)
- `RNF/Features/Habits/ContentView.swift` (add narrative section)

---

## EXP-02: Reward Moment Redesign

**Problem:** Completing a habit — the single most important interaction — feels like nothing. A 2% scale, a toast, gone. The moment that should create dopamine creates apathy.

**Vision:** Tapping "done" should be the best 0.5 seconds in the app. Every. Single. Time.

### The New Completion Sequence (0.5s total)

1. **Frame 0ms:** Tap detected
2. **Frame 0-50ms:** Row snaps to `scaleEffect(0.95)` — tactile press
3. **Frame 50ms:** `RNFHaptics.impact(.medium)` fires
4. **Frame 50-200ms:** Row springs to `scaleEffect(1.03)` with the completed gradient flooding in from left to right (wipe transition)
5. **Frame 200ms:** Checkmark icon scales in from 0 → 1 with `.spring(response: 0.25, dampingFraction: 0.6)`
6. **Frame 200-350ms:** XP number floats up from the row (+10 XP) with upward drift + fade out
7. **Frame 350ms:** Row settles to `scaleEffect(1.0)`, completed state
8. **Frame 350-500ms:** If this completes the daily goal → bigger celebration fires from NotificationManager

### Additional Reward Layers

- **Streak combo:** Complete 2+ habits within 60 seconds → "COMBO x2" appears briefly, +5 bonus XP
- **Stat growth flash:** The stat that gained points briefly highlights in the stat pill area
- **Sound:** Soft completion tone (optional, off by default) — a single "tink" like a sword on an anvil

### Implementation

- Refactor `HabitRow.swift` completion animation to a multi-stage choreographed sequence
- Add floating XP text overlay using `matchedGeometryEffect` or manual offset animation
- Add combo detection in `HabitsViewModel` (timestamp of last completion, if < 60s → combo)
- Add `CompletionSoundPlayer.swift` using `AVAudioPlayer` with a single .caf asset

### Acceptance Criteria

- AC-1: Full completion sequence MUST complete in ≤ 500ms
- AC-2: Haptic MUST fire at the press moment (not after animation)
- AC-3: XP float MUST originate from the completed row's position
- AC-4: Combo bonus MUST only trigger for rapid sequential completions
- AC-5: All animations MUST respect Reduce Motion (instant complete, no float)
- AC-6: Sound MUST be off by default, togglable in settings

### Files

- `RNF/Components/HabitRow.swift` (major animation rework)
- `RNF/Components/FloatingXPText.swift` (new)
- `RNF/ViewModels/HabitsViewModel.swift` (combo detection)
- `RNF/Core/CompletionSoundPlayer.swift` (new)
- `RNF/Resources/completion.caf` (asset, ~20KB)

---

## EXP-03: Morning Intention & Evening Reflection Ritual

**Problem:** No ritual frame. Users open → see tasks → do them → leave. There's no psychological bookend that makes the app feel like a *practice* rather than a *checklist*.

**Vision:** Two micro-rituals that take <5 seconds each but create the feeling of opening and closing a session.

### Morning Intention (first open of the day)

Triggers on first `app_opened` per calendar day.

**Screen layout:**
- Full-screen, clean background
- Time-aware greeting: "Good morning" / "Good afternoon" (adjusts after noon)
- Today's narrative (from EXP-01)
- Three stat icons in a row — user taps one to set their "focus intent" for the day
- Intent selection subtly weights XP (+10% to chosen stat for today)
- "Begin" button → transitions to normal home screen

**Duration:** 3-5 seconds to read + tap + begin. Not a blocker. If user taps "Begin" without choosing, defaults to weakest stat.

### Evening Reflection (triggers after all daily quests complete)

**Screen layout:**
- Appears as a sheet after the "Mission Complete" celebration
- Shows today's summary:
  - Habits completed: 4/4
  - XP earned: +85
  - Streak: 14 days
  - Stat growth: Focus +2, Discipline +1
- One line: "Tomorrow is day 15. Rest well."
- "Close Day" button → dismisses, writes analytics event

**Not a modal prison.** User can swipe down at any time. It's an invitation, not a gate.

### Implementation

- `RNF/Features/Rituals/MorningIntentionView.swift` (new)
- `RNF/Features/Rituals/EveningReflectionView.swift` (new)
- `RNF/Core/RitualManager.swift` — tracks today's first open, intent selection, daily completion state
- State stored in UserDefaults: `lastIntentDate`, `todayFocusStat`
- Morning view presented as `.fullScreenCover` from RootView on first appearance
- Evening view presented as `.sheet` when `dailyCompleted >= dailyGoal` first triggers

### Acceptance Criteria

- AC-1: Morning intention MUST appear only once per calendar day
- AC-2: Morning intention MUST be dismissable in < 2 seconds (not forced)
- AC-3: Intent selection MUST provide tangible XP bonus (not placebo)
- AC-4: Evening reflection MUST only appear after mission complete (not on partial)
- AC-5: Evening reflection MUST be dismissable immediately (swipe down)
- AC-6: Both rituals MUST respect Dynamic Type and VoiceOver

### Files

- `RNF/Features/Rituals/MorningIntentionView.swift` (new)
- `RNF/Features/Rituals/EveningReflectionView.swift` (new)
- `RNF/Core/RitualManager.swift` (new)
- `RNF/Navigation/RootView.swift` (presentation logic)
- `RNF/ViewModels/HabitsViewModel.swift` (evening trigger)

---

## EXP-04: The Discipline Card (Shareable Identity Artifact)

**Problem:** Users can't express their RNF identity externally. There's no viral loop, no social proof artifact, no "look what I built."

**Vision:** A beautifully rendered card that encapsulates the user's discipline identity. Shareable as an image. Think Spotify Wrapped meets a martial arts rank certificate.

### Card Design

```
┌─────────────────────────────────┐
│  [Tier Icon]                    │
│                                 │
│  IRON ASCENDANT                 │
│  Level 12 • 34 Day Streak      │
│                                 │
│  ┌─────────────────────┐       │
│  │   [Radar Chart]     │       │
│  │   (small, filled)   │       │
│  └─────────────────────┘       │
│                                 │
│  "Day 34 of the forge."        │
│                                 │
│  ─── RNF ───                   │
└─────────────────────────────────┘
```

- Background: gradient based on evolution tier color
- Tier icon: large, centered, glowing
- Stats radar chart: compact, filled, no labels (visual fingerprint)
- Dynamic tagline from NarrativeEngine
- RNF wordmark at bottom
- Rendered as a SwiftUI view → exported via `ImageRenderer`

### Unlock Triggers

| Milestone | Card Type |
|-----------|-----------|
| Day 7 | "First Week" card |
| Day 30 | "One Month" card |
| Day 90 | "Challenge Complete" card |
| Each tier evolution | "Evolution" card |
| Level 10, 20, 30... | "Level Milestone" card |

### Share Flow

1. Milestone reached → celebration overlay includes "Share Your Card" button
2. Tapping opens card preview (full resolution)
3. Share button → `UIActivityViewController` with rendered PNG
4. Card also accessible from Profile anytime ("My Card")

### Implementation

- `RNF/Features/Profile/DisciplineCardView.swift` (new) — the visual card
- `RNF/Features/Profile/DisciplineCardRenderer.swift` (new) — `ImageRenderer` wrapper
- `RNF/Core/MilestoneCardTrigger.swift` (new) — determines when to show card prompt
- Integration with `NotificationManager` for milestone celebrations

### Acceptance Criteria

- AC-1: Card MUST render at 2x resolution for sharing (clean on all screens)
- AC-2: Card MUST reflect current tier, level, streak, and stats accurately
- AC-3: Card background MUST adapt to evolution tier (each tier = distinct gradient)
- AC-4: Share MUST work via standard iOS share sheet (Messages, Instagram Stories, Twitter)
- AC-5: Card MUST be accessible from Profile at any time (not just at milestones)
- AC-6: Card MUST NOT include any private data (no email, no user ID)

### Files

- `RNF/Features/Profile/DisciplineCardView.swift` (new)
- `RNF/Features/Profile/DisciplineCardRenderer.swift` (new)
- `RNF/Core/MilestoneCardTrigger.swift` (new)
- `RNF/Features/Profile/ProfileView.swift` (add card entry point)


---

## EXP-05: Power Streaks (Compounding Rewards)

**Problem:** Streaks are a number. They don't *do* anything. Breaking a streak is just a counter reset — no tangible loss. Building one grants no tangible power.

**Vision:** Streaks become your most valuable asset. They compound real mechanical power. Breaking one costs you something you *feel*.

### Streak Tier System

| Streak | Tier Name | XP Multiplier | Perks |
|--------|-----------|:---:|------|
| 1-6 days | Spark | 1.0x | None |
| 7-13 days | Ember | 1.05x | +5% XP on all actions |
| 14-29 days | Flame | 1.10x | +10% XP, streak badge on profile |
| 30-59 days | Blaze | 1.15x | +15% XP, +1 forgiveness token |
| 60-89 days | Inferno | 1.20x | +20% XP, exclusive title unlocked |
| 90+ days | Eternal | 1.25x | +25% XP, profile glow effect, "Eternal" badge |

### Breaking Cost

When a streak breaks (missed day, no forgiveness):
- Multiplier drops to Spark (1.0x)
- Tier name reverts
- Glow/badge removed
- BUT: "Best Streak" is permanently recorded and displayed

This creates real loss aversion without being cruel. The forgiveness system protects against accidents. Breaking means you chose not to show up AND used your safety net already.

### Visual Integration

- Streak tier name displayed next to streak count: "🔥 14 days • Flame"
- Active multiplier shown subtly on habit completion: "+10 XP (×1.10)"
- Tier-up moment: mini-celebration when crossing a threshold (similar to level-up but smaller)
- Profile glow at 90+ days: subtle animated border on the Ascension level circle

### Implementation

- `RNF/Systems/StreakTierSystem.swift` (new) — tier calculation, multiplier logic
- Update `PerkSystem.swift` to include streak multiplier in XP calculations
- Update `HabitsViewModel` to apply streak multiplier on completion
- Update stat pill in ContentView to show tier name
- Add tier-up detection in `ProgressionEngine`

### Acceptance Criteria

- AC-1: Multiplier MUST apply to ALL XP sources (habits, workouts, reading)
- AC-2: Tier-up MUST fire a celebration (smaller than level-up, larger than toast)
- AC-3: Breaking MUST immediately revert to Spark (no grace period beyond forgiveness)
- AC-4: "Best Streak" MUST persist permanently in profile
- AC-5: Multiplier MUST be visible on every XP award: "+15 XP (×1.10)"
- AC-6: Forgiveness tokens MUST protect the streak tier (not just the counter)

### Files

- `RNF/Systems/StreakTierSystem.swift` (new)
- `RNF/Systems/PerkSystem.swift` (integrate streak multiplier)
- `RNF/Core/ProgressionEngine.swift` (tier-up detection)
- `RNF/Features/Habits/ContentView.swift` (display tier)
- `RNF/Components/HabitRow.swift` (show multiplier on XP)

---

## EXP-06: Living UI (Visual Evolution Over Time)

**Problem:** Day 1 looks identical to day 60. The UI never acknowledges growth. A veteran user gets the same sterile experience as a newcomer.

**Vision:** The app itself evolves as the user progresses. Subtle but unmistakable. Like a game where the home base upgrades as you level.

### Visual Evolution Layers

| Level Range | UI Treatment |
|-------------|-------------|
| 1-4 (Disciple) | Default clean white/dark surfaces. Minimal. "Empty dojo." |
| 5-9 (Awakened) | Subtle purple accent glow on card borders. Badge appears on tab bar. |
| 10-14 (Ascendant) | Card backgrounds gain a very subtle gradient shimmer. Header card gains depth. |
| 15-19 (Warlord) | Accent shifts to deeper tones. Radar chart gets a second ring (progress ghost). |
| 20+ (Apex) | Full premium treatment: subtle particle ambient in Ascension view. Gold accents on completed states. |

### How It Works

- `UIEvolutionProvider.swift` — reads current level, outputs a `UIEvolutionState` with:
  - `accentVariant: Color`
  - `surfaceStyle: SurfaceStyle` (plain, shimmer, gradient)
  - `showAmbientParticles: Bool`
  - `completedAccent: Color` (green → gold at apex)
  - `borderGlow: Bool`
- Views read from this provider via EnvironmentObject
- Changes are gradual — user notices "something feels different" without being jarring

### Key Constraint

This MUST be subtle. Not a theme overhaul — a *patina of use*. Like a leather journal that looks different after years of daily writing. The app should feel "worn in" by someone who shows up.

### Implementation

- `RNF/Core/UIEvolutionProvider.swift` (new) — derives visual state from level
- `RNF/DesignSystem/EvolvingStyles.swift` (new) — conditional style modifiers
- Update surface/accent references to conditionally apply evolution state
- Add ambient particle view (only at level 20+, only in Ascension)

### Acceptance Criteria

- AC-1: Visual changes MUST be subtle (user feels it, doesn't consciously notice immediately)
- AC-2: Evolution MUST be progressive (not a sudden jump)
- AC-3: Particles MUST respect Reduce Motion (disabled entirely)
- AC-4: Level 1 experience MUST remain clean and minimal (no "empty" feeling)
- AC-5: Performance MUST not degrade at any evolution level (no extra render passes)
- AC-6: Dark mode and light mode MUST both evolve appropriately

### Files

- `RNF/Core/UIEvolutionProvider.swift` (new)
- `RNF/DesignSystem/EvolvingStyles.swift` (new)
- `RNF/Features/Ascension/AscensionView.swift` (ambient particles at apex)
- `RNF/Features/Habits/ContentView.swift` (surface evolution)

---

## EXP-07: The 90-Day Arc Visualization

**Problem:** The 90-day challenge — the emotional backbone of the app — is a tiny progress bar in a card. It should be the MAIN character.

**Vision:** A dedicated, beautiful "journey map" that makes the 90-day challenge feel epic. Think of a mountain path with markers for each milestone.

### Journey Map Design

A horizontal scrollable path (or vertical timeline) showing:

```
Day 1 ●━━━━━● Day 7 ━━━━━● Day 14 ━━━━━● Day 30 ━━━━━● Day 60 ━━━━━● Day 90
 🌱         🔥           ⚡           💎            🗡️           👑
 Spark      Ember        Flame       Blaze        Inferno      Eternal
```

- Current position animated with a pulsing dot
- Completed segments filled with tier-appropriate gradient
- Milestones show what was unlocked at each point
- Future milestones show what's coming (anticipation)
- Tapping a past milestone shows that day's "memory snapshot" (EXP-09)

### Entry Point

- Accessible from the challenge summary card (tap to expand)
- Also accessible from Ascension view as a "Journey" section
- On milestone days (7, 14, 30, 60, 90): auto-opens briefly as part of celebration

### Post-90 State

After challenge completion:
- Journey map shows the completed path (golden, fully lit)
- "Begin New Arc" button appears
- New arcs can be custom duration: 30, 60, or 90 days
- Previous arcs are archived and viewable (trophy case)

### Implementation

- `RNF/Features/Journey/JourneyMapView.swift` (new) — the scrollable path
- `RNF/Features/Journey/JourneyMilestoneView.swift` (new) — each milestone node
- `RNF/Models/JourneyArc.swift` (new) — arc definition, milestones
- Integration with challenge summary card (tap to navigate)
- Integration with `ChallengeEngine` for arc lifecycle

### Acceptance Criteria

- AC-1: Journey map MUST show current position clearly (pulsing indicator)
- AC-2: Future milestones MUST show what unlocks (creates anticipation)
- AC-3: Past milestones MUST be tappable for memory/detail
- AC-4: Post-90 MUST offer clear "next arc" path (no dead end)
- AC-5: Path MUST be horizontally scrollable with today centered on open
- AC-6: MUST be accessible (VoiceOver reads milestone descriptions sequentially)

### Files

- `RNF/Features/Journey/JourneyMapView.swift` (new)
- `RNF/Features/Journey/JourneyMilestoneView.swift` (new)
- `RNF/Models/JourneyArc.swift` (new)
- `RNF/Features/Habits/ContentView.swift` (navigation link from challenge card)
- `RNF/Features/Ascension/AscensionView.swift` (journey section)

---

## EXP-08: Immersive Workout Experience

**Problem:** Users stare at a ring for 1-15 minutes. No intensity feedback, no encouragement, no sense of effort. It's a countdown, not a training session.

**Vision:** The workout timer should make you feel like you're IN a workout — even though it's just timing you.

### Intensity Phases

The timer background and ring shift through phases:

| Progress | Phase | Visual | Audio Cue |
|----------|-------|--------|-----------|
| 0-30% | Warm Up | Cool blue ambient | — |
| 30-60% | Build | Deepening blue → purple gradient | — |
| 60-80% | Push | Purple → amber, ring pulses subtly | — |
| 80-100% | Finish Strong | Amber → green, ring brightens | Soft rising tone |
| 100% | Complete | Green burst, full celebration | Completion tone |

### Encouragement Text

Subtle text below the timer that rotates through the session:

- 0-30%: "Settle in. Find the rhythm."
- 30-60%: "Building momentum."
- 60-80%: "The hard part is where growth happens."
- 80-100%: "Almost there. Finish strong."
- Threshold (80%): "XP threshold reached. Everything from here is bonus."

### Breathing Pacer (optional)

For longer workouts (5min+), subtle breathing circle animation available:
- Expand circle: inhale (4s)
- Contract: exhale (4s)
- Helps with exercises like planks, stretching
- Toggle: small button, doesn't interfere with timer

### Implementation

- Update `ActiveWorkoutTimerView.swift`:
  - Add phase-based background gradient
  - Add encouragement text rotation
  - Add optional breathing pacer
- `RNF/Features/Workouts/WorkoutPhase.swift` (new) — phase calculation from progress
- Update `CircularProgressRing` to accept phase-based color (already interpolates, extend it)

### Acceptance Criteria

- AC-1: Background gradient MUST transition smoothly between phases (no jarring shifts)
- AC-2: Encouragement text MUST change at phase boundaries (not every second)
- AC-3: Breathing pacer MUST be optional and not interfere with timer display
- AC-4: 80% threshold MUST have distinct visual + haptic acknowledgment
- AC-5: All visual effects MUST respect Reduce Motion
- AC-6: Timer accuracy MUST not be affected by visual effects

### Files

- `RNF/Features/Workouts/ActiveWorkoutTimerView.swift` (major enhancement)
- `RNF/Features/Workouts/WorkoutPhase.swift` (new)
- `RNF/Components/BreathingPacer.swift` (new)


---

## EXP-09: Milestone Memories & Progress Snapshots

**Problem:** Users can't look back at their journey. There's no emotional callback, no "look how far you've come" moment.

**Vision:** At key milestones, the app auto-generates a "memory" — a snapshot of who the user was at that point vs who they are now. Creates emotional weight.

### Milestone Memory Cards

| Trigger | Memory Content |
|---------|---------------|
| Day 7 | "One week in. XP: 320. Level: 2. Streak: 7. You chose this." |
| Day 14 | "Two weeks. Stats then vs now." (mini radar comparison) |
| Day 30 | "30 days. You outlasted 80% of people who try." + stat delta |
| Day 60 | "Two months of forging." + full before/after radar overlay |
| Day 90 | "The promise is kept." Full transformation summary |
| Each evolution tier-up | "You evolved. [Old Tier] → [New Tier]." + stat comparison |
| Level milestones (10, 20, 30) | "Level [X] reached. Total XP: [n]. Time spent forging: [days]." |

### Before/After Radar

The killer feature: overlay current radar chart on top of the saved radar at the milestone's snapshot point. User sees their shape literally growing.

### Storage

- On each milestone day, save a `ProgressSnapshot` to UserDefaults:
  - `date`, `level`, `streak`, `xp_total`, `stats` (7 values), `tier`
- Snapshots are lightweight (~200 bytes each)
- Max ~20 snapshots over a full lifecycle

### Presentation

- On milestone trigger: memory card appears as a bottom sheet after celebration
- Accessible anytime from Journey Map (EXP-07) — tap a past milestone to see its memory
- Accessible from Profile under "Memories" section

### Implementation

- `RNF/Models/ProgressSnapshot.swift` (new) — snapshot data model
- `RNF/Core/MemoryService.swift` (new) — save/load snapshots from UserDefaults
- `RNF/Features/Journey/MemoryCardView.swift` (new) — the visual card
- `RNF/Components/RadarComparisonView.swift` (new) — overlay current vs past radar
- Integration with milestone triggers in `ProgressionEngine`

### Acceptance Criteria

- AC-1: Snapshots MUST be saved automatically on milestone days (no user action)
- AC-2: Radar comparison MUST clearly show "then" (ghost/faded) vs "now" (solid)
- AC-3: Memory cards MUST be viewable anytime from Journey Map or Profile
- AC-4: Storage MUST NOT exceed 5KB total across all snapshots
- AC-5: Memory card MUST be shareable (renders as image, feeds into Discipline Card)
- AC-6: VoiceOver MUST read full memory text + stat comparison

### Files

- `RNF/Models/ProgressSnapshot.swift` (new)
- `RNF/Core/MemoryService.swift` (new)
- `RNF/Features/Journey/MemoryCardView.swift` (new)
- `RNF/Components/RadarComparisonView.swift` (new)
- `RNF/Core/ProgressionEngine.swift` (trigger snapshots)

---

## EXP-10: Social Presence Layer

**Problem:** Social features exist in a tab but are invisible in the daily experience. Users never feel that others are forging alongside them.

**Vision:** Ambient social proof woven into the daily view. Not a social feed — a sense that you're part of something.

### Social Presence Elements

1. **Guild Pulse** (if in guild): Small bar below the header card:
   - "🔥 8 guild members completed today"
   - Updates as members complete (could lag, uses cached count)

2. **Friend Milestone Whisper:** Occasional note in the narrative area:
   - "Your friend [Name] just hit Level 10."
   - Max 1 per day, only for connected friends, dismissable

3. **Leaderboard Position Chip:** In Ascension view stat area:
   - "Ranked #4 in [Guild Name] this week"
   - Tappable → navigates to leaderboard

4. **Streak Comparison:** Calendar view shows guild average streak as a subtle underline:
   - User's streak vs guild average (e.g., "You: 14 • Guild avg: 9")

### Privacy & Control

- All social elements toggleable in settings: "Social Presence: On/Off"
- Never shows exact user data of others without their consent
- Aggregate stats only (guild count, averages) unless user has accepted friend connection
- No push notifications from social (pull only when app is open)

### Implementation

- `RNF/Core/SocialPresenceProvider.swift` (new) — fetches guild activity, friend milestones
- `RNF/Components/GuildPulseBar.swift` (new) — "8 members completed today"
- Update `ContentView` to include GuildPulseBar below header (if user in guild)
- Update `AscensionView` to include leaderboard position chip
- Cache social data (refresh max 1x per hour)

### Acceptance Criteria

- AC-1: Social presence MUST be off by default for non-guild users
- AC-2: Social data MUST be cached (no request per screen open)
- AC-3: Friend milestones MUST appear max 1x per day
- AC-4: MUST be fully toggleable off in settings
- AC-5: MUST NOT affect app performance when offline (graceful fallback: hidden)
- AC-6: MUST NOT show real names without friend connection consent

### Files

- `RNF/Core/SocialPresenceProvider.swift` (new)
- `RNF/Components/GuildPulseBar.swift` (new)
- `RNF/Features/Habits/ContentView.swift` (guild pulse integration)
- `RNF/Features/Ascension/AscensionView.swift` (rank chip)

---

## EXP-11: Reading Experience Upgrade

**Problem:** Reading is "upload a photo." That's accountability but not engagement. The user's reading life isn't tracked or celebrated.

**Vision:** Make reading feel like a discipline pillar, not a checkbox. Track the reading *journey*, not just daily proof.

### Reading Profile

- **Current Book:** User can optionally set what they're reading (title only, manual entry)
- **Pages Logged:** Running total (user enters page count with proof, default 10)
- **Books Completed:** Counter that increments when user marks a book done
- **Reading Streak:** Separate sub-streak for reading specifically

### Updated Read View

```
┌─────────────────────────────────┐
│ READ                            │
│ "Train attention. Feed mind."   │
│                                 │
│ Currently Reading:              │
│ ┌─────────────────────────────┐ │
│ │ 📖 Atomic Habits            │ │
│ │    Page 145 • Day 12        │ │
│ └─────────────────────────────┘ │
│                                 │
│ Today's Proof: [Upload Button]  │
│                                 │
│ Stats:                          │
│ 📄 1,230 pages total           │
│ 📚 4 books completed           │
│ 🔥 12 day reading streak       │
└─────────────────────────────────┘
```

### Book Completion Celebration

When user marks a book complete:
- Celebration overlay with book name
- "+1 Book" added to reading profile
- Special "Librarian" title unlock at 5 books
- Discipline Card updated with book count

### Implementation

- `RNF/Models/ReadingProfile.swift` (new) — current book, page count, books completed
- `RNF/Core/ReadingProfileService.swift` (new) — persist reading state (UserDefaults)
- Update `ReadView.swift` — add current book section, page entry, stats display
- Add book completion flow (mark done → celebration → reset current book)

### Acceptance Criteria

- AC-1: Current book MUST be optional (user can skip and just upload proof)
- AC-2: Page count MUST be manually entered (not OCR — keep it simple)
- AC-3: Reading streak MUST track independently from main streak
- AC-4: Book completion MUST trigger a unique celebration
- AC-5: All reading stats MUST persist across sessions (UserDefaults)
- AC-6: Reading data MUST appear on Discipline Card (books completed count)

### Files

- `RNF/Models/ReadingProfile.swift` (new)
- `RNF/Core/ReadingProfileService.swift` (new)
- `RNF/Features/Read/ReadView.swift` (major enhancement)

---

## EXP-12: Seasonal Arcs & Limited-Time Content

**Problem:** After day 90, content becomes static. The quest system generates variety but nothing feels *new* or time-limited.

**Vision:** Monthly themed arcs that create urgency, freshness, and exclusivity. Miss it and it's gone.

### Arc Structure

Each calendar month has a themed arc (optional participation):

| Month | Arc Name | Theme | Bonus |
|-------|----------|-------|-------|
| January | "Foundation" | All stats balanced | +10% all XP |
| February | "Endurance" | Streak focus | Double streak tier bonuses |
| March | "Strength" | Workout heavy | +20% workout XP |
| April | "Mind" | Reading + Focus | +20% reading XP, Focus quests |
| May | "Discipline" | Perfect days | Bonus for all-complete days |
| ... | Rotates annually | | |

### Mechanics

- Arc has a progress bar (actions that match theme fill it faster)
- Completing an arc (filling bar by month end) unlocks:
  - Exclusive monthly title: "Forged in Fire • March 2026"
  - Exclusive badge (never available again)
  - Bonus XP dump (500 XP)
- Not completing: no penalty, you just miss the exclusive

### FOMO Without Cruelty

- Arcs are BONUSES, not requirements
- Missing an arc doesn't break your streak or progression
- It adds bonus XP and exclusive cosmetics for participation
- Creates "I need to finish before the month ends" urgency
- Missed arcs appear in "Archive" greyed out — visible reminder

### Implementation

- `RNF/Systems/SeasonalArcSystem.swift` (new) — determines current arc, progress calculation
- `RNF/Models/SeasonalArc.swift` (new) — arc definition, rewards
- `RNF/Features/Habits/ContentView.swift` — arc progress bar below quests (if participating)
- `RNF/Features/Profile/ArcArchiveView.swift` (new) — view past arcs and missed ones
- Arc progress calculated from existing actions (no new backend needed)

### Acceptance Criteria

- AC-1: Arc participation MUST be implicit (no opt-in; doing actions that match = progress)
- AC-2: Monthly title MUST include month+year (making it permanently unique)
- AC-3: Missed arcs MUST be visible but greyed out in archive (creates collection desire)
- AC-4: Arc rewards MUST NOT be required for progression (purely cosmetic + bonus XP)
- AC-5: Arc progress MUST be visible on home screen during the month
- AC-6: Arc MUST work offline (calculated client-side from completed actions)

### Files

- `RNF/Systems/SeasonalArcSystem.swift` (new)
- `RNF/Models/SeasonalArc.swift` (new)
- `RNF/Features/Habits/ContentView.swift` (arc progress display)
- `RNF/Features/Profile/ArcArchiveView.swift` (new)

---

## EXP-13: Focus Timer (Deep Work Companion)

**Problem:** RNF tracks workouts (body) and reading (mind) but ignores the most valuable habit for professionals: focused deep work.

**Vision:** A Pomodoro-style focus timer that awards XP to Mind/Focus stats. Makes RNF a complete discipline OS, not just fitness+reading.

### Focus Session Types

| Duration | Name | XP Award |
|----------|------|:---:|
| 15 min | Quick Focus | 10 XP |
| 25 min | Standard | 15 XP |
| 45 min | Deep Session | 25 XP |
| 60 min | Flow State | 35 XP |

### UX

- Accessible from Habits tab (as an optional "Focus" quest)
- OR from a dedicated button in the nav area
- Same CircularProgressRing as workout timer
- Background shifts through focus-appropriate colors (deep blue → indigo)
- Encouragement text: "Depth over speed." / "One task. Full attention."
- On completion: awards XP to Mind + Focus stats
- Counts toward daily goal if "Focus" is in quest plan

### Do Not Disturb Integration

- On start: offers to enable Focus mode (iOS DND)
- On completion: suggests disabling
- Completely optional — no permissions required if user declines

### Implementation

- `RNF/Features/Focus/FocusTimerView.swift` (new) — reuses CircularProgressRing
- `RNF/Features/Focus/FocusSessionType.swift` (new) — duration/XP definitions
- Integration with `QuestGenerator` — can generate Focus quests when Mind/Focus are weak stats
- Integration with `ProgressionEngine` — awards XP on completion
- Tab bar: Consider 5th tab OR accessible from Habits as a special quest type

### Acceptance Criteria

- AC-1: Focus timer MUST reuse existing CircularProgressRing component
- AC-2: XP award MUST go to Mind and Focus stats
- AC-3: DND integration MUST be optional (prompt, not forced)
- AC-4: Focus sessions MUST count toward daily goal when Focus is a quest
- AC-5: Timer MUST continue when app is backgrounded (same behavior as workout)
- AC-6: Completion MUST trigger same celebration path as workout (toast + haptic)

### Files

- `RNF/Features/Focus/FocusTimerView.swift` (new)
- `RNF/Features/Focus/FocusSessionType.swift` (new)
- `RNF/Systems/QuestGenerator.swift` (add Focus quest generation)
- `RNF/Navigation/RootView.swift` (entry point)

---

## Dependency Graph

```
EXP-01 (Narrative) ← Independent (build first — sets emotional tone)
EXP-02 (Reward Moment) ← Independent (highest daily impact)
EXP-03 (Rituals) ← Depends on EXP-01 (morning shows narrative)
EXP-04 (Discipline Card) ← Depends on EXP-01 (card uses narrative tagline)
EXP-05 (Power Streaks) ← Independent 
EXP-06 (Living UI) ← Independent
EXP-07 (Journey Map) ← Depends on EXP-09 (milestones show memories)
EXP-08 (Workout Immersion) ← Independent
EXP-09 (Memories) ← Independent (build before EXP-07)
EXP-10 (Social Presence) ← Independent
EXP-11 (Reading Upgrade) ← Independent
EXP-12 (Seasonal Arcs) ← Depends on EXP-05 (arcs reference streak tiers)
EXP-13 (Focus Timer) ← Independent
```

## Execution Order

| Sprint | Issues | Rationale |
|--------|--------|-----------|
| 1 | EXP-01, EXP-02 | Emotional foundation + daily delight |
| 2 | EXP-05, EXP-09 | Streak value + memory system |
| 3 | EXP-03, EXP-04 | Rituals + shareable identity |
| 4 | EXP-06, EXP-08 | Living UI + workout immersion |
| 5 | EXP-07, EXP-11 | Journey map + reading depth |
| 6 | EXP-10, EXP-12, EXP-13 | Social + arcs + focus timer |

## Novelty Summary

What makes RNF different from every other habit app after these additions:

| Feature | What Others Do | What RNF Does |
|---------|---------------|---------------|
| **Habit completion** | Checkbox → done | Choreographed 500ms reward sequence with haptic + float + combo |
| **Streaks** | Counter | Compounding power system with tangible mechanical benefit |
| **Progress** | Stats page | Living UI that evolves as you grow — your app ages with you |
| **Identity** | Profile page | Shareable Discipline Card — your rank made visual |
| **Daily open** | Task list | Personalized narrative + morning intention ritual |
| **Long-term** | Same UI forever | Seasonal arcs, milestone memories, journey map |
| **Reading** | Checkbox | Full reading profile with books, pages, reading streak |
| **Social** | Separate tab | Ambient guild presence woven into daily view |
| **Workouts** | Timer | Phase-based immersive experience with encouragement |
| **Deep work** | Not tracked | Focus timer with stat progression |

**This is how you get a 10/10.** Not by having more features — by making every moment *feel* like something.

---

## Definition of Done (per EXP issue)

- [ ] All acceptance criteria pass
- [ ] Build succeeds
- [ ] Dark + Light mode verified
- [ ] Reduce Motion path verified
- [ ] VoiceOver tested
- [ ] Dynamic Type AX3 verified
- [ ] Performance: 60fps maintained
- [ ] Feels genuinely good to use (subjective gut check)


---

## EXP-14: Passive Discipline Rewards (Easter Egg System)

**Problem:** RNF only rewards explicit actions (tap habit, run timer, upload photo). But discipline happens all day — walks, runs, steps. The app ignores it.

**Vision:** Hidden XP rewards that trigger from HealthKit data without the user explicitly logging anything. Opens the app → surprise: "You walked 10,000 steps. +25 XP." Feels like the app is paying attention to their real life.

### How It Discovers

On app foreground (via existing `HealthKitService`):
1. Check today's step count
2. Check if any Apple Health workouts completed since last check
3. Compare against hidden thresholds
4. If threshold crossed → trigger "Discovery" reward

### Hidden Thresholds (Easter Eggs)

| Trigger | Name | XP | Message |
|---------|------|:---:|---------|
| 5,000 steps today | "The Walker" | +10 | "5K steps today. The body moved." |
| 10,000 steps today | "The Wanderer" | +25 | "10K steps. Discipline in motion." |
| 15,000+ steps today | "The Pilgrim" | +40 | "15K. You walked further than most ever will." |
| Running workout detected (≥2km) | "The Runner" | +20 | "You ran today. The forge respects effort." |
| Running workout ≥5km | "Distance Forged" | +35 | "5K run. Strength earned in silence." |
| Running workout ≥10km | "The Endurance" | +50 | "10K. Most people will never understand this." |
| 3 days in a row with 8K+ steps | "Consistency Walker" | +30 | "Three days walking. Patterns become power." |
| Weekend workout detected | "No Rest Days" | +15 | "Saturday forge. Discipline doesn't take weekends." |

### Discovery UX

- **NOT a notification.** Only triggers when user opens the app.
- Appears as a special toast variant with a "✨" icon and gold tint
- Message appears for 3 seconds, then fades
- XP is silently added to Energy/Strength stats
- Achievement log records it (visible in a hidden "Discoveries" section in Profile)

### Rules & Constraints

- Max 1 discovery reward per category per day (can't spam 10K steps repeatedly)
- Step thresholds reset daily at midnight
- Running thresholds: 1 per workout session (deduped by HealthKit UUID)
- Multi-day streaks (like "3 days walking"): checked on app open, awarded once per streak achievement
- All HealthKit data stays on-device (never uploaded to Supabase)
- If HealthKit permission not granted: system is invisible (no broken UX)

### Discovery Log (Hidden Profile Section)

In Profile → small "🔍 Discoveries" link at bottom:
- Shows all earned easter egg rewards with dates
- "12 discoveries found" counter
- Locked discoveries shown as "???" with hint: "Keep moving."

### Why This Works

1. **Surprise delight:** User did nothing in-app but gets rewarded → "this app sees me"
2. **Passive engagement:** Even on days they skip habits, opening the app might give them a reward → reduces "shame spiral" of missed days
3. **HealthKit justification:** The app already requests health permissions — this makes that permission *feel valuable* to the user
4. **Easter egg psychology:** Hidden discoveries create word-of-mouth ("did you know RNF gives you XP for running?!")

### Implementation

- `RNF/Systems/PassiveDiscoverySystem.swift` (new):
  - `evaluate(steps: Int, workouts: [HealthWorkoutSummary], history: DiscoveryHistory) → [Discovery]`
  - Pure function, no side effects
- `RNF/Models/Discovery.swift` (new):
  - `id`, `name`, `message`, `xp`, `earnedDate`, `category`
- `RNF/Core/DiscoveryService.swift` (new):
  - Loads history from UserDefaults
  - Checks HealthKit on foreground
  - Awards XP through existing XP pipeline
  - Fires toast via NotificationManager
- `RNF/Features/Profile/DiscoveryLogView.swift` (new):
  - Shows earned + locked discoveries
- Integration point: `RootView` or `AppStateManager` foreground handler

### Acceptance Criteria

- AC-1: Discoveries MUST only trigger on app open (never push notifications)
- AC-2: Each discovery category MUST award max once per day
- AC-3: XP MUST flow through existing ProgressionEngine (not bypass)
- AC-4: If HealthKit not authorized, system MUST be completely invisible
- AC-5: All health data MUST stay on-device (privacy-first)
- AC-6: Discovery toast MUST use distinct visual style (gold tint, ✨ icon)
- AC-7: Discovery log MUST show locked items as hints (creates curiosity)
- AC-8: Running detection MUST deduplicate by HealthKit workout UUID

### Files

- `RNF/Systems/PassiveDiscoverySystem.swift` (new)
- `RNF/Models/Discovery.swift` (new)
- `RNF/Core/DiscoveryService.swift` (new)
- `RNF/Features/Profile/DiscoveryLogView.swift` (new)
- `RNF/Core/NotificationManager.swift` (add `.discovery` toast variant)
- `RNF/Navigation/RootView.swift` (trigger check on foreground)


---

## EXP-14 Extended: Full Easter Egg Compendium

The discovery system should span the entire user lifecycle and reward *unexpected* behaviors. The magic is that users never know the full list — they just keep finding them.

### Category A: Time-Based Discoveries

| Trigger | Name | XP | Message |
|---------|------|:---:|---------|
| Complete a habit before 6:00 AM | "Before Dawn" | +15 | "The world sleeps. You don't." |
| Complete all habits before 8:00 AM | "First Light Forge" | +25 | "All done before most people wake. Lethal efficiency." |
| Complete a habit after 11:00 PM | "The Late Forge" | +10 | "Late, but you showed up. That counts." |
| Open app at exactly midnight | "The Witching Hour" | +5 | "Midnight discipline. Rare breed." |
| Complete habits 7 days in a row before 9 AM | "Morning Protocol" | +40 | "A week of mornings owned. The pattern is you now." |
| Use the app on New Year's Day | "Day One" | +20 | "January 1st. Everyone talks. You're already doing." |
| Use the app on your birthday (if set) | "Birthday Forge" | +30 | "A year older. A year sharper." |
| Complete habits on Christmas/major holiday | "No Holidays" | +25 | "Holidays are for rest. You chose growth." |

### Category B: Consistency Discoveries

| Trigger | Name | XP | Message |
|---------|------|:---:|---------|
| 7 perfect days in a row (all quests complete) | "Perfect Week" | +50 | "Seven days. Zero compromise." |
| 30 perfect days | "The Unbroken Month" | +150 | "30 days without a single miss. Legends are made of this." |
| Complete 100 total habits | "Centurion" | +40 | "100 habits completed. Each one a brick in the wall." |
| Complete 500 total habits | "The Machine" | +100 | "500. You're not trying anymore. You just ARE." |
| Complete 1000 total habits | "Thousandfold" | +200 | "1,000 habits. Most people don't do 100 in a lifetime." |
| Log reading 30 days in a row | "Bookworm" | +60 | "30 days of pages. Knowledge compounds silently." |
| Complete a workout every day for 14 days | "Iron Body" | +50 | "Two weeks of movement. The body remembers." |
| Use forgiveness and then complete 7 days straight | "Redemption Arc" | +35 | "You fell. You recovered. You proved it wasn't who you are." |

### Category C: Stat-Based Discoveries

| Trigger | Name | XP | Message |
|---------|------|:---:|---------|
| All 7 stats above 10 | "Balanced" | +50 | "No weakness. Every stat above 10. The complete warrior." |
| Any single stat reaches 25 | "Specialist" | +40 | "One stat at 25. Mastery in a single domain." |
| All 7 stats above 20 | "Polymath" | +100 | "Every stat above 20. You are the exception." |
| Focus stat becomes your highest (was lowest) | "The Turnaround" | +30 | "Your weakest became your strongest. That's character." |
| Earn 1,000 total XP in a single day | "XP Surge" | +25 | "1K XP in one day. The forge burned hot." |
| Reach Level 5 | "Awakening" | +20 | "Level 5. Most quit before here. You didn't." |
| Reach Level 20 | "Veteran" | +50 | "Level 20. You're not a beginner at anything anymore." |

### Category D: Behavioral Discoveries (the really hidden ones)

| Trigger | Name | XP | Message |
|---------|------|:---:|---------|
| Open app 3 days after a streak break | "The Return" | +20 | "You came back. That's the only thing that matters." |
| Complete a habit within 10 seconds of opening | "Instant Action" | +10 | "No hesitation. Open → done. That's discipline." |
| Complete habits in the same order 5 days in a row | "Ritualist" | +20 | "Same order, 5 days running. Your ritual is forming." |
| Share your Discipline Card for the first time | "Identity Declared" | +15 | "You shared who you're becoming. Bold." |
| Set morning intention 7 days in a row | "Intentional" | +25 | "A week of chosen focus. Not reactive — proactive." |
| Use the app in 3+ different locations (based on timezone shifts or rough location) | — | — | *Skip this — privacy concern* |
| Complete a focus session (EXP-13) for the first time | "Deep Diver" | +15 | "First focus session. The mind has entered the dojo." |
| Defeat your first boss | "Slayer" | +25 | "First boss defeated. The demons are real and beatable." |
| Earn your first achievement | "Collector" | +10 | "First achievement unlocked. There are many more hiding." |
| Reach Eternal streak tier (90 days) | "Eternal" | +100 | "90 days without breaking. You are the exception to every rule." |

### Category E: Meta/Secret Discoveries

| Trigger | Name | XP | Message |
|---------|------|:---:|---------|
| Find and open the Discovery Log for the first time | "The Curious" | +5 | "You found the hidden log. Curiosity is its own reward." |
| Earn 10 discoveries | "Seeker" | +30 | "10 discoveries found. You pay attention." |
| Earn 25 discoveries | "The Archaeologist" | +60 | "25. Most users will never find half of these." |
| Earn ALL discoveries | "Omniscient" | +200 | "Every secret found. There is nothing left to hide from you." |
| Have the app installed for exactly 365 days | "One Year" | +100 | "365 days since you downloaded RNF. Look who you've become." |
| Complete the 90-day challenge twice | "Double Forged" | +75 | "180 days of challenges. This isn't a phase. It's who you are." |

### Category F: HealthKit Passive (from original EXP-14)

*(Already defined above — steps, running, weekend workouts, consistency walking)*

---

### Discovery Rarity Tiers

| Tier | Color | Criteria |
|------|-------|----------|
| Common | White | Time-based, easy to trigger |
| Uncommon | Blue | Requires 1-2 weeks of behavior |
| Rare | Purple | Requires 30+ days or specific stat states |
| Legendary | Gold | Major milestones (1000 habits, all stats 20+, Omniscient) |

Discovery Log shows the rarity tier. Locked items show tier color but name as "???".

---

### Total Discovery Count: ~45-50

Enough that users keep finding them for months. Few enough that earning "Omniscient" is genuinely impressive and takes 6-12 months of dedicated use.

### Key Design Rules

1. **Never show the full list.** Users should discover organically.
2. **Never punish.** No discovery for negative behavior ("You missed 5 days" → no).
3. **Always surprise.** The toast should feel like finding a coin in an old jacket.
4. **Acknowledge recovery.** "The Return" and "Redemption Arc" reward coming back after failure.
5. **Scale with commitment.** Early discoveries are easy (first week). Later ones require months.
6. **Never require spending money.** No discovery locked behind subscription.


---

## EXP-15: Discipline Quotes Engine

**Problem:** The app has no ambient voice between interactions. Dead air everywhere.

**Vision:** 365 curated quotes — stoic, sharp, discipline-focused — that rotate daily and appear across surfaces.

### Surfaces

- Morning Intention screen (below narrative)
- Evening Reflection (closing thought)
- Widget subtitle (daily rotation)
- Saved favorites on Discipline Card as tagline

### Quote Tone

NOT generic motivation. Stoic, philosophical, uncomfortable truths:
- Marcus Aurelius, Epictetus, Jocko Willink, David Goggins, James Clear
- "You do not rise to the level of your goals. You fall to the level of your systems."
- "The impediment to action advances action."
- Tone: cold truth, earned wisdom, quiet intensity

### Favorites

- User can tap ♥ to save a quote to personal collection
- Saved quotes accessible from Profile → "My Quotes"
- One saved quote becomes the tagline on their Discipline Card

### Implementation

- `RNF/Systems/QuoteEngine.swift` (new) — 365 quotes indexed by day-of-year, deterministic selection
- `RNF/Models/DisciplineQuote.swift` (new) — quote text, author, dayIndex
- `RNF/Core/QuoteFavoritesService.swift` (new) — save/load favorites from UserDefaults
- Integration: MorningIntentionView, EveningReflectionView, WidgetProvider, DisciplineCardView

### Acceptance Criteria

- AC-1: Exactly 365 quotes, one per calendar day, never repeats within a year
- AC-2: Quote MUST match app tone (no "you can do it!" cheerfulness)
- AC-3: Favorites MUST persist across sessions
- AC-4: Widget MUST show today's quote as subtitle
- AC-5: Discipline Card MUST use favorited quote as tagline (or default if none saved)

---

## EXP-16: Multi-Pillar Streak Dashboard

**Problem:** One streak for everything. User skips a workout but their reading streak was 22 days — invisible and lost in the single counter.

**Vision:** Independent streaks per discipline pillar, displayed as a compact row of flames.

### Pillar Streaks

| Pillar | Tracked By | Icon |
|--------|-----------|------|
| Habits | Any habit completed today | 🔥 |
| Workouts | Workout completed today | 💪 |
| Reading | Reading proof uploaded today | 📖 |
| Focus | Focus session completed today | 🧠 |
| Overall | ALL above done in same day | ⚡ |

### Display

Compact row on home screen below the daily mission bar:
```
🔥14  💪8  📖22  🧠5  ⚡8
```

Each pillar streak breaks independently. Overall only breaks if you miss everything.

### Implementation

- `RNF/Systems/PillarStreakSystem.swift` (new) — tracks per-pillar consecutive days
- `RNF/Models/PillarStreaks.swift` (new) — struct with each pillar's count
- `RNF/Components/PillarStreakRow.swift` (new) — compact HStack display
- Storage: UserDefaults (last completion date per pillar + current count)
- Update triggers: habit completion, workout completion, reading completion, focus completion

### Acceptance Criteria

- AC-1: Each pillar MUST track independently
- AC-2: Overall streak MUST only break when ALL pillars miss
- AC-3: Display MUST be compact (single row, no scrolling)
- AC-4: Breaking a pillar streak MUST NOT affect other pillars
- AC-5: Pillar streaks MUST contribute to easter egg discoveries ("Iron Body", "Bookworm")

---

## EXP-17: Weekly Discipline Report

**Problem:** Days blur together. No sense of the week as a meaningful unit.

**Vision:** Every Sunday evening / Monday morning, a shareable full-screen weekly summary.

### Report Content

```
WEEK 6 COMPLETE

Days Active: 6/7
Habits Completed: 24
XP Earned: 680
Stat Growth: Focus +4, Discipline +2
Streak: 42 days (Blaze tier)
Best Day: Wednesday (180 XP)
Missed: Saturday

Consistency Rate: 86%

[Share Week]  [Continue →]
```

### Timing

- Triggers on first app open after Sunday midnight (or Monday morning)
- Presented as fullScreenCover (dismissable)
- Shows only once per week

### Shareable

- "Share Week" renders as image via ImageRenderer
- Same approach as Discipline Card
- Includes RNF branding at bottom

### Implementation

- `RNF/Core/WeeklyReportService.swift` (new) — aggregates past 7 days of logs/completions
- `RNF/Models/WeeklyReport.swift` (new) — struct with all aggregated data
- `RNF/Features/Reports/WeeklyReportView.swift` (new) — the visual card
- `RNF/Features/Reports/WeeklyReportRenderer.swift` (new) — image export
- Presentation: triggered from RootView on Monday open (once per week)

### Acceptance Criteria

- AC-1: Report MUST appear max once per week
- AC-2: Report MUST be dismissable immediately
- AC-3: "Best Day" MUST highlight the highest XP day
- AC-4: Share image MUST render cleanly at 2x resolution
- AC-5: Report MUST work offline (uses local data only)
- AC-6: Missed days acknowledged without guilt framing

---

## EXP-18: Habit Agency System (Progressive Unlock)

**Problem:** Users need agency but blank-slate custom creation on day 1 creates friction. System-only quests feel impersonal.

**Vision:** Curated selection on day 0, earned customization over time. Discipline earns the right to design your own path.

### Onboarding: Pick 3 from Curated List (Day 0)

Presented after commitment, before first day begins.

**Preset Menu (12 options across 3 categories):**

Body:
- Cold shower (Energy)
- 10-minute walk (Strength)
- Stretch / mobility (Energy)
- No junk food (Discipline)

Mind:
- Read 10 pages (Wisdom)
- Journal 5 minutes (Mind)
- Meditate 5 minutes (Focus)
- No phone first hour (Discipline)

Spirit:
- Gratitude list (Spirit)
- Hydrate 2L water (Energy)
- Sleep before midnight (Discipline)
- Deep breathing 3 min (Focus)

User picks exactly 3. These become persistent "core habits" alongside system quests.

### Progressive Unlock

| Day | Unlock | Celebration |
|-----|--------|-------------|
| 0 | Pick 3 from presets | "Choose your path" |
| 7 | Swap 1 core habit per week (from preset list) | "You've earned adjustment" |
| 14 | Create 1 custom habit (free text + stat) | "Forge your own discipline" |
| 30 | Create 2nd custom habit | "Your discipline is real" |
| 60 | Create 3rd custom habit | "Your forge, your rules" |

### Custom Habit Rules

- Free text name (max 30 chars)
- Assign to one stat
- XP award: fixed at 10 (same as preset habits)
- Displays with "⚒️" custom badge in quest list
- Counts toward daily goal and streaks

### System Quest Interaction

- User's 3 core picks + up to 3 custom habits = their persistent base
- Quest engine still generates 1-2 dynamic quests daily targeting weak stats
- Total daily goal: core picks + customs + dynamic = flexible (4-6 habits)

### Implementation

- `RNF/Models/HabitPreset.swift` (new) — the 12 preset options with stat mapping
- `RNF/Core/HabitAgencyService.swift` (new) — manages selections, unlock states, custom creation
- `RNF/Features/Onboarding/HabitSelectionView.swift` (new) — the pick-3 grid
- `RNF/Features/Habits/CustomHabitCreationView.swift` (new) — free text + stat picker
- Update `QuestGenerator` to incorporate user selections into daily plan
- Update `AppStateManager` onboarding flow to include habit selection step

### Acceptance Criteria

- AC-1: Onboarding MUST present exactly 12 options in 3 categories
- AC-2: User MUST pick exactly 3 (enforced, not optional)
- AC-3: Custom creation MUST be locked until Day 14 with active streak
- AC-4: Unlock moments MUST trigger celebration (discovery-style toast)
- AC-5: Custom habits MUST persist across days (not regenerated)
- AC-6: Swapping MUST be limited to 1 per week (prevents churn/gaming)
- AC-7: Quest engine MUST still fill weak-stat gaps around user picks

---

## EXP-19: Live Activity & Ambient Presence

**Problem:** RNF only exists when you open it. Premium apps live on your lock screen, your wrist, your peripheral vision.

**Vision:** A Live Activity that shows streak + daily progress on the lock screen all day. Updated in real-time as habits complete.

### Live Activity Content

**Compact (lock screen):**
```
🔥 Day 42 • Blaze  │  ●●●○ 3/4 habits
```

**Expanded (Dynamic Island long-press):**
```
Day 42 • Blaze Tier
━━━━━━━━━━━●━━ 3/4 habits
Next: Read 10 pages
```

### Lifecycle

- Starts on first app open of the day
- Updates on each habit completion (via app → ActivityKit push)
- Ends when daily goal complete → shows "✓ Day Complete" briefly, then dismisses
- If user doesn't complete by midnight → ends silently

### Watch Complication Upgrade

Current: basic text. New:
- Show streak tier icon (flame color matches tier)
- Circular progress ring showing habits done / goal
- Tap → opens habit list for quick completion on Watch

### Implementation

- `RNF/LiveActivity/RNFLiveActivity.swift` (new) — ActivityAttributes + content state
- `RNF/LiveActivity/RNFLiveActivityView.swift` (new) — lock screen + Dynamic Island layouts
- Update `HabitsViewModel` to push Activity updates on completion
- Update `RNFWatchComplication.swift` to use streak tier icon + progress ring
- Add ActivityKit capability to main app target

### Acceptance Criteria

- AC-1: Live Activity MUST start on first open, end on daily goal complete
- AC-2: MUST update in real-time on habit completion (no delay)
- AC-3: MUST show streak tier name and icon (not just number)
- AC-4: MUST NOT drain battery (use ActivityKit push, not polling)
- AC-5: MUST work when app is backgrounded
- AC-6: Watch complication MUST show progress ring, not just text
