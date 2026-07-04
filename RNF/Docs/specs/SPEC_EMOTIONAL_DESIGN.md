# SPEC: Emotional Design System

**Status:** Draft
**Created:** 2026-07-03
**Domain:** User Psychology, Retention, Mental Health Safety
**Depends On:** Streak System, Narrative Engine, Calendar View, Profile Settings

---

## Overview

This specification defines how RNF responds emotionally to user states — struggle, absence, partial success, and vulnerability. The app's emotional intelligence layer exists to prevent the gamification mechanics from becoming psychologically harmful while maintaining their motivational power.

**Core Principle:** The app should feel like a wise mentor, not a disappointed parent. Silence is better than judgment. Acknowledgment is better than punishment.

---

## 1. Welcome-Back Flow (2+ Day Absence)

### Problem

When a user returns after missing 2+ days, the current experience is punitive:
- Grey calendar squares visible immediately
- Reset streak counter displayed prominently
- Lower stats shown without context
- No acknowledgment of the difficulty of returning

This creates a "walk of shame" that makes users close the app again — the exact opposite of the desired behavior. The hardest moment in habit-building is the return, and we punish it.

### Psychology

Returning after failure requires more willpower than maintaining a streak. Research on habit loops (Duhigg, Clear) shows that the restart moment has the highest dropout risk. Reducing cognitive load and emotional weight at this moment dramatically increases re-engagement probability.

The user already feels bad. The app's job is to lower the activation energy of re-engagement, not raise it.

### Design

Override the normal home screen with a dedicated **WelcomeBackView**:

1. **Hide the calendar** — do not show missed days on return
2. **Reduce the daily goal** — ask for 1 habit only (not the full list)
3. **Use warm, minimal narrative** — no stats, no numbers, no judgment
4. **Single habit picker** — simplified selection (not the full dashboard)
5. **Completion acknowledgment** — brief, warm confirmation
6. **Next day restoration** — full normal view returns

### UI/UX Details

**WelcomeBackView Layout:**
- Background: Subtle warm gradient (ember glow, not harsh)
- No navigation bar, no tabs visible
- Center-aligned content, generous whitespace
- Single CTA button: habit picker

**Flow:**
```
App Launch → Absence Detection → WelcomeBackView
  ↓
Narrative: "You're here. That's the hardest part."
  ↓
Narrative: "Pick one thing. Just one."
  ↓
[Habit Picker — single selection, large tap targets]
  ↓
User completes 1 habit
  ↓
Narrative: "The forge remembers you. Welcome back."
  ↓
[Soft transition to normal home — calendar still hidden today]
  ↓
Next app open: Normal HomeView restored with full daily goal
```

**Haptics:** Gentle tap on narrative appearance. Medium success haptic on completion.

### Copy Examples

| Moment | Copy | Tone |
|--------|------|------|
| Initial greeting | "You're here. That's the hardest part." | Warm, quiet |
| Prompt | "Pick one thing. Just one." | Direct, unburdened |
| Completion | "The forge remembers you. Welcome back." | Affirming, brief |
| If user picks 2+ | "One was enough. But you chose more. Noted." | Acknowledging |

### Implementation

```swift
// AppStateManager.swift
func checkReturnState() -> AppLaunchRoute {
    let daysSinceLastActivity = Calendar.current.dateComponents(
        [.day],
        from: lastActivityDate,
        to: Date()
    ).day ?? 0

    guard daysSinceLastActivity > 2 else { return .normal }
    guard !streakSystem.hasActiveFreeze(covering: lastActivityDate) else { return .normal }

    if daysSinceLastActivity >= 7 && pauseSystem.isPauseAvailable() {
        return .lifeHappened
    }

    return .welcomeBack
}
```

**Components:**
- `WelcomeBackView` — dedicated return screen
- `AppStateManager.checkReturnState()` — routing logic
- `DailyGoal.reducedMode` — serves 1 habit instead of full list
- `CalendarView.hideUntilTomorrow` — suppresses calendar on return day

**State transitions:**
- `days_since_last_activity > 2` AND no active streak freeze → route to WelcomeBackView
- After 1 habit completion → set `returnDayCompleted = true`
- Next app launch → normal routing resumes

### Edge Cases

| Case | Behavior |
|------|----------|
| User had streak freeze covering absence | Skip WelcomeBackView entirely — streak intact, no emotional intervention needed |
| User returns but doesn't complete the 1 habit | WelcomeBackView persists on next open (same day). After midnight, reset and show again |
| Absence is 7+ days | Route to Life Happened flow instead (§4) |
| User force-closes during WelcomeBackView | Same state on next open |
| User was on Day 1-3 of challenge (new user) | Still show WelcomeBackView — even more critical for new users |

---

## 2. Graduated Success Acknowledgment

### Problem

The current system treats daily completion as binary: all habits done = success (green), anything less = failure (grey). A user who completes 3 out of 4 habits receives the same visual feedback as someone who did nothing. This is psychologically crushing for perfectionist-prone users and factually inaccurate — 75% completion is not zero.

Binary success/failure framing:
- Discourages users who "almost" made it
- Creates all-or-nothing thinking patterns
- Ignores effort and partial progress
- Punishes high-goal users disproportionately (4 habits is harder than 2)

### Psychology

Self-Determination Theory (Deci & Ryan) shows that perceived competence is a core motivational driver. When effort goes unacknowledged, intrinsic motivation collapses. The "what-the-hell effect" (Cochran & Tesser) describes how perceiving partial failure as total failure causes complete abandonment: "I already failed today, might as well skip the rest."

Graduated acknowledgment interrupts this cycle by making partial progress visible and valued.

### Design

Replace binary success/fail with a **four-tier graduated celebration system**:

