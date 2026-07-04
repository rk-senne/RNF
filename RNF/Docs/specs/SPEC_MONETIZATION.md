# SPEC: Monetization Model

**Status:** Draft  
**Created:** 2026-07-03  
**Last Updated:** 2026-07-03  
**Owner:** RNF Core  

---

## Table of Contents

1. [Business Model Overview](#business-model-overview)
2. [Free Tier](#free-tier)
3. [Pro Tier](#pro-tier)
4. [Lifetime Option](#lifetime-option)
5. [Micro-Transactions (Forge Tokens)](#micro-transactions-forge-tokens)
6. [14-Day Full Trial Strategy](#14-day-full-trial-strategy)
7. [Forgiveness Token Economics](#forgiveness-token-economics)
8. [Paywall Design & Placement](#paywall-design--placement)
9. [StoreKit 2 Implementation](#storekit-2-implementation)
10. [Revenue Projection Model](#revenue-projection-model)
11. [Migration Plan](#migration-plan)

---

## Business Model Overview

RNF operates a **freemium subscription model** with a deliberate ethical constraint: no pay-to-win mechanics. The revenue strategy is built on three pillars:

| Pillar | Mechanism | Revenue Share Target |
|--------|-----------|---------------------|
| Recurring subscriptions | Pro monthly/yearly | 70% |
| One-time purchases | Lifetime option | 20% |
| Engagement economy | Forge Tokens (earned, not bought) | 0% (retention driver) |

### Core Philosophy

- **Earn it, don't buy it.** Progress is always skill/discipline-based.
- **Loss aversion over FOMO.** Show users what they'll lose, not what they're missing.
- **Never punish free users.** Free tier is genuinely useful, not a crippled experience.
- **Respect completion moments.** Paywalls never interrupt positive reinforcement.

### Pricing Summary

| Tier | Price | Billing |
|------|-------|---------|
| Free | $0 | — |
| Pro Monthly | $4.99/mo | Recurring |
| Pro Yearly | $39.99/yr | Recurring (~$3.33/mo, 33% savings) |
| Lifetime | $79.99 | One-time |

---

## Free Tier

The Free tier provides a complete, functional habit-tracking experience constrained by scope rather than quality.

### Included Features

| Feature | Constraint |
|---------|-----------|
| Core habits | 3 total (one Body, one Mind, one Spirit) |
| Streak tracking | Full calendar view |
| XP & leveling | Capped at Level 10 |
| Forgiveness tokens | 1 per 30 days (auto-granted) |
| Notifications | Basic, 2 per day max |
| Social proof | Community counter (read-only) |
| Weekly summary | Basic stats (completions, streaks) |
| Achievements | First 10 only |

### Design Rationale

- **3 habits** is enough to form a genuine routine without overwhelming new users.
- **Level 10 cap** creates a natural ceiling that makes users feel "ready" for more.
- **1 forgiveness token** lets free users recover once per month — enough to experience the mechanic, not enough to feel fully protected.
- **Basic weekly summary** proves the value of data reflection before upselling full insights.

### Free Tier Boundaries

The following are explicitly **not** available on Free:

- Custom habit creation beyond 3
- Skill tree system
- Seasonal arcs
- Streak multipliers
- Living/Evolving UI themes
- Focus timer
- Detailed weekly reports
- Discipline Card generation
- Reading profile
- Boss battles
- Leaderboard leagues
- Data export

---

## Pro Tier

**Pricing:** $4.99/month | $39.99/year (33% discount)

Pro unlocks the full RNF experience — gamification, insights, social features, and personalization.

### Complete Feature Set

#### Habits & Tracking
- **Unlimited custom habits** — no category or count restrictions
- **Streak multipliers** — all tiers (2x at 7 days, 3x at 30 days, 5x at 90 days)
- **3 streak freezes per month** — auto-applied on missed days (no user action required)

#### Gamification
- **Full skill tree system** — branching progression paths
- **Seasonal arcs** — time-limited narrative challenges
- **Boss battles** — milestone challenges requiring sustained performance
- **All achievements unlocked** — full achievement catalog
- **Leaderboard leagues** — competitive brackets with weekly resets

#### Insights & Data
- **Full weekly reports** — detailed analytics with trend insights
- **Focus timer** — integrated Pomodoro-style timer linked to habits
- **Reading profile** — book/content tracking tied to Mind habits
- **Export data** — JSON and CSV export of all user data

#### Social & Identity
- **Discipline Card generation** — shareable achievement cards
- **Priority notification personalization** — custom schedules, motivational tone selection

#### Experience
- **Living/Evolving UI** — interface that changes based on user progress and streaks

### Pro Value Proposition

At $4.99/mo, users get approximately:
- $0.17/day for unlimited habit tracking + gamification
- Equivalent to ~1 coffee per month for a complete self-improvement system

---

## Lifetime Option

**Price:** $79.99 (one-time)

### What's Included

- All Pro features, permanently
- **"Founding Forger" badge** — exclusive profile indicator
- **5 bonus Forge Tokens monthly** — permanent monthly grant

### Target Customer

- Discipline-focused users who philosophically dislike subscriptions
- Users who have demonstrated 60+ day retention (ideal conversion point)
- Power users who would otherwise pay $40/yr for 2+ years

### Revenue Logic

| Scenario | Revenue |
|----------|---------|
| User pays yearly for 2 years | $79.98 |
| User pays lifetime once | $79.99 |
| Breakeven vs yearly | ~2 years |
| Breakeven vs monthly | ~16 months |

**Strategic value:** Captures committed users who might otherwise churn at annual renewal. The upfront $79.99 has zero renewal risk and funds development immediately.

### Availability

- Shown in subscription options after Day 30 of active use
- Highlighted during yearly renewal prompts
- May be time-limited during launch window for urgency

---

## Micro-Transactions (Forge Tokens)

### Core Rule: NOT Purchasable with Real Money

Forge Tokens are the **internal engagement currency**. They cannot be bought with real money. This is a hard constraint that preserves the integrity of the discipline-based progression system.

### Earning Methods

| Method | Tokens Earned |
|--------|--------------|
| Daily habit completion (all habits) | 1 |
| 7-day streak milestone | 3 |
| 30-day streak milestone | 10 |
| Boss battle victory | 5 |
| Weekly challenge completion | 2 |
| Seasonal arc chapter completion | 5 |
| Achievement unlock | 1-5 (varies) |
| Pro: Monthly bonus (Lifetime users) | 5 |

### Spending Options

| Item | Cost | Limit |
|------|------|-------|
| Cosmetic themes | 15-30 tokens | Unlimited |
| Extra streak freeze | 10 tokens | 2/month |
| Quote packs | 5 tokens | Unlimited |
| Profile frames | 20 tokens | Unlimited |
| Custom habit icons | 10 tokens | Unlimited |

### Anti-P2W Guarantee

- No token item provides a competitive advantage
- Streak freezes are convenience, not power (capped at 2/month via tokens)
- Leaderboard position is never influenced by token spending
- Cosmetics are purely visual

### Economic Balance

- Average engaged user earns ~15-20 tokens/month
- Prevents hoarding: no interest, no trading
- Keeps users returning daily to earn (retention mechanic)

---

## 14-Day Full Trial Strategy

### Mechanism

Every new user receives **all Pro features for 14 days** with no credit card required.

### Timeline

| Day | Event |
|-----|-------|
| 1 | Full Pro access begins. Subtle "Trial" badge in settings. |
| 7 | In-app message: "You've been using Pro features for a week. Here's what you've unlocked." |
| 10 | Gentle reminder: "4 days left of your Pro trial." |
| 13 | Pre-expiry nudge: "Tomorrow your skill tree, multipliers, and auto-freezes pause." |
| 14 | Final day notification: "Last day to keep your Pro features active." |
| 15 | Soft paywall appears. Features locked but data preserved. |

### Day 15 Paywall Message

> "Your skill tree, weekly insights, and streak multiplier are Pro features. Your streak is 14 days — protect it."

### Psychological Design

- **Loss aversion:** Frame as losing what they have, not gaining something new
- **Streak anchoring:** Always show current streak prominently on paywall
- **Data preservation:** Make clear that progress is saved, not lost — just paused
- **Social proof:** "X users upgraded to protect their streak this week"

### A/B Testing Plan

| Variant | Trial Duration | Hypothesis |
|---------|---------------|-----------|
| Control (A) | 14 days | Longer trial builds deeper habits, higher conversion |
| Test (B) | 7 days | Shorter trial creates urgency, faster decision |

**Primary metric:** Trial → Paid conversion rate  
**Secondary metrics:** Day 30 retention post-conversion, monthly churn rate  
**Sample size:** 5,000 users per variant minimum  
**Duration:** 8 weeks

### Conversion Targets

| Metric | Target | Industry Benchmark |
|--------|--------|--------------------|
| Trial start rate | 15% of installs | 10-20% |
| Trial → Paid conversion | 12-15% | 8-12% (premium habit apps) |
| Yearly vs Monthly split | 40% yearly | 30-40% |

---

## Forgiveness Token Economics

Forgiveness tokens (streak freezes) are the **primary conversion lever** — they protect what users value most (their streak).

### Token Allocation by Tier

| Tier | Allocation | Mechanism |
|------|-----------|-----------|
| Free | 1 per 30 days | Auto-granted on calendar day 1 |
| Pro | 3 per month | Auto-applied on first 3 missed days |
| Forge Token purchase | 10 tokens = 1 freeze | Manual redemption, max 2/month |

### Auto-Apply Behavior (Pro)

1. User misses a habit day
2. System checks: freeze tokens available?
3. If yes: freeze applied automatically, streak preserved, notification sent
4. If no: streak breaks, recovery flow triggered

### Free Tier Scarcity Design

- 1 token per 30 days creates genuine scarcity
- Users learn to value streak protection through experience
- When streak is long (14+ days), the single token feels insufficient
- This is the **primary emotional trigger** for Pro upgrade

### Revenue Hook Messaging

Triggered when a Free user's streak is at risk and they have 0 tokens:

> "Your 30-day streak is at risk. Upgrade to Pro for automatic protection."

Additional contextual messages:

| Scenario | Message |
|----------|---------|
| Streak 7+ days, 0 tokens | "You've built 7 days of momentum. Pro users get 3 auto-freezes per month." |
| Streak broken, had been 14+ | "Your 14-day streak ended yesterday. With Pro, it would have been saved automatically." |
| Used last free token | "Your forgiveness token is used. Next one arrives in 29 days. Pro gives you 3 every month." |

### Forge Token Freeze Purchase

- Cost: 10 Forge Tokens per freeze
- Monthly cap: 2 freezes via token purchase
- Available to both Free and Pro users
- Pro users can exceed their 3 auto-freezes with token purchases (up to 5 total/month)

---

## Paywall Design & Placement

### Golden Rule

> **NEVER interrupt a completion moment.**

When a user marks a habit complete, celebrates a streak, or earns an achievement — the paywall must not appear. These are sacred moments of positive reinforcement.

### Paywall Trigger Points

| Trigger | Context | Priority |
|---------|---------|----------|
| Locked feature tap | User taps a Pro-only feature in locked state | High |
| Trial expiry | Day 15, first app open | High |
| Settings → Subscription | User-initiated | Medium |
| Post-streak-break recovery | After showing broken streak, before recovery | Medium |
| Weekly summary upsell | At bottom of Free weekly summary | Low |

### Paywall UI Components

```
┌─────────────────────────────────────┐
│         🔥 Your Streak: 14 days      │
│                                       │
│   ┌─────────────────────────────┐    │
│   │  [Feature Preview Cards]     │    │
│   │  • Skill Tree (locked)       │    │
│   │  • Weekly Insights (locked)  │    │
│   │  • Auto-Freeze (locked)      │    │
│   └─────────────────────────────┘    │
│                                       │
│  "You've earned 1,200 XP with streak │
│   multipliers this week. Keep your   │
│   momentum."                          │
│                                       │
│  ┌─────────────────────────────┐     │
│  │  $4.99/mo  │  $39.99/yr ✓  │     │
│  │            │  Save 33%      │     │
│  └─────────────────────────────┘     │
│                                       │
│  [ Continue with Pro ]                │
│                                       │
│  ── or ──                             │
│                                       │
│  (dismiss) Not now                    │
│                                       │
└─────────────────────────────────────┘
```

### Design Principles

| Principle | Implementation |
|-----------|---------------|
| Loss aversion | Show streak + earned XP prominently |
| Easy dismiss | Single tap "Not now" — never hidden |
| Non-aggressive | No countdown timers, no fake urgency |
| Value-first | Show concrete stats from their usage |
| Personalized | Reference their actual data (streak length, XP earned, habits tracked) |

### Paywall Frequency Caps

- Max 1 paywall impression per session
- Max 3 paywall impressions per week
- After 3 dismissals in a row: suppress for 7 days
- Never show paywall on: first app open of the day, during active timer, immediately after habit completion

---

## StoreKit 2 Implementation

### Product Configuration

| Product ID | Type | Price |
|-----------|------|-------|
| `com.rnf.pro.monthly` | Auto-renewable subscription | $4.99 |
| `com.rnf.pro.yearly` | Auto-renewable subscription | $39.99 |
| `com.rnf.pro.lifetime` | Non-consumable | $79.99 |

**Subscription Group:** `com.rnf.pro`  
**Group Level:** Monthly (Level 2), Yearly (Level 1)

### Client-Side Architecture

```swift
// SubscriptionManager.swift

import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    @Published var proEntitlement: Bool = false
    @Published var currentSubscription: Product.SubscriptionInfo?
    @Published var availableProducts: [Product] = []
    
    private let productIDs: Set<String> = [
        "com.rnf.pro.monthly",
        "com.rnf.pro.yearly",
        "com.rnf.pro.lifetime"
    ]
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        do {
            availableProducts = try await Product.products(for: productIDs)
        } catch {
            // Handle product loading failure
        }
    }
    
    // MARK: - Entitlement Checking
    
    func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if productIDs.contains(transaction.productID) {
                    proEntitlement = true
                    return
                }
            case .unverified:
                break
            }
        }
        proEntitlement = false
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await checkEntitlements()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }
    
    // MARK: - Transaction Listener
    
    func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                    await self.checkEntitlements()
                }
            }
        }
    }
}
```

### Native Subscription UI

```swift
// ProSubscriptionView.swift

import StoreKit
import SwiftUI

struct ProSubscriptionView: View {
    var body: some View {
        SubscriptionStoreView(groupID: "com.rnf.pro") {
            VStack {
                // Custom marketing content
                StreakProtectionHeader()
                FeatureComparisonList()
            }
        }
        .subscriptionStoreControlStyle(.prominentPicker)
        .storeButton(.visible, for: .restorePurchases)
    }
}
```

### State Management Scenarios

| Scenario | Handling |
|----------|----------|
| New purchase | Verify → update local state → sync to Supabase |
| Upgrade (monthly → yearly) | Apple handles proration. Listen for transaction update. |
| Downgrade (yearly → monthly) | Takes effect at end of current period |
| Cancellation | Retain access until expiry_date. Show "expiring" state. |
| Grace period | 16-day grace period. Show "billing issue" banner. Retain access. |
| Billing retry | Apple retries for 60 days. User retains access during retry window. |
| Restore purchases | `Transaction.currentEntitlements` re-checks all transactions |
| Refund | Server notification triggers access revocation |

### Server-Side Verification

**Supabase Edge Function:** `verify-receipt`

```typescript
// supabase/functions/verify-receipt/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
  const { signedTransactionInfo } = await req.json();
  
  // Decode and verify JWS
  // Validate with Apple's public key
  // Extract transaction details
  // Upsert to subscriptions table
  
  return new Response(JSON.stringify({ valid: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
```

**Apple Server Notifications V2 Endpoint:** `POST /functions/v1/apple-notifications`

Handles:
- `DID_RENEW` — extend expiry_date
- `DID_CHANGE_RENEWAL_STATUS` — mark cancellation pending
- `EXPIRED` — revoke access
- `GRACE_PERIOD_EXPIRED` — revoke access
- `REFUND` — immediate access revocation
- `REVOKE` — family sharing revocation

### Database Schema

```sql
-- subscriptions table
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    product_id TEXT NOT NULL,
    original_transaction_id TEXT UNIQUE,
    purchase_date TIMESTAMPTZ NOT NULL,
    expiry_date TIMESTAMPTZ,
    status TEXT NOT NULL CHECK (status IN (
        'active', 'expired', 'grace_period', 
        'billing_retry', 'cancelled', 'refunded'
    )),
    environment TEXT NOT NULL CHECK (environment IN ('sandbox', 'production')),
    auto_renew_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index for fast entitlement checks
CREATE INDEX idx_subscriptions_user_active 
    ON subscriptions(user_id) 
    WHERE status IN ('active', 'grace_period', 'billing_retry');

-- RLS policy
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own subscription"
    ON subscriptions FOR SELECT
    USING (auth.uid() = user_id);
```

### Entitlement Resolution Logic

```
1. Check local Transaction.currentEntitlements (fastest)
2. If no local entitlement, check Supabase subscriptions table
3. If conflict: server state wins (handles refunds, family sharing revocation)
4. Cache result for 1 hour, refresh on app foreground
```

---

## Revenue Projection Model

### Assumptions

| Parameter | Value | Source |
|-----------|-------|--------|
| Monthly downloads | 10,000 | Target (App Store Optimization + content marketing) |
| Day 7 retention | 40% | Industry benchmark for habit apps |
| Trial start rate | 15% | 15% of Day 7 retained users start trial |
| Trial → Paid conversion | 12% | Target (benchmark: 8-12%) |
| Monthly vs Yearly split | 60% / 40% | Industry standard |
| Lifetime purchasers | 5% of paid | Niche segment |
| Monthly churn | 8% | Target (benchmark: 10-15%) |
| Yearly churn | 25% (at renewal) | Target |

### Monthly Revenue Calculation (Steady State — Month 6+)

```
Monthly downloads:                           10,000
Day 7 retained users:         10,000 × 40% = 4,000
Trial starters:                4,000 × 15% =   600
Converted to paid:               600 × 12% =    72 new paying users/month

New paid breakdown:
  Monthly subscribers:            72 × 60% =    43 @ $4.99 = $214.57
  Yearly subscribers:             72 × 40% =    29 @ $39.99 = $1,159.71
  Lifetime (5% of paid):          72 × 5%  =     4 @ $79.99 = $319.96

New MRR contribution/month:                          $1,694.24
```

### Cumulative Subscriber Growth (12-Month Projection)

| Month | Active Monthly Subs | Active Yearly Subs | Lifetime (Total) | MRR | Cumulative Revenue |
|-------|--------------------|--------------------|-------------------|-----|-------------------|
| 1 | 43 | 29 | 4 | $359 | $1,694 |
| 2 | 83 | 58 | 8 | $698 | $4,086 |
| 3 | 119 | 87 | 12 | $1,015 | $6,795 |
| 4 | 153 | 116 | 16 | $1,312 | $9,801 |
| 5 | 184 | 145 | 20 | $1,590 | $13,085 |
| 6 | 212 | 174 | 24 | $1,850 | $16,629 |
| 7 | 238 | 203 | 28 | $2,093 | $20,416 |
| 8 | 262 | 232 | 32 | $2,320 | $24,430 |
| 9 | 284 | 261 | 36 | $2,533 | $28,657 |
| 10 | 304 | 290 | 40 | $2,731 | $33,082 |
| 11 | 323 | 319 | 44 | $2,917 | $37,693 |
| 12 | 340 | 348 | 48 | $3,090 | $42,477 |

*Note: Monthly subs account for 8% monthly churn. Yearly subs accumulate for first 12 months.*

### LTV by Tier

| Tier | Calculation | LTV |
|------|-------------|-----|
| Monthly subscriber | $4.99 × (1 / 0.08) = 12.5 months avg | $62.38 |
| Yearly subscriber | $39.99 × 2.5 avg renewals | $99.98 |
| Lifetime | One-time payment | $79.99 |

**Blended LTV per paying user:** ~$78.50  
**LTV per install:** $78.50 × 0.72% conversion = **$0.57**

### Revenue After Apple's Cut (30% → 15% after Year 1)

| Period | Apple Cut | Net Revenue Rate |
|--------|-----------|-----------------|
| Year 1 | 30% | 70% of gross |
| Year 2+ (Small Business Program) | 15% | 85% of gross |

**Year 1 net revenue estimate:** $42,477 × 0.70 = **$29,734**  
**Year 2 net revenue estimate (if growth maintains):** ~$55,000 × 0.85 = **~$46,750**

---

## Migration Plan

### Context

Existing users (pre-monetization) have been using RNF with no paywall. The migration must respect their investment while transitioning to the freemium model.

### Migration Tiers

| User Segment | Criteria | Migration Treatment |
|--------------|----------|-------------------|
| Early Adopters | Installed before monetization launch | 30-day Pro trial + "Founder" status |
| Active Users | 7+ day streak at migration | 14-day Pro trial (standard) |
| Dormant Users | No activity in 14+ days | Standard Free tier (no trial) |

### Early Adopter Benefits

Users who installed before the monetization update receive:

1. **30-day extended Pro trial** (instead of 14)
2. **"Early Forger" badge** — permanent, regardless of tier
3. **5 bonus Forge Tokens** — one-time grant
4. **Grandfather clause:** Any habits already created beyond the Free limit remain active (read-only if they downgrade — can complete but not edit/add)

### Grandfather Clause Details

```
IF user has > 3 habits AND does not subscribe:
  - All existing habits remain visible and completable
  - Cannot create new habits beyond Free limit
  - Cannot edit grandfathered habits
  - Message: "You have 5 active habits. Free accounts support 3. 
    Your existing habits are preserved — upgrade to Pro to add more."
```

### Migration Timeline

| Week | Action |
|------|--------|
| Week -2 | In-app announcement: "RNF Pro is coming. As an early user, you'll get special benefits." |
| Week -1 | Show preview of Pro features (locked but visible) |
| Week 0 | Deploy monetization update. Early adopters get 30-day trial. |
| Week 1-4 | Early adopter trial period. Soft education about Pro value. |
| Week 4 | Trial expires for early adopters. Soft paywall appears. |
| Week 5+ | Standard monetization flow for all users. |

### Communication Strategy

- **Tone:** Grateful, not transactional
- **Key message:** "You helped build RNF. Here's our thank you."
- **Never imply:** Features are being "taken away"
- **Always frame:** "New features are being added to Pro. Your core experience remains free."

### Technical Migration Steps

1. Add `installed_at` timestamp to user profile (backfill from first activity date)
2. Deploy subscription infrastructure (StoreKit 2, Supabase table)
3. Compute migration segment per user on first app open post-update
4. Grant appropriate trial/tokens based on segment
5. Enable paywall UI with segment-aware timing
6. Track migration cohort separately in analytics

### Rollback Plan

If conversion rates are significantly below target (< 5%) after 30 days:

1. Extend all trials by 14 additional days
2. A/B test alternative paywall messaging
3. Consider adjusting Free tier limits (e.g., 5 habits instead of 3)
4. If fundamentally broken: revert to full-free while redesigning approach

---

## Analytics & Success Metrics

### Key Metrics to Track

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Trial start rate | 15% | < 10% |
| Trial → Paid conversion | 12% | < 7% |
| Day 30 retention (paid) | 85% | < 75% |
| Monthly churn (monthly subs) | 8% | > 12% |
| Yearly renewal rate | 75% | < 60% |
| Paywall dismiss rate | < 90% | > 95% |
| Revenue per install | $0.57 | < $0.30 |

### Event Tracking

```
paywall_shown(trigger, streak_length, day_in_trial)
paywall_dismissed(trigger, streak_length)
purchase_started(product_id, trigger)
purchase_completed(product_id, price, trigger)
purchase_failed(product_id, error)
trial_started(source)
trial_expired(converted: bool, streak_at_expiry)
subscription_cancelled(product_id, days_active, reason)
forge_token_spent(item_type, balance_after)
streak_freeze_applied(source: auto|token|free, streak_length)
```

---

## Open Questions

1. **Family Sharing:** Should Pro support Apple Family Sharing? (Revenue impact vs. acquisition benefit)
2. **Student Pricing:** Offer 50% discount for students? (Verification complexity vs. LTV of young users)
3. **Referral Program:** Grant 1 week Pro for successful referral? (CAC reduction vs. abuse potential)
4. **Regional Pricing:** Adjust prices for developing markets? (Revenue vs. accessibility)
5. **Bundle Opportunities:** Partner with other wellness apps for Apple subscription bundles?

---

## Dependencies

- StoreKit 2 (iOS 15+)
- Supabase Edge Functions (Deno runtime)
- Apple App Store Connect (product configuration)
- Apple Server Notifications V2 (webhook setup)
- Analytics infrastructure (event tracking)

---

## References

- [Apple StoreKit 2 Documentation](https://developer.apple.com/storekit/)
- [Apple Server Notifications V2](https://developer.apple.com/documentation/appstoreservernotifications)
- [App Store Small Business Program](https://developer.apple.com/app-store/small-business-program/)
- Revenue Benchmarks: Liftoff 2025 Mobile App Trends Report
