# SPEC: Psychological Retention Mechanics

**Status:** Draft
**Created:** 2026-07-03
**Domain:** Engagement & Retention
**References:** Duolingo retention model, Nir Eyal's Hook Model, B.F. Skinner operant conditioning, Kahneman loss aversion research

---

## Overview

This specification defines seven psychological retention mechanics designed to maximize daily return rate and long-term engagement. Each mechanic is borrowed from best-in-class consumer apps and grounded in behavioral psychology research.

Design philosophy:
- **Ethical engagement** — no dark patterns that cause financial harm or addiction-related distress
- **Earn-only economy** — no real-money purchases for gameplay advantages
- **Transparent systems** — users can understand why they received a reward
- **Opt-out friendly** — social features can be disabled without penalty

---

## 1. Variable Ratio Rewards (Critical Hits)

### Problem

Fixed +10 XP per habit completion is a **fixed ratio** reward schedule — the least engaging schedule in operant conditioning research. Users quickly habituate to predictable rewards, reducing the dopamine response over time.

### Psychology Principle

**Variable ratio reinforcement** (Skinner, 1957). Slot machines, loot boxes, and Duolingo's "double or nothing" all exploit this: when reward magnitude is unpredictable, engagement per action increases because each attempt *might* be the big one.

### Design

- 1 in 5 habit completions randomly awards **2x–3x XP** (a "Critical Hit")
- Visual: Gold flash overlay, subtle screen shake, distinct haptic burst, "+30 XP" floating text
- Audio: Metallic anvil strike sound (on-brand with forge theme)
- Streak tier scaling increases crit chance:
  - Base: 20%
  - Ember (+5%): 25%
  - Flame (+10%): 30%
  - Blaze (+15%): 35%
  - Inferno (+20%): 40%

### Implementation Details

```
Crit determination (pseudo-code):

seed = hash(user_id + date_string + habit_id + attempt_number)
rng = SeededRandom(seed)
base_chance = 0.20
tier_bonus = user.streak_tier.crit_modifier
final_chance = min(base_chance + tier_bonus, 0.50)  // hard cap at 50%

is_crit = rng.next() < final_chance
crit_multiplier = is_crit ? rng.nextInRange(2.0, 3.0) : 1.0
xp_awarded = base_xp * crit_multiplier
```

Key constraints:
- **Deterministic per attempt**: Seeded RNG ensures the same user+day+habit always produces the same result. No re-roll exploit by re-completing.
- **Attempt number tracks**: If a habit can only be completed once per day, attempt is always 1. If repeatable, increment.
- **Crit cap**: 50% maximum chance regardless of tier stacking.

### XP / Economy Impact

| Scenario | Avg XP per habit |
|----------|-----------------|
| No crits (current) | 10.0 |
| 20% crit @ 2.5x avg | 13.0 |
| 30% crit @ 2.5x avg | 14.5 |
| 40% crit @ 2.5x avg | 16.0 |

**Decision**: Accept faster leveling in early tiers; adjust level thresholds for Tier 3+ to compensate.

### A/B Test Plan

- **Control**: Fixed 10 XP per completion
- **Variant A**: 20% crit chance, 2x multiplier only
- **Variant B**: 20% crit chance, 2x–3x multiplier range
- **Metrics**: D7 retention, completions per day, session length
- **Duration**: 14 days minimum, 1000 users per cohort
- **Hypothesis**: Variant B increases D7 retention by ≥8% vs control

---

## 2. Endowed Progress Effect

### Problem

Starting at Streak 0 gives users **nothing to protect**. The first day feels like a cold start with no momentum. Users who see "0" have no loss aversion trigger — there's nothing at stake.

### Psychology Principle

**Endowment effect** (Kahneman, Knetsch & Thaler, 1990). People value what they already possess more than equivalent potential gains. A car wash loyalty card pre-stamped with 2/10 stamps converts better than a blank 0/8 card — even though both require 8 more stamps.

### Design

- The moment a user completes their **first-ever habit**, streak immediately displays "1" with a "🔥 Spark Lit" celebration message
- Progress bar on Day 1 shows **1/90** filled (not 0/90)
- Copy: "Your flame is lit. Don't let it go out."
- No waiting for end-of-day streak calculation

