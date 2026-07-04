# SPEC: Lifecycle Endgame — Post-90 Retention & Power User Systems

**Status:** Draft
**Created:** 2026-07-03
**Domain:** Retention, Lifecycle, Economy
**References:** Diablo Paragon system, Call of Duty Prestige, Duolingo leagues, Habitica class system, Destiny 2 seasons

---

## Overview

This specification defines seven interconnected systems that solve the **Day 91 cliff** — the moment where the core "90-day forge challenge" narrative ends and users lose structural motivation. Without these systems, the app faces binary outcomes: users restart (losing visual progress and feeling punished) or drift away (no new objectives).

Design philosophy:
- **Earned progression** — every endgame system requires meaningful prior achievement
- **Narrative continuity** — the forge metaphor evolves rather than resets
- **Layered depth** — casual users see Chapters; power users discover Prestige and Mastery Mode
- **Economy preservation** — new XP sources are bounded and don't inflate early-game balance
- **Content sustainability** — systems generate novelty without requiring constant manual content creation

### System Dependency Map

```
Day 90 Complete
    │
    ├── Chapter 2 unlocks
    │       │
    │       ├── Chapter 3-5 (sequential)
    │       │
    │       ├── Prestige System (after Ch.2 OR Level 20)
    │       │
    │       └── Mastery Mode (Level 15+)
    │
    ├── Habit Leveling (always active, visible post-Day 30)
    │
    ├── Monthly Habit Injection (Level 5+)
    │
    ├── Seasonal Events (all users, quarterly)
    │
    └── Legacy System (Day 365)
```

### Content Pacing Strategy

The critical challenge of endgame design is **overwhelming veterans without underwhelming newcomers**. This spec uses a gated revelation model:

| User Stage | Days Active | Systems Visible |
|-----------|-------------|-----------------|
| Newcomer | 1–30 | Core habits, daily quests, streak |
| Committed | 31–60 | Habit levels appearing, seasonal arc |
| Challenger | 61–90 | Challenge countdown, mastery path tease |
| Graduate | 91–120 | Chapter 2, habit injection, mastery mode |
| Veteran | 121–270 | Chapters 3-5, prestige available |
| Legacy | 365+ | Legacy profile, time capsule |

**Pacing rules:**
1. Never surface more than 1 new system per week
2. New system introductions use a "discovery moment" — a one-time modal explaining the system with a single CTA
3. Systems that are locked show a teaser tooltip ("Unlocks at Level 15") but never a full explanation
4. Veterans who complete all chapters still have seasonal events + habit injection for indefinite engagement
5. Prestige is the "infinite loop" — voluntary reset ensures the core 90-day loop remains replayable with permanent progression

---

## 1. Post-90 Chapters System

### Problem

The entire product narrative is built around "90 days." Every UI element — the day counter, the progress ring, the challenge completion badge — reinforces a single finite arc. After Day 90, users face a design vacuum:

- **Restart**: Resets visual progress, punishes loyalty, feels like failure framing
- **Continue aimlessly**: No objectives, no narrative, no sense of forward motion
- **Leave**: The most common outcome — 70%+ of Day 90 completers churn within 30 days in comparable apps (Habitica data)

The app needs a **structured post-challenge narrative** that maintains the goal-oriented dopamine loop without repeating the same 90-day countdown.

### Design

Upon completing the 90-day challenge, the user enters a **Chapter system** — sequential, objective-based arcs that shift from time-pressure to mastery-pursuit:

| Chapter | Name | Objective | Unlock Condition |
|---------|------|-----------|-----------------|
| 1 | The Forge | Complete 90-day challenge | Day 1 (default) |
| 2 | Master a New Pillar | Raise any single stat to 25+ | Chapter 1 complete |
| 3 | The Balanced Path | All stats above 15 | Chapter 2 complete |
| 4 | The Specialist | Any single stat above 40 | Chapter 3 complete |
| 5 | The Complete Warrior | All stats above 25 | Chapter 4 complete |

**Key design decisions:**
- Each chapter has a **90-day soft timer** (narrative framing, not a hard deadline). If the objective is met before 90 days, the chapter completes early. If 90 days pass without completion, the user receives encouragement ("The forge is patient") but is NOT penalized.
- Chapters are **objective-based**, not time-based. This shifts the psychology from "survive X days" to "achieve X mastery."
- Narrative voice evolves: Chapter 1 is directive ("Complete your daily forge work"). Chapter 2+ is collaborative ("The forge has shaped you. Now shape the forge.").
- Chapters cannot be skipped. Sequential progression ensures each user has a clear single objective.

### User Flow

```
1. User completes Day 90 challenge
2. Celebration screen: "Chapter 1: Complete. The Forge is yours."
3. 24-hour cooldown (let the achievement breathe)
4. Next app open: "Chapter 2 Begins" modal
   - Shows objective: "Master a New Pillar — raise any stat to 25"
   - Shows current stats with distance-to-goal indicators
   - CTA: "Begin Chapter 2"
5. Dashboard transforms:
   - Day counter → Chapter banner ("Chapter 2 • Day 14")
   - Progress ring → Objective progress (e.g., "Strength: 18/25")
   - Narrative quote rotates chapter-appropriate text
6. On objective completion:
   - Chapter complete celebration (unique per chapter)
   - Title awarded: "Pillar Master", "The Balanced", "The Specialist", "Complete Warrior"
   - 24-hour cooldown before next chapter unlocks
```

### Implementation

**Data model:**

```sql
CREATE TABLE chapters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) NOT NULL,
    chapter_number INT NOT NULL DEFAULT 1,
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    objective_type TEXT NOT NULL,  -- 'single_stat_25', 'all_stats_15', 'single_stat_40', 'all_stats_25'
    objective_target JSONB NOT NULL DEFAULT '{}',  -- e.g. {"stat": "any", "value": 25}
    current_progress JSONB NOT NULL DEFAULT '{}',  -- e.g. {"strength": 18, "focus": 22}
    completed_at TIMESTAMPTZ,
    UNIQUE(user_id, chapter_number)
);

CREATE INDEX idx_chapters_user_active ON chapters(user_id) WHERE completed_at IS NULL;
```

**Swift service:**

```swift
// ChapterService.swift
final class ChapterService {
    private let supabase: SupabaseService

    struct Chapter: Codable, Identifiable {
        let id: UUID
        let user_id: UUID
        let chapter_number: Int
        let started_at: Date
        let objective_type: String
        let objective_target: [String: Int]
        var current_progress: [String: Int]
        var completed_at: Date?
    }

    func activeChapter(for userId: UUID) async throws -> Chapter? {
        // Fetch chapter where completed_at IS NULL
    }

    func evaluateProgress(chapter: Chapter, stats: Stats) -> Bool {
        switch chapter.objective_type {
        case "single_stat_25":
            return stats.allValues.contains { $0 >= 25 }
        case "all_stats_15":
            return stats.allValues.allSatisfy { $0 > 15 }
        case "single_stat_40":
            return stats.allValues.contains { $0 >= 40 }
        case "all_stats_25":
            return stats.allValues.allSatisfy { $0 > 25 }
        default: return false
        }
    }

    func advanceChapter(userId: UUID, currentChapter: Int) async throws {
        // Mark current complete, insert next chapter row
    }
}
```

**Integration points:**
- `ProgressionEngine.processHabitCompletion()` → after stats update, call `ChapterService.evaluateProgress()`
- `DashboardView` → swap day counter for chapter banner when `profile.hasCompletedChallenge`
- `ProfileView` → show chapter history with completion dates