| Completion | Label | Narrative Tone | Haptic |
|-----------|-------|---------------|--------|
| 1/N (25%) | "You showed up." | Warm, no judgment | Gentle tap |
| 2/N (50%) | "Momentum building." | Encouraging | Light pulse |
| 3/N (75%) | "Almost there. Tomorrow you'll close it." | Forward-looking | Medium pulse |
| N/N (100%) | "Mission Complete. The forge burns bright." | Full celebration | Strong success |

**Calendar Cell Rendering:**
- Replace binary green/grey with gradient intensity fill
- 25% completion → 25% opacity fill
- 50% completion → 50% opacity fill
- 75% completion → 75% opacity fill
- 100% completion → full solid fill
- 0% → grey (unchanged)
- Rest/Pause days → distinct icons (see §4, §7)

### UI/UX Details

**End-of-Day Summary Card:**
```
┌─────────────────────────────┐
│                             │
│    ◉◉◉○  (3/4 complete)    │
│                             │
│  "Almost there.             │
│   Tomorrow you'll close it."│
│                             │
│  [View Details]             │
└─────────────────────────────┘
```

**Calendar Cell States:**
- Solid fill color at varying opacity (not different colors)
- Primary brand color used for all completion levels
- Grey reserved exclusively for 0% days
- Small dot indicator at bottom of cell for 100% days (bonus visual)

**Animation:** Completion circles fill sequentially with a 0.2s delay between each, creating a "progress wave" feel.

### Copy Examples

| Ratio | Copy Variants |
|-------|--------------|
| 1/4 | "You showed up." · "One down. That's not nothing." · "The forge lit today." |
| 2/4 | "Momentum building." · "Halfway. The fire's catching." · "Two anchors set." |
| 3/4 | "Almost there. Tomorrow you'll close it." · "Three of four. So close." · "The forge is warm." |
| 4/4 | "Mission Complete. The forge burns bright." · "All four. Clean sweep." · "Full power today." |

### Implementation

```swift
// DailyStatus.swift
struct DailyStatus {
    let completedCount: Int
    let totalCount: Int

    var completionRatio: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var tier: CompletionTier {
        switch completionRatio {
        case 0: return .none
        case 0.01..<0.4: return .showed_up
        case 0.4..<0.7: return .momentum
        case 0.7..<1.0: return .almost
        case 1.0: return .complete
        default: return .none
        }
    }
}

enum CompletionTier: String {
    case none, showed_up, momentum, almost, complete
}

// CalendarCellView.swift
struct CalendarCellView: View {
    let status: DailyStatus

    var fillOpacity: Double {
        status.completionRatio
    }
}
```

**Streak Impact (Configurable):**
- Default mode: 100% (N/N) required for streak maintenance
- Flexible mode: 75%+ counts as streak-maintaining
- Setting: `Profile.streakFlexibility: .strict | .flexible`
- Flexible mode is suggested (not forced) during onboarding for users who select 4+ habits

### Edge Cases

| Case | Behavior |
|------|----------|
| User has only 1 habit | Binary by nature — 0% or 100%. Graduated messaging still applies (just two tiers) |
| User adds/removes habits mid-day | Ratio calculated against habit count at end of day (final state) |
| User completes habits after midnight | Belongs to the day the habit was scheduled, not current clock day (configurable timezone) |
| Flexible mode + streak display | Streak increments on 75%+ days. Calendar still shows actual ratio (not inflated) |
| User switches between strict/flexible | Applies going forward only. Historical streak not recalculated |

---

## 3. Humor Injection (1-in-20 Light Moments)

### Problem

The Forge narrative voice is stoic, intense, and motivational. This works brilliantly for short-term engagement but creates emotional fatigue over 365 days of continuous use. Relentless intensity becomes background noise — or worse, feels oppressive. Users develop "narrative blindness" and stop reading the messages entirely.

### Psychology

Humor theory (Incongruity Theory, Benign Violation Theory) shows that unexpected tonal shifts dramatically increase attention and memorability. A single light moment among serious ones is remembered far longer than 20 serious moments in sequence.

Additionally, humor signals safety and rapport. A mentor who can joke has earned trust. It signals "we're past the hard part — you're doing well enough to laugh about it." This is why humor is gated behind streak milestones.

### Design

**5% of ForgeVoice/Narrative messages** use an unexpectedly light tone.