### Implementation Details

```swift
// In HabitCompletionViewModel
func onHabitCompleted(habit: Habit, user: User) {
    // ... existing XP logic ...
    
    if user.totalCompletions == 0 {
        // First-ever completion: immediately show streak as 1
        user.currentStreak = 1
        user.streakStartDate = Date()
        triggerSparkLitAnimation()
    }
}
```

Changes:
- Streak display logic: Show `max(1, calculatedStreak)` once user has ≥1 lifetime completion
- Progress ring: `progress = max(1, currentStreak) / 90.0`
- Streak start: Recorded on first completion, not first full day

### XP / Economy Impact

None directly. This is a display/framing change only. Indirect impact: higher D1→D2 retention means more users reach streak tier bonuses sooner.

### A/B Test Plan

- **Control**: Streak shows 0 until end-of-day calculation confirms Day 1 complete
- **Variant**: Streak shows 1 immediately on first completion + Spark Lit animation
- **Metrics**: D1→D2 return rate, D1→D7 retention
- **Duration**: 14 days, new users only, 500 per cohort
- **Hypothesis**: Variant increases D1→D2 return rate by ≥12%

---

## 3. Anonymous Social Proof

### Problem

The solo experience feels isolating. Without guilds, clans, or friends lists, there's no sense of community. Users don't know if anyone else uses the app, which reduces perceived value and social accountability.

### Psychology Principle

**Social proof / herd behavior** (Cialdini, 1984). People conform to what others are doing, especially under uncertainty. "12,847 habits completed today" signals: this works, others are doing it, you should too.

### Design

- **Home screen footer**: "🔥 12,847 habits completed by the RNF community today"
- **Peak hours variant**: "🔥 847 people forging right now" (users with activity in last 15 min)
- Display with **CountUp animation** on load (0 → 12,847 over 1.5s)
- Updates every 5 minutes (not real-time)
- Subtle pulse animation on the number when it increments

### Implementation Details

```sql
-- Supabase Edge Function: get_community_stats
SELECT 
  COUNT(*) as today_completions
FROM habit_completions
WHERE completed_at >= CURRENT_DATE 
  AND completed_at < CURRENT_DATE + INTERVAL '1 day';

-- Active users (for peak hours variant)
SELECT 
  COUNT(DISTINCT user_id) as active_now
FROM habit_completions
WHERE completed_at >= NOW() - INTERVAL '15 minutes';
```

Caching strategy:
- Edge function result cached for **5 minutes** in Supabase CDN
- Client fetches on app launch + every 5 min while app is foregrounded
- Fallback: Show last-known value if fetch fails (never show 0)

Privacy guarantees:
- **Aggregate only** — no user-identifiable data in response
- No breakdown by habit type, location, or demographic
- Edge function returns only: `{ today_count: number, active_now: number }`

### XP / Economy Impact

None. This is a social framing mechanic, not a reward mechanic.

### A/B Test Plan

- **Control**: No community stats shown
- **Variant A**: Daily completion count only
- **Variant B**: Daily count + "forging right now" active count
- **Metrics**: Session frequency, D7 retention, perceived app value (survey)
- **Duration**: 21 days, 1000 users per cohort
- **Hypothesis**: Variant B increases daily session count by ≥5%

---

## 4. Spendable Currency (Forge Tokens)

### Problem

Earn-only systems (XP, streaks) create no **sunk cost** and no **investment loop**. Users accumulate numbers but never spend them, so nothing feels "wasted" by quitting. There's no IKEA effect — users haven't *built* anything with their rewards.

### Psychology Principle

**Sunk cost fallacy** (Arkes & Blumer, 1985) + **IKEA effect** (Norton, Mochon & Ariely, 2012). When people spend resources to customize something, they value it more. Spending creates investment, investment creates switching cost, switching cost creates retention.

### Design

**Earning Forge Tokens:**

| Activity | Tokens Earned |
|----------|---------------|
| Challenge completion | 5 |
| Boss defeat | 3 |
| Weekly streak maintained | 2 |
| Daily login bonus | 1 |
| League promotion | 3 |
| 30-day streak milestone | 10 |

**Spending Forge Tokens:**

