# SPEC: Intelligence & Personalization Layer

**Status:** Draft  
**Created:** 2026-07-03  
**Scope:** Adaptive systems that learn from user behavior and personalize the RNF experience  
**Principle:** All intelligence serves the user. No dark patterns. Suggestions, never coercion.

---

## Overview

The intelligence layer transforms RNF from a static habit tracker into an adaptive system that learns each user's patterns and responds accordingly. Six interconnected systems form this layer:

1. Adaptive Notification Timing
2. Dynamic Daily Goal
3. Behavioral Insights (Weekly)
4. Churn Prediction State Machine
5. Quest Personalization
6. Habit Difficulty Profiling

All systems share a common philosophy: **observe → compute → suggest → respect the user's response.**

---

## 1. Adaptive Notification Timing

### Problem

Fixed notification times (user-set during onboarding) don't match actual behavior patterns. A user who set "8:00 AM" but consistently completes habits at 7:15 AM receives a notification after they've already acted. A user whose schedule shifts seasonally gets stuck with a stale reminder time.

### Data Required

| Field | Source | Retention |
|-------|--------|-----------|
| `habit_id` | Local DB | Permanent |
| `completion_timestamp` | Local DB | 90 days rolling |
| `day_of_week` | Derived | Computed |
| `is_weekend` | Derived | Computed |

Minimum data threshold: **14 days** of completion timestamps before adaptive timing activates.

### Algorithm

```
1. Partition completion_timestamps by:
   - Weekday (Mon-Fri)
   - Weekend (Sat-Sun)

2. For each partition:
   a. Calculate median completion time
   b. adaptive_notification_time = median - 5 minutes
      (Prime the user just before their natural action time)

3. Drift detection (runs weekly):
   a. Compare current 7-day median to previous 7-day median
   b. If |delta| >= 30 minutes → re-adapt immediately
   c. If |delta| < 30 minutes → maintain current schedule

4. Outlier filtering:
   a. Discard completions between 00:00-04:00 (likely previous-day catch-ups)
   b. Require minimum 5 data points per partition before computing
```

### Implementation

| Component | Responsibility |
|-----------|---------------|
| `CompletionTimeAggregator` | Queries local DB for timestamps, computes medians |
| `NotificationScheduler` | Reads adaptive time; falls back to user-set time if < 14 days data |
| `AdaptiveTimingModel` | Stores weekday/weekend medians + last drift check date |

**Flow:**
```
App foreground → CompletionTimeAggregator.recompute(if stale)
                 → AdaptiveTimingModel.update()
                 → NotificationScheduler.reschedule()
```

**Fallback hierarchy:**
1. Adaptive time (if 14+ days data)
2. User-set time (always available)
3. Default 8:00 AM (if user never set a time)

### Privacy Considerations

- All computation runs **locally on-device**.
- No completion timestamps are transmitted to Supabase or any third party.
- The `AdaptiveTimingModel` is stored in local-only storage (not synced).
- User can disable adaptive timing in Settings → Notifications → "Smart Timing" toggle.

---

## 2. Dynamic Daily Goal

### Problem

The app presents the same daily habit count goal regardless of performance. A user completing 100% for 30 straight days receives no encouragement to grow. A user struggling at 40% completion receives no relief. One-size-fits-all goals lead to either boredom or overwhelm.

### Data Required

| Field | Source | Retention |
|-------|--------|-----------|
| `daily_completion_rate` | Local DB | 30 days rolling |
| `consecutive_days_above_threshold` | Computed | Real-time |
| `consecutive_days_below_threshold` | Computed | Real-time |
| `current_daily_goal` | User profile | Permanent |
| `difficulty_adjustments` | Local DB | Permanent (audit trail) |

### Algorithm

