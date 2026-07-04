# SPEC: Growth, Virality & Community

**Status:** Draft
**Created:** 2026-07-03
**Domain:** Organic Growth, Virality, Community & Content Moderation
**References:** Duolingo referral loops, Strava social mechanics, Wordle shareable results, Apple App Store Optimization guidelines

---

## Overview

This specification defines eight growth and community systems designed to drive organic acquisition, increase viral coefficient, and build lightweight social mechanics without full social-network complexity.

Design philosophy:
- **Organic-first** — no paid acquisition dependency; every feature has a sharing surface
- **Lightweight social** — pairs and links over friend graphs and feeds
- **Safe community** — moderation by default, escalation paths for abuse
- **Brand amplification** — every shared artifact carries RNF branding and App Store link
- **Privacy-respecting** — minimal data exposure between users; opt-in only

Target viral coefficient: **k = 0.3** (each user invites 0.3 new users on average)
Target organic acquisition share: **≥60%** of all installs by Month 6

---

## Viral Loop Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        RNF VIRAL LOOP                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────┐    share card    ┌──────────────┐    install app      │
│  │  User    │ ───────────────→ │  Social Feed │ ──────────────→     │
│  │ Milestone│                  │  (IG/TikTok) │              │      │
│  └──────────┘                  └──────────────┘              │      │
│       ↑                                                      ↓      │
│       │                                               ┌──────────┐  │
│       │  XP + streak                                  │  New User │  │
│       │  progression                                  │  Onboard  │  │
│       │                                               └──────────┘  │
│       │                                                      │      │
│       │         ┌────────────────────────────────────────────┘      │
│       │         ↓                                                   │
│       │   ┌──────────┐   referral     ┌──────────────┐             │
│       │   │  Day 3   │ ──reward───→   │  Referrer    │             │
│       │   │ Complete │                │  Gets Tokens │             │
│       │   └──────────┘                └──────────────┘             │
│       │         │                            │                      │
│       │         ↓                            ↓                      │
│       │   ┌──────────┐              ┌──────────────┐               │
│       │   │  Buddy   │ ←───link───→ │  1v1 Micro-  │               │
│       │   │  Pairing │              │  Challenge   │               │
│       │   └──────────┘              └──────────────┘               │
│       │         │                            │                      │
│       │         ↓                            ↓                      │
│       │   ┌──────────┐              ┌──────────────┐               │
│       │   │  Daily   │              │  Victory     │               │
│       │   │  Engage  │              │  Card Share  │               │
│       │   └──────────┘              └──────────────┘               │
│       │         │                            │                      │
│       └─────────┴────────────────────────────┘                      │
│                                                                     │
│  NOTIFICATIONS re-engage dormant users back into the loop           │
│  UGC PIPELINE keeps engaged users creating content that attracts    │
│  ASO ensures organic discovery feeds new users into the top         │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Loop mechanics:**
1. User hits milestone → generates shareable card → posts to social
2. Viewer installs app via App Store link on card
3. New user applies referral code → both earn rewards
4. New user pairs with referrer as buddy or accepts micro-challenge
5. Daily engagement generates new milestones → loop repeats
6. Notifications pull back lapsed users before streak breaks
7. UGC from engaged users creates fresh content that attracts new users

---

## 1. Day 1 Shareable Milestones

### Problem

Users have no shareable moment until Phase 20's Discipline Card — a full 90-day completion achievement. This means the app generates **zero organic social impressions** during the critical first 89 days of a user's journey. Competing apps (Duolingo, Wordle, Strava) generate shareable moments within the first session.

The result: RNF has no viral surface area during peak engagement, and users who are proud of early progress have no branded artifact to share.

### Solution

Generate beautiful, branded milestone cards at key progression moments throughout the journey. These cards serve dual purpose: celebrate the user's achievement and act as organic acquisition assets when shared to social media.

**Milestone trigger points:**

| Trigger | Card Title | Unlock Timing |
|---------|-----------|---------------|
| Streak 7 | "Ember Initiate" | ~Day 7 |
| Streak 14 | "Flame Bearer" | ~Day 14 |
| Streak 30 | "Blaze Master" | ~Day 30 |
| Level 5 | "Apprentice Smith" | ~Day 10-14 |
| Level 10 | "Journeyman Forger" | ~Day 25-35 |
| Level 15 | "Master Craftsman" | ~Day 50-60 |
| Level 20 | "Grandmaster" | ~Day 80-90 |
| Boss defeated | "Victory" (boss-specific) | Variable |
| Challenge complete (Day 90) | Full Discipline Card | Day 90 |

### User Flow

```
1. User completes habit → milestone threshold reached
2. Full-screen celebration animation plays (1.5s)
3. Card renders with user stats overlaid on branded template
4. Bottom sheet appears: "Share your achievement?"
   → [Share] → UIActivityViewController (image + text)
   → [Save to Photos] → saves static PNG to camera roll
   → [Later] → dismisses (card saved to Profile > Achievements)
5. Shared image contains App Store link + "Rise and Forge" branding
```

### Design Specifications

**Dimensions & Format:**
- Aspect ratio: 9:16 (1080×1920px) — optimized for Instagram Stories, TikTok, Snapchat
- Secondary format: 1:1 (1080×1080px) for Instagram feed / Twitter posts
- Export: Static PNG for sharing, animated (Lottie) in-app celebration

**Visual Design:**
- Background: Dark gradient (charcoal → deep ember orange)
- Central element: Milestone-specific icon/illustration (forge anvil, flame, sword)
- User stats displayed: Streak count, level, total habits completed
- Typography: Bold serif title (milestone name), clean sans-serif stats
- Branding: "Rise and Forge" watermark (bottom-left, 20% opacity)
- App Store badge: Small "Download on the App Store" (bottom-right)
- QR code: Optional small QR linking to App Store listing (bottom-center)

**Animated variant (in-app only):**
- Particle effects: Embers floating upward
- Card entrance: Scales from 0.8→1.0 with spring animation
- Stat counters: Animated number roll-up
- Duration: 2.5s total animation before share prompt

### Implementation Details

```swift
// MilestoneCardGenerator.swift
struct MilestoneCard {
    let type: MilestoneType
    let title: String
    let subtitle: String
    let stats: MilestoneStats
    let template: CardTemplate
}

enum MilestoneType {
    case streak(Int)        // 7, 14, 30
    case level(Int)         // 5, 10, 15, 20
    case bossDefeated(Boss)
    case challengeComplete
}

struct MilestoneStats {
    let currentStreak: Int
    let level: Int
    let totalHabitsCompleted: Int
    let daysActive: Int
}

class MilestoneCardRenderer {
    /// Renders a static UIImage for sharing
    func renderShareImage(card: MilestoneCard, format: CardFormat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: format.size)
        return renderer.image { context in
            drawBackground(in: context, template: card.template)
            drawIcon(in: context, type: card.type)
            drawTitle(card.title, subtitle: card.subtitle, in: context)
            drawStats(card.stats, in: context)
            drawBranding(in: context)
            drawAppStoreLink(in: context)
        }
    }
    
    /// Presents share sheet with pre-composed content
    func presentShareSheet(card: MilestoneCard, from viewController: UIViewController) {
        let image = renderShareImage(card: card, format: .story)
        let text = composeShareText(card: card)
        let url = URL(string: "https://apps.apple.com/app/rnf-rise-and-forge/id_PLACEHOLDER")!
        
        let activityVC = UIActivityViewController(
            activityItems: [image, text, url],
            applicationActivities: nil
        )
        activityVC.excludedActivityTypes = [.assignToContact, .addToReadingList]
        viewController.present(activityVC, animated: true)
    }
    
    private func composeShareText(card: MilestoneCard) -> String {
        switch card.type {
        case .streak(7):
            return "🔥 7-day streak unlocked! I'm an Ember Initiate on Rise and Forge."
        case .streak(14):
            return "🔥🔥 14 days strong. Flame Bearer status earned. #RiseAndForge"
        case .streak(30):
            return "🔥🔥🔥 30-day Blaze Master. The forge never cools. #RiseAndForge"
        case .bossDefeated(let boss):
            return "⚔️ \(boss.name) defeated! Another challenge conquered. #RiseAndForge"
        case .challengeComplete:
            return "🏆 90-day challenge COMPLETE. Full Discipline Card earned. #RiseAndForge"
        default:
            return "Leveling up in real life with Rise and Forge 🔥"
        }
    }
}

enum CardFormat {
    case story   // 1080×1920 (9:16)
    case square  // 1080×1080 (1:1)
    
    var size: CGSize {
        switch self {
        case .story: return CGSize(width: 1080, height: 1920)
        case .square: return CGSize(width: 1080, height: 1080)
        }
    }
}
```

**SwiftUI Celebration View:**
```swift
struct MilestoneCelebrationView: View {
    let card: MilestoneCard
    @State private var showShareSheet = false
    @State private var animationPhase: AnimationPhase = .entrance
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [.black, Color("EmberOrange").opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Particle embers
            EmberParticleView()
            
            // Card content
            VStack(spacing: 24) {
                milestoneIcon
                titleSection
                statsSection
            }
            .scaleEffect(animationPhase == .entrance ? 0.8 : 1.0)
            .animation(.spring(dampingFraction: 0.7), value: animationPhase)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animationPhase = .revealed
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                animationPhase = .sharePrompt
            }
        }
        .overlay(alignment: .bottom) {
            if animationPhase == .sharePrompt {
                shareBottomSheet
            }
        }
    }
    
    private var shareBottomSheet: some View {
        VStack(spacing: 16) {
            Button("Share Achievement") {
                showShareSheet = true
            }
            .buttonStyle(.primaryForge)
            
            Button("Save to Photos") {
                saveToPhotos()
            }
            .buttonStyle(.secondaryForge)
            
            Button("Later") {
                dismiss()
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .transition(.move(edge: .bottom))
    }
}
```

**Milestone detection logic:**
```swift
// MilestoneDetector.swift
class MilestoneDetector: ObservableObject {
    private let milestoneStreaks = [7, 14, 30]
    private let milestoneLevels = [5, 10, 15, 20]
    
    func checkForMilestone(after event: ProgressEvent) -> MilestoneCard? {
        switch event {
        case .streakUpdated(let newStreak):
            guard milestoneStreaks.contains(newStreak) else { return nil }
            return buildStreakCard(streak: newStreak)
            
        case .levelUp(let newLevel):
            guard milestoneLevels.contains(newLevel) else { return nil }
            return buildLevelCard(level: newLevel)
            
        case .bossDefeated(let boss):
            return buildBossCard(boss: boss)
            
        case .challengeCompleted:
            return buildDisciplineCard()
        }
    }
    
    /// Prevents duplicate milestone triggers
    func hasBeenShown(_ type: MilestoneType, for userId: UUID) -> Bool {
        UserDefaults.standard.bool(forKey: "milestone_shown_\(userId)_\(type.key)")
    }
    
    func markShown(_ type: MilestoneType, for userId: UUID) {
        UserDefaults.standard.set(true, forKey: "milestone_shown_\(userId)_\(type.key)")
    }
}
```

### Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Milestone card generation rate | 85% of eligible users see card | % users who reach milestone and see celebration |
| Share rate | ≥15% of cards shown | Cards shared / cards displayed |
| Save-to-photos rate | ≥25% of cards shown | Save actions / cards displayed |
| Install attribution from cards | Track via App Store link UTM | Installs with `utm_source=milestone_card` |
| Viral impressions per share | Estimate 150 avg story views | Self-reported or platform analytics |
| Time-to-first-share | ≤Day 7 (Ember Initiate) | Median days from install to first share |

### A/B Test Plan

- **Control**: No milestone cards (existing behavior)
- **Variant A**: Milestone cards with share prompt
- **Variant B**: Milestone cards with share prompt + "Share to unlock 5 Forge Tokens" incentive
- **Metrics**: Share rate, D7/D14/D30 retention, organic installs
- **Duration**: 21 days, 1000 users per cohort
- **Hypothesis**: Variant A increases organic installs by ≥10%; Variant B by ≥18%

---

## 2. Referral System

### Problem

RNF has no mechanism for existing users to bring in new users. Word-of-mouth happens organically but there's no tracking, no incentive structure, and no frictionless path from "I told my friend about this app" to that friend actually installing and engaging.

Without referral infrastructure:
- No attribution for organic invites
- No reward loop to incentivize sharing
- No deep link to reduce friction from recommendation to install
- No way to measure viral coefficient

### Solution

A lightweight referral system using unique invite codes and deep links. Both referrer and referee are rewarded when the referee demonstrates real engagement (completing Day 3), preventing gaming through fake accounts.

**Reward structure:**
- Referrer receives: +1 Forgiveness Token + 5 Forge Tokens
- Referee receives: +1 Forgiveness Token + 5 Forge Tokens
- Trigger: Referee completes at least 1 habit on 3 separate days (not necessarily consecutive)