| Item | Cost | Category |
|------|------|----------|
| Profile border (bronze) | 15 | Cosmetic |
| Profile border (gold) | 40 | Cosmetic |
| Alternative flame color | 25 | Cosmetic |
| Custom card background | 20 | Cosmetic |
| Quote pack unlock | 30 | Content |
| Extra forgiveness token | 10 | Utility |
| Streak freeze (see §5) | 10 | Utility |

### Implementation Details

Database schema:

```sql
-- Add to users table
ALTER TABLE users ADD COLUMN forge_tokens INTEGER DEFAULT 0;

-- Transaction ledger
CREATE TABLE token_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) NOT NULL,
    amount INTEGER NOT NULL,  -- positive = earn, negative = spend
    reason TEXT NOT NULL,     -- 'challenge_complete', 'boss_defeat', 'purchase_border', etc.
    reference_id UUID,       -- optional: links to challenge_id, item_id, etc.
    balance_after INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_token_tx_user ON token_transactions(user_id, created_at DESC);

-- Shop items catalog
CREATE TABLE shop_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT NOT NULL,  -- 'cosmetic', 'content', 'utility'
    cost INTEGER NOT NULL,
    asset_key TEXT NOT NULL, -- references local asset bundle
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User purchases
CREATE TABLE user_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) NOT NULL,
    item_id UUID REFERENCES shop_items(id) NOT NULL,
    purchased_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, item_id)  -- no duplicate cosmetic purchases
);
```

UI components:
- **Token balance**: Displayed in profile header (anvil icon + count)
- **Shop view**: Grid of purchasable items, organized by category
- **Purchase confirmation**: "Spend 25 🪙 on Blue Flame?" with balance preview
- **Insufficient funds**: "You need 12 more tokens. Complete challenges to earn!"

Key constraint:
- **Tokens are NOT purchasable with real money**. No IAP. No token packs. This is purely an engagement currency. This avoids App Store review complications and keeps the economy clean.

### XP / Economy Impact

Tokens are orthogonal to XP — they don't convert to XP and don't affect leveling. However, utility items (forgiveness tokens, streak freezes) indirectly affect streak maintenance, which affects tier bonuses, which affects XP rates.

Expected token velocity:
- Active user earns ~15–20 tokens/week
- First meaningful purchase (20 tokens) available after ~1.5 weeks
- Premium items (40 tokens) after ~3 weeks of engagement

### A/B Test Plan

- **Control**: No token system
- **Variant**: Full token system with shop
- **Metrics**: D30 retention, sessions per week, streak length distribution
- **Duration**: 30 days minimum (tokens need time to accumulate), 1000 users per cohort
- **Hypothesis**: Variant increases D30 retention by ≥10% and weekly session count by ≥15%

---

## 5. Purchasable Streak Freezes

### Problem

The current system grants 1 forgiveness token per 30 days. Users with long streaks (30+ days) live in **constant terror** of losing everything to a single bad day. This anxiety becomes a reason to quit preemptively — "I'll inevitably lose my streak, so why bother continuing?"

### Psychology Principle

**Loss aversion** (Kahneman & Tversky, 1979). Losses are psychologically ~2x more painful than equivalent gains are pleasurable. Users will invest disproportionate effort (or currency) to prevent a loss they perceive as imminent. Duolingo's streak freeze is their #1 monetization driver precisely because of this.

### Design

| User Tier | Freeze Allocation | Source |
|-----------|-------------------|--------|
| Free | 1 auto-forgiveness per 30 days | Existing system |
| Free + Tokens | +1 purchased freeze (10 Forge Tokens, max 2/month) | Token shop |
| Pro Subscriber | 3 freezes per month (auto-applied) | Subscription perk |
| Pro + Renewal | +1 bonus freeze per 30-day renewal | Loyalty reward |

Freeze behavior:
- **Auto-applied**: When a day is missed, the system checks for available freezes before breaking the streak
- **Priority order**: Free auto-forgiveness → purchased token freezes → Pro freezes
- **Notification**: "⚡ Streak Freeze activated! Your 47-day streak lives on."
- **Visual**: Ice crystal overlay on the streak flame for that day in the calendar view

### Implementation Details