```
ON app_foreground:

1. Compute trailing_7day_rate = completions / (active_habits × 7)

2. INCREASE suggestion:
   IF trailing_7day_rate > 0.90 for 7 CONSECUTIVE days
   AND current_daily_goal < 6
   AND account_age >= 14 days
   THEN suggest_increase()
   
   Message: "The Forge sees your strength. Ready for more?"
   Action: Add 1 to daily goal (user confirms)

3. DECREASE suggestion:
   IF trailing_7day_rate < 0.50 for 3 CONSECUTIVE days
   AND current_daily_goal > 2
   AND account_age >= 7 days
   THEN suggest_decrease()
   
   Message: "Quality over quantity. Master these first."
   Action: Remove 1 from daily goal (user confirms)

4. BOUNDARIES:
   - Minimum daily goal: 2
   - Maximum daily goal: 6
   - Cooldown: No re-suggestion for 7 days after user dismisses

5. OVERRIDE:
   - User can always manually set goal in Settings
   - Manual override resets suggestion cooldown
```

### Implementation

| Component | Responsibility |
|-----------|---------------|
| `DifficultyAdvisor` | Core service. Evaluates rules on app foreground |
| `SuggestionBanner` | SwiftUI view component for increase/decrease prompts |
| `difficulty_adjustments` table | Logs all suggestions + user responses |

**Schema — `difficulty_adjustments`:**
```sql
CREATE TABLE difficulty_adjustments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  suggested_at TIMESTAMPTZ NOT NULL,
  direction TEXT CHECK (direction IN ('increase', 'decrease')),
  from_goal INT NOT NULL,
  to_goal INT NOT NULL,
  user_response TEXT CHECK (user_response IN ('accepted', 'dismissed', 'pending')),
  responded_at TIMESTAMPTZ
);
```

### Edge Cases

- Don't suggest **increase** during first 14 days (let habits solidify).
- Don't suggest **decrease** during first 7 days (give user time to adjust).
- If user has exactly 2 habits and is struggling, show encouragement instead of decrease.
- If user manually added a habit today, suppress increase suggestion for 48 hours.

### Privacy Considerations