### Economy Impact

| Metric | Before | After | Notes |
|--------|--------|-------|-------|
| XP generation rate | Unchanged | Unchanged | Chapters don't add XP sources |
| Stat progression rate | Unchanged | Unchanged | No stat bonuses for being in a chapter |
| Title supply | +4 titles | Low | One per chapter, sequential |
| Engagement ceiling | Day 90 | Day 450+ | 5 chapters × ~90 days each |

Chapters are **economy-neutral** — they provide structure and narrative without adding inflationary XP or stat bonuses. The reward is titles and the progression feeling itself.

### Acceptance Criteria

- [ ] User who completes Day 90 challenge sees Chapter 2 introduction within 24-48 hours
- [ ] Chapter banner displays correctly, replacing day counter on dashboard
- [ ] Objective progress updates in real-time as stats change
- [ ] Early completion (before 90-day timer) triggers chapter complete flow
- [ ] Late completion (after 90-day timer) still works without penalty
- [ ] Chapter-specific title is awarded on completion and appears in profile
- [ ] User cannot skip chapters or be in multiple chapters simultaneously
- [ ] Chapter history is viewable in profile (completed chapters with dates)
- [ ] `chapters` table has proper RLS policies (users see only their own)
- [ ] ChapterService integration does not regress ProgressionEngine performance (< 50ms added latency)

---

## 2. Prestige / Rebirth System

### Problem

Power RPG players crave **voluntary reset mechanics** — the feeling of starting fresh with permanent advantages earned through mastery. Games like Diablo (Paragon levels), Call of Duty (Prestige), Cookie Clicker (Ascension), and Realm Grinder (Abdication) prove that resetting can be MORE engaging than continuing, because:

1. It validates prior achievement ("I'm strong enough to reset")
2. It provides a fresh dopamine curve (early leveling is fast and rewarding)
3. It creates permanent differentiation (prestige players are visually distinct)
4. It extends content lifespan infinitely without new content creation

Without this, power users who max out Chapters hit a terminal ceiling with no replay incentive.

### Design

**Unlock condition:** Complete Chapter 2 OR reach Level 20 with challenge complete (whichever comes first).

**Reset mechanics:**

| Category | On Rebirth |
|----------|-----------|
| Stats | Reset to baseline (all stats = 5) |
| Level | Reset to 1 |
| XP Total | Reset to 0 |
| Streak | Reset to 0 |
| Chapter | Reset to Chapter 1 (re-do the 90-day challenge) |
| Titles earned | **KEPT** |
| Achievements | **KEPT** |
| Forge Tokens balance | **KEPT** |
| Prestige count | **INCREMENTED** |
| Habit history | **KEPT** (for analytics, hidden from active UI) |

**Permanent bonuses per rebirth:**

| Rebirth | XP Multiplier | Starting Stat Bonus | Cosmetic |
|---------|--------------|--------------------|---------| 
| 1 | +5% base XP | — | Prestige ★ star (bronze) |
| 2 | +10% base XP | +1 to all starting stats | Prestige ★★ (silver) |
| 3 | +15% base XP | +2 to all starting stats | 'Reborn' evolution card skin |
| 4 | +18% base XP | +3 to all starting stats | Gold card border |
| 5 (max) | +20% base XP | +4 to all starting stats | Legendary flame aura on profile |

**Design constraints:**
- Maximum 5 rebirths. Diminishing returns prevent runaway inflation.
- XP multiplier is additive to base, not multiplicative with other bonuses (prevents stacking exploits with seasonal arcs, crit hits, etc.)
- Starting stat bonus means stats begin at 5 + prestige_bonus instead of flat 5
- Prestige players replay the same content but faster — this is intentional (power fantasy)

### User Flow

```
1. User meets prestige requirements (Chapter 2 complete OR Level 20 + challenge done)
2. "Rebirth" option appears in Profile → Settings (subtle, not pushed)
3. User taps "Rebirth"
4. Step 1 confirmation: Overview screen
   "Rebirth resets your stats, level, and streak.
    You keep: Titles, Achievements, Forge Tokens.
    You gain: +5% permanent XP bonus."
   [Cancel] [Continue]
5. Step 2 confirmation: Explicit warning
   "Your stats will return to baseline.
    Your level will reset to 1.
    Your streak will reset to 0.
    This cannot be undone."
   [Go Back] [I Understand]
6. Step 3 confirmation: Final commit
   "Type REBIRTH to confirm."
   [Text field] [Confirm]
7. Rebirth animation: Stats dissolve, phoenix/flame animation, new star appears
8. App returns to fresh state with prestige star visible
9. Chapter 1 begins again (90-day challenge, now with XP bonus)
```

### Implementation

**Data model:**

```sql
CREATE TABLE prestige_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) NOT NULL,
    prestige_number INT NOT NULL,  -- 1, 2, 3, 4, 5
    rebirthed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    level_at_rebirth INT NOT NULL,
    xp_at_rebirth INT NOT NULL,
    stats_at_rebirth JSONB NOT NULL,
    streak_at_rebirth INT NOT NULL,
    UNIQUE(user_id, prestige_number)
);

-- Add to profiles table
ALTER TABLE profiles ADD COLUMN prestige_level INT NOT NULL DEFAULT 0;
ALTER TABLE profiles ADD COLUMN prestige_xp_bonus DECIMAL(4,2) NOT NULL DEFAULT 0.00;
ALTER TABLE profiles ADD COLUMN prestige_stat_bonus INT NOT NULL DEFAULT 0;
```

**Swift integration:**

```swift
// PrestigeService.swift
final class PrestigeService {

    struct PrestigeBonuses {
        let xpMultiplier: Double    // 1.05, 1.10, 1.15, 1.18, 1.20
        let startingStatBonus: Int  // 0, 1, 2, 3, 4
        let cosmetic: PrestigeCosmetic
    }

    static func bonuses(for level: Int) -> PrestigeBonuses {
        switch level {
        case 1: return PrestigeBonuses(xpMultiplier: 1.05, startingStatBonus: 0, cosmetic: .bronzeStar)
        case 2: return PrestigeBonuses(xpMultiplier: 1.10, startingStatBonus: 1, cosmetic: .silverStar)
        case 3: return PrestigeBonuses(xpMultiplier: 1.15, startingStatBonus: 2, cosmetic: .rebornSkin)
        case 4: return PrestigeBonuses(xpMultiplier: 1.18, startingStatBonus: 3, cosmetic: .goldBorder)
        case 5: return PrestigeBonuses(xpMultiplier: 1.20, startingStatBonus: 4, cosmetic: .legendaryAura)
        default: return PrestigeBonuses(xpMultiplier: 1.0, startingStatBonus: 0, cosmetic: .none)
        }
    }

    func executeRebirth(userId: UUID, profile: Profile) async throws {
        // 1. Record current state in prestige_records
        // 2. Increment prestige_level on profile
        // 3. Reset stats to baseline + prestige_stat_bonus
        // 4. Reset level to 1, xp_total to 0, streak to 0
        // 5. Reset chapters (delete or mark reset)
        // 6. Update prestige_xp_bonus
        // 7. Trigger rebirth analytics event
    }

    func isEligible(profile: Profile, chapterComplete: Int) -> Bool {
        guard profile.prestige_level < 5 else { return false }
        return chapterComplete >= 2 || (profile.level >= 20 && profile.hasCompletedChallenge)
    }
}
```

**XP integration in ProgressionEngine:**