```sql
-- Add to user profile
ALTER TABLE users ADD COLUMN streak_freezes_available INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN streak_freezes_used_this_month INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN last_freeze_reset DATE;

-- Freeze usage log
CREATE TABLE streak_freeze_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) NOT NULL,
    used_date DATE NOT NULL,
    source TEXT NOT NULL,  -- 'auto_forgiveness', 'token_purchase', 'pro_subscription'
    streak_preserved INTEGER NOT NULL,  -- streak length at time of use
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

```swift
// Streak calculation (simplified)
func calculateStreak(for user: User, on date: Date) -> StreakResult {
    let yesterday = date.addingDays(-1)
    let hadCompletionYesterday = completionExists(user: user, date: yesterday)
    
    if hadCompletionYesterday {
        return .continued
    }
    
    // Check for available freezes
    if user.streakFreezesAvailable > 0 {
        user.streakFreezesAvailable -= 1
        user.streakFreezesUsedThisMonth += 1
        logFreezeUsage(user: user, date: yesterday)
        sendFreezeNotification(user: user)
        return .frozenButAlive
    }
    
    return .broken
}
```

Monthly reset logic:
- On the 1st of each month (or 30 days after subscription start for Pro):
  - Reset `streak_freezes_used_this_month` to 0
  - Grant Pro users their 3 monthly freezes
  - Grant free users their 1 auto-forgiveness (existing logic)

Purchase constraints:
- Max 2 token-purchased freezes per calendar month
- Purchase only available when user has active streak ≥ 3 days (prevent hoarding before starting)
- Cost: 10 Forge Tokens per freeze

### XP / Economy Impact

Indirect but significant:
- Longer average streaks → more users in higher streak tiers → higher crit chance → higher average XP
- Estimated: +2–3 XP/habit average across population due to preserved tier bonuses
- Pro subscribers maintain streaks ~40% longer (based on Duolingo's published data)

### A/B Test Plan

- **Control**: Current system (1 forgiveness/30 days, no purchase option)
- **Variant A**: Token-purchasable freezes only (no Pro tier)
- **Variant B**: Full system (token purchase + Pro subscription perks)
- **Metrics**: Streak survival rate at Day 14/30/60, token spend rate, subscription conversion
- **Duration**: 60 days (need to observe full streak lifecycle), 500 users per cohort
- **Hypothesis**: Variant B increases 30-day streak survival by ≥25% and drives ≥5% subscription conversion

---

## 6. Leaderboard Leagues with Promotion/Demotion

### Problem

Flat leaderboards lose engagement after initial novelty. Once a user settles into a stable rank, there are no stakes — nothing to gain, nothing to lose. Top users dominate permanently, discouraging newcomers.

### Psychology Principle

**Loss aversion** (demotion threat) + **achievement motivation** (promotion reward). Duolingo's league system increased weekly engagement by 17% specifically because users in the "demotion zone" worked harder to avoid dropping. The weekly reset ensures no permanent hopelessness.

### Design

**League Structure:**

| League | Tier | Color | Icon |
|--------|------|-------|------|
| Bronze | 1 | 🟤 | Copper anvil |
| Silver | 2 | ⚪ | Silver anvil |
| Gold | 3 | 🟡 | Gold anvil |
| Diamond | 4 | 💎 | Diamond anvil |
| Apex | 5 | 🔥 | Flaming anvil |

**Weekly Cycle:**
- Starts: Monday 00:00 UTC
- Ends: Sunday 23:59 UTC
- Score: Total XP earned that week (resets each Monday)
- Instance size: 30 users per league instance

**Promotion/Demotion Rules:**
- Top 5 in instance → **Promote** to next league (unless already Apex)
- Bottom 5 in instance → **Demote** to lower league (unless already Bronze)
- Middle 20 → Stay in current league
- Promotion reward: +50 XP bonus + weekly badge
- Demotion: League drop only (no XP penalty, no badge removal)

**Unlock Gate:**
- Requires: Level 5 AND 7-day streak
- Rationale: Ensures users understand the core game loop before adding competitive pressure

### Implementation Details

```sql
-- League assignments
CREATE TABLE league_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) NOT NULL,
    league_tier INTEGER NOT NULL DEFAULT 1,  -- 1=Bronze, 5=Apex
    league_instance_id UUID NOT NULL,
    week_start DATE NOT NULL,
    weekly_xp INTEGER DEFAULT 0,
    final_rank INTEGER,  -- populated at week end
    promoted BOOLEAN DEFAULT false,
    demoted BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, week_start)
);