**Selection Criteria (ALL must be true):**
1. User has streak > 14 days (earned trust — they've proven commitment)
2. Random selection: 5% probability per eligible message slot
3. Never during Day 1-7 (too early — trust not established)
4. Never following a missed day or return flow
5. Only on success moments (completion, streak milestone, stat increase)

**Tone:** Self-aware, slightly meta, dry wit. The Forge breaking character briefly. Never sarcastic, never at the user's expense.

### UI/UX Details

- Light messages appear in the same locations as normal narratives (no special formatting)
- No emoji, no exclamation marks — humor comes from the writing, not decoration
- Slightly longer display time (user needs a moment to register the shift)
- No "LOL" reactions or social sharing prompts — let the moment be private

### Copy Examples

**Streak Milestones:**
- "Day 47. The Forge considered giving you a day off. It didn't. But it considered it."
- "Streak 30. At this point, you're not building habits — they're building you."
- "Day 60. The Forge has run out of dramatic things to say. You just… keep showing up."
- "Streak 100. At this point, you're not the apprentice. Don't tell the Forge I said that."

**Stat Increases:**
- "Your Discipline stat went up. You're now officially more disciplined than the Forge's last apprentice. He's a boulder."
- "Endurance +1. At this rate, you'll outlast the app's servers."
- "Focus increased. Your attention span is now longer than this message. Barely."

**Late Completions:**
- "The Forge noticed you completed habits at 11:47 PM. Technically, discipline. Questionably, sleep."
- "11:58 PM. The Forge respects the deadline commitment. The Forge questions the strategy."

**Weekend/Pattern-Based:**
- "Saturday completion before 8 AM. The Forge is impressed. And slightly concerned."
- "7 days straight before 7 AM. You're either very disciplined or have a very loud alarm."

### Implementation

```swift
// NarrativeEngine.swift
enum NarrativeTone {
    case stoic      // Default forge voice
    case warm       // Return flows, partial success
    case light      // Humor injection (this feature)
    case quiet      // Acknowledging struggle
}

struct NarrativeTemplate {
    let id: String
    let content: String
    let tone: NarrativeTone
    let context: NarrativeContext  // .streakMilestone, .statIncrease, .completion, etc.
    let minStreak: Int  // Minimum streak required to show this template
}

func selectNarrative(for event: NarrativeEvent, userState: UserState) -> NarrativeTemplate {
    // Gate: No humor in first 7 days
    guard userState.currentStreak > 14 else {
        return selectStandardNarrative(for: event)
    }

    // Gate: No humor after absence or on return days
    guard !userState.isReturnDay else {
        return selectStandardNarrative(for: event)
    }

    // Gate: Only on success events
    guard event.isSuccessEvent else {
        return selectStandardNarrative(for: event)
    }

    // 5% chance of light tone
    if Double.random(in: 0...1) < 0.05 {
        return selectLightNarrative(for: event, userState: userState)
    }

    return selectStandardNarrative(for: event)
}
```

**Template Bank:** ~20 light-tone templates, tagged by context. Rotated to avoid repetition (track `lastShownLightTemplateIds`).

**Rules (Hard Constraints):**
- ❌ Never joke about failure
- ❌ Never joke about missed days
- ❌ Never joke about struggle or return
- ❌ Never joke about the user's habits specifically (could feel mocking)
- ✅ Only joke about success, commitment, or the Forge itself
- ✅ Self-deprecating Forge humor is always safe
- ✅ Observational humor about patterns (time of day, consistency) is safe

### Edge Cases

| Case | Behavior |
|------|----------|
| User just returned from absence (streak reset) | No humor until streak > 14 again |
| User has streak-free mode enabled | Humor still triggers (based on internal streak, not displayed one) |
| Same joke shown twice in 30 days | Template rotation prevents — track recently shown IDs |
| User completes at 11:59 PM but time-completion joke was shown yesterday | Suppress time-based jokes if shown within 7 days |
| Light message appears during boss battle week | Allowed — boss battles are success-context (user is engaged) |

---

## 4. "Life Happened" Pause Mode

### Problem

The forgiveness token system covers single missed days — an overslept alarm, a busy travel day. But life crises (illness, grief, burnout, family emergencies) last longer than 1 day. A user returning after 7-14 days of genuine hardship sees a devastating wall of grey squares and a reset streak. The app, which was supposed to support them, now represents another failure.

This is the moment users delete the app permanently.

### Psychology

Grief, illness, and burnout are not character failures — they're human experiences. An app that cannot distinguish between "gave up" and "life intervened" lacks emotional intelligence. The Pause system communicates: "We know. It's okay. Your progress isn't erased by circumstances beyond your control."

Self-Compassion research (Kristin Neff) shows that self-kindness after setbacks improves future performance, while self-criticism after setbacks increases avoidance behavior. The pause is therapeutic design.

### Design

**Trigger:** User opens app after 7+ consecutive missed days.

**Flow:**
```
App Launch → 7+ days detected → LifeHappenedView

┌─────────────────────────────────────────┐
│                                         │
│  "It looks like life pulled you away.   │
│   That's okay."                         │
│                                         │
│  "Would you like to pause those days?"  │
│                                         │
│  [Pause Those Days]     [No Thanks]     │
│                                         │
│  ── What this means ──                  │
│  • Missed days marked as paused (blue)  │
│  • Your streak is preserved             │
│  • No XP earned for paused days         │
│  • Challenge day counter paused too     │
│                                         │
└─────────────────────────────────────────┘
```

**If accepted:**
- Missed days between last_activity and today marked as `paused`
- Calendar renders paused days in blue (not grey, not green)
- Streak preserved at pre-absence value
- Challenge day counter frozen during pause (Day 45 stays Day 45)
- No XP earned for paused period (fairness)
- Confirmation: "Those days are paused. Your streak stands at [X]. Let's continue."

**If declined:**
- Normal absence handling applies (streak resets, grey squares)
- Route to WelcomeBackView (§1) for re-engagement support
- Decision is final for this absence (cannot retroactively pause later)

**Limits:**
- 1 pause per 90-day cycle
- Maximum 14 consecutive days per pause
- If absence > 14 days, only the first 14 can be paused (remaining days are grey)
- Cycle resets on day 1, 91, 181, 271 of the challenge year

### UI/UX Details

**LifeHappenedView:**
- Soft, muted color palette — no high-energy visuals
- No streak number shown (avoid highlighting the loss)
- Explanation text is expandable (hidden by default to reduce cognitive load)
- Both buttons equally weighted visually (no dark-pattern "accept" emphasis)

**Calendar After Pause:**
- Paused days: Blue fill with subtle pause icon (‖)
- Clearly distinct from: green (complete), grey (missed), lotus (rest)
- Tapping a paused day shows: "Paused — life happened"

**Post-Pause Transition:**
- After accepting pause → simplified return (1 habit goal for today, like WelcomeBackView)
- Day after return → normal full goal

### Copy Examples

| Moment | Copy |
|--------|------|
| Initial prompt | "It looks like life pulled you away. That's okay." |
| Explanation | "Would you like to pause those days?" |
| Acceptance | "Those days are paused. Your streak stands at [X]. Let's continue." |
| Calendar tooltip | "Paused — life happened." |
| If at limit | "You've already used your pause this cycle. Your streak will reset, but the forge remembers everything you built before." |

### Implementation

```swift
// PauseSystem.swift
struct PausePeriod: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let createdAt: Date
}

class PauseSystem: ObservableObject {
    @Published var pausePeriods: [PausePeriod] = []

    private let maxPauseDays = 14
    private let cycleLengthDays = 90

    func isPauseAvailable() -> Bool {
        let currentCycleStart = calculateCurrentCycleStart()
        let pausesInCycle = pausePeriods.filter { $0.createdAt >= currentCycleStart }
        return pausesInCycle.isEmpty
    }

    func applyPause(from startDate: Date, to endDate: Date) -> PausePeriod? {
        guard isPauseAvailable() else { return nil }

        let cappedEnd = min(endDate, startDate.addingDays(maxPauseDays))
        let pause = PausePeriod(
            id: UUID(),
            startDate: startDate,
            endDate: cappedEnd,
            createdAt: Date()
        )
        pausePeriods.append(pause)
        return pause
    }

    func isDayPaused(_ date: Date) -> Bool {
        pausePeriods.contains { pause in
            date >= pause.startDate && date <= pause.endDate
        }
    }
}

// StreakSystem modification
func calculateStreak(logs: [DailyLog], pauseSystem: PauseSystem) -> Int {
    var streak = 0
    var date = Date().yesterday

    while true {
        if pauseSystem.isDayPaused(date) {
            // Skip paused days — don't break or increment
            date = date.yesterday
            continue
        }
        guard let log = logs.first(where: { $0.date == date }),
              log.isStreakMaintaining else {
            break
        }
        streak += 1
        date = date.yesterday
    }
    return streak
}
```

**Data Model:**
- New: `PausePeriod` entity (id, start_date, end_date, created_at)
- Modified: `CalendarCellView` checks `pauseSystem.isDayPaused(date)`
- Modified: `StreakSystem.calculateStreak()` skips paused days
- Modified: `ChallengeProgress.currentDay` subtracts paused days from count

### Edge Cases

| Case | Behavior |
|------|----------|
| Absence is exactly 7 days | Life Happened triggers (threshold is ≥7) |
| Absence is 20 days | First 14 days pausable, remaining 6 are grey missed days |
| User already used pause this cycle | Show WelcomeBackView instead. Mention: "Your pause was already used this cycle." |
| User had streak freeze AND 7+ absence | Streak freeze covers its day(s); pause covers remaining days |
| User declines pause then regrets | Cannot retroactively apply. Decision is final. (Prevents decision paralysis) |
| Pause spans a boss battle day | Boss battle timer also pauses. User faces boss on return as if no time passed |
| User opens app on day 8, then again on day 10 without completing | Pause window is from last_activity to first_return_date (day 8), not re-offered on day 10 |

### Safety & Abuse Prevention

This is **not** a cheat mechanism. Safeguards:
- 1 pause per 90-day cycle (cannot repeatedly exploit)
- Max 14 days (extended absences still have consequences beyond 14 days)
- No XP earned (no reward for inactivity)
- Cannot be applied retroactively (must decide on return)
- Visible on calendar (transparent, not hidden)

---

## 5. Streak-Free Mode

### Problem

For some users — particularly those with anxiety, OCD tendencies, or perfectionist patterns — streak counters become a source of unhealthy obsession rather than motivation. The streak becomes the goal instead of the habits. Breaking a streak causes disproportionate distress: panic, guilt, shame spirals, or compulsive late-night habit completion that harms sleep.

The very mechanism designed to motivate becomes a cage.

### Psychology

Variable Ratio Reinforcement (Skinner) makes streaks addictive by design. For most users this is productive. For anxiety-prone users, it creates a loss-aversion trap where the fear of losing the streak exceeds the joy of building it. This is the same mechanism behind gambling addiction — the sunk-cost fallacy applied to consecutive days.

Streak-Free Mode reframes progress as cumulative (never decreases) rather than consecutive (fragile, breakable). This preserves motivation while removing the anxiety trigger.

### Design

**Setting Location:** Profile → Display Preferences → Streak Display

**Three Modes:**

| Mode | Display | Narrative | Internal Calculation |
|------|---------|-----------|---------------------|
| `.streak` (default) | "Streak: 47" | "47 days forged" | Unchanged |
| `.totalDays` | "47 days active" | "Day 47 active" | Cumulative count |
| `.hidden` | Nothing shown | No streak reference | Unchanged |

**When `.totalDays` is active:**
- Streak number replaced with total active days (cumulative, never decreases)
- Calendar shows completion without consecutive-day highlighting
- No "streak broken" notification ever fires
- Narrative uses "Day X active" framing
- XP multiplier still functions (calculated from internal streak, applied silently)
- Streak tier bonuses still apply (user still benefits, just doesn't see the fragile number)

**When `.hidden` is active:**
- No streak-related UI anywhere
- No streak number, no streak tier badge visible
- XP multiplier still functions silently
- Calendar shows daily completion only (no consecutive emphasis)
- Narrative never references streaks or consecutive days

### UI/UX Details

**Profile Toggle:**
```
┌─────────────────────────────────────┐
│ Streak Display                      │
│                                     │
│ ○ Show streak (default)             │
│ ○ Show total active days            │
│ ○ Hide streak counter               │
│                                     │
│ ℹ️ Your progress bonuses still      │
│    apply regardless of display mode │
└─────────────────────────────────────┘
```

**Home Screen Variants:**

| Mode | Hero Stat |
|------|-----------|
| `.streak` | 🔥 47 day streak |
| `.totalDays` | ◉ 47 days active |
| `.hidden` | [Section removed — more space for today's habits] |

**Calendar Rendering Differences:**
- `.streak` mode: Connected-day visual (line between consecutive completed days)
- `.totalDays` / `.hidden`: Individual day fills only (no connecting visual)

### Copy Examples

| Context | .streak | .totalDays | .hidden |
|---------|---------|------------|---------|
| Daily greeting | "Streak: 47. Keep forging." | "Day 47 active. The forge burns steady." | "Today's mission awaits." |
| Milestone | "30-day streak! 🔥" | "30 active days! Consistent." | "Milestone reached." |
| After missed day | "Streak reset. Begin again." | (No change — number doesn't decrease) | (No notification) |

### Implementation

```swift
// Profile.swift
enum StreakDisplayMode: String, Codable, CaseIterable {
    case streak     // Default: show consecutive streak
    case totalDays  // Show cumulative active days
    case hidden     // Show nothing streak-related
}

struct Profile {
    var streakDisplayMode: StreakDisplayMode = .streak
    // ...
}

// HomeView.swift
@ViewBuilder
var streakDisplay: some View {
    switch profile.streakDisplayMode {
    case .streak:
        StreakBadgeView(count: streakSystem.currentStreak)
    case .totalDays:
        TotalDaysBadgeView(count: streakSystem.totalActiveDays)
    case .hidden:
        EmptyView()
    }
}

// NarrativeEngine.swift — streak reference check
func narrativeForStreak(_ event: NarrativeEvent, profile: Profile) -> String? {
    switch profile.streakDisplayMode {
    case .streak:
        return standardStreakNarrative(event)
    case .totalDays:
        return totalDaysNarrative(event)
    case .hidden:
        return nil // Skip streak narratives entirely
    }
}

// NotificationSystem.swift
func shouldSendStreakBreakNotification(profile: Profile) -> Bool {
    return profile.streakDisplayMode == .streak
}
```

**Key Implementation Notes:**
- XP multiplier calculation NEVER checks display mode — always uses internal streak
- Streak tier progression NEVER checks display mode — always advances based on internal streak
- Only UI rendering and narrative text respect the display mode
- "Total active days" counter uses separate `activeDaysCount` property (simple count of days with ≥1 completion)

### Edge Cases

| Case | Behavior |
|------|----------|
| User switches from .streak to .totalDays mid-challenge | Immediate. No recalculation needed — totalDays already tracked |
| User switches from .hidden to .streak | Streak number appears (may be 0 if recently broken — could be jarring). Show one-time tooltip: "Your streak resets on missed days. Your bonuses have been active the whole time." |
| User in .totalDays breaks internal streak | No visible change to user. XP multiplier resets but user only notices slightly less XP (subtle) |
| User asks "why did my XP drop?" (hidden mode) | FAQ/help section explains that consistency bonuses apply but aren't shown. No in-app popup |
| Leaderboard/social features (future) | Respect display mode — don't expose streak to others if user has it hidden |

---

## 6. Sensitivity Filter for Boss Battles

### Problem

Boss Battles represent internal obstacles: "Doubt," "Procrastination," "Apathy." They use adversarial language — taunting the user, questioning their progress, voicing their inner critic. For a healthy user with a stable mindset, this is motivating (externalize the enemy, defeat it).

For a user in mental health crisis — experiencing clinical depression, anxiety disorder, imposter syndrome, or grief — fighting a boss called "Doubt" that says *"Is this even working?"* mirrors their actual internal experience. The app becomes another voice confirming their worst thoughts. This is harmful.

### Psychology

Cognitive Behavioral Therapy distinguishes between productive challenge (growth zone) and harmful reinforcement (trigger zone). The same stimulus can be therapeutic or damaging depending on the user's current state. We cannot know the user's state — so we provide the opt-out.

Externalization techniques (narrative therapy) work when the user has enough psychological distance from the named problem. When they don't, naming "Doubt" as an enemy can feel like the app is identifying their core self as the enemy.

### Design

**Setting Location:** Profile → Experience → Boss Encounters

**Two Modes:**

| Mode | Label | Mechanics | Narrative |
|------|-------|-----------|-----------|
| `.full` (default) | Boss Battle | Complete 5 days to defeat boss | Named adversary with taunting copy |
| `.neutral` | Challenge Gate | Complete 5 days to unlock tier | Neutral progression checkpoint |

**`.full` mode (default):**
- Boss has a name: "Doubt," "Procrastination," "Apathy," etc.
- Boss delivers taunting messages during the 5-day fight
- Victory narrative: "Doubt falls silent. You proved it wrong."
- Dramatic, adversarial tone

**`.neutral` mode:**
- No named adversary
- No taunting copy
- Same mechanic: complete 5 consecutive days to progress
- Label: "Challenge Gate" or "Consistency Check"
- Neutral narrative: "Consistency check: complete 5 days to unlock the next tier"
- Victory: "Gate cleared. Next tier unlocked."

### UI/UX Details

**Onboarding Opt-Out:**
During initial setup, after selecting habits and before first day:
```
┌─────────────────────────────────────────┐
│ One more thing:                         │
│                                         │
│ Every few days, you'll face a           │
│ "Boss Battle" — a challenge that        │
│ represents obstacles like Doubt         │
│ or Procrastination.                     │
│                                         │
│ Would you prefer:                       │
│                                         │
│ ○ Boss Battles (dramatic, adversarial)  │
│ ○ Challenge Gates (neutral checkpoints) │
│                                         │
│ You can change this anytime in Profile. │
└─────────────────────────────────────────┘
```

**BossBattleView vs ChallengeGateView:**

| Element | .full | .neutral |
|---------|-------|----------|
| Header | "Boss: Doubt" | "Challenge Gate" |
| Subheader | "It whispers: is this even working?" | "Complete 5 days to progress" |
| Progress | "Day 3/5 — Doubt weakens" | "Day 3/5 — 2 days remaining" |
| Victory | "DOUBT DEFEATED. The forge burns brighter." | "Gate cleared. Tier unlocked." |
| Visual | Dark, dramatic boss silhouette | Clean progress bar |
| Sound | Dramatic audio cue | Neutral completion chime |

### Copy Examples

**Full Mode:**
- "Doubt enters the forge. It asks: 'Why bother?'"
- "Day 2. Doubt is still watching. Keep going."
- "Day 5. Doubt falls silent. You answered without words."

**Neutral Mode:**
- "Challenge gate ahead. 5 days of consistency to pass."
- "Day 2 of 5. Steady progress."
- "Gate cleared. The path continues."

### Implementation

```swift
// Profile.swift
enum BossDisplayMode: String, Codable {
    case full      // Named adversary with taunting copy
    case neutral   // Neutral challenge gate
}

struct Profile {
    var bossDisplayMode: BossDisplayMode = .full
    // ...
}

// BossBattleView.swift
struct BossBattleView: View {
    let boss: BossEncounter
    let profile: Profile

    var body: some View {
        switch profile.bossDisplayMode {
        case .full:
            FullBossBattleContent(boss: boss)
        case .neutral:
            ChallengeGateContent(daysRequired: boss.daysRequired, daysCompleted: boss.daysCompleted)
        }
    }
}

// NarrativeEngine.swift — boss context
func bossNarrative(for event: BossEvent, mode: BossDisplayMode) -> String {
    switch mode {
    case .full:
        return fullBossNarrative(event)
    case .neutral:
        return neutralGateNarrative(event)
    }
}
```

**Onboarding Integration:**
- `OnboardingFlow` includes boss mode selection as final preference step
- Default: `.full` (most users benefit from the dramatic framing)
- Selection stored in Profile, changeable anytime

### Edge Cases

| Case | Behavior |
|------|----------|
| User switches mode mid-boss-battle | Immediate switch. Progress preserved (day 3/5 stays day 3/5). Only presentation changes |
| User in .neutral mode sees friend's boss battle (future social) | Show neutral version of their own — never expose full-mode content to .neutral users |
| Notifications reference boss battles | Check mode before sending. .neutral users get: "Challenge gate ahead" not "Boss approaching" |
| User selects .neutral during onboarding | No additional explanation needed. Respect the choice silently |
| User switches from .neutral to .full | Show boss content immediately. If mid-battle, introduce the boss: "You've been fighting Doubt all along. Now it has a face." |

---

## 7. Intentional Rest Days

### Problem

The app demands identical output 7 days per week, 365 days per year. There is no acknowledgment that recovery is part of discipline, that rest is a training strategy, or that sustainable performance requires periodization. This creates:

- Burnout from relentless daily pressure
- Guilt on days when rest is genuinely needed
- "Sneaking" habits (doing the minimum to avoid grey) instead of genuinely resting
- No distinction between intentional recovery and lazy avoidance

### Psychology

Performance science (periodization theory, supercompensation) demonstrates that recovery is not the absence of discipline — it IS discipline. Elite athletes schedule rest. Musicians have rest bars. The forge itself must cool to strengthen steel.

By making rest an explicit, intentional choice (not a failure), the app honors the user's autonomy and supports sustainable long-term engagement over unsustainable perfection.

### Design

**Mechanic:** 1 rest day per 7-day rolling window.

**How it works:**
1. User opens app on a day they want to rest
2. Marks the day as "Intentional Rest" (before end of day)
3. Day is logged as rest — no habits required
4. Streak does not break
5. No XP earned (rest is neutral, not rewarding)
6. Calendar shows rest icon (lotus/pause symbol in calm color)
7. Next day: normal full goal resumes

**Constraints:**
- 1 rest day per rolling 7-day window
- Cannot be stacked (no "saving up" rest days)
- Cannot be applied retroactively (must be declared same-day, before midnight)
- Cannot be used on boss battle days (commitment mechanic requires consistency)

### UI/UX Details

**Declaring Rest:**
```
┌─────────────────────────────────────┐
│ Today's Habits                      │
│                                     │
│ ☐ Habit 1                           │
│ ☐ Habit 2                           │
│ ☐ Habit 3                           │
│ ☐ Habit 4                           │
│                                     │
│ ─── or ───                          │
│                                     │
│ [🌿 Take a Rest Day]               │
│                                     │
│ 1 available this week               │
└─────────────────────────────────────┘
```

**Confirmation:**
```
┌─────────────────────────────────────┐
│ Mark today as rest?                 │
│                                     │
│ • Your streak continues             │
│ • No XP earned today                │
│ • Habits won't show for today       │
│                                     │
│ "Rest is training. The forge cools  │
│  to strengthen the steel."          │
│                                     │
│ [Confirm Rest]      [Cancel]        │
└─────────────────────────────────────┘
```

**Rest Day State (after confirmation):**
```
┌─────────────────────────────────────┐
│                                     │
│         🌿 Rest Day                 │
│                                     │
│  "The forge cools. Return           │
│   tomorrow, stronger."              │
│                                     │
│  Streak: 47 (continues)            │
│                                     │
└─────────────────────────────────────┘
```

**Calendar Rendering:**
- Rest day cell: Lotus icon (🌿) on soft blue/teal background
- Clearly distinct from: green (complete), grey (missed), blue (paused)
- Tooltip on tap: "Intentional rest day"

### Copy Examples

| Moment | Copy |
|--------|------|
| Rest button | "Take a Rest Day" |
| Confirmation narrative | "Rest is training. The forge cools to strengthen the steel." |
| Rest day greeting | "The forge cools. Return tomorrow, stronger." |
| If already used this week | "Rest day already taken this week. The forge asks for your presence today." |
| Boss battle day | "Rest unavailable during active challenges. The forge needs you today." |

### Implementation

```swift
// DailyLog.swift
enum DailyLogStatus: String, Codable {
    case active      // Normal day (in progress or completed)
    case completed   // All habits done
    case partial     // Some habits done
    case missed      // No activity
    case rest        // Intentional rest day
    case paused      // Life Happened pause
}

// RestDaySystem.swift
class RestDaySystem: ObservableObject {
    func isRestAvailable(on date: Date, logs: [DailyLog]) -> Bool {
        let windowStart = date.addingDays(-6) // Rolling 7-day window
        let restDaysInWindow = logs.filter { log in
            log.date >= windowStart &&
            log.date <= date &&
            log.status == .rest
        }
        return restDaysInWindow.isEmpty
    }

    func isBossBattleDay(on date: Date, bossSystem: BossSystem) -> Bool {
        return bossSystem.activeBattle?.isActive(on: date) ?? false
    }

    func canTakeRest(on date: Date, logs: [DailyLog], bossSystem: BossSystem) -> Bool {
        guard isRestAvailable(on: date, logs: logs) else { return false }
        guard !isBossBattleDay(on: date, bossSystem: bossSystem) else { return false }
        guard date.isToday else { return false } // Cannot apply retroactively
        return true
    }

    func declareRestDay(on date: Date) {
        // Mark today's log as .rest
        // Remove any partial completions for today
        // Streak calculation will skip this day
    }
}

// StreakSystem modification
func calculateStreak(logs: [DailyLog], pauseSystem: PauseSystem) -> Int {
    var streak = 0
    var date = Date().yesterday

    while true {
        if pauseSystem.isDayPaused(date) {
            date = date.yesterday
            continue
        }

        guard let log = logs.first(where: { $0.date == date }) else { break }

        switch log.status {
        case .rest:
            // Skip rest days — don't break or increment streak
            date = date.yesterday
            continue
        case .completed, .partial where log.isStreakMaintaining:
            streak += 1
            date = date.yesterday
        default:
            // .missed or non-maintaining partial
            break
        }
    }
    return streak
}
```

### Edge Cases

| Case | Behavior |
|------|----------|
| User declares rest then tries to complete a habit | Rest declaration is revocable until end of day. Completing any habit auto-cancels rest and restores normal day |
| User declares rest at 11:55 PM | Valid — they chose rest for today. Cannot declare for tomorrow |
| Last day of boss battle is a rest request | Denied. "Rest unavailable during active challenges." |
| User on streak-free mode (.totalDays) takes rest | Rest day does NOT increment total active days (it's rest, not active) |
| User has 4+ habits but completed 1, then declares rest | Cannot declare rest after any habit completion. Rest must be declared on a clean day (0 completions) |
| 7th day of the week, no rest taken | No prompt or reminder. Rest is optional, not expected |
| Calendar shows 3 rest days visible in one month | Normal — that's ~1/week. No limit beyond 1-per-7-days |

---

## Copy Tone Guidelines

The emotional design system requires precise tonal control. The Forge voice is not one tone — it's a spectrum that responds to context.

### Tone Spectrum

| Tone | When to Use | Characteristics | Example |
|------|-------------|-----------------|---------|
| **Warm** | Return flows, partial success (1-2/N), first-time events | Soft, accepting, non-judgmental. Short sentences. No commands. | "You're here. That's the hardest part." |
| **Quiet** | After struggle, missed days, declining to pause | Minimal words. Acknowledgment without commentary. Space over noise. | "Begin again." |
| **Encouraging** | Mid-progress (2-3/N), building momentum, early streaks | Forward-looking, active language. Names the trajectory. | "Momentum building. Tomorrow you'll close it." |
| **Celebratory** | Full completion, milestones, boss victories | Bold, declarative. The Forge at full voice. Earned triumph. | "Mission Complete. The forge burns bright." |
| **Light** | Success moments for established users (streak > 14) | Self-aware, dry, slightly meta. The Forge breaking character. | "The Forge considered giving you a day off. It didn't." |
| **Neutral** | Challenge gates (.neutral mode), settings, explanations | Functional, clear, no emotional loading. Information only. | "Complete 5 days to unlock the next tier." |

### Tone Selection Rules

```
IF user is returning after absence:
    → WARM (Welcome Back) or QUIET (Life Happened)

IF user completed partial habits:
    → WARM (low ratio) or ENCOURAGING (high ratio)

IF user completed all habits:
    → CELEBRATORY (95% of the time) or LIGHT (5%, if eligible)

IF user is in .neutral boss mode:
    → NEUTRAL (always, for boss-related content)

IF user just declared rest:
    → QUIET with WARM undertone

IF user hit a milestone:
    → CELEBRATORY (default) or LIGHT (if eligible)

IF context is unclear:
    → Default to QUIET over WARM, WARM over ENCOURAGING
    → The safest tone is always the quietest one
```

### Hard Rules for Copy

1. **Never celebrate absence.** Pausing and rest are acknowledged, not praised.
2. **Never blame.** Even in streak-reset messages, the user is not at fault.
3. **Never use "but."** "You did 3 habits, but missed one" undermines the 3. Use "and" or separate sentences.
4. **Never compare to other users.** Progress is always self-referential.
5. **Never use exclamation marks in warm/quiet tones.** Reserve ! for celebratory only.
6. **Never reference specific habits by name in emotional copy.** Keep it abstract ("one thing," "your mission") to avoid judgment about which habits matter more.
7. **Short over long.** Emotional moments need fewer words, not more. If the copy is longer than 2 lines, cut it.
8. **The Forge is the speaker, not the user's inner voice.** Third-person ("The forge remembers") not second-person-as-self ("You remember").

### Copy Length by Tone

| Tone | Max Length | Typical |
|------|-----------|---------|
| Warm | 15 words | 8-12 words |
| Quiet | 5 words | 2-4 words |
| Encouraging | 12 words | 8-10 words |
| Celebratory | 12 words | 6-10 words |
| Light | 25 words | 15-20 words (needs setup + payoff) |
| Neutral | 15 words | 8-12 words |

### Haptic Pairing

| Tone | Haptic |
|------|--------|
| Warm | `.soft` — single gentle tap |
| Quiet | None — silence is the point |
| Encouraging | `.light` — light double-tap |
| Celebratory | `.success` — strong triple-pulse |
| Light | `.light` — same as encouraging (don't over-signal the joke) |
| Neutral | `.selection` — minimal UI feedback |

---

## System Integration Map

```
┌─────────────────────────────────────────────────────────────┐
│                    AppStateManager                           │
│                                                             │
│  checkReturnState()                                         │
│    ├── days_since > 7 + pause available → LifeHappenedView │
│    ├── days_since > 2 (no freeze) → WelcomeBackView        │
│    └── normal → HomeView                                    │
└─────────────────┬───────────────────────────────────────────┘
                  │
    ┌─────────────┼──────────────────┐
    │             │                  │
    ▼             ▼                  ▼
┌────────┐  ┌──────────┐  ┌─────────────────┐
│ Streak │  │ Pause    │  │ Rest Day        │
│ System │  │ System   │  │ System          │
│        │  │          │  │                 │
│ skip:  │  │ 1/cycle  │  │ 1/week          │
│ rest   │  │ 14d max  │  │ same-day only   │
│ pause  │  │          │  │ no boss days    │
└────┬───┘  └────┬─────┘  └────┬────────────┘
     │           │              │
     └───────────┼──────────────┘
                 ▼
    ┌────────────────────────┐
    │   Calendar Renderer    │
    │                        │
    │   States:              │
    │   ■ Green (100%)       │
    │   ■ Green 75% opacity  │
    │   ■ Green 50% opacity  │
    │   ■ Green 25% opacity  │
    │   ■ Grey (missed)      │
    │   ■ Blue (paused)      │
    │   ■ Teal/Lotus (rest)  │
    └────────────────────────┘
                 │
                 ▼
    ┌────────────────────────┐
    │   Narrative Engine     │
    │                        │
    │   Inputs:              │
    │   - completion ratio   │
    │   - streak display mode│
    │   - boss display mode  │
    │   - days since absence │
    │   - humor eligibility  │
    │                        │
    │   Output: tone + copy  │
    └────────────────────────┘
                 │
                 ▼
    ┌────────────────────────┐
    │   Profile Settings     │
    │                        │
    │   .streakDisplayMode   │
    │   .bossDisplayMode     │
    │   .streakFlexibility   │
    └────────────────────────┘
```

---

## Feature Interaction Matrix

| Feature | Streak | Pause | Rest | Boss Battle | Graduated | Humor |
|---------|--------|-------|------|-------------|-----------|-------|
| **Streak** | — | Paused days skipped | Rest days skipped | Boss requires streak-maintaining days | Flexible mode: 75% maintains | Humor gated on streak > 14 |
| **Pause** | Preserves streak | — | Cannot rest during pause (absent) | Boss timer pauses | N/A (absent) | No humor on return |
| **Rest** | Doesn't break streak | Cannot stack with pause | — | Cannot rest on boss day | Rest = 0% but not "missed" | No humor on rest days |
| **Boss** | Boss needs 5 streak days | Boss pauses if user pauses | No rest during boss | — | Must be 100% during boss | Humor allowed during boss |
| **Graduated** | Flexible mode configurable | N/A during pause | Rest is distinct from partial | Boss requires full completion | — | Humor on any success tier |
| **Humor** | Needs streak > 14 | Never on return | Not on rest days | Allowed during boss | Only on success | — |

---

## Data Model Additions

```swift
// New entities
struct PausePeriod: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let createdAt: Date
}

// Modified entities
enum DailyLogStatus: String, Codable {
    case active, completed, partial, missed, rest, paused
}

// Profile additions
struct Profile {
    var streakDisplayMode: StreakDisplayMode    // .streak | .totalDays | .hidden
    var bossDisplayMode: BossDisplayMode        // .full | .neutral
    var streakFlexibility: StreakFlexibility    // .strict | .flexible
}

enum StreakDisplayMode: String, Codable { case streak, totalDays, hidden }
enum BossDisplayMode: String, Codable { case full, neutral }
enum StreakFlexibility: String, Codable { case strict, flexible }

// Narrative additions
enum NarrativeTone: String, Codable { case stoic, warm, quiet, encouraging, celebratory, light, neutral }
```

---

## Implementation Priority

| Priority | Feature | Complexity | User Impact |
|----------|---------|-----------|-------------|
| P0 | Graduated Success | Low | High — fixes daily frustration |
| P0 | Welcome-Back Flow | Medium | High — fixes critical dropout moment |
| P1 | Intentional Rest Days | Low | Medium — sustainable engagement |
| P1 | Streak-Free Mode | Low | Medium — mental health safety |
| P2 | Life Happened Pause | Medium | Medium — crisis safety net |
| P2 | Boss Sensitivity Filter | Low | Medium — mental health safety |
| P3 | Humor Injection | Low | Low-Medium — long-term retention |

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Return rate after 2-7 day absence | +40% vs current | % of absent users who return within 14 days |
| Retention at Day 30 | +15% | Standard cohort retention |
| Streak-Free Mode adoption | 10-15% of users | Settings analytics |
| Rest day usage | 60%+ of users use at least 1/month | Feature analytics |
| Pause usage | < 5% of users per cycle | Confirms it's a safety net, not a crutch |
| App deletions after streak break | -30% | Store analytics + streak-break cohort |
| NPS improvement | +10 points | Survey after 30 days |

---

## Open Questions

1. Should the "Flexible mode" (75% = streak maintaining) be the default for users with 4+ habits? The cognitive load argument suggests yes.
2. Should rest days be available from Day 1, or earned after first week? Risk of Day 1 rest = never starting.
3. Should humor injection percentage be user-configurable, or is 5% the universal sweet spot?
4. Should the pause system require a reason (for future analysis) or is that invasive?
5. Calendar gradient fill — does it work visually at small cell sizes, or do we need a different encoding (icons, dots)?