```swift
// In PerkSystem.modifiedXPReward or equivalent
let prestigeMultiplier = profile.prestige_xp_bonus  // e.g., 0.05
let finalXP = Int(Double(baseXP) * (1.0 + prestigeMultiplier))
// Note: prestige bonus is ADDITIVE, applied before crit multiplication
```

### Economy Impact

| Metric | Impact | Mitigation |
|--------|--------|-----------|
| XP generation | +5% to +20% permanently | Caps at 20%; early levels are cheap anyway |
| Stat growth | +1 to +4 starting stats | Small vs. endgame stats (25-40 range) |
| Leveling speed | Faster on replay | Intentional — power fantasy reward |
| Token economy | Neutral | Tokens are kept but not generated faster |
| Title inflation | None | Titles from prior run are kept, not duplicated |

**Key constraint:** Prestige bonus does NOT stack with seasonal arc multipliers multiplicatively. Formula:
```
final_xp = base_xp * (1.0 + prestige_bonus + seasonal_bonus) * crit_multiplier
```

This prevents compound inflation (1.20 × 1.20 × 3.0 = 4.32x would be excessive).

### Acceptance Criteria

- [ ] Prestige option only visible when eligibility conditions are met
- [ ] 3-step confirmation flow prevents accidental rebirths
- [ ] Final step requires typing "REBIRTH" (exact match, case-insensitive)
- [ ] On rebirth: stats, level, XP, streak, and chapter all reset correctly
- [ ] On rebirth: titles, achievements, tokens, and prestige count are preserved
- [ ] Prestige XP bonus applies correctly to all subsequent XP awards
- [ ] Starting stat bonus applies on reset (stats begin at 5 + bonus, not flat 5)
- [ ] Prestige star displays next to username in all relevant views
- [ ] Gold border / cosmetic unlocks apply to Discipline Card
- [ ] Maximum 5 rebirths enforced — option disappears after 5th
- [ ] `prestige_records` captures full snapshot of pre-rebirth state
- [ ] Rebirth does not corrupt habit completion history (kept for analytics)
- [ ] Prestige bonus formula is additive, not multiplicative with other bonuses
- [ ] Rebirth animation plays smoothly (< 3 seconds, no frame drops)
- [ ] Analytics event fires on rebirth with prestige_number and pre-rebirth stats

---

## 3. Habit Leveling

### Problem

"Read 10 pages" on Day 300 feels identical to Day 1. The habit itself has no growth arc — no sense that the user has *mastered* this particular discipline. Every completion awards the same flat XP regardless of whether it's the user's 5th or 500th time doing it.

This creates two retention failures:
1. **No micro-progression** — between level-ups (which can take days), there's no smaller feedback loop
2. **No habit identity** — users can't point to a specific habit and say "I've mastered this"
3. **No differentiation** — a veteran's habit list looks identical to a newcomer's

### Design

Each habit gains its own level based on total lifetime completions:

| Completions | Habit Level | Visual | XP Bonus |
|-------------|-------------|--------|----------|
| 0–9 | Level 1 | No stars | +0 (base 10 XP) |
| 10–24 | Level 2 | ★ | +1 (11 XP) |
| 25–49 | Level 3 | ★★ | +2 (12 XP) |
| 50–99 | Level 4 | ★★★ | +3 (13 XP) |
| 100–199 | Level 5 "Mastered" | ★★★★ | +4 (14 XP) |
| 200+ | Level 6 "Legendary" | ★★★★★ | +5 (15 XP) |

**Design decisions:**
- XP bonus is **additive to base**, not multiplicative. A +5 XP bonus on a 10 XP habit = 15 XP (50% increase at maximum). This is generous for veterans but bounded.
- Habit level is per-habit-name, not per-habit-instance. If a user removes and re-adds "Read 10 pages," the completion count persists (tracked by habit name + user_id).
- Level-up moment: When a habit crosses a threshold, show a brief celebratory toast ("★ Read 10 pages leveled up!") with a new star animation.
- Visual: Stars render inline in `HabitRow`, left of the habit name. Mastered habits (L5+) get a subtle gold shimmer on the row background. Legendary habits (L6) get a pulsing gold border.

### User Flow

```
1. User completes "Read 10 pages" for the 10th time
2. Normal completion animation plays
3. Additional toast: "★ Habit Level Up! Read 10 pages → Level 2"
4. Star appears next to habit name in list
5. Next completion: user notices "+11 XP" instead of "+10 XP"
6. Habit detail view shows: "Level 2 • 10/25 to next level"
7. At 100 completions: "MASTERED" badge appears, gold shimmer activates
8. At 200 completions: "LEGENDARY" status, 5 stars, max bonus
```

### Implementation

**Data approach — computed, not stored:**

Habit level is derived from the `habit_completions` table count. No separate level table needed.

```swift
// HabitLevelSystem.swift
struct HabitLevelSystem {

    struct HabitLevel {
        let level: Int
        let stars: Int
        let title: String?  // nil, nil, nil, nil, "Mastered", "Legendary"
        let xpBonus: Int
        let completionsToNext: Int?  // nil if max level
    }

    private static let thresholds: [(completions: Int, level: Int, xpBonus: Int)] = [
        (0, 1, 0),
        (10, 2, 1),
        (25, 3, 2),
        (50, 4, 3),
        (100, 5, 4),
        (200, 6, 5)
    ]

    static func level(forCompletions count: Int) -> HabitLevel {
        var current = thresholds[0]
        for threshold in thresholds {
            if count >= threshold.completions {
                current = threshold
            } else {
                break
            }
        }

        let nextThreshold = thresholds.first { $0.completions > count }
        let toNext = nextThreshold.map { $0.completions - count }

        let title: String? = switch current.level {
        case 5: "Mastered"
        case 6: "Legendary"
        default: nil
        }

        return HabitLevel(
            level: current.level,
            stars: max(0, current.level - 1),
            title: title,
            xpBonus: current.xpBonus,
            completionsToNext: toNext
        )
    }
}
```

**Completion count source:**

```swift
// In HabitCompletionService or DailyLogService
func completionCount(userId: UUID, habitName: String) async throws -> Int {
    // SELECT COUNT(*) FROM habit_completions
    // WHERE user_id = $1 AND habit_name = $2
}
```

**Integration with ProgressionEngine:**

```swift
// In ProgressionEngine.processHabitCompletion()
let completionCount = await habitCompletionService.completionCount(
    userId: profile.id, 
    habitName: habit.name
)
let habitLevel = HabitLevelSystem.level(forCompletions: completionCount)
let habitXPBonus = habitLevel.xpBonus

// Modify XP calculation
let baseXP = habit.xpReward + habitXPBonus  // 10 + bonus
let awardedXP = PerkSystem.modifiedXPReward(
    baseXP: baseXP,
    activePerks: activePerks,
    currentDailyXP: todayLog.xp_earned,
    streak: updatedProfile.streak
)
```

**UI integration in HabitRow:**

```swift
// HabitRow.swift additions
HStack(spacing: 2) {
    ForEach(0..<habitLevel.stars, id: \.self) { _ in
        Image(systemName: "star.fill")
            .font(.system(size: 8))
            .foregroundColor(habitLevel.level >= 5 ? .yellow : .orange)
    }
}
```

**Performance consideration:**
- Completion counts should be cached per session (fetched once on habit list load, incremented locally on completion)
- Do NOT query the database per-row render
- Cache invalidation: on app foreground + on habit completion

### Economy Impact