CREATE INDEX idx_league_instance ON league_assignments(league_instance_id, weekly_xp DESC);
CREATE INDEX idx_league_user_week ON league_assignments(user_id, week_start DESC);

-- League history for badge display
CREATE TABLE league_badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) NOT NULL,
    league_tier INTEGER NOT NULL,
    week_start DATE NOT NULL,
    achievement TEXT NOT NULL,  -- 'promotion', 'top_3', 'first_place'
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Weekly Recalculation Edge Function:**

```typescript
// Runs every Monday at 00:05 UTC via cron
async function recalculateLeagues() {
    const lastWeek = getLastWeekStart();
    
    // Get all instances for last week
    const instances = await getDistinctInstances(lastWeek);
    
    for (const instance of instances) {
        const rankings = await getRankings(instance.id);  // ordered by weekly_xp DESC
        
        // Top 5 promote
        for (const user of rankings.slice(0, 5)) {
            if (user.league_tier < 5) {
                await promoteUser(user, lastWeek);
            }
        }
        
        // Bottom 5 demote
        for (const user of rankings.slice(-5)) {
            if (user.league_tier > 1) {
                await demoteUser(user, lastWeek);
            }
        }
    }
    
    // Create new week's instances
    await assignUsersToNewWeekInstances();
}

async function assignUsersToNewWeekInstances() {
    const thisWeek = getCurrentWeekStart();
    const tiers = [1, 2, 3, 4, 5];
    
    for (const tier of tiers) {
        const users = await getUsersAtTier(tier);
        const shuffled = shuffle(users);  // random assignment
        const chunks = chunkArray(shuffled, 30);  // 30 per instance
        
        for (const chunk of chunks) {
            const instanceId = generateUUID();
            await createAssignments(chunk, tier, instanceId, thisWeek);
        }
    }
}
```

**UI Components:**
- League badge next to username (anvil icon in league color)
- Leaderboard view: scrollable list of 30 users in your instance
- Promotion zone (top 5) highlighted in green
- Demotion zone (bottom 5) highlighted in amber
- Your position always visible (pinned row if scrolled away)
- End-of-week celebration/commiseration animation

### XP / Economy Impact

- Promotion bonus: +50 XP (one-time per promotion per week)
- Competitive pressure increases completions/day → higher overall XP earn rate
- Estimated: Users in leagues complete 1.3x more habits than non-league users
- League-driven XP inflation: ~15% more XP per active user per week

### A/B Test Plan

- **Control**: No league system (existing flat leaderboard or none)
- **Variant A**: Leagues with promotion only (no demotion)
- **Variant B**: Full promotion + demotion system
- **Metrics**: Weekly XP earned, habits completed per week, D7/D14/D30 retention, weekly active days
- **Duration**: 28 days (4 full weekly cycles), 500 users per cohort (must all meet unlock gate)
- **Hypothesis**: Variant B increases weekly habits completed by ≥20% vs control. Variant B outperforms Variant A by ≥8% on same metric.

---

## 7. Combo System Enhancement

### Problem

Completing multiple habits in rapid succession (a common behavior — users batch their morning routine) has no special reward. This misses an opportunity to reinforce **flow state** and encourage completing "just one more" while in the zone.

### Psychology Principle

**Flow state reinforcement** (Csikszentmihalyi, 1990) + **escalation of commitment**. When users experience increasing rewards for continued action, they enter a self-reinforcing loop. Games exploit this with combo meters, hit streaks, and multiplier chains.

### Design

| Combo Level | Condition | XP Bonus |
|-------------|-----------|----------|
| x1 | Single completion | +0 (base) |
| x2 | 2nd habit within 5 min | +5 |
| x3 | 3rd habit within 5 min | +10 |
| x4 | 4th habit within 5 min | +15 |
| x5+ | 5th+ habit within 5 min | +20 (cap) |

**Visual Design:**
- Combo counter appears in top-right corner after x2 triggered
- Counter pulses/scales up on each increment
- Fire trail effect intensifies with combo level
- Distinct haptic cadence: double-tap for x2, triple-tap for x3, etc.
- At x5 (cap): "🔥 FORGE FURY!" message with enhanced animation