**Constraints:**
- Maximum 10 successful referrals per user (prevents spam/exploitation)
- Invite codes expire after 30 days
- One referral code per new account (can't stack)

### User Flow

```
REFERRER FLOW:
1. Profile tab → "Invite a Friend" button
2. System generates unique 8-character alphanumeric code (e.g., "FORGE-A7K2")
3. Share sheet presents:
   → Copy link: https://rnf.app/invite/FORGE-A7K2
   → Share via Messages/WhatsApp/etc.
   → QR code for in-person sharing
4. Referrer sees "Pending Invites" list in profile
5. When referee hits Day 3: push notification + reward animation

REFEREE FLOW:
1. Taps deep link → App Store (if not installed) → installs app
2. On first launch, code is auto-applied from deferred deep link
3. Onboarding shows: "You were invited by [referrer display name]!"
4. Normal onboarding proceeds
5. On Day 3 completion: "🎉 Welcome bonus unlocked! +1 Forgiveness Token + 5 Forge Tokens"
6. Optional: "Add [referrer] as your Accountability Buddy?"
```

### Implementation Details

**Deep Link Architecture:**
```
Universal Link: https://rnf.app/invite/{code}
Custom URL Scheme: rnf://invite/{code}

Flow:
1. Link tapped → Safari opens universal link
2. If app installed → opens app directly with code parameter
3. If not installed → redirects to App Store
4. On install → deferred deep link (via Apple's SKAdNetwork or custom clipboard-based approach)
```

**Deferred deep link strategy:**
```swift
// AppDelegate or SceneDelegate
func handleDeferredDeepLink() {
    // Option A: Pasteboard-based (works without third-party SDK)
    if let clipboardContent = UIPasteboard.general.string,
       clipboardContent.hasPrefix("FORGE-") {
        applyReferralCode(clipboardContent)
        UIPasteboard.general.string = "" // Clear after use
    }
    
    // Option B: NSUserActivity from universal link
    // Stored by the system when user tapped link before install
}
```

**Referral code generation:**
```swift
struct ReferralCodeGenerator {
    /// Generates a unique 8-char code: "FORGE-" + 4 alphanumeric chars
    static func generate(for userId: UUID) -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // No ambiguous chars (0/O, 1/I/L)
        let suffix = (0..<4).map { _ in chars.randomElement()! }
        return "FORGE-\(String(suffix))"
    }
    
    /// Validates code format before server lookup
    static func isValid(_ code: String) -> Bool {
        let pattern = #"^FORGE-[A-HJ-NP-Z2-9]{4}$"#
        return code.range(of: pattern, options: .regularExpression) != nil
    }
}
```

**Database schema:**
```sql
-- Supabase table: referrals
CREATE TABLE referrals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_id UUID NOT NULL REFERENCES profiles(id),
    referee_id UUID REFERENCES profiles(id),  -- NULL until referee signs up
    code VARCHAR(10) NOT NULL UNIQUE,
    deep_link_url TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
        -- pending: code generated, no signup yet
        -- signed_up: referee created account
        -- qualifying: referee started but not Day 3 yet
        -- completed: referee hit Day 3, rewards distributed
        -- expired: 30 days passed without signup
    rewarded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '30 days',
    
    CONSTRAINT valid_status CHECK (status IN ('pending', 'signed_up', 'qualifying', 'completed', 'expired'))
);

-- Index for fast lookup by code
CREATE INDEX idx_referrals_code ON referrals(code);
-- Index for referrer's referral list
CREATE INDEX idx_referrals_referrer ON referrals(referrer_id, status);
-- Index for checking referee's referral
CREATE INDEX idx_referrals_referee ON referrals(referee_id);

-- View: referrer stats
CREATE VIEW referrer_stats AS
SELECT 
    referrer_id,
    COUNT(*) FILTER (WHERE status = 'completed') as successful_referrals,
    COUNT(*) FILTER (WHERE status IN ('pending', 'signed_up', 'qualifying')) as pending_referrals,
    COUNT(*) as total_referrals
FROM referrals
GROUP BY referrer_id;
```

**Reward distribution (Supabase Edge Function):**
```typescript
// supabase/functions/process-referral-reward/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
    const { referee_id } = await req.json();
    const supabase = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );
    
    // Check if referee has completed 3 days
    const { data: completions } = await supabase
        .from("habit_completions")
        .select("completed_date")
        .eq("user_id", referee_id)
        .order("completed_date");
    
    const uniqueDays = new Set(completions?.map(c => c.completed_date));
    if (uniqueDays.size < 3) return new Response("Not yet qualified", { status: 200 });
    
    // Find the referral record
    const { data: referral } = await supabase
        .from("referrals")
        .select("*")
        .eq("referee_id", referee_id)
        .eq("status", "qualifying")
        .single();
    
    if (!referral) return new Response("No qualifying referral", { status: 200 });
    
    // Check referrer hasn't exceeded limit
    const { count } = await supabase
        .from("referrals")
        .select("*", { count: "exact" })
        .eq("referrer_id", referral.referrer_id)
        .eq("status", "completed");
    
    if ((count ?? 0) >= 10) {
        // Referrer maxed out — still reward referee
        await grantReward(supabase, referee_id);
        await supabase.from("referrals").update({ status: "completed" }).eq("id", referral.id);
        return new Response("Referee rewarded, referrer at limit", { status: 200 });
    }
    
    // Grant rewards to both
    await grantReward(supabase, referral.referrer_id);
    await grantReward(supabase, referee_id);
    
    // Update referral status
    await supabase
        .from("referrals")
        .update({ status: "completed", rewarded_at: new Date().toISOString() })
        .eq("id", referral.id);
    
    // Send push notification to referrer
    await sendPushNotification(referral.referrer_id, {
        title: "Referral Complete! 🎉",
        body: "Your friend completed Day 3. You earned +1 Forgiveness Token + 5 Forge Tokens!"
    });
    
    return new Response("Rewards granted", { status: 200 });
});

async function grantReward(supabase: any, userId: string) {
    // +1 Forgiveness Token
    await supabase.rpc("increment_forgiveness_tokens", { user_id: userId, amount: 1 });
    // +5 Forge Tokens
    await supabase.rpc("increment_forge_tokens", { user_id: userId, amount: 5 });
}
```

**Anti-abuse measures:**
- Rate limit: Max 3 referral code generations per day
- Device fingerprint: One referral reward per device (prevents alt accounts)
- IP clustering: Flag if >3 referrals come from same IP within 24h
- Day-3 requirement: Prevents install-and-delete farming

### Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Viral coefficient (k) | ≥0.3 | Successful referrals / total active users |
| Invite send rate | ≥20% of MAU | Users who share at least 1 invite / MAU |
| Code-to-install conversion | ≥25% | Installs from referral links / links shared |
| Install-to-Day3 conversion | ≥40% | Referred users completing Day 3 / referred installs |
| Referrer reward claim rate | 95%+ | Rewards actually distributed / eligible referrals |
| Average referrals per referrer | 2.5 | Total successful referrals / users who referred ≥1 |
| Time from invite to install | <48h median | Median time between link share and install |

### A/B Test Plan

- **Control**: No referral system (organic only)
- **Variant A**: Referral with current reward (1 forgiveness + 5 tokens)
- **Variant B**: Referral with enhanced reward (2 forgiveness + 10 tokens)
- **Metrics**: k-factor, installs, referred user D7 retention
- **Duration**: 30 days, all users eligible
- **Hypothesis**: Variant A achieves k ≥ 0.2; Variant B achieves k ≥ 0.3

---

## 3. 1v1 Micro-Challenges

### Problem

Full guild systems (Phase 18+) require critical mass of users, complex social graphs, and significant development investment. Meanwhile, users want simple competitive pressure *now* — particularly pairs (friends, couples, siblings) who want lightweight accountability without joining a community.

The gap: no social mechanic exists between solo play and full guilds.

### Solution

Link-based 1v1 micro-challenges: 7-day streak races between two users. No friend graph, no guild membership, no complex social infrastructure. Just a shared link, a timer, and a winner.

**Rules:**
- Duration: 7 days from acceptance
- Score: Total habits completed during the 7-day window
- Winner: Higher score. Ties broken by streak consistency (fewer missed days wins).
- Prize: Winner gets 20 Forge Tokens + "Victor" badge (displayed for 7 days)
- Loser: Gets 5 Forge Tokens for participation
- Max simultaneous: 2 active micro-challenges per user

### User Flow

```
CHALLENGER FLOW:
1. Home screen → "Challenge a Friend" button (or Profile → Challenges)
2. Confirmation: "Start a 7-day habit race? Whoever completes more habits wins!"
3. System generates challenge invite link
4. Share sheet: copy link / send via Messages / WhatsApp / etc.
5. Waiting state: "Waiting for opponent..." (link valid for 72h)
6. Opponent accepts → challenge begins next calendar day
7. Daily: see comparison card (your completions vs theirs)
8. Day 7: results screen → winner celebration or graceful loss

CHALLENGEE FLOW:
1. Taps invite link → app opens (or installs first)
2. Challenge preview: "[Challenger name] challenges you to a 7-day habit race!"
3. Accept / Decline
4. On accept: challenge starts next calendar day
5. Same daily comparison view as challenger
```

### Implementation Details

**Database schema:**
```sql
-- Supabase table: micro_challenges
CREATE TABLE micro_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenger_id UUID NOT NULL REFERENCES profiles(id),
    challengee_id UUID REFERENCES profiles(id),  -- NULL until accepted
    invite_code VARCHAR(12) NOT NULL UNIQUE,
    invite_link TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
        -- pending: invite sent, not accepted
        -- active: both users confirmed, race in progress
        -- completed: 7 days finished, winner determined
        -- expired: invite not accepted within 72h
        -- cancelled: challenger cancelled before acceptance
        -- declined: challengee declined
    start_date DATE,  -- first scoring day (day after acceptance)
    end_date DATE,    -- last scoring day (start_date + 6)
    challenger_score INT NOT NULL DEFAULT 0,
    challengee_score INT NOT NULL DEFAULT 0,
    challenger_streak_days INT NOT NULL DEFAULT 0,  -- days with ≥1 completion (tiebreaker)
    challengee_streak_days INT NOT NULL DEFAULT 0,
    winner_id UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '72 hours',
    completed_at TIMESTAMPTZ,
    
    CONSTRAINT valid_challenge_status CHECK (
        status IN ('pending', 'active', 'completed', 'expired', 'cancelled', 'declined')
    )
);

-- Indexes
CREATE INDEX idx_micro_challenges_challenger ON micro_challenges(challenger_id, status);
CREATE INDEX idx_micro_challenges_challengee ON micro_challenges(challengee_id, status);
CREATE INDEX idx_micro_challenges_invite ON micro_challenges(invite_code);
CREATE INDEX idx_micro_challenges_active ON micro_challenges(status) WHERE status = 'active';

-- Function: count active challenges for rate limiting
CREATE OR REPLACE FUNCTION active_challenge_count(user_uuid UUID)
RETURNS INT AS $$
    SELECT COUNT(*)::INT FROM micro_challenges
    WHERE (challenger_id = user_uuid OR challengee_id = user_uuid)
    AND status = 'active';
$$ LANGUAGE sql STABLE;
```

**Score update trigger (runs on habit completion):**
```sql
-- Trigger function: update micro-challenge scores
CREATE OR REPLACE FUNCTION update_micro_challenge_scores()
RETURNS TRIGGER AS $$
DECLARE
    challenge RECORD;
BEGIN
    -- Find active challenges for this user
    FOR challenge IN
        SELECT * FROM micro_challenges
        WHERE status = 'active'
        AND (challenger_id = NEW.user_id OR challengee_id = NEW.user_id)
        AND NEW.completed_date BETWEEN start_date AND end_date
    LOOP
        IF challenge.challenger_id = NEW.user_id THEN
            UPDATE micro_challenges
            SET challenger_score = challenger_score + 1
            WHERE id = challenge.id;
        ELSE
            UPDATE micro_challenges
            SET challengee_score = challengee_score + 1
            WHERE id = challenge.id;
        END IF;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_challenge_scores
AFTER INSERT ON habit_completions
FOR EACH ROW
EXECUTE FUNCTION update_micro_challenge_scores();
```

**Challenge completion (scheduled function — runs daily):**
```typescript
// supabase/functions/finalize-micro-challenges/index.ts
serve(async () => {
    const supabase = createClient(/* ... */);
    const today = new Date().toISOString().split("T")[0];
    
    // Find challenges that ended yesterday
    const { data: ended } = await supabase
        .from("micro_challenges")
        .select("*")
        .eq("status", "active")
        .lt("end_date", today);
    
    for (const challenge of ended ?? []) {
        let winnerId: string | null = null;
        
        if (challenge.challenger_score > challenge.challengee_score) {
            winnerId = challenge.challenger_id;
        } else if (challenge.challengee_score > challenge.challenger_score) {
            winnerId = challenge.challengee_id;
        } else {
            // Tiebreaker: more consistent days
            winnerId = challenge.challenger_streak_days >= challenge.challengee_streak_days
                ? challenge.challenger_id
                : challenge.challengee_id;
        }
        
        // Update challenge record
        await supabase.from("micro_challenges").update({
            status: "completed",
            winner_id: winnerId,
            completed_at: new Date().toISOString()
        }).eq("id", challenge.id);
        
        // Grant rewards
        const loserId = winnerId === challenge.challenger_id
            ? challenge.challengee_id
            : challenge.challenger_id;
        
        await supabase.rpc("increment_forge_tokens", { user_id: winnerId, amount: 20 });
        await supabase.rpc("increment_forge_tokens", { user_id: loserId, amount: 5 });
        
        // Grant Victor badge (7-day expiry)
        await supabase.from("user_badges").insert({
            user_id: winnerId,
            badge_type: "victor",
            expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
        });
        
        // Notify both users
        await sendPushNotification(winnerId, {
            title: "Victory! ⚔️",
            body: `You won the micro-challenge ${challenge.challenger_score}-${challenge.challengee_score}! +20 Forge Tokens`
        });
        await sendPushNotification(loserId, {
            title: "Challenge Complete",
            body: `Close race! Final score: ${challenge.challenger_score}-${challenge.challengee_score}. +5 Forge Tokens for competing.`
        });
    }
});
```

**SwiftUI Comparison Card:**
```swift
struct MicroChallengeComparisonCard: View {
    let challenge: MicroChallenge
    @EnvironmentObject var userProfile: UserProfile
    
    private var isChallenger: Bool {
        challenge.challengerId == userProfile.id
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("Day \(currentDay) of 7")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Score comparison
            HStack(spacing: 32) {
                // You
                VStack {
                    Text(isChallenger ? "\(challenge.challengerScore)" : "\(challenge.challengeeScore)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                    Text("You")
                        .font(.caption)
                }
                
                Text("vs")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                // Opponent
                VStack {
                    Text(isChallenger ? "\(challenge.challengeeScore)" : "\(challenge.challengerScore)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    Text(opponentName)
                        .font(.caption)
                }
            }
            
            // Daily dots
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { day in
                    Circle()
                        .fill(dayColor(day))
                        .frame(width: 8, height: 8)
                }
            }
            
            // Days remaining
            Text("\(daysRemaining) days left")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```

### Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Challenge send rate | ≥10% of WAU | Users who create ≥1 challenge / weekly active users |
| Acceptance rate | ≥50% | Challenges accepted / challenges sent |
| Completion rate (both finish) | ≥75% | Challenges where both users are active all 7 days / active challenges |
| Habit completion lift | +15% during challenge | Avg daily completions during challenge vs. user's baseline |
| Viral install rate | ≥5% of challenges | Challenges that result in a new app install |
| Re-challenge rate | ≥40% | Users who start another challenge within 14 days of completion |
| Victor badge share rate | ≥10% | Users who share their Victor badge card |

### A/B Test Plan

- **Control**: No micro-challenge feature
- **Variant**: Micro-challenges enabled
- **Metrics**: WAU, habit completions/day, D14 retention, organic installs
- **Duration**: 21 days, 500 users per cohort
- **Hypothesis**: Variant increases WAU by ≥12% and daily completions by ≥15%

---

## 4. Buddy System (Accountability Partners)

### Problem

Couples, close friends, and siblings want simple mutual accountability without the complexity of guilds (which require critical mass and ongoing community management). Existing options are:
- Solo play: no external accountability
- Micro-challenges: competitive, time-limited, not ongoing
- Guilds (future): require 3+ members, leadership, complex social dynamics

The missing middle: **persistent, intimate, 1:1 accountability** that's always-on and low-friction.

### Solution

A single accountability buddy — linked via share code. Each user sees only their buddy's daily completion status (checkmark or X for each habit slot, without revealing habit names or details). When both complete all habits on the same day, they earn a shared "Forge Bond" bonus.

**Design principles:**
- Intimate, not social: 1 buddy maximum
- Private: completion status only, no habit details
- Low-pressure: visibility creates gentle accountability, not judgment
- Rewarding: shared bonus for mutual completion

### User Flow

```
LINKING FLOW:
1. Profile → "Add Accountability Buddy"
2. Two options:
   a) "Share my code" → generates 6-char code (valid 24h) → share via any channel
   b) "Enter a code" → input field → validates → confirms buddy name
3. Both users see confirmation: "🤝 Forge Bond established with [name]"
4. Buddy widget appears on home screen

DAILY EXPERIENCE:
1. Home screen shows small buddy avatar in corner
2. Avatar states:
   - Grey circle: buddy hasn't completed anything today
   - Partial checkmarks: buddy completed some habits (shows ✓✓✗✗ pattern)
   - Green glow + full checkmarks: buddy completed everything
3. Tapping avatar shows expanded buddy card with today's pattern
4. No messaging, no chat, no additional social features

FORGE BOND BONUS:
1. Both users complete ALL their habits on the same calendar day
2. Both receive: +5 XP bonus + "Forge Bond" streak increments
3. Streak display: "🤝 Forge Bond: 12 days" (mutual completion streak)
4. If either misses a day: Forge Bond streak resets to 0

UNLINKING:
1. Profile → Buddy section → "Remove Buddy"
2. Confirmation dialog: "This will end your Forge Bond streak. Continue?"
3. Both users notified: "Your Forge Bond with [name] has ended."
4. 24h cooldown before linking a new buddy (prevents rapid cycling)
```

### Implementation Details

**Database schema:**
```sql
-- Supabase table: buddy_pairs
CREATE TABLE buddy_pairs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_a_id UUID NOT NULL REFERENCES profiles(id),
    user_b_id UUID NOT NULL REFERENCES profiles(id),
    status VARCHAR(15) NOT NULL DEFAULT 'active',
        -- active: currently paired
        -- dissolved: one user removed the bond
    forge_bond_streak INT NOT NULL DEFAULT 0,
    longest_forge_bond INT NOT NULL DEFAULT 0,
    linked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    dissolved_at TIMESTAMPTZ,
    
    -- Prevent duplicate pairs
    CONSTRAINT unique_buddy_pair UNIQUE (user_a_id, user_b_id),
    -- Prevent self-pairing
    CONSTRAINT no_self_buddy CHECK (user_a_id != user_b_id)
);

-- Ensure a user can only have 1 active buddy
CREATE UNIQUE INDEX idx_buddy_active_a ON buddy_pairs(user_a_id) WHERE status = 'active';
CREATE UNIQUE INDEX idx_buddy_active_b ON buddy_pairs(user_b_id) WHERE status = 'active';

-- Buddy invite codes (ephemeral)
CREATE TABLE buddy_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id),
    code VARCHAR(6) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '24 hours',
    used BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_buddy_invites_code ON buddy_invites(code) WHERE NOT used;
```

**Privacy-safe completion sharing:**
```swift
/// What the buddy sees — deliberately minimal
struct BuddyCompletionStatus {
    let date: Date
    let totalHabits: Int          // e.g., 4
    let completedCount: Int       // e.g., 3
    let pattern: [Bool]           // e.g., [true, true, true, false]
    // NOTE: No habit names, no categories, no details
    
    var isFullyComplete: Bool { completedCount == totalHabits }
}

/// Fetches buddy's status — server-side function ensures privacy
// Supabase RPC: get_buddy_status(buddy_pair_id, date)
// Returns only: { total_habits: 4, completed_count: 3, pattern: [true, true, true, false] }
// Never exposes: habit names, completion times, XP earned, or other details
```

**Forge Bond calculation (nightly cron):**
```sql
-- Run daily at midnight UTC
CREATE OR REPLACE FUNCTION calculate_forge_bonds()
RETURNS void AS $$
DECLARE
    pair RECORD;
    a_complete BOOLEAN;
    b_complete BOOLEAN;
    yesterday DATE := CURRENT_DATE - 1;
BEGIN
    FOR pair IN SELECT * FROM buddy_pairs WHERE status = 'active'
    LOOP
        -- Check if user_a completed all habits yesterday
        SELECT (COUNT(*) FILTER (WHERE completed = true) = COUNT(*)) INTO a_complete
        FROM user_habits
        LEFT JOIN habit_completions ON user_habits.id = habit_completions.habit_id
            AND habit_completions.completed_date = yesterday
        WHERE user_habits.user_id = pair.user_a_id
            AND user_habits.is_active = true;
        
        -- Check if user_b completed all habits yesterday
        SELECT (COUNT(*) FILTER (WHERE completed = true) = COUNT(*)) INTO b_complete
        FROM user_habits
        LEFT JOIN habit_completions ON user_habits.id = habit_completions.habit_id
            AND habit_completions.completed_date = yesterday
        WHERE user_habits.user_id = pair.user_b_id
            AND user_habits.is_active = true;
        
        IF a_complete AND b_complete THEN
            -- Both completed: increment streak
            UPDATE buddy_pairs
            SET forge_bond_streak = forge_bond_streak + 1,
                longest_forge_bond = GREATEST(longest_forge_bond, forge_bond_streak + 1)
            WHERE id = pair.id;
            
            -- Grant XP bonus to both
            PERFORM grant_xp(pair.user_a_id, 5, 'forge_bond');
            PERFORM grant_xp(pair.user_b_id, 5, 'forge_bond');
        ELSE
            -- Streak broken
            UPDATE buddy_pairs SET forge_bond_streak = 0 WHERE id = pair.id;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
```

**SwiftUI Buddy Widget (Home Screen):**
```swift
struct BuddyWidget: View {
    @ObservedObject var buddyVM: BuddyViewModel
    @State private var showExpanded = false
    
    var body: some View {
        Button(action: { showExpanded = true }) {
            ZStack {
                // Avatar circle
                Circle()
                    .fill(buddyVM.status.isFullyComplete ? Color.green.opacity(0.3) : Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                // Avatar image or initials
                if let avatar = buddyVM.buddyAvatar {
                    Image(uiImage: avatar)
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: 40, height: 40)
                } else {
                    Text(buddyVM.buddyInitials)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                // Completion indicator dots
                HStack(spacing: 2) {
                    ForEach(0..<buddyVM.status.totalHabits, id: \.self) { i in
                        Circle()
                            .fill(buddyVM.status.pattern[i] ? Color.green : Color.gray.opacity(0.4))
                            .frame(width: 5, height: 5)
                    }
                }
                .offset(y: 24)
            }
        }
        .sheet(isPresented: $showExpanded) {
            BuddyDetailCard(status: buddyVM.status, bondStreak: buddyVM.forgeBondStreak)
        }
    }
}

struct BuddyDetailCard: View {
    let status: BuddyCompletionStatus
    let bondStreak: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Your Buddy's Progress")
                .font(.headline)
            
            // Habit completion pattern (no names!)
            HStack(spacing: 12) {
                ForEach(0..<status.totalHabits, id: \.self) { i in
                    Image(systemName: status.pattern[i] ? "checkmark.circle.fill" : "xmark.circle")
                        .font(.title2)
                        .foregroundColor(status.pattern[i] ? .green : .gray)
                }
            }
            
            Text("\(status.completedCount)/\(status.totalHabits) completed today")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            // Forge Bond streak
            HStack {
                Text("🤝")
                Text("Forge Bond Streak: \(bondStreak) days")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .presentationDetents([.height(250)])
    }
}
```

### Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Buddy pairing rate | ≥15% of users pair within 14 days | Users with active buddy / total users at D14 |
| Forge Bond activation rate | ≥60% of pairs trigger bond ≥1 time | Pairs with ≥1 mutual day / total active pairs |
| Avg Forge Bond streak | ≥5 days | Mean streak length across active pairs |
| Retention lift for paired users | +20% D30 retention | D30 retention of paired vs unpaired users |
| Habit completion lift | +10% daily completions | Avg completions for paired vs unpaired users |
| Dissolution rate | <15% within 30 days | Pairs dissolved within 30 days / pairs created |
| Buddy-driven installs | Track via invite code | New installs attributed to buddy invite codes |

### A/B Test Plan

- **Control**: No buddy feature
- **Variant**: Buddy system enabled with Forge Bond bonus
- **Metrics**: D14/D30 retention, daily completion rate, organic installs
- **Duration**: 30 days, 500 users per cohort (paired users only counted in variant metrics)
- **Hypothesis**: Paired users show ≥20% higher D30 retention than unpaired users

---

## 5. User-Generated Content Pipeline

### Problem

RNF currently relies entirely on developer-curated content (quotes, challenge templates, boss encounters). This creates:
- Content staleness: users see repeated quotes/challenges
- Scaling bottleneck: dev team must write all motivational content
- Missed engagement: experienced users have no way to contribute back
- Community gap: no sense of shared ownership or co-creation

### Solution

A structured pipeline allowing experienced users to submit content (quotes and challenge templates) that flows through AI pre-filtering and human moderation before going live. Contributors are rewarded with Forge Tokens and exclusive badges.

**Content types:**
| Type | Unlock Level | Description |
|------|-------------|-------------|
| Quote submissions | Level 10+ | Motivational quotes for the daily quote pool |
| Custom 7-day challenges | Level 15+ | Challenge templates other users can adopt |

**Content pipeline states:**
```
submitted → ai_review → human_approved → live
              ↓                ↓
          ai_rejected     human_rejected
```

### User Flow

```
QUOTE SUBMISSION:
1. Level 10+ user unlocks "Sage's Quill" feature in Profile
2. Profile → "Submit a Quote" → text input (max 200 chars) + optional attribution
3. Preview card shows how the quote will look in the daily feed
4. Submit → confirmation: "Your quote is under review. You'll be notified when it goes live!"
5. AI pre-filter runs immediately (profanity, spam, plagiarism check)
6. If AI passes → enters human review queue
7. Human approves → quote goes live + user receives 10 Forge Tokens + "Sage" badge
8. Human rejects → user notified with reason: "Too similar to existing quote" / "Doesn't meet guidelines"

CHALLENGE TEMPLATE SUBMISSION:
1. Level 15+ user unlocks "Forge Master" feature
2. Profile → "Create a Challenge" → template builder:
   - Title (max 50 chars)
   - Description (max 200 chars)
   - Duration: 7 days (fixed for user-created)
   - Daily habit suggestions (3-5 habits, text descriptions)
   - Difficulty: Easy / Medium / Hard
   - Category: Fitness / Mindfulness / Productivity / Social / Creative
3. Preview → Submit → same pipeline as quotes
4. Approved → appears in "Community Challenges" section
5. Reward: 20 Forge Tokens + "Forge Master" badge

USER VIEWING SUBMITTED CONTENT:
1. Profile → "My Submissions" shows all submitted content with status
2. Status badges: 🟡 Pending | 🟢 Approved | 🔴 Rejected
3. Rejected items show reason + "Edit & Resubmit" option (max 2 resubmits)
```

### Implementation Details

**Database schema:**
```sql
-- Supabase table: content_submissions
CREATE TABLE content_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id),
    content_type VARCHAR(20) NOT NULL,
        -- 'quote', 'challenge_template'
    title VARCHAR(50),          -- for challenges
    body TEXT NOT NULL,          -- quote text or challenge description
    metadata JSONB,             -- additional structured data (habits list, difficulty, category)
    status VARCHAR(20) NOT NULL DEFAULT 'submitted',
        -- submitted: just created
        -- ai_review: being processed by AI
        -- ai_approved: passed AI, waiting for human
        -- ai_rejected: AI rejected (auto-decline)
        -- human_approved: live
        -- human_rejected: manually rejected
    ai_review_result JSONB,     -- AI scores and flags
    rejection_reason TEXT,       -- shown to user if rejected
    reviewer_id UUID REFERENCES profiles(id),  -- admin who reviewed
    reviewed_at TIMESTAMPTZ,
    resubmit_count INT NOT NULL DEFAULT 0,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT valid_content_type CHECK (content_type IN ('quote', 'challenge_template')),
    CONSTRAINT valid_content_status CHECK (
        status IN ('submitted', 'ai_review', 'ai_approved', 'ai_rejected', 'human_approved', 'human_rejected')
    ),
    CONSTRAINT max_resubmits CHECK (resubmit_count <= 2)
);

-- Indexes
CREATE INDEX idx_submissions_user ON content_submissions(user_id, status);
CREATE INDEX idx_submissions_review_queue ON content_submissions(status, created_at) 
    WHERE status = 'ai_approved';
CREATE INDEX idx_submissions_live ON content_submissions(content_type, published_at) 
    WHERE status = 'human_approved';

-- Community quotes pool (approved quotes join this view)
CREATE VIEW live_quotes AS
SELECT id, body AS quote_text, user_id AS author_id, published_at
FROM content_submissions
WHERE content_type = 'quote' AND status = 'human_approved'
ORDER BY published_at DESC;

-- Community challenges pool
CREATE VIEW live_community_challenges AS
SELECT id, title, body AS description, metadata, user_id AS creator_id, published_at
FROM content_submissions
WHERE content_type = 'challenge_template' AND status = 'human_approved'
ORDER BY published_at DESC;
```

**AI pre-filter (Supabase Edge Function):**
```typescript
// supabase/functions/ai-content-review/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

interface ReviewResult {
    approved: boolean;
    scores: {
        profanity: number;      // 0-1, threshold: 0.3
        spam: number;           // 0-1, threshold: 0.4
        toxicity: number;       // 0-1, threshold: 0.2
        relevance: number;      // 0-1, threshold: 0.5 (must be above)
        plagiarism: number;     // 0-1, threshold: 0.8 (similarity to existing)
    };
    flags: string[];
    reason?: string;
}

serve(async (req) => {
    const { submission_id, content_type, body, title } = await req.json();
    const supabase = createClient(/* ... */);
    
    // Update status to ai_review
    await supabase.from("content_submissions")
        .update({ status: "ai_review" })
        .eq("id", submission_id);
    
    // Run checks
    const scores = {
        profanity: await checkProfanity(body),
        spam: await checkSpam(body),
        toxicity: await checkToxicity(body),
        relevance: await checkRelevance(body, content_type),
        plagiarism: await checkPlagiarism(body, content_type)
    };
    
    const flags: string[] = [];
    if (scores.profanity > 0.3) flags.push("profanity");
    if (scores.spam > 0.4) flags.push("spam");
    if (scores.toxicity > 0.2) flags.push("toxicity");
    if (scores.relevance < 0.5) flags.push("low_relevance");
    if (scores.plagiarism > 0.8) flags.push("plagiarism");
    
    const approved = flags.length === 0;
    const result: ReviewResult = {
        approved,
        scores,
        flags,
        reason: flags.length > 0 ? `Flagged for: ${flags.join(", ")}` : undefined
    };
    
    // Update submission with result
    await supabase.from("content_submissions").update({
        status: approved ? "ai_approved" : "ai_rejected",
        ai_review_result: result,
        rejection_reason: result.reason
    }).eq("id", submission_id);
    
    // If AI-rejected, notify user
    if (!approved) {
        await sendPushNotification(/* user_id */, {
            title: "Submission Update",
            body: "Your submission didn't pass our content guidelines. Tap to see details."
        });
    }
    
    return new Response(JSON.stringify(result), { status: 200 });
});

// Simple keyword-based profanity check (supplement with ML model later)
async function checkProfanity(text: string): Promise<number> {
    const keywords = await loadProfanityList(); // from Supabase storage
    const normalized = text.toLowerCase();
    const matches = keywords.filter(k => normalized.includes(k));
    return Math.min(matches.length / 3, 1.0); // 3+ matches = definite flag
}

// Similarity check against existing approved content
async function checkPlagiarism(text: string, type: string): Promise<number> {
    // Use embedding similarity against existing approved content
    // Returns highest cosine similarity score
    const embedding = await generateEmbedding(text);
    const { data: similar } = await supabase.rpc("match_similar_content", {
        query_embedding: embedding,
        content_type: type,
        match_threshold: 0.7,
        match_count: 1
    });
    return similar?.[0]?.similarity ?? 0;
}
```

**Admin review interface (lightweight — via Supabase Dashboard custom view):**
```sql
-- View for admin review queue
CREATE VIEW admin_review_queue AS
SELECT 
    cs.id,
    cs.content_type,
    cs.title,
    cs.body,
    cs.metadata,
    cs.ai_review_result,
    cs.created_at,
    cs.resubmit_count,
    p.display_name AS submitter_name,
    p.level AS submitter_level
FROM content_submissions cs
JOIN profiles p ON cs.user_id = p.id
WHERE cs.status = 'ai_approved'
ORDER BY cs.created_at ASC;
```

**Reward distribution on approval:**
```sql
-- Trigger on status change to 'human_approved'
CREATE OR REPLACE FUNCTION reward_content_creator()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'human_approved' AND OLD.status != 'human_approved' THEN
        -- Grant tokens
        IF NEW.content_type = 'quote' THEN
            PERFORM increment_forge_tokens(NEW.user_id, 10);
            -- Grant Sage badge if first approved quote
            INSERT INTO user_badges (user_id, badge_type)
            VALUES (NEW.user_id, 'sage')
            ON CONFLICT (user_id, badge_type) DO NOTHING;
        ELSIF NEW.content_type = 'challenge_template' THEN
            PERFORM increment_forge_tokens(NEW.user_id, 20);
            INSERT INTO user_badges (user_id, badge_type)
            VALUES (NEW.user_id, 'forge_master')
            ON CONFLICT (user_id, badge_type) DO NOTHING;
        END IF;
        
        -- Set published timestamp
        NEW.published_at := NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_reward_content_creator
BEFORE UPDATE ON content_submissions
FOR EACH ROW
EXECUTE FUNCTION reward_content_creator();
```

### Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Submission rate | ≥5% of eligible users/month | Users submitting / users at required level |
| AI approval rate | 70-80% | AI-approved / total submissions |
| Human approval rate | ≥85% of AI-approved | Human-approved / AI-approved |
| End-to-end approval rate | ≥60% | Published / total submissions |
| Time to review | <48h median | Median time from ai_approved to human decision |
| Content staleness reduction | -50% repeat views | Users seeing same quote twice / total quote views |
| Contributor retention lift | +15% D30 | D30 retention of contributors vs non-contributors |
| Resubmission rate | <30% of rejected | Users who resubmit after rejection |

### A/B Test Plan

- **Control**: Developer-curated content only
- **Variant**: Mix of developer + community content (25% community)
- **Metrics**: Quote engagement (tap to dismiss time), challenge adoption rate, overall retention
- **Duration**: 30 days
- **Hypothesis**: Community content increases quote engagement time by ≥10%

---

## 6. App Store Optimization (ASO)

### Problem

Without deliberate ASO strategy, RNF will be invisible in App Store search results for high-intent keywords. The habit tracker and RPG categories are competitive, and organic discovery depends on:
- Keyword relevance in title/subtitle
- Screenshot conversion rate
- Description quality
- Category placement
- Custom product pages for different audience segments

### Solution

A comprehensive ASO strategy targeting three audience segments (gamers, wellness seekers, fitness enthusiasts) with optimized metadata, screenshots, and custom product pages.

### App Store Metadata

**Title:** `RNF: Rise and Forge — Habit RPG`
- 30 chars max constraint met ✓ (29 chars)
- Contains primary keywords: "Habit RPG"
- Brand name leads for recognition

**Subtitle:** `Level up your real life`
- 30 chars max constraint met ✓ (22 chars)
- Aspirational hook, unique positioning
- Contains implicit keyword: "level up"

**Primary keywords (100 char field):**
```
habit tracker RPG,discipline app,self improvement game,daily habits,streak tracker,routine builder
```
(97 characters — within 100 char limit)

**Category:** Health & Fitness (primary), Games > Role Playing (secondary)

**Description structure:**
```
[HOOK - first 3 lines visible before "more"]
Transform your daily habits into an epic RPG adventure. Every habit you complete
earns XP, builds streaks, and levels up your character. Miss a day? Face the
consequences. Stay disciplined? Forge an unstoppable version of yourself.

[USP]
Rise and Forge isn't another habit checklist. It's a 90-day discipline challenge
wrapped in deep RPG mechanics — XP, skill trees, boss battles, evolution tiers,
and a final Discipline Card that proves you conquered the challenge.

[FEATURES]
🔥 STREAK SYSTEM — Build fire streaks from Ember (7 days) to Inferno (60+ days)
⚔️ BOSS BATTLES — Face discipline challenges that test your consistency
🌳 SKILL TREE — Unlock abilities as you level up through real-life habits
🏆 DISCIPLINE CARD — Earn your unique achievement card after 90 days
👥 BUDDY SYSTEM — Pair with a friend for mutual accountability
📊 PROGRESS TRACKING — XP, levels, streaks, and evolution tiers

[SOCIAL PROOF]
Join thousands forging better versions of themselves. Share milestone cards,
challenge friends, and prove that discipline is the ultimate superpower.

[CTA]
Download now. Light your first ember. Begin the forge.
```

### Screenshot Strategy

**Order (priority for conversion):**
| Position | Content | Hook Text Overlay |
|----------|---------|-------------------|
| 1 | XP animation on habit completion | "Every habit earns XP" |
| 2 | Streak fire visualization (7→14→30) | "Build unstoppable streaks" |
| 3 | Skill tree with unlocked abilities | "Unlock your potential" |
| 4 | Boss battle encounter screen | "Face your challenges" |
| 5 | Discipline Card (Day 90 reward) | "Earn your Discipline Card" |
| 6 | Evolution tier progression | "Evolve from Ember to Inferno" |

**Design specs:**
- Device frame: iPhone 15 Pro (latest flagship)
- Background: Dark gradient matching app theme
- Text: 2 lines max, above device frame, 60pt bold
- Aspect ratio: 6.7" display format (1290×2796)
- Localization: English (US) primary, expand later

### Custom Product Pages

Apple allows up to 35 custom product pages with different screenshots/promotional text, each with a unique URL for targeted ad campaigns and organic channels.

**Page 1: Gamer Audience (RPG Focus)**
- URL: `apps.apple.com/app/rnf/id_PLACEHOLDER?ppid=gamer`
- Screenshots emphasize: Boss battles, skill tree, XP system, evolution tiers
- Promotional text: "The RPG where YOUR habits are the gameplay"
- Target: Reddit r/RPG, gaming Discord servers, RPG YouTube channels

**Page 2: Wellness Audience (Habits Focus)**
- URL: `apps.apple.com/app/rnf/id_PLACEHOLDER?ppid=wellness`
- Screenshots emphasize: Streak tracking, daily routine, progress stats, buddy system
- Promotional text: "Build lasting habits with game-powered motivation"
- Target: Wellness blogs, mindfulness communities, productivity podcasts

**Page 3: Fitness Audience (Workout Focus)**
- URL: `apps.apple.com/app/rnf/id_PLACEHOLDER?ppid=fitness`
- Screenshots emphasize: Physical habit tracking, streak consistency, challenge system
- Promotional text: "Gamify your fitness routine. Never skip a day again."
- Target: Fitness subreddits, gym communities, workout influencers

### Implementation Details

**App Store Connect configuration checklist:**
```
□ Title: "RNF: Rise and Forge — Habit RPG"
□ Subtitle: "Level up your real life"
□ Keywords: habit tracker RPG,discipline app,self improvement game,daily habits,streak tracker,routine builder
□ Primary category: Health & Fitness
□ Secondary category: Games > Role Playing
□ Description: [structured as above]
□ Promotional text: Updated monthly with seasonal hooks
□ Screenshots: 6 screens per device size (6.7", 6.1", iPad)
□ App preview video: 30s showing habit completion → XP → level up → streak
□ Custom product pages: 3 (gamer, wellness, fitness)
□ Privacy policy URL: configured
□ Support URL: configured
□ Age rating: 4+ (no objectionable content)
```

**ASO monitoring cadence:**
- Weekly: keyword ranking check for primary 5 keywords
- Bi-weekly: screenshot A/B test rotation (App Store Connect built-in)
- Monthly: promotional text refresh
- Quarterly: full keyword audit and competitor analysis
- Per release: update "What's New" with engaging changelog

**UTM tracking for custom product pages:**
```swift
// Track which product page converted the user
func trackInstallSource() {
    // Apple's SKAdNetwork provides campaign attribution
    // Custom product page ID available via App Store receipt
    if let productPageId = AppStore.installProductPageId {
        Analytics.track("install_source", properties: [
            "product_page": productPageId,
            "audience_segment": mapPageToSegment(productPageId)
        ])
    }
}
```

### Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Impression-to-install conversion | ≥8% | App Store Connect analytics |
| Product page view-to-install | ≥35% | For users who open full listing |
| Keyword ranking (primary 5) | Top 10 for ≥3 keywords | ASO tool tracking (AppFollow/Sensor Tower) |
| Search vs Browse installs | ≥40% from search | App Store Connect source breakdown |
| Custom product page lift | +20% vs default | A/B conversion comparison per page |
| Screenshot scroll depth | ≥4 screenshots viewed avg | App Store Connect analytics |
| App preview video play rate | ≥15% of page views | Video engagement tracking |

### A/B Test Plan (App Store Connect Native)

- **Test 1**: Screenshot order — XP animation first vs. Boss battle first
- **Test 2**: Subtitle — "Level up your real life" vs. "Discipline through gaming"
- **Test 3**: Icon — Flame icon vs. Anvil icon vs. Shield icon
- **Duration**: 7 days per test (Apple minimum for statistical significance)
- **Traffic split**: 50/50 for each test

---

## 7. Content Moderation System

### Problem

As RNF introduces social features (guilds, buddy system, micro-challenges, UGC pipeline), user-generated text surfaces throughout the app. Without moderation:
- Offensive guild names / display names damage brand perception
- Toxic content in shared challenges drives away users
- Inappropriate user-submitted quotes could appear in others' daily feeds
- Legal liability for hosting unmoderated user content
- App Store review risk (Apple requires moderation for UGC)

Apple App Store Review Guideline 1.2: "Apps with user-generated content must include a method for filtering objectionable material, a mechanism for users to report offensive content, and the ability to block abusive users."

### Solution

A multi-layered moderation system with client-side pre-filtering, server-side AI classification, user reporting, blocking, and admin escalation workflows.

**Content requiring moderation:**
| Content Type | Where It Appears | Risk Level |
|-------------|-----------------|------------|
| Display names | Everywhere (buddy, challenges, leaderboards) | High |
| Guild names | Guild listings, challenge cards | High |
| Guild descriptions | Guild detail pages | Medium |
| Social challenge titles | Challenge invites, comparison cards | Medium |
| User-submitted quotes | Daily quote feed for all users | Critical |
| Custom challenge templates | Community challenge listings | High |

### User Flow

```
CONTENT CREATION (with moderation):
1. User types content (guild name, display name, quote, etc.)
2. Client-side: real-time keyword filter blocks submission if profanity detected
3. If blocked: inline error "This content contains inappropriate language. Please revise."
4. If passed client filter: submit to server
5. Server-side: Supabase edge function runs text classification
6. If server rejects: user sees "Content doesn't meet community guidelines"
7. If server approves: content goes live (or enters human review queue for quotes)

REPORTING FLOW:
1. User long-presses on any UGC element
2. Context menu shows: "Report Content"
3. Tap → reason selection: Offensive / Spam / Harassment / Inappropriate / Other
4. Optional: text field for additional context
5. Submit → confirmation: "Report submitted. We'll review within 24 hours."
6. Reported content is immediately hidden from the reporter
7. If 3+ unique reports: content auto-hidden pending review

BLOCKING FLOW:
1. User navigates to offending user's mini-profile (via challenge card, buddy, guild)
2. Profile → "Block User"
3. Confirmation: "Block [name]? You won't see their content or receive challenges from them."
4. Blocked user's content hidden from blocker across all surfaces
5. Blocked user cannot send challenges/buddy requests to blocker
6. Block list manageable in Settings → Blocked Users

ADMIN ESCALATION:
1. Auto-hidden content (3+ reports) enters admin review queue
2. Admin sees: content, reporter reasons, user history, AI scores
3. Actions: Approve (reinstate) / Remove (confirm violation) / Ban user
4. Violation recorded on user's moderation history
5. Automated consequences based on violation count
```

### Implementation Details

**Client-side profanity filter:**
```swift
// ProfanityFilter.swift
class ProfanityFilter {
    private let keywords: Set<String>
    private let patterns: [NSRegularExpression]
    
    init() {
        // Load from bundled JSON (updated with app releases)
        guard let url = Bundle.main.url(forResource: "profanity_list", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let words = try? JSONDecoder().decode([String].self, from: data) else {
            self.keywords = []
            self.patterns = []
            return
        }
        self.keywords = Set(words.map { $0.lowercased() })
        
        // Common obfuscation patterns (l33t speak, character substitution)
        self.patterns = [
            try! NSRegularExpression(pattern: "[a@][s$][s$]", options: .caseInsensitive),
            try! NSRegularExpression(pattern: "f[u\\*][c\\*k]", options: .caseInsensitive),
            // ... additional patterns
        ]
    }
    
    func containsProfanity(_ text: String) -> Bool {
        let normalized = text.lowercased()
            .replacingOccurrences(of: "0", with: "o")
            .replacingOccurrences(of: "1", with: "i")
            .replacingOccurrences(of: "3", with: "e")
            .replacingOccurrences(of: "@", with: "a")
            .replacingOccurrences(of: "$", with: "s")
        
        // Keyword check
        let words = normalized.components(separatedBy: .whitespacesAndNewlines)
        for word in words {
            if keywords.contains(word) { return true }
        }
        
        // Pattern check
        for pattern in patterns {
            if pattern.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)) != nil {
                return true
            }
        }
        
        return false
    }
    
    /// Returns filtered version (asterisks) for display
    func sanitize(_ text: String) -> String {
        var result = text
        for keyword in keywords {
            let replacement = String(repeating: "*", count: keyword.count)
            result = result.replacingOccurrences(
                of: keyword,
                with: replacement,
                options: [.caseInsensitive]
            )
        }
        return result
    }
}

// Usage in text fields
struct ModeratedTextField: View {
    @Binding var text: String
    @State private var showProfanityWarning = false
    private let filter = ProfanityFilter()
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("Enter text...", text: $text)
                .onChange(of: text) { newValue in
                    showProfanityWarning = filter.containsProfanity(newValue)
                }
            
            if showProfanityWarning {
                Text("This content contains inappropriate language")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}
```

**Server-side moderation (Supabase Edge Function):**
```typescript
// supabase/functions/moderate-content/index.ts
interface ModerationResult {
    approved: boolean;
    confidence: number;
    categories: {
        profanity: boolean;
        harassment: boolean;
        hate_speech: boolean;
        sexual: boolean;
        violence: boolean;
        spam: boolean;
    };
    action: "approve" | "reject" | "flag_for_review";
}

serve(async (req) => {
    const { content, content_type, user_id } = await req.json();
    const supabase = createClient(/* ... */);
    
    // Check user's moderation history
    const { count: violations } = await supabase
        .from("moderation_actions")
        .select("*", { count: "exact" })
        .eq("user_id", user_id)
        .eq("action", "violation_confirmed");
    
    // If user has prior violations, apply stricter thresholds
    const strictMode = (violations ?? 0) >= 1;
    
    // Run text classification
    const result = await classifyText(content, strictMode);
    
    // Log moderation check
    await supabase.from("moderation_logs").insert({
        user_id,
        content_type,
        content_text: content,
        result: result,
        created_at: new Date().toISOString()
    });
    
    return new Response(JSON.stringify(result), {
        status: result.approved ? 200 : 422
    });
});

async function classifyText(text: string, strict: boolean): Promise<ModerationResult> {
    // Option A: Use OpenAI Moderation API (free, no token cost)
    const response = await fetch("https://api.openai.com/v1/moderations", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${Deno.env.get("OPENAI_API_KEY")}`
        },
        body: JSON.stringify({ input: text })
    });
    
    const data = await response.json();
    const scores = data.results[0].category_scores;
    const threshold = strict ? 0.3 : 0.5;
    
    const categories = {
        profanity: scores["harassment"] > threshold,
        harassment: scores["harassment/threatening"] > threshold,
        hate_speech: scores["hate"] > threshold,
        sexual: scores["sexual"] > threshold,
        violence: scores["violence"] > threshold,
        spam: false // Separate heuristic check
    };
    
    const flagged = Object.values(categories).some(v => v);
    
    return {
        approved: !flagged,
        confidence: flagged ? Math.max(...Object.values(scores)) : 1 - Math.max(...Object.values(scores)),
        categories,
        action: flagged ? "reject" : "approve"
    };
}
```

**Database schema:**
```sql
-- Content reports from users
CREATE TABLE content_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES profiles(id),
    content_type VARCHAR(30) NOT NULL,
        -- 'display_name', 'guild_name', 'guild_description', 
        -- 'challenge_title', 'quote', 'challenge_template'
    content_id UUID NOT NULL,        -- references the specific content item
    content_text TEXT,                -- snapshot of reported text (in case it's edited)
    reported_user_id UUID REFERENCES profiles(id),
    reason VARCHAR(20) NOT NULL,
        -- 'offensive', 'spam', 'harassment', 'inappropriate', 'other'
    additional_context TEXT,          -- optional user-provided detail
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
        -- 'pending', 'reviewing', 'action_taken', 'dismissed'
    reviewed_at TIMESTAMPTZ,
    reviewer_action VARCHAR(20),
        -- 'remove_content', 'warn_user', 'mute_user', 'ban_user', 'dismiss'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Prevent duplicate reports from same user on same content
    CONSTRAINT unique_report UNIQUE (reporter_id, content_type, content_id)
);