- Suggestion logic runs locally.
- `difficulty_adjustments` table syncs to Supabase for historical tracking (user's own data, RLS-protected).
- No aggregate data shared across users.

---

## 3. Behavioral Insights (Weekly)

### Problem

Users complete habits daily but never receive data-driven observations about their own patterns. The app collects rich behavioral data but doesn't reflect it back in a meaningful way. Users who understand their patterns make better decisions about habit design.

### Data Required

| Field | Source | Window |
|-------|--------|--------|
| Completion records (habit, date, time) | Local DB / Supabase | 28 days |
| Stat growth per category | Supabase | 28 days |
| Streak history | Local DB | 28 days |
| Habit ordering on completion days | Derived | 28 days |

### Insight Catalog

| Insight Type | Template | Trigger Condition |
|-------------|----------|-------------------|
| Best day | "You never miss habits on {day}s" | One day has ≥90% completion rate AND ≥20% higher than average |
| Worst day | "{day}s are your hardest day — {rate}% completion" | One day has ≤50% completion AND ≥20% lower than average |
| Streak correlation | "Your streak grows fastest when you complete {habit} first" | Statistically significant ordering correlation (p < 0.05) |
| Time pattern | "Morning completions are {multiplier}x more likely to result in a full day" | AM vs PM completion correlation with daily success |
| Stat focus | "Your {stat} stat grew {percent}% this month — that's your strongest pillar" | One stat grew ≥30% more than others |
| Consistency | "You've completed {habit} {count} days straight — your most reliable habit" | Single habit streak ≥ 14 days |

### Algorithm

```
RUN weekly (Sunday 18:00 local time):

1. Query 28-day completion dataset

2. For each insight type:
   a. Compute the relevant metric
   b. Calculate statistical significance / variance
   c. Score = significance × novelty_factor
      - novelty_factor = 1.0 if never shown before
      - novelty_factor = 0.3 if shown in last 4 weeks
      - novelty_factor = 0.0 if shown last week (suppress)

3. Rank all candidate insights by score

4. Select top 2 insights WHERE score > minimum_threshold (0.4)

5. If < 2 insights meet threshold:
   - Fill remaining slots with motivational stat (e.g., total XP earned this week)

6. Minimum variance threshold:
   - Day-of-week insight requires ≥15% variance between best and worst day
   - Time pattern requires ≥25% difference between AM/PM outcomes
   - Avoids surfacing obvious or noise-level observations
```

### Implementation

| Component | Responsibility |
|-----------|---------------|
| `InsightEngine` | Core analysis service. Runs Sunday evening |
| `InsightGenerator` (protocol) | Per-insight-type computation modules |
| `weekly_insights` table | Persists generated insights |
| `WeeklyReportView` | SwiftUI display in weekly summary screen |

**Schema — `weekly_insights`:**
```sql
CREATE TABLE weekly_insights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  week_start DATE NOT NULL,
  insight_type TEXT NOT NULL,
  insight_text TEXT NOT NULL,
  metric_value DOUBLE PRECISION,
  significance_score DOUBLE PRECISION,
  generated_at TIMESTAMPTZ DEFAULT now(),
  viewed_at TIMESTAMPTZ,
  UNIQUE(user_id, week_start, insight_type)
);
```

**Trigger:** Background task scheduled via `BGAppRefreshTask` on Sunday 18:00. If app isn't opened, compute on next foreground after Sunday.

### Privacy Considerations

- All analysis runs **on-device** or via Supabase RLS-protected query (user's own data only).
- Insights are stored per-user; no cross-user analysis.
- No behavioral data leaves the device except what's already synced to the user's own Supabase row.
- User can disable insights in Settings → Intelligence → "Weekly Insights" toggle.

---

## 4. Churn Prediction State Machine

### Problem

Users drift away gradually — from daily use, to sporadic, to gone. The app currently doesn't intervene until it's too late. A state machine allows proportional, respectful re-engagement that escalates slowly and stops before becoming annoying.

### State Definitions

| State | Entry Condition | Duration |
|-------|----------------|----------|
| `ENGAGED` | Opens daily AND completes ≥50% habits | Ongoing |
| `AT_RISK` | Opens but completes 0 habits for 2 days, OR doesn't open for 1 day | 1-2 days |
| `DRIFTING` | Doesn't open for 2-3 days | 2-3 days |
| `LAPSED` | Doesn't open for 4-7 days | 4-7 days |
| `CHURNED` | Doesn't open for 7+ days | Indefinite |

### State Transition Diagram

```
                    ┌──────────────────────────────────────────┐
                    │          (any state)                      │
                    │              │                            │
                    │              ▼                            │
                    │         ENGAGED ◄────────────────────────┤
                    │           │                               │
                    │           ▼                               │
                    │        AT_RISK                            │
                    │           │                    (return    │
                    │           ▼                     from      │
                    │       DRIFTING               DRIFTING+)   │
                    │           │                               │
                    │           ▼                               │
                    │        LAPSED                             │
                    │           │                               │
                    │           ▼                               │
                    │        CHURNED ──── (no more pushes) ────┘
                    └──────────────────────────────────────────┘
```

### Transition Actions

| Transition | Action | Channel |
|-----------|--------|---------|
| ENGAGED → AT_RISK | "Just do one" banner. Soften daily goal display. | In-app |
| AT_RISK → DRIFTING | Push: streak-at-risk warning | Push notification |
| DRIFTING → LAPSED | Push: "The forge grows cold. One spark brings it back." | Push notification |
| LAPSED → CHURNED | Final push (1 only): "Your journey isn't over. Tap to return." | Push notification |
| CHURNED → (silence) | No more pushes. Respect the user's choice. | None |
| Any → ENGAGED (from DRIFTING+) | Welcome-back flow. Celebrate return. Reset state. | In-app |

### Algorithm

```
CLIENT-SIDE (on app foreground):
1. Read last_engagement_state from UserDefaults
2. Compute current state based on:
   - last_open_date
   - recent_completion_count
3. If state changed → trigger transition action
4. Store new state + transition timestamp

SERVER-SIDE (Supabase edge function, daily 09:00 UTC):
1. Query all users WHERE engagement_state != 'CHURNED'
2. For each user:
   a. Calculate days_since_last_activity
   b. Determine if state transition needed
   c. If push notification warranted → enqueue via push service
3. Update engagement_state in user profile
```

### Implementation

| Component | Responsibility |
|-----------|---------------|
| `EngagementStateManager` | Client-side state evaluation + in-app actions |
| `engagement_state` (UserDefaults) | Fast local state for UI decisions |
| `user_engagement` (Supabase) | Server-side state for push scheduling |
| Supabase Edge Function: `check-engagement` | Daily batch job for server-side transitions |

**Schema — `user_engagement`:**
```sql
CREATE TABLE user_engagement (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  current_state TEXT NOT NULL DEFAULT 'ENGAGED',
  state_entered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_activity_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  pushes_sent_30d INT NOT NULL DEFAULT 0,
  last_push_sent_at TIMESTAMPTZ
);
```

### Safeguards

- **Maximum 5 re-engagement pushes per 30-day rolling window.** Never spam.
- **No push after CHURNED.** The user has chosen to leave. One final message only.
- **Welcome-back flow** acknowledges absence without guilt: "Welcome back, Forgekeeper. The flame awaits."
- **User override:** Settings → Notifications → "Re-engagement reminders" toggle.
- **Cool-down:** Minimum 48 hours between consecutive push notifications.

### Privacy Considerations

- Engagement state synced to Supabase (needed for server-side push scheduling).
- No behavioral data shared with third-party push services — only the notification payload.
- Push token stored server-side (standard iOS push architecture).
- User can opt out of all re-engagement pushes independently of habit reminders.

---

## 5. Quest Personalization

### Problem

The current quest generator (`QuestGenerator.selectQuestForWeakestStat`) targets the user's weakest stat exclusively. This ignores:
- User preferences (some quest types are consistently skipped)
- Time-of-day compatibility (suggesting evening quests in the morning)
- Fatigue from repetitive quest types

### Data Required

| Field | Source | Window |
|-------|--------|--------|
| Quest completions per type | Local DB | 30 days |
| Quest skips/dismissals per type | Local DB | 30 days |
| Quest completion timestamps | Local DB | 14 days |
| Consecutive same-type quest days | Derived | 7 days |
| Stat weakness scores | Existing stat system | Current |

### Algorithm

```
SCORING MODEL (per candidate quest):

score = (stat_weakness × 0.50)
      + (preference × 0.30)
      + (freshness × 0.20)

WHERE:

stat_weakness (0.0 - 1.0):
  = 1.0 - (stat_value / max_stat_value)
  Normalized so weakest stat = 1.0, strongest = 0.0

preference (0.0 - 1.0):
  = completion_rate for this quest_type over 30 days
  If quest_type never seen → 0.5 (neutral)
  If quest_type always skipped → 0.1 (low but not zero, allow retry)

freshness (0.0 - 1.0):
  = 1.0 if quest_type not seen in 3+ days
  = 0.5 if quest_type seen yesterday
  = 0.0 if quest_type seen today or 3 consecutive days
  
FATIGUE OVERRIDE:
  IF same quest_type appeared 3 days in a row
  THEN set freshness = 0.0 for that type (forces rotation)

TIME BIAS (optional multiplier):
  IF current_hour < 12 AND quest requires evening context
  THEN score × 0.7
  IF current_hour < 12 AND quest is morning-compatible
  THEN score × 1.2
```

### Implementation

| Component | Responsibility |
|-----------|---------------|
| `QuestGenerator.selectQuestForWeakestStat` | Enhanced to accept history parameters |
| `QuestPreferenceTracker` | Tracks completions/skips per quest type |
| `QuestFatigueDetector` | Monitors consecutive same-type days |

**Enhanced function signature:**
```swift
func selectPersonalizedQuest(
    stats: UserStats,
    questHistory: [QuestRecord],       // Last 30 days
    completionPreferences: QuestPreferences,  // Aggregated rates
    currentHour: Int
) -> Quest
```

**Migration path:** Existing `selectQuestForWeakestStat` remains as fallback. New method used when `questHistory` has ≥ 7 days of data.

### Privacy Considerations

- Quest preference data stored locally.
- No quest behavior data shared externally.
- Quest personalization is entirely on-device computation.

---

## 6. Habit Difficulty Profiling

### Problem

All habits are treated as equally difficult. In reality, "Read 10 pages" and "30-minute HIIT workout" have vastly different completion rates for each user. Treating them equally leads to unfair XP distribution and suboptimal goal ordering.

### Data Required

| Field | Source | Window |
|-------|--------|--------|
| Per-habit completion count | Local DB | 30 days |
| Per-habit possible days | Derived (days since habit created, max 30) | 30 days |
| Completion rate per habit | Computed | 30 days rolling |

### Classification

| Difficulty | Completion Rate | Meaning |
|-----------|----------------|---------|
| Easy | > 90% | User completes almost automatically |
| Moderate | 60% - 90% | Requires effort but achievable |
| Hard | < 60% | Significant barrier to completion |

### Algorithm

```
RUN weekly (computed alongside InsightEngine):

FOR each active habit:
  1. rate = completions_30d / possible_days_30d
  2. Classify:
     - rate > 0.90 → EASY
     - 0.60 ≤ rate ≤ 0.90 → MODERATE  
     - rate < 0.60 → HARD
  3. Store difficulty_rating on habit model

STABILITY RULE:
  - Don't reclassify unless rating would change by ≥1 tier
  - Require ≥7 days of data before first classification
  - New habits default to MODERATE until classified
```

### Usage

| Application | Behavior |
|------------|----------|
| **Daily goal ordering** | User setting: "Hardest first" (eat the frog) or "Easiest first" (build momentum) |
| **XP adjustment** | Hard habits: +3 bonus XP. Moderate: +1 bonus XP. Easy: base XP only. |
| **Insights** | "Your hardest habit is [X] at 45% completion. Consider breaking it into smaller steps." |
| **DifficultyAdvisor integration** | When suggesting goal decrease, prefer removing the hardest habit from required set |

### Implementation

| Component | Responsibility |
|-----------|---------------|
| `HabitDifficultyProfiler` | Weekly computation service |
| `difficulty_rating` field | Added to Habit model (enum: easy, moderate, hard) |
| `HabitOrderingStrategy` | Reads difficulty + user preference to sort daily view |

**Model addition:**
```swift
enum HabitDifficulty: String, Codable {
    case easy
    case moderate
    case hard
    
    var bonusXP: Int {
        switch self {
        case .easy: return 0
        case .moderate: return 1
        case .hard: return 3
        }
    }
}
```

### Privacy Considerations

- Difficulty profiling is entirely local computation.
- Difficulty ratings stored on local habit model (synced to Supabase as part of habit data, user-owned).
- No cross-user difficulty benchmarking.

---

## Data Architecture

### Computation Location Summary

| System | Local (On-Device) | Supabase (Server) | Edge Function |
|--------|:-----------------:|:-----------------:|:-------------:|
| Adaptive Notification Timing | ✅ All computation | ❌ | ❌ |
| Dynamic Daily Goal | ✅ Rule evaluation | ✅ `difficulty_adjustments` storage | ❌ |
| Behavioral Insights | ✅ Primary analysis | ✅ `weekly_insights` storage | ❌ |
| Churn Prediction | ✅ Client-side state | ✅ `user_engagement` state | ✅ Daily batch check + push |
| Quest Personalization | ✅ All computation | ❌ | ❌ |
| Habit Difficulty Profiling | ✅ All computation | ✅ `difficulty_rating` on habit | ❌ |

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        ON-DEVICE (Swift)                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐   ┌──────────────────┐   ┌────────────┐  │
│  │ CompletionTime  │   │ DifficultyAdvisor│   │InsightEngine│  │
│  │  Aggregator     │   │                  │   │            │  │
│  └────────┬────────┘   └────────┬─────────┘   └──────┬─────┘  │
│           │                      │                     │        │
│  ┌────────┴────────┐   ┌────────┴─────────┐   ┌──────┴─────┐  │
│  │ Notification    │   │ SuggestionBanner │   │WeeklyReport│  │
│  │  Scheduler      │   │                  │   │   View     │  │
│  └─────────────────┘   └──────────────────┘   └────────────┘  │
│                                                                 │
│  ┌─────────────────┐   ┌──────────────────┐                   │
│  │ EngagementState │   │  QuestGenerator  │                   │
│  │   Manager       │   │ (Personalized)   │                   │
│  └────────┬────────┘   └──────────────────┘                   │
│           │                                                     │
│  ┌────────┴────────┐   ┌──────────────────┐                   │
│  │ UserDefaults    │   │HabitDifficulty   │                   │
│  │ (local state)   │   │  Profiler        │                   │
│  └────────┬────────┘   └──────────────────┘                   │
│           │                                                     │
└───────────┼─────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     SUPABASE (Server-side)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Tables:                                                        │
│  ├── difficulty_adjustments (goal change log)                   │
│  ├── weekly_insights (generated insights)                       │
│  ├── user_engagement (churn state + push tracking)              │
│  └── habits.difficulty_rating (profiled difficulty)             │
│                                                                 │
│  Edge Functions:                                                │
│  └── check-engagement (daily cron: state transitions + push)   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Storage Ownership

All intelligence data is **owned by the user** and protected by Supabase Row-Level Security:

```sql
-- All intelligence tables follow this RLS pattern:
ALTER TABLE weekly_insights ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can only access own insights"
  ON weekly_insights FOR ALL
  USING (auth.uid() = user_id);
```

### Data Retention

| Data Type | Retention | Reason |
|-----------|-----------|--------|
| Completion timestamps (local) | 90 days rolling | Sufficient for all algorithms |
| Difficulty adjustments | Permanent | Audit trail for goal changes |
| Weekly insights | 1 year | Allow year-over-year comparison |
| Engagement state | Current only | Only latest state matters |
| Quest preference history | 30 days rolling | Preference window |
| Habit difficulty rating | Current only | Recomputed weekly |

---

## Cross-System Integration

### Dependency Graph

```
HabitDifficultyProfiler
    ├── feeds → DifficultyAdvisor (knows which habits are hard)
    ├── feeds → InsightEngine (difficulty-based insights)
    └── feeds → QuestGenerator (difficulty-aware quest selection)

InsightEngine
    ├── reads ← CompletionTimeAggregator (time patterns)
    ├── reads ← HabitDifficultyProfiler (difficulty insights)
    └── reads ← EngagementStateManager (streak data)

DifficultyAdvisor
    ├── reads ← HabitDifficultyProfiler (suggest removing hardest habit)
    └── triggers → SuggestionBanner

EngagementStateManager
    └── triggers → DifficultyAdvisor (softer goals when AT_RISK)
```

### Execution Schedule

| System | Trigger | Frequency |
|--------|---------|-----------|
| Adaptive Notification Timing | App foreground (if stale > 24h) | Daily max |
| Dynamic Daily Goal | App foreground | Every foreground |
| Behavioral Insights | Background task | Weekly (Sunday 18:00) |
| Churn Prediction (client) | App foreground | Every foreground |
| Churn Prediction (server) | Edge function cron | Daily (09:00 UTC) |
| Quest Personalization | Quest generation time | On-demand |
| Habit Difficulty Profiling | Background task | Weekly (with InsightEngine) |

---

## Implementation Priority

| Phase | Systems | Prerequisite |
|-------|---------|-------------|
| Phase 1 | Churn Prediction, Habit Difficulty Profiling | Core habit tracking complete |
| Phase 2 | Dynamic Daily Goal, Adaptive Notification Timing | 14+ days user data |
| Phase 3 | Behavioral Insights, Quest Personalization | Insight UI + Quest system complete |

---

## Open Questions

1. Should adaptive timing account for timezone changes (travel)?
2. Should the DifficultyAdvisor consider external calendar integration (busy weeks)?
3. Should weekly insights be push-notified or only visible in-app?
4. Should churned users receive a monthly "state of your forge" email (requires email infrastructure)?
5. Should difficulty profiling factor in habit frequency (daily vs 3x/week habits)?