**Timing:**
- Window: 5 minutes between consecutive completions
- Timer is visible (subtle countdown ring around combo counter)
- Gap > 5 min: combo resets to x1 silently
- Different habits only (completing same habit twice doesn't count)

### Implementation Details

```swift
class ComboTracker: ObservableObject {
    @Published var currentCombo: Int = 0
    @Published var isActive: Bool = false
    
    private var lastCompletionTime: Date?
    private var completedHabitIDs: Set<UUID> = []
    private var comboTimer: Timer?
    
    private let comboWindow: TimeInterval = 300  // 5 minutes
    
    func onHabitCompleted(habitID: UUID) -> Int {
        let now = Date()
        
        // Check if this is a different habit and within window
        guard !completedHabitIDs.contains(habitID) else { return 0 }
        
        if let lastTime = lastCompletionTime,
           now.timeIntervalSince(lastTime) <= comboWindow {
            // Extend combo
            currentCombo += 1
            completedHabitIDs.insert(habitID)
        } else {
            // Start new combo
            currentCombo = 1
            completedHabitIDs = [habitID]
        }
        
        lastCompletionTime = now
        isActive = currentCombo >= 2
        resetTimer()
        
        return comboXPBonus
    }
    
    var comboXPBonus: Int {
        switch currentCombo {
        case 0...1: return 0
        case 2: return 5
        case 3: return 10
        case 4: return 15
        default: return 20  // cap at x5+
        }
    }
    
    private func resetTimer() {
        comboTimer?.invalidate()
        comboTimer = Timer.scheduledTimer(withTimeInterval: comboWindow, repeats: false) { _ in
            self.currentCombo = 0
            self.isActive = false
            self.completedHabitIDs.removeAll()
        }
    }
}
```

**Persistence:** Combo state is ephemeral (in-memory only). Not persisted across app kills. This is intentional — combos reward active engagement sessions, not background accumulation.

**Interaction with Critical Hits:** Combo bonus XP is added *after* crit multiplier is applied to base XP. A crit during a combo: `(10 × 2.5) + 15 combo bonus = 40 XP` for a single habit.

### XP / Economy Impact

Assumptions: Average user has 5 habits, completes 3–4 per session, average gap is 2–3 min.

| Scenario | Extra XP per session |
|----------|---------------------|
| 3 habits in combo | +5 + 10 = 15 |
| 4 habits in combo | +5 + 10 + 15 = 30 |
| 5 habits in combo | +5 + 10 + 15 + 20 = 50 |

Average active user (4 habits/session): **+30 XP per day** from combos.

### A/B Test Plan

- **Control**: No combo system
- **Variant A**: Combo with XP bonus only (no visual flair)
- **Variant B**: Full combo with visuals, haptics, and XP bonus
- **Metrics**: Habits completed per session, time-between-completions, total daily XP, session duration
- **Duration**: 14 days, 1000 users per cohort
- **Hypothesis**: Variant B increases habits-per-session by ≥15% and session duration by ≥10%

---

## Economy Balance Analysis

### Current Baseline (Pre-Retention Mechanics)

| Metric | Value |
|--------|-------|
| Base XP per habit | 10 |
| Avg habits per day | 4 |
| Daily XP (no bonuses) | 40 |
| Level thresholds | 100, 250, 500, 1000, 2000... |
| Days to Level 2 | 2.5 |
| Days to Level 5 | 12.5 |

### Projected New Baseline (All Mechanics Active)

| XP Source | Daily XP Contribution | Notes |
|-----------|-----------------------|-------|
| Base habit XP | 40 | 4 habits × 10 XP |
| Critical Hit bonus | +12 | 20% chance × 2.5x on 4 habits ≈ +3/habit avg |
| Combo bonus | +30 | 4 habits in combo: 0+5+10+15 |
| League promotion | +7/day avg | 50 XP/week ÷ 7 (when promoting) |
| **Total average daily XP** | **~89** | **2.2x current baseline** |

### Level Threshold Adjustment

To maintain similar progression pacing despite 2.2x XP inflation:

| Level | Current Threshold | Adjusted Threshold | Days to Reach (new) |
|-------|-------------------|-------------------|---------------------|
| 2 | 100 | 200 | ~2.2 days |
| 3 | 250 | 550 | ~6.2 days |
| 4 | 500 | 1,100 | ~12.4 days |
| 5 | 1,000 | 2,200 | ~24.7 days |
| 10 | 5,000 | 11,000 | ~124 days |

**Recommendation:** Apply 2x multiplier to all level thresholds from Level 3 onward. Keep Levels 1–2 at current thresholds to preserve the "fast first levels" onboarding dopamine hit. This means:
- Levels 1–2: Feel faster than before (good for onboarding)
- Levels 3+: Feel similar to current pacing
- Net effect: Retention mechanics add *variety* to XP earning without trivializing progression

### Token Economy Balance

| Week | Tokens Earned | Cumulative | Affordable Items |
|------|---------------|------------|-----------------|
| 1 | 8–12 | 10 | Streak freeze (10) |
| 2 | 8–12 | 20 | Card background (20) |
| 3 | 8–12 | 30 | Quote pack (30) |
| 4 | 10–15 | 42 | Gold border (40) |

Target: First purchase within 7–10 days. No item should require more than 5 weeks of earning. Token scarcity creates meaningful choice without frustration.

### Interaction Matrix

| Mechanic | Interacts With | Effect |
|----------|---------------|--------|
| Critical Hits | Streak Tiers | Higher tier → more crits → more XP |
| Critical Hits | Combos | Crit during combo = massive single-habit payout |
| Combos | Leagues | Combo XP counts toward league weekly score |
| Forge Tokens | Streak Freezes | Tokens buy safety → longer streaks → higher tiers |
| Leagues | All XP sources | All XP feeds league position |
| Endowed Progress | Streak Freezes | Early streak protection reinforces endowment |
| Social Proof | Leagues | "X people forging" complements competitive pressure |

### Risk: Runaway XP Inflation

**Worst case:** User at max streak tier (40% crit) completes 5 habits in combo with all crits.
- `(10 × 3.0 + 0) + (10 × 3.0 + 5) + (10 × 3.0 + 10) + (10 × 3.0 + 15) + (10 × 3.0 + 20)` = 30 + 35 + 40 + 45 + 50 = **200 XP in one session**

This is 5x the normal daily rate in a single session. Mitigation:
1. **Daily XP cap**: 300 XP per day (prevents exploits, doesn't affect 99% of users)
2. **Crit cap**: 50% maximum regardless of bonuses
3. **Combo cap**: x5 maximum (no infinite scaling)
4. **Adjusted thresholds**: Higher levels require proportionally more XP

### Summary of Economy Changes

| Parameter | Before | After |
|-----------|--------|-------|
| Avg daily XP (active user) | 40 | ~89 |
| XP variance per habit | 0 (always 10) | High (10–50 range) |
| Level 5 time | ~12.5 days | ~12–14 days (adjusted thresholds) |
| Currencies | 1 (XP) | 2 (XP + Forge Tokens) |
| Monetizable mechanic | None | Streak Freezes (Pro sub) |
| Social systems | None | Leagues + anonymous proof |
| Daily XP cap | None | 300 |

---

## Implementation Priority

| Phase | Mechanics | Rationale |
|-------|-----------|-----------|
| **Phase 1** (MVP+) | Endowed Progress, Critical Hits | Zero backend, pure client-side, immediate retention impact |
| **Phase 2** (v1.1) | Combo System, Social Proof | Light backend (1 edge function), high engagement lift |
| **Phase 3** (v1.2) | Forge Tokens, Streak Freezes | Full economy system, enables monetization |
| **Phase 4** (v2.0) | Leaderboard Leagues | Requires critical mass of users (~500+ active) |

---

## Open Questions

1. **Daily XP cap value**: 300 feels right but needs validation. Too low frustrates power users; too high allows runaway.
2. **Combo window duration**: 5 min is generous. Should we test 3 min vs 5 min vs 10 min?
3. **League instance size**: 30 is Duolingo's number. With smaller user base, might need 15–20.
4. **Token earn rates**: Need telemetry on challenge/boss completion frequency before finalizing.
5. **Pro subscription pricing**: Needs market research. $4.99/mo? $9.99/mo? Annual discount?