-- Indexes
CREATE INDEX idx_reports_pending ON content_reports(status, created_at) WHERE status = 'pending';
CREATE INDEX idx_reports_content ON content_reports(content_type, content_id);
CREATE INDEX idx_reports_user ON content_reports(reported_user_id);

-- Moderation actions (enforcement history)
CREATE TABLE moderation_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id),
    action VARCHAR(20) NOT NULL,
        -- 'warning', 'content_removed', 'mute_7d', 'permanent_ban'
    reason TEXT,
    related_report_id UUID REFERENCES content_reports(id),
    expires_at TIMESTAMPTZ,    -- for time-limited actions (mutes)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mod_actions_user ON moderation_actions(user_id, created_at);

-- User blocks
CREATE TABLE user_blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id UUID NOT NULL REFERENCES profiles(id),
    blocked_id UUID NOT NULL REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT unique_block UNIQUE (blocker_id, blocked_id),
    CONSTRAINT no_self_block CHECK (blocker_id != blocked_id)
);

CREATE INDEX idx_blocks_blocker ON user_blocks(blocker_id);
CREATE INDEX idx_blocks_blocked ON user_blocks(blocked_id);

-- Auto-hide trigger: when content gets 3+ reports
CREATE OR REPLACE FUNCTION auto_hide_reported_content()
RETURNS TRIGGER AS $$
DECLARE
    report_count INT;