| Metric | Impact | Notes |
|--------|--------|-------|
| Max XP per habit | 10 → 15 (+50%) | Only for 200+ completion veterans |
| Average XP increase | ~+15% for Day 90 users | Most habits at Level 2-3 by Day 90 |
| Inflation risk | Low | +1 to +5 XP is small vs. crit hits (2-3x) |
| Level curve impact | Slight acceleration | Veterans level ~15% faster; appropriate for retention |

**Interaction with prestige:**
- On rebirth, habit completion counts are NOT reset (they represent historical mastery)
- This means prestige players re-enter with habits already leveled — intentional power fantasy
- A prestige player's "Read 10 pages" still shows ★★★★★ even at Level 1 character

### Acceptance Criteria

- [ ] Habit level computed correctly from completion count at all thresholds
- [ ] Stars display inline in HabitRow (0 to 5 stars)
- [ ] XP bonus applies correctly (+1 per habit level above 1)
- [ ] Level-up toast displays on threshold crossing (not on every completion)
- [ ] Gold shimmer visual on Level 5+ habits
- [ ] Legendary pulsing border on Level 6 habits
- [ ] Habit detail view shows level progress ("12/25 to next level")
- [ ] Completion count persists across habit removal and re-addition (keyed by name)
- [ ] Performance: habit list renders in < 16ms (cached counts, no per-row DB queries)
- [ ] Prestige does NOT reset habit completion counts
- [ ] HabitLevelSystem has unit tests for all threshold boundaries
- [ ] XP bonus integrates correctly with existing PerkSystem modifiers (additive, not multiplicative)

---

## 4. Monthly Habit Injection (Content Refresh)

### Problem

After 90 days, veterans have seen every habit in the preset pool and every quest combination. The system becomes entirely predictable — no novelty, no surprise, no discovery. This directly reduces the "variable reward" psychology that drives daily opens.

Comparable apps solve this with:
- Duolingo: New lesson content monthly
- Destiny 2: Seasonal content drops
- Wordle: Daily unique puzzle (novelty is the product)

RNF needs a sustainable content injection pipeline that doesn't require engineering effort per release.

### Design

Every calendar month, 2-3 new optional habits are added to the preset pool:

**Content categories (rotating):**
- Physical: Cold exposure, mobility work, outdoor walk, sport practice
- Mental: Skill practice, deep focus session, teach someone something
- Spiritual: Gratitude list, nature immersion, digital sunset, journaling prompt
- Social: Call a friend, community contribution, mentorship moment

**Example 6-month content calendar:**

| Month | New Habits |
|-------|-----------|
| Jan | Cold exposure 2 min, Year intention journaling |
| Feb | Skill practice 15 min, Partner appreciation note |
| Mar | Walk in nature 20 min, Digital sunset (no screens 1hr before bed) |
| Apr | Gratitude list (3 items), Mobility routine 10 min |
| May | Teach someone something, Cold shower finish |
| Jun | Deep focus block 45 min, Outdoor workout |

**Gating:** New habits only appear for users at Level 5+ (prevents overwhelming newcomers who are still building their first 3-4 habits).

**Delivery mechanism:**
1. "New Habit Available" push notification on 1st of the month (if user is Level 5+)
2. Badge indicator on Habits tab
3. New habits highlighted with "NEW" tag for 7 days
4. User can browse and optionally add to their active set
5. New habits are never auto-added — always opt-in

### User Flow

```
1. 1st of the month arrives
2. User opens app → badge on Habits tab
3. Taps Habits → sees "New This Month" section at top
4. Browses 2-3 new habit options with descriptions
5. Taps "Add" on desired habit → habit joins active roster
6. "NEW" tag fades after 7 days
7. If user ignores: habits remain available in "Browse Habits" but badge clears after 3 days
```

### Implementation

**Data model:**

```sql
CREATE TABLE habit_presets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,  -- 'physical', 'mental', 'spiritual', 'social'
    pillar TEXT NOT NULL,    -- maps to stat: 'strength', 'focus', 'discipline', etc.
    xp_reward INT NOT NULL DEFAULT 10,
    available_from DATE NOT NULL,  -- first date this habit appears
    available_to DATE,  -- NULL = permanent; set date for seasonal-only habits
    min_level INT NOT NULL DEFAULT 5,  -- minimum user level to see this habit
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_habit_presets_available ON habit_presets(available_from, min_level);
```

**Swift service:**

```swift
// HabitAgencyService.swift (extends existing)
extension HabitAgencyService {

    func availableNewHabits(userLevel: Int, currentDate: Date = Date()) async throws -> [HabitPreset] {
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: currentDate))!

        return try await supabase.client
            .from("habit_presets")
            .select()
            .lte("available_from", value: currentDate.ISO8601Format())
            .gte("available_from", value: startOfMonth.ISO8601Format())
            .lte("min_level", value: userLevel)
            .execute()
            .value
    }

    func hasUnseenNewHabits(userId: UUID, userLevel: Int) async throws -> Bool {
        let newHabits = try await availableNewHabits(userLevel: userLevel)
        let seen = UserDefaults.standard.stringArray(forKey: "rnf_seen_habits_\(userId)") ?? []
        return newHabits.contains { !seen.contains($0.id.uuidString) }
    }
}
```

**Content management:**
- New habits are inserted via Supabase dashboard or admin script
- No app update required — content is server-driven
- `available_from` date controls when habits appear
- `available_to` date allows seasonal-only habits (e.g., "New Year intention" only in January)

**Notification trigger:**

```swift
// Scheduled local notification on 1st of each month
func scheduleMonthlyHabitNotification() {
    let content = UNMutableNotificationContent()
    content.title = "New Habits Available"
    content.body = "Fresh disciplines have been added to the forge. Explore them."
    content.badge = 1

    var dateComponents = DateComponents()
    dateComponents.day = 1
    dateComponents.hour = 9

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    // Register notification...
}
```

### Economy Impact

| Metric | Impact | Notes |
|--------|--------|-------|
| XP sources | +2-3 per month | Same base XP as existing habits (10) |
| Daily XP ceiling | Slightly higher | If user adds more active habits |
| Stat diversity | Improved | New habits can target underserved stats |
| Content freshness | High | Prevents "seen it all" fatigue |

**Constraint:** New habits award standard base XP (10). No inflated rewards for new content. Habit leveling applies as normal (they start at Level 1 with 0 completions).

### Acceptance Criteria

- [ ] New habits appear on their `available_from` date and not before
- [ ] Users below `min_level` do not see gated habits
- [ ] Badge indicator appears on Habits tab when unseen new habits exist
- [ ] "NEW" tag displays for 7 days after user first sees the habit
- [ ] User can add new habit to active roster with single tap
- [ ] New habits are never auto-added to user's active set
- [ ] `habit_presets` table supports server-side content additions without app update
- [ ] Push notification fires on 1st of month for eligible users (Level 5+)
- [ ] Badge clears after user views the new habits section (or after 3 days)
- [ ] Seasonal habits (with `available_to`) disappear after their window closes
- [ ] Content calendar has 6+ months of planned content before launch
- [ ] New habits integrate with existing stat system (proper pillar mapping)
- [ ] Habit preset descriptions are clear, actionable, and under 50 characters

---

## 5. Mastery Mode (Single-Habit Deep Dive)

### Problem

The app treats all habits as equal-weight checkboxes. A user who has completed "Cold shower" 200 times has no deeper relationship with that habit than someone who did it twice. There's no way to signal "this is MY discipline" — no deep analytics, no intensified tracking, no recognition of singular focus.

Power users who've identified their core discipline want:
- Detailed statistics beyond "you did it today"
- Recognition for depth, not just breadth
- A reason to keep pushing one habit beyond "Legendary" level