BEGIN
    SELECT COUNT(*) INTO report_count
    FROM content_reports
    WHERE content_type = NEW.content_type
    AND content_id = NEW.content_id;
    
    IF report_count >= 3 THEN
        -- Auto-hide the content (implementation depends on content type)
        PERFORM hide_content(NEW.content_type, NEW.content_id);
        
        -- Escalate to admin queue
        UPDATE content_reports
        SET status = 'reviewing'
        WHERE content_type = NEW.content_type
        AND content_id = NEW.content_id
        AND status = 'pending';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_hide_content
AFTER INSERT ON content_reports
FOR EACH ROW
EXECUTE FUNCTION auto_hide_reported_content();
```

**Escalation rules:**
```
Violation count → Consequence:
  1st violation  → Content removed + warning notification
  2nd violation  → 7-day mute (cannot create UGC, send challenges, update display name)
  3rd violation  → Permanent ban from all social features (app still works solo)
  
Mute check:
  Before any UGC creation, check:
  SELECT EXISTS (
      FROM moderation_actions
      WHERE user_id = $1
      AND action IN ('mute_7d', 'permanent_ban')
      AND (expires_at IS NULL OR expires_at > NOW())
  );
```

### Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Client-side block rate | <5% of submissions | Submissions blocked by client filter / total attempts |
| Server-side rejection rate | <3% of server-submitted | Server rejections / submissions passing client filter |
| False positive rate | <1% | Legitimate content incorrectly blocked (sampled manually) |
| Report volume | <0.1% of content views | Reports submitted / total UGC impressions |
| Report-to-action time | <24h median | Median time from report to admin decision |
| Auto-hide accuracy | ≥90% confirmed | Auto-hidden content later confirmed as violation / total auto-hides |
| User block rate | <2% of social users | Users who block ≥1 person / users with social features |
| App Store compliance | 0 rejections | Apple review rejections for moderation issues |

### A/B Test Plan

Not applicable — moderation is a compliance requirement, not an optimization feature. Ship with launch of any social feature. Monitor false positive rate and adjust thresholds based on manual review of edge cases.

---

## 8. Notification-Driven Re-Engagement

### Problem

Users who miss a single day often don't return — the streak is broken, loss aversion reverses into avoidance ("I already failed"), and without a re-engagement nudge, the app fades into the notification graveyard.

Current state: No intelligent notification system. Users receive no contextual reminders tied to their specific progress or risk state.

### Solution

A personalized notification system that sends the right message at the right time based on user behavior patterns. Notifications fall into five categories, each with specific triggers, timing rules, and copy frameworks.

**Notification categories:**

| Category | Trigger | Timing | Urgency |
|----------|---------|--------|---------|
| Streak-at-risk | 0 completions today, streak ≥ 3 | 8 PM local (or 4h before historical bedtime) | High |
| Milestone celebration | User hits milestone threshold | Immediately on achievement | Medium |
| Friend activity | Buddy completes all habits | Within 30 min of buddy completion | Low |
| Comeback | 3+ days inactive | Day 3 at 9 AM local | Medium |
| Challenge progress | Specific day milestones (25%, 50%, 75%) | 9 AM on milestone day | Low |

### User Flow

```
STREAK-AT-RISK:
1. System checks at user's risk-notification time (default 8 PM, adjustable)
2. If completions today = 0 AND current streak ≥ 3:
   → Send: "Your [X]-day streak ends in [Y] hours. One habit keeps it alive. 🔥"