### Design

**Unlock:** Level 15+ (ensures user has broad experience before specializing)

**Mastery Focus** — choose 1 active habit for intensified tracking:

| Feature | Description |
|---------|-------------|
| Dedicated page | Full-screen progress view for the focused habit |
| Best streak | Longest consecutive days completing this specific habit |
| Total count | Lifetime completions with historical graph |
| Day-of-week heatmap | Which days the user is most/least consistent |
| Completion rate | % of days the habit was completed vs. available |
| Mastery milestones | Specific achievements for this habit |
| 1.5x XP bonus | Mastery focus habit awards 50% more XP |

**Mastery Milestones (per-habit):**

| Milestone | Condition | Reward |
|-----------|-----------|--------|
| Dedicated | 7-day streak on this habit | +50 XP bonus |
| Committed | 14-day streak | +100 XP bonus |
| Relentless | 30-day streak | +200 XP bonus, "Relentless" micro-badge |
| Unbreakable | 60-day streak | +500 XP bonus, "Unbreakable" micro-badge |
| Transcendent | 90-day streak | +1000 XP bonus, unique habit frame |

**Constraints:**
- 1 mastery focus at a time
- Can change mastery focus once per month (prevents gaming by switching to whichever habit is closest to a milestone)
- Changing focus does NOT reset the previous habit's streak/stats (they're preserved, just not actively focused)
- 1.5x XP only applies to the focused habit

### User Flow

```
1. User reaches Level 15
2. "Mastery Mode Unlocked" discovery modal appears
   "Choose one discipline to master. Track it deeply. Earn bonus XP."
3. User selects a habit from their active roster
4. Mastery page unlocks for that habit:
   - Header: habit name + mastery level ring
   - Stats grid: streak, total, rate, best day
   - Heatmap calendar: last 90 days color-coded
   - Milestone tracker: next milestone + progress
5. Daily completion of mastery habit shows enhanced feedback:
   - "+15 XP (Mastery 1.5x)" instead of "+10 XP"
   - Streak counter specific to this habit
6. Monthly: option to change focus appears (small "Change Focus" link)
7. On milestone hit: celebration + XP bonus + micro-badge
```

### Implementation

**Data model:**

```sql
-- Add to profiles
ALTER TABLE profiles ADD COLUMN mastery_focus_habit_id UUID REFERENCES habits(id);
ALTER TABLE profiles ADD COLUMN mastery_focus_set_at TIMESTAMPTZ;

-- Mastery stats are computed from habit_completions, no separate table needed
-- Milestones tracked in achievements table with type = 'mastery_milestone'
```

**Swift service (extend existing MasteryPathService):**

```swift
// MasteryFocusService.swift
final class MasteryFocusService {

    struct MasteryStats {
        let habitName: String
        let totalCompletions: Int
        let currentStreak: Int
        let bestStreak: Int
        let completionRate: Double  // 0.0-1.0
        let dayOfWeekDistribution: [Int: Int]  // 1(Sun)-7(Sat) → count
        let nextMilestone: MasteryMilestone?
        let earnedMilestones: [MasteryMilestone]
    }

    enum MasteryMilestone: Int, CaseIterable {
        case dedicated = 7
        case committed = 14
        case relentless = 30
        case unbreakable = 60
        case transcendent = 90

        var xpReward: Int {
            switch self {
            case .dedicated: return 50
            case .committed: return 100
            case .relentless: return 200
            case .unbreakable: return 500
            case .transcendent: return 1000
            }
        }

        var title: String {
            switch self {
            case .dedicated: return "Dedicated"
            case .committed: return "Committed"
            case .relentless: return "Relentless"
            case .unbreakable: return "Unbreakable"
            case .transcendent: return "Transcendent"
            }
        }
    }

    func canChangeFocus(lastSetAt: Date?) -> Bool {
        guard let lastSet = lastSetAt else { return true }
        let daysSinceSet = Calendar.current.dateComponents([.day], from: lastSet, to: Date()).day ?? 0
        return daysSinceSet >= 30
    }

    func computeStats(userId: UUID, habitId: UUID) async throws -> MasteryStats {
        // Query habit_completions for this user+habit
        // Compute streak, rate, distribution from completion dates
        // Determine earned/next milestones from current streak
    }

    func setFocus(userId: UUID, habitId: UUID) async throws {
        // Update profile.mastery_focus_habit_id and mastery_focus_set_at
    }
}
```

**XP integration:**

```swift
// In ProgressionEngine.processHabitCompletion()
let isMasteryFocus = habit.id == profile.mastery_focus_habit_id
let masteryMultiplier: Double = isMasteryFocus ? 1.5 : 1.0
let baseXP = Int(Double(habit.xpReward + habitLevelBonus) * masteryMultiplier)
```

**UI: MasteryFocusView.swift**

```swift
struct MasteryFocusView: View {
    let stats: MasteryFocusService.MasteryStats

    var body: some View {
        ScrollView {
            // Habit name + mastery ring header
            // Stats grid (2x2): streak, total, rate, best day
            // 90-day heatmap calendar
            // Milestone progress list
        }
    }
}
```

### Economy Impact

| Metric | Impact | Notes |
|--------|--------|-------|
| Focused habit XP | +50% (10 → 15 base) | Only 1 habit gets this bonus |
| Daily XP ceiling | +5 XP per day (approx) | Minimal inflation |
| Milestone bonuses | +50 to +1000 XP (one-time) | Spaced out over months |
| Leveling impact | Negligible | One-time bonuses don't compound |

**Interaction with Habit Leveling:**
- Mastery 1.5x applies AFTER habit level bonus: `(10 + habitLevelBonus) * 1.5`
- A Legendary (Level 6) mastery focus habit gives: `(10 + 5) * 1.5 = 22 XP` per completion
- This is the maximum possible single-habit XP without crits — acceptable for 200+ completion veterans

### Acceptance Criteria

- [ ] Mastery Mode unlocks at Level 15 with discovery modal
- [ ] User can select exactly 1 habit as mastery focus
- [ ] Mastery focus cannot be changed more than once per 30 days
- [ ] 1.5x XP applies only to the mastery focus habit
- [ ] Mastery page displays: total completions, current streak, best streak, completion rate, day-of-week heatmap
- [ ] Heatmap shows last 90 days of completion data
- [ ] Mastery milestones trigger at correct streak thresholds (7, 14, 30, 60, 90)
- [ ] Milestone XP bonus awards correctly as one-time payment
- [ ] Micro-badges ("Relentless", "Unbreakable") display on profile
- [ ] Changing focus preserves previous habit's stats (no data loss)
- [ ] Enhanced "+15 XP (Mastery)" feedback shows on focused habit completion
- [ ] MasteryFocusView renders within 200ms (computed stats cached)
- [ ] Focus selection UI clearly communicates the 30-day lock-in
- [ ] Mastery XP integrates correctly with prestige bonus and habit level bonus (additive chain)

---

## 6. Seasonal Events

### Problem

The app lacks external time pressure and real-world novelty. Every day feels the same structurally. There's no "something special is happening RIGHT NOW" urgency that drives daily opens in live-service games.

Current `SeasonalArc` system provides monthly stat bonuses and titles, but:
- It's passive (bonus applies automatically, no active participation required)
- No limited-time objectives to chase
- No exclusive rewards that create FOMO (fear of missing out)
- No community-wide shared goals

### Design

Quarterly mega-events layered ON TOP of the existing monthly `SeasonalArc` system:

| Quarter | Event | Duration | Theme | Core Mechanic |
|---------|-------|----------|-------|---------------|
| Q1 (Spring) | The Awakening | 21 days | New habit adoption | Adopt & complete a new habit 15/21 days |
| Q2 (Summer) | The Crucible | 30 days | Maximum intensity | Complete ALL active habits every day for 30 days |
| Q3 (Autumn) | The Harvest | 14 days | Reflection & sharing | Complete reflection prompts, share Discipline Card |
| Q4 (Winter) | The Deep Forge | 28 days | Endurance through adversity | Maintain streak through holiday distractions |

**Event structure:**
- **Announcement:** 7 days before event, teaser banner appears
- **Active period:** Event objectives tracked daily
- **Grace:** 1-2 miss days allowed (except The Crucible which is all-or-nothing)
- **Completion:** Event-exclusive rewards delivered immediately

**Rewards per event:**

| Reward Type | Examples |
|-------------|---------|
| Exclusive badge | "Awakened 2026", "Crucible Survivor", "Harvest Moon" |
| Forge Tokens | 50-200 tokens depending on event difficulty |
| Cosmetic unlock | Event-themed card border, stat icon skin, profile frame |
| XP bonus | One-time 500-2000 XP award on completion |
| Title | Event-year specific ("Crucible 2026") — never repeats |

**Difficulty scaling by user level:**

| User Level | Event Difficulty |
|-----------|-----------------|
| 1-10 | Relaxed (lower completion threshold) |
| 11-20 | Standard |
| 21+ | Hardcore (higher threshold, better rewards) |

### User Flow

```
1. 7 days before event: Banner appears on dashboard
   "The Crucible approaches. 30 days of total commitment. Are you ready?"
2. Event start date: Full-screen event introduction
   - Theme narrative
   - Objectives explained
   - Rewards preview
   - [Join Event] CTA (opt-in, not forced)
3. During event:
   - Event progress bar on dashboard (replacing seasonal arc card temporarily)
   - Daily check: "Crucible Day 14/30 ✓" or "Day 14/30 ✗ (1 miss remaining)"
   - Event-specific encouragement copy
4. On event completion:
   - Celebration screen with exclusive rewards
   - Badge + tokens + cosmetic delivered
   - "Share your achievement" option
5. On event failure:
   - Consolation: "You made it X days. The forge remembers effort."
   - Partial reward: reduced tokens (25% of full)
   - No badge (exclusivity preserved)
6. Post-event: results summary, event disappears until next quarter
```

### Implementation

**Data model:**

```sql
CREATE TABLE seasonal_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,  -- 'crucible_2026_q2'
    quarter INT NOT NULL,       -- 1-4
    year INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    announcement_date DATE NOT NULL,
    objective_type TEXT NOT NULL,  -- 'all_habits_daily', 'new_habit_adoption', 'reflection', 'streak_maintain'
    objective_config JSONB NOT NULL DEFAULT '{}',
    rewards_config JSONB NOT NULL,  -- {badge_id, tokens, xp, cosmetic_id}
    difficulty_tiers JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE event_participations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) NOT NULL,
    event_id UUID REFERENCES seasonal_events(id) NOT NULL,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    difficulty_tier TEXT NOT NULL DEFAULT 'standard',
    daily_progress JSONB NOT NULL DEFAULT '[]',  -- [{date, completed: bool}]
    misses_used INT NOT NULL DEFAULT 0,
    max_misses INT NOT NULL DEFAULT 2,
    status TEXT NOT NULL DEFAULT 'active',  -- 'active', 'completed', 'failed'
    completed_at TIMESTAMPTZ,
    rewards_claimed BOOLEAN DEFAULT false,
    UNIQUE(user_id, event_id)
);

CREATE INDEX idx_event_participations_active ON event_participations(user_id, status) WHERE status = 'active';
```

**Swift service (extend SeasonalArcService):**

```swift
// SeasonalEventService.swift
final class SeasonalEventService {

    struct SeasonalEvent: Codable, Identifiable {
        let id: UUID
        let name: String
        let slug: String
        let startDate: Date
        let endDate: Date
        let announcementDate: Date
        let objectiveType: String
        let rewardsConfig: EventRewards
    }

    struct EventParticipation: Codable {
        let id: UUID
        let eventId: UUID
        var dailyProgress: [DailyEventEntry]
        var missesUsed: Int
        let maxMisses: Int
        var status: String
    }

    func activeEvent() async throws -> SeasonalEvent? {
        let today = Date()
        // Fetch event where start_date <= today <= end_date
    }

    func upcomingEvent() async throws -> SeasonalEvent? {
        let today = Date()
        // Fetch event where announcement_date <= today < start_date
    }

    func joinEvent(userId: UUID, eventId: UUID, userLevel: Int) async throws -> EventParticipation {
        let tier = difficultyTier(for: userLevel)
        // Insert participation record
    }

    func recordDailyProgress(participationId: UUID, completed: Bool) async throws {
        // Append to daily_progress, check miss count
        // If misses > max_misses → status = 'failed'
        // If days_completed >= required → status = 'completed'
    }

    private func difficultyTier(for level: Int) -> String {
        switch level {
        case 1...10: return "relaxed"
        case 11...20: return "standard"
        default: return "hardcore"
        }
    }
}
```

**Integration with existing SeasonalArcService:**
- Monthly arcs continue running during quarterly events
- Event banner takes visual priority over arc card on dashboard
- XP from event completion stacks with monthly arc bonus (both are one-time awards, not multipliers)

### Economy Impact

| Metric | Impact | Notes |
|--------|--------|-------|
| Tokens per quarter | +50 to +200 | 4 events/year = 200-800 tokens annually |
| XP per event | +500 to +2000 (one-time) | Equivalent to 50-200 habit completions |
| Badge supply | +4 per year | Exclusive, non-repeating |
| Cosmetic supply | +4 per year | Drives Discipline Card engagement |
| Inflation risk | Low | One-time awards, quarterly cadence |

**Constraint:** Event rewards are delivered once. Failing and retrying next year gives a different badge (year-stamped). No farming.

### Acceptance Criteria

- [ ] Events announced 7 days before start (banner visible on dashboard)
- [ ] Event participation is opt-in (Join button required)
- [ ] Difficulty tier auto-selected based on user level
- [ ] Daily progress tracked correctly (completed/missed per day)
- [ ] Miss allowance enforced (event fails when misses exceed max)
- [ ] Event completion triggers reward delivery (badge + tokens + XP + cosmetic)
- [ ] Failed events award partial tokens (25%) and no badge
- [ ] Event badges are year-stamped and never repeat
- [ ] Event UI replaces seasonal arc card during active event period
- [ ] Upcoming event teaser shows countdown and theme preview
- [ ] Events work independently of chapter progress (all users can join)
- [ ] `seasonal_events` table supports server-side event creation without app update
- [ ] Event progress persists across app kills and device restarts
- [ ] SeasonalEventService integrates without breaking existing SeasonalArcService functionality
- [ ] Share functionality works for event completion (generates shareable image)

---

## 7. Legacy System (Long-term Identity)

### Problem

After 1 year of consistent use, what defines the user's identity in the app? Most habit trackers treat a 365-day user the same as a 30-day user — just with bigger numbers. There's no ceremony, no narrative closure, no sense that the app *knows* and *honors* the journey.

Users who reach Day 365 need:
- Recognition of their extraordinary commitment
- A permanent identity marker that distinguishes them
- A reason to look back AND a reason to look forward
- Emotional connection that transcends gamification

### Design