3. User taps notification → opens app directly to habit list
4. Deep link: rnf://habits (goes straight to today's habits)

MILESTONE CELEBRATION:
1. User completes habit → milestone detected (streak 7/14/30, level up, boss defeat)
2. Immediate push: "🔥 [X] days! You've joined the [Tier] tier. Share your achievement?"
3. Tap → opens milestone celebration screen with share card
4. Deep link: rnf://milestone/{type}/{value}

FRIEND ACTIVITY:
1. Buddy completes all habits for the day
2. Wait 15-30 minutes (batch window to avoid instant surveillance feeling)
3. Push: "Your buddy completed all [X] habits. Your turn? 💪"
4. Tap → opens app showing buddy widget highlighted
5. Rate limit: max 1 friend activity notification per day

COMEBACK (RE-ENGAGEMENT):
1. User has been inactive for 3 consecutive days
2. Day 3: "The forge is cold but not extinguished. One habit relights it. 🔥"
3. Day 7: "Your habits miss you. Tap to restart with a clean slate."
4. Day 14: "Still there? Your forge awaits. No judgment, just progress."
5. Day 30+: silence (respect user's choice to leave)
6. Tap → opens app with "Welcome Back" flow (reduced friction, forgiveness token offer)
7. Deep link: rnf://comeback

CHALLENGE PROGRESS:
1. User is on Day 23/45/68 of 90-day challenge (25%/50%/75%)
2. 9 AM notification:
   - Day 23: "Quarter of the way there. 67 days of forging remain. ⚒️"
   - Day 45: "Day 45 of 90 — you're exactly halfway. The hardest days are behind you. 🏔️"
   - Day 68: "75% complete. The final stretch. Your Discipline Card is taking shape. 🏆"
3. Tap → opens challenge progress screen
```

### Implementation Details

**Personalized timing engine:**
```swift
// NotificationTimingEngine.swift
class NotificationTimingEngine {
    /// Calculate optimal notification time based on user's historical behavior
    func optimalReminderTime(for user: UserProfile) -> DateComponents {
        // Use user's historical completion time minus 5 minutes
        // Falls back to 8 PM if insufficient data
        
        guard let avgCompletionHour = user.averageCompletionHour,
              let avgCompletionMinute = user.averageCompletionMinute else {
            // Default: 8 PM local
            return DateComponents(hour: 20, minute: 0)
        }
        
        // Send 5 minutes before typical completion time
        var components = DateComponents()
        components.hour = avgCompletionHour
        components.minute = max(0, avgCompletionMinute - 5)
        
        // If average is before 6 PM, use 6 PM (don't send too early)
        if let hour = components.hour, hour < 18 {
            components.hour = 18
            components.minute = 0
        }
        
        return components
    }
    
    /// Schedule streak-at-risk check
    func scheduleStreakRiskNotification(for user: UserProfile) {
        let timing = optimalReminderTime(for: user)
        
        let content = UNMutableNotificationContent()
        content.title = "Streak at risk 🔥"
        content.body = "Your \(user.currentStreak)-day streak ends in \(hoursUntilMidnight()) hours. One habit keeps it alive."
        content.sound = .default
        content.userInfo = ["deep_link": "rnf://habits"]
        content.interruptionLevel = .timeSensitive
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: timing, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_risk_\(user.id)_\(Date().formatted(.iso8601.day()))",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
```

**Server-side notification orchestrator (Supabase scheduled function):**
```typescript
// supabase/functions/notification-orchestrator/index.ts
// Runs every hour via Supabase cron

interface NotificationPayload {
    user_id: string;
    category: "streak_risk" | "milestone" | "friend_activity" | "comeback" | "challenge_progress";
    title: string;
    body: string;
    deep_link: string;
    priority: "high" | "normal";
}

serve(async () => {
    const supabase = createClient(/* ... */);
    const now = new Date();
    const currentHour = now.getUTCHours();
    
    // --- STREAK-AT-RISK ---
    // Find users whose local time is their notification hour + have 0 completions today
    const { data: atRiskUsers } = await supabase.rpc("get_streak_at_risk_users", {
        current_utc_hour: currentHour
    });
    
    for (const user of atRiskUsers ?? []) {
        await sendNotification({
            user_id: user.id,
            category: "streak_risk",
            title: "Streak at risk 🔥",
            body: `Your ${user.current_streak}-day streak ends in ${user.hours_remaining} hours. One habit keeps it alive.`,
            deep_link: "rnf://habits",
            priority: "high"
        });
    }
    
    // --- COMEBACK ---
    // Find users inactive for exactly 3 days
    const { data: comebackUsers } = await supabase.rpc("get_comeback_users", {
        inactive_days: 3
    });
    
    for (const user of comebackUsers ?? []) {
        await sendNotification({
            user_id: user.id,
            category: "comeback",
            title: "The forge awaits 🔥",
            body: "The forge is cold but not extinguished. One habit relights it.",
            deep_link: "rnf://comeback",
            priority: "normal"
        });
    }
    
    // --- CHALLENGE PROGRESS ---
    const milestonePercents = [25, 50, 75];
    for (const pct of milestonePercents) {
        const targetDay = Math.floor(90 * (pct / 100));
        const { data: milestoneUsers } = await supabase
            .from("user_challenges")
            .select("user_id, current_day")
            .eq("current_day", targetDay)
            .eq("status", "active");
        
        for (const user of milestoneUsers ?? []) {
            const messages: Record<number, string> = {
                25: "Quarter of the way there. 67 days of forging remain. ⚒️",
                50: "Day 45 of 90 — you're exactly halfway. The hardest days are behind you. 🏔️",
                75: "75% complete. The final stretch. Your Discipline Card is taking shape. 🏆"
            };
            
            await sendNotification({
                user_id: user.user_id,
                category: "challenge_progress",
                title: `${pct}% Complete`,
                body: messages[pct],
                deep_link: "rnf://challenge/progress",
                priority: "normal"
            });
        }
    }
});

// SQL function for streak-at-risk detection
/*
CREATE OR REPLACE FUNCTION get_streak_at_risk_users(current_utc_hour INT)
RETURNS TABLE (id UUID, current_streak INT, hours_remaining INT, notification_hour INT) AS $$
    SELECT 
        p.id,
        p.current_streak,
        (24 - EXTRACT(HOUR FROM NOW() AT TIME ZONE p.timezone))::INT as hours_remaining,
        COALESCE(p.notification_hour, 20) as notification_hour
    FROM profiles p
    WHERE p.current_streak >= 3
    AND NOT EXISTS (
        SELECT 1 FROM habit_completions hc
        WHERE hc.user_id = p.id
        AND hc.completed_date = CURRENT_DATE
    )
    AND EXTRACT(HOUR FROM NOW() AT TIME ZONE COALESCE(p.timezone, 'UTC')) = COALESCE(p.notification_hour, 20)
    AND p.notifications_enabled = true;
$$ LANGUAGE sql STABLE;
*/
```

**Notification copy framework:**
```swift
// NotificationCopyEngine.swift
enum NotificationTemplate {
    case streakAtRisk(streak: Int, hoursRemaining: Int)
    case milestoneCelebration(type: MilestoneType)
    case friendActivity(buddyName: String, habitCount: Int)
    case comeback(daysAway: Int)
    case challengeProgress(currentDay: Int, totalDays: Int)
    
    var title: String {
        switch self {
        case .streakAtRisk: return "Streak at risk 🔥"
        case .milestoneCelebration: return "Achievement Unlocked! 🏆"
        case .friendActivity: return "Buddy Update 💪"
        case .comeback: return "The forge awaits 🔥"
        case .challengeProgress: return "Challenge Update ⚒️"
        }
    }
    
    var body: String {
        switch self {
        case .streakAtRisk(let streak, let hours):
            return "Your \(streak)-day streak ends in \(hours) hours. One habit keeps it alive."
            
        case .milestoneCelebration(let type):
            switch type {
            case .streak(30): return "🔥 30 days! You've joined the Blaze tier. Share your achievement?"
            case .streak(14): return "🔥 14-day streak! Flame Bearer status unlocked."
            case .level(let l): return "Level \(l) reached! New abilities await in your skill tree."
            default: return "New milestone reached! Tap to celebrate."
            }
            
        case .friendActivity(let name, let count):
            return "Your buddy \(name) completed all \(count) habits. Your turn?"
            
        case .comeback(let days):
            switch days {
            case 3: return "The forge is cold but not extinguished. One habit relights it."
            case 7: return "Your habits miss you. Tap to restart with a clean slate."
            case 14: return "Still there? Your forge awaits. No judgment, just progress."
            default: return "Ready to return? The forge is waiting."
            }
            
        case .challengeProgress(let current, let total):
            let pct = Int((Double(current) / Double(total)) * 100)
            switch pct {
            case 50: return "Day \(current) of \(total) — you're exactly halfway. The hardest days are behind you."
            case 75: return "\(pct)% complete. The final stretch. Your Discipline Card is taking shape."
            default: return "Day \(current) of \(total). Keep forging. 🔥"
            }
        }
    }
}
```

**Rate limiting and notification fatigue prevention:**
```swift
struct NotificationRateLimiter {
    /// Maximum notifications per day per user
    static let maxDailyNotifications = 3
    
    /// Minimum gap between notifications (hours)
    static let minimumGapHours = 2
    
    /// Categories that can bypass rate limits
    static let highPriorityCategories: Set<String> = ["streak_risk"]
    
    /// Check if we can send a notification
    func canSend(to userId: UUID, category: String) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let sentToday = notificationsSentToday(userId: userId)
        
        // High priority bypasses daily limit (but not gap limit)
        if !Self.highPriorityCategories.contains(category) {
            guard sentToday.count < Self.maxDailyNotifications else { return false }
        }
        
        // Check minimum gap
        if let lastSent = sentToday.last?.sentAt {
            let hoursSinceLast = Date().timeIntervalSince(lastSent) / 3600
            guard hoursSinceLast >= Double(Self.minimumGapHours) else { return false }
        }
        
        return true
    }
}
```

**Notification preferences (user-controlled):**
```swift
// Settings → Notifications
struct NotificationPreferences: Codable {
    var streakReminders: Bool = true
    var milestoneAlerts: Bool = true
    var friendActivity: Bool = true
    var comebackMessages: Bool = true
    var challengeProgress: Bool = true
    var quietHoursStart: Int = 22  // 10 PM
    var quietHoursEnd: Int = 7     // 7 AM
    
    /// User can disable all social notifications while keeping streak reminders
    var socialNotificationsEnabled: Bool {
        friendActivity
    }
}
```

### Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Streak-at-risk open rate | ≥35% | Notification opens / streak-risk notifications sent |
| Streak save rate | ≥50% | Users who complete ≥1 habit after risk notification / notifications opened |
| Comeback notification open rate | ≥15% | Opens / comeback notifications sent |
| Comeback return rate (D3) | ≥20% | Users returning within 48h of comeback notification / sent |
| Friend activity open rate | ≥25% | Opens / friend activity notifications sent |
| Notification opt-out rate | <10% | Users disabling notifications / users who received ≥5 notifications |
| Overall notification CTR | ≥20% | Total opens / total notifications sent |
| Daily notification volume | ≤2 avg per user | Total notifications / active users receiving them |
| Uninstall correlation | <5% increase | Compare uninstall rate: notification-heavy vs. light users |

### A/B Test Plan

- **Test 1: Streak-at-risk timing**
  - Control: 8 PM fixed
  - Variant: Personalized (historical completion time - 5min)
  - Metric: Streak save rate
  - Hypothesis: Personalized timing increases save rate by ≥15%

- **Test 2: Comeback copy**
  - Control: Generic "Come back to your habits"
  - Variant: Themed copy ("The forge is cold but not extinguished...")
  - Metric: Comeback return rate
  - Hypothesis: Themed copy increases returns by ≥25%

- **Test 3: Friend activity notifications**
  - Control: No friend activity notifications
  - Variant: Buddy completion notifications (max 1/day)
  - Metric: Daily habit completions for paired users
  - Hypothesis: Notifications increase buddy's completions by ≥10%

---

## Cross-Feature Dependencies

```
Feature                  | Depends On           | Enables
─────────────────────────┼──────────────────────┼────────────────────────
1. Milestone Cards       | Core XP/Streak system| Referrals, ASO
2. Referral System       | Deep links, Onboarding| Buddy System, Micro-Challenges
3. Micro-Challenges      | Habit completions    | Milestone Cards (Victory card)
4. Buddy System          | Profile system       | Notifications (friend activity)
5. UGC Pipeline          | Moderation system    | Community engagement
6. ASO                   | Screenshots, App live| All organic acquisition
7. Content Moderation    | None (foundation)    | UGC, Guilds, Buddy, Challenges
8. Notifications         | APNs setup, user TZ  | Streak saves, Comeback, Buddy
```

**Recommended build order:**
1. Content Moderation (foundation for all social features)
2. Milestone Cards (immediate viral surface, no dependencies)
3. Notifications (retention infrastructure)
4. Referral System (acquisition infrastructure)
5. Buddy System (lightweight social)
6. Micro-Challenges (competitive social)
7. UGC Pipeline (community depth)
8. ASO (optimize once app is stable)

---

## Economy Impact Summary

| Feature | Tokens Generated | Tokens Purpose |
|---------|-----------------|----------------|
| Referral (referrer) | +5 Forge Tokens + 1 Forgiveness | Incentivize sharing |
| Referral (referee) | +5 Forge Tokens + 1 Forgiveness | Welcome bonus |
| Micro-Challenge winner | +20 Forge Tokens | Competition reward |
| Micro-Challenge loser | +5 Forge Tokens | Participation reward |
| Buddy Forge Bond | +5 XP (daily, both) | Mutual accountability |
| UGC quote approved | +10 Forge Tokens | Content creation reward |
| UGC challenge approved | +20 Forge Tokens | Content creation reward |

**Monthly token generation estimate (per active user):**
- Referrals: ~5 tokens/month (assuming 1 successful referral/month avg)
- Challenges: ~15 tokens/month (assuming 1 challenge/month)
- UGC: ~2 tokens/month (only engaged creators)
- **Total additional: ~22 tokens/month per active user**

This is within acceptable inflation bounds given token sinks in the skill tree and cosmetic shop.

---

## Privacy & Compliance

| Feature | Data Shared | GDPR/Privacy Consideration |
|---------|------------|---------------------------|
| Milestone Cards | User's own stats (opt-in share) | User controls what's shared externally |
| Referrals | Referrer display name to referee | Minimal PII, display name only |
| Micro-Challenges | Completion counts (no habit details) | Aggregated data only |
| Buddy System | Completion pattern (✓/✗) only | No habit names, no details, no timing |
| UGC | Submitted text + display name | Content license agreement on submission |
| Notifications | Sent to device only | Standard APNs, no third-party tracking |

**Required consent flows:**
- First social feature activation: "RNF Social Features" consent screen explaining data sharing
- Buddy pairing: Explicit acceptance of completion sharing
- UGC submission: Content license agreement (RNF can display/distribute)
- Notifications: iOS permission prompt (deferred to optimal moment, not first launch)

---

## Success Criteria (Launch Readiness)

| Criterion | Threshold | Measured By |
|-----------|-----------|-------------|
| Viral coefficient (k) | ≥0.2 (target 0.3) | Referral completions / MAU |
| Organic install share | ≥40% (target 60%) | App Store Connect attribution |
| Share rate (milestone cards) | ≥10% | Cards shared / cards displayed |
| D7 retention (referred users) | ≥45% | Cohort analysis |
| Moderation response time | <24h | Report → action median |
| Notification opt-out rate | <10% | Users disabling / users receiving |
| False positive moderation | <2% | Manual audit sample |
| App Store keyword ranking | Top 20 for 3+ keywords | ASO tool |