At Day 365, the app generates a **Legacy Profile** — a comprehensive summary and identity system:

**Components:**

| Component | Description |
|-----------|-------------|
| Year One Badge | Permanently displayed, premium visual treatment |
| Journey Summary | Total habits completed, XP earned, longest streak, stats evolution |
| Stats Timeline | Graph showing all stats from Day 1 to Day 365 |
| Legacy Title | User-written custom title (up to 30 chars) |
| Time Capsule | Write a message to future self, delivered at Day 730 |
| Shareable Infographic | Auto-generated image summarizing the year |

**Legacy Title:**
- Free-form text the user writes themselves
- Displayed under username on profile and Discipline Card
- Examples: "The Patient Storm", "Iron Will", "Forged in Silence"
- Moderation: Client-side profanity filter (no server round-trip needed for most cases)
- Can be changed once per month

**Time Capsule:**
- Write a message (up to 500 characters) to your Day 730 self
- Sealed immediately — cannot be read or edited after submission
- Delivered as a push notification + in-app modal on Day 730
- If user is still active at Day 730: emotional retention anchor
- If user has churned: re-engagement hook via push notification

**Shareable Infographic:**
- Auto-generated image (rendered client-side with SwiftUI → UIImage)
- Contains: username, legacy title, top stats, total XP, year badge, key milestones
- Formatted for Instagram Stories (9:16) and Twitter/X (16:9)
- "Share Your Legacy" button generates and presents share sheet

### User Flow

```
1. User reaches Day 365
2. Special app open: "Legacy" full-screen celebration
   - Cinematic animation: forge transforms into something greater
   - "One year. 365 days of discipline. Your legacy is written."
3. Journey Summary auto-displays:
   - Scrolling stats: "You completed 1,247 habits. Earned 18,430 XP."
   - Stats graph: animated line chart showing growth over time
   - Top achievements highlighted
4. Legacy Title prompt:
   "Name your legacy. What title will you carry?"
   [Text field, 30 char limit]
   [Set Title] / [Skip for now]
5. Time Capsule prompt:
   "Write a message to the warrior you'll be in one year."
   [Text area, 500 char limit]
   [Seal Capsule] / [Skip]
6. Year One badge added to profile permanently
7. "Share Your Legacy" → generates infographic → share sheet
8. Return to normal app use with legacy title displayed
```

**Day 730 (Year Two):**
```
1. Push notification: "A message from your past self awaits."
2. App open: Time capsule reveal animation
3. Message displayed with original date
4. Prompt: "Write a new capsule for Year Three?"
5. Year Two badge awarded
```

### Implementation

**Data model:**

```sql
CREATE TABLE legacy_milestones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) NOT NULL,
    milestone_type TEXT NOT NULL,  -- 'year_one', 'year_two', 'year_three'
    achieved_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    legacy_title TEXT,  -- user-written title
    legacy_title_updated_at TIMESTAMPTZ,
    time_capsule_message TEXT,  -- encrypted at rest
    time_capsule_sealed_at TIMESTAMPTZ,
    time_capsule_delivered_at TIMESTAMPTZ,
    time_capsule_delivery_date DATE,  -- when to deliver
    stats_snapshot JSONB NOT NULL,  -- full stats at milestone
    journey_summary JSONB NOT NULL,  -- aggregated metrics
    UNIQUE(user_id, milestone_type)
);

-- Add to profiles
ALTER TABLE profiles ADD COLUMN legacy_title TEXT;
```

**Journey summary aggregation:**

```swift
// LegacyService.swift
final class LegacyService {

    struct JourneySummary: Codable {
        let totalHabitsCompleted: Int
        let totalXPEarned: Int
        let longestStreak: Int
        let totalActiveDays: Int
        let topStat: (name: String, value: Int)
        let habitsAtLegendary: Int
        let chaptersCompleted: Int
        let prestigeLevel: Int
        let eventsCompleted: Int
        let statsTimeline: [(date: Date, stats: [String: Int])]
    }

    func generateSummary(userId: UUID) async throws -> JourneySummary {
        // Aggregate from:
        // - habit_completions (count, group by date)
        // - daily_logs (active days, XP sum)
        // - profiles (stats, streak records)
        // - chapters (completed count)
        // - prestige_records (level)
        // - event_participations (completed count)
        // - weekly stats snapshots (for timeline graph)
    }

    func generateInfographic(summary: JourneySummary, profile: Profile) -> UIImage {
        // Render SwiftUI view to image
        // Layout: profile header, stats ring, key metrics, badge
        // Output formats: 9:16 (stories), 16:9 (feed)
    }

    func sealTimeCapsule(userId: UUID, message: String, deliveryDate: Date) async throws {
        // Store encrypted message with delivery date
        // Schedule push notification for delivery date
    }

    func deliverTimeCapsule(userId: UUID) async throws -> String? {
        // Check if delivery date has passed
        // Return decrypted message
        // Mark as delivered
    }
}
```

**Stats timeline data source:**

```sql
-- Weekly stats snapshots (populated by background job or on each Sunday)
CREATE TABLE stats_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) NOT NULL,
    snapshot_date DATE NOT NULL,
    stats JSONB NOT NULL,
    level INT NOT NULL,
    xp_total INT NOT NULL,
    UNIQUE(user_id, snapshot_date)
);
```

**Infographic rendering (client-side):**

```swift
// LegacyInfographicView.swift
struct LegacyInfographicView: View {
    let summary: LegacyService.JourneySummary
    let profile: Profile

    var body: some View {
        VStack(spacing: 20) {
            // Profile avatar + legacy title
            // "Year One" badge (large, centered)
            // Key stats in grid
            // Mini stats graph
            // Forge branding footer
        }
    }

    func renderToImage(size: CGSize) -> UIImage {
        let renderer = ImageRenderer(content: self.frame(width: size.width, height: size.height))
        renderer.scale = 3.0  // @3x for quality
        return renderer.uiImage ?? UIImage()
    }
}
```

### Economy Impact

| Metric | Impact | Notes |
|--------|--------|-------|
| XP | None | Legacy is recognition, not XP source |
| Tokens | None | No token reward (badge is the reward) |
| Titles | +1 custom per user | User-written, not system-generated |
| Badges | +1 per year | Year One, Year Two, etc. |
| Retention hook | High | Time capsule creates future appointment |
| Re-engagement | High | Day 730 push notification for churned users |

Legacy is **economy-neutral** — it's pure identity and emotion. No XP, no tokens, no mechanical advantage. The reward is meaning itself.

### Acceptance Criteria

- [ ] Legacy celebration triggers on Day 365 (first app open on/after that day)
- [ ] Journey summary accurately aggregates all lifetime metrics
- [ ] Stats timeline graph renders with weekly data points over 52 weeks
- [ ] Legacy title accepts 1-30 characters, rejects profanity (client-side filter)
- [ ] Legacy title displays on profile and Discipline Card
- [ ] Legacy title can be changed once per month
- [ ] Time capsule accepts up to 500 characters
- [ ] Time capsule is sealed (cannot be read/edited after submission)
- [ ] Time capsule delivery notification fires on Day 730
- [ ] Time capsule message is encrypted at rest in database
- [ ] Shareable infographic generates in both 9:16 and 16:9 formats
- [ ] Infographic renders in < 2 seconds on iPhone 12 or newer
- [ ] Share sheet correctly presents image to Instagram, Twitter, Messages
- [ ] Year One badge permanently displays on profile
- [ ] Year Two (Day 730) follows same flow with new badge + capsule delivery
- [ ] Legacy flow handles edge cases: user has no completions in some weeks, prestige resets mid-year
- [ ] `stats_snapshots` populated weekly without user action (background job or on-login check)

---

## Unified XP Formula (All Systems Combined)

With all endgame systems active, the XP formula becomes:

```
final_xp = floor(
    (base_habit_xp + habit_level_bonus)
    * mastery_focus_multiplier
    * (1.0 + prestige_bonus + seasonal_arc_bonus + perk_bonus)
    * crit_multiplier
)
```

**Worked example — maximum possible single-habit XP:**

```
Base XP:                    10
Habit Level 6 bonus:        +5  → 15
Mastery Focus (1.5x):       × 1.5 → 22 (floored)
Prestige 5 (+20%):          × 1.20
Seasonal Arc (+20%):        × (additive, so total multiplier = 1.40) → 30 (floored)
Perk bonus (+10% assumed):  × (additive, so total = 1.50) → 33 (floored)
Critical Hit (3x):          × 3.0 → 99
```

**Maximum single-completion XP: 99 XP** (requires Level 6 habit + mastery focus + prestige 5 + seasonal arc + active perk + perfect crit roll)

**Realistic veteran daily XP (5 habits, no crits):**
- Base: 5 × 10 = 50
- Habit levels (avg L4): 5 × 13 = 65
- Mastery focus on 1 habit: 65 + (13 × 0.5) = 71
- Prestige 2 (+10%): 71 × 1.10 = 78
- Total: ~78 XP/day vs. newcomer's ~50 XP/day

This 56% increase is appropriate for a veteran who has invested hundreds of hours — it accelerates leveling without breaking early-game balance.

---

## Content Pacing Deep Dive

### The Overwhelm Problem

The #1 killer of endgame systems is overwhelming users with too many things at once. A user who sees Chapters + Prestige + Mastery Mode + Seasonal Events + Monthly Habits all on Day 91 will:
1. Feel the app became "complicated"
2. Suffer decision paralysis
3. Disengage from ALL systems (paradox of choice)

### Pacing Rules

**Rule 1: One revelation per week, maximum.**

After Day 90 challenge completion, new systems are revealed on this schedule:

| Week | Revelation | Trigger |
|------|-----------|---------|
| Week 1 (Day 91-97) | Chapter 2 introduction | Auto (24hr after challenge complete) |
| Week 2 (Day 98-104) | Habit Leveling visibility | First habit reaches Level 2 |
| Week 3 (Day 105-111) | Monthly Habit Injection | 1st of next month (if Level 5+) |
| Week 4+ | Mastery Mode | Level 15 reached (organic) |
| Ongoing | Seasonal Events | Quarterly (passive discovery) |
| Chapter 2+ complete | Prestige | Organic unlocked |
| Day 365 | Legacy | Calendar milestone |

**Rule 2: Passive systems don't need introduction.**

- Habit Leveling is visible the moment a habit crosses Level 2 — no modal needed, just a star appearing
- Seasonal events are announced via banner — no tutorial modal
- Only Chapter start and Mastery Mode get full discovery modals

**Rule 3: Tooltips over tutorials.**

Systems that are locked show a single line:
- "Mastery Mode • Unlocks at Level 15"
- "Prestige • Complete Chapter 2 to unlock"

No extended explanation until the user is ready to engage.

**Rule 4: Veterans self-discover.**

Power users don't need hand-holding. After the first Chapter 2 modal, subsequent chapters begin with a brief banner, not a full-screen modal. Prestige is discoverable in Profile settings, not pushed via notification.

### Engagement Cadence by User Type

| User Type | Daily Loops | Weekly Loops | Monthly Loops | Quarterly Loops |
|-----------|------------|-------------|--------------|----------------|
| Casual (Day 91-180) | Habits + Chapter progress | Review habit levels | New habit browse | Seasonal event |
| Committed (Day 181-365) | Habits + Mastery tracking | Milestone progress | Habit injection + review | Event + arc |
| Power (Day 365+) | Habits + Legacy title showing | Everything above + stats deep dive | Title refinement | Event + prestige decision |
| Prestige (Rebirthed) | Fresh 90-day loop with bonuses | Nostalgia (seeing leveled habits) | Fast progression tracking | All of the above |

### Content Sustainability

| System | Requires Manual Content? | Frequency | Effort |
|--------|--------------------------|-----------|--------|
| Chapters | No | Never (objective-based) | Zero after launch |
| Prestige | No | Never (algorithmic) | Zero after launch |
| Habit Leveling | No | Never (computed) | Zero after launch |
| Monthly Habits | Yes | Monthly | Low (2-3 habit names + descriptions) |
| Mastery Mode | No | Never (analytics-based) | Zero after launch |
| Seasonal Events | Yes | Quarterly | Medium (objectives + rewards config) |
| Legacy | No | Annual (auto-generated) | Zero after launch |

**5 of 7 systems require zero ongoing content creation.** Only Monthly Habits (trivial effort) and Seasonal Events (moderate effort, quarterly) need maintenance.

---

## Implementation Priority

| Priority | System | Effort | Impact | Dependencies |
|----------|--------|--------|--------|-------------|
| P0 | Post-90 Chapters | Medium | Critical | Challenge completion detection |
| P1 | Habit Leveling | Low | High | habit_completions count query |
| P2 | Seasonal Events | Medium | High | SeasonalArcService extension |
| P3 | Mastery Mode | Medium | Medium | MasteryPathService extension |
| P4 | Monthly Habit Injection | Low | Medium | habit_presets table + content pipeline |
| P5 | Prestige / Rebirth | High | Medium | All profile reset logic, economy rebalance |
| P6 | Legacy System | Medium | Medium | stats_snapshots, infographic rendering |

**Recommended rollout:**
1. **v2.0** (Day 91 problem): Chapters + Habit Leveling
2. **v2.1** (90 days later): Seasonal Events + Mastery Mode
3. **v2.2** (30 days later): Monthly Habit Injection
4. **v3.0** (major release): Prestige System
5. **v3.1** (Year One approaching): Legacy System

---

## Cross-System Interactions Matrix

| System A | System B | Interaction |
|----------|----------|-------------|
| Chapters | Prestige | Prestige resets chapter progress |
| Habit Leveling | Prestige | Habit levels NOT reset (intentional) |
| Habit Leveling | Mastery Mode | Level bonus applied before mastery multiplier |
| Mastery Mode | Prestige | Mastery focus resets (must re-select) |
| Seasonal Events | All | Events independent of all other systems |
| Monthly Injection | Habit Leveling | New habits start at Level 1 (0 completions) |
| Legacy | Prestige | Legacy summary includes prestige count |
| Legacy | Chapters | Legacy summary includes chapters completed |

---

## Open Questions

1. **Chapter timer strictness:** Should chapters have any consequence for exceeding 90 days? Current design says no — validate with user research.
2. **Prestige and social:** Should prestige stars be visible to other users (leaderboards, shared cards)? Could create unhealthy comparison.
3. **Habit level reset on name change:** If a user edits a habit's name, does the completion count persist? Recommendation: yes (keyed by original habit_id, not name).
4. **Event difficulty fairness:** Should Level 5 users and Level 25 users compete in the same event pool? Current design tiers them separately.
5. **Legacy title moderation:** Client-side profanity filter may not catch creative circumvention. Is server-side moderation needed at scale?
6. **Time capsule privacy:** Should time capsule messages be end-to-end encrypted (user-held key) or server-encrypted (we can read if legally required)?

---

*Last updated: 2026-07-03*
