# RNF Launch & Scale Playbook

---

## Phase A: Pre-Launch (Weeks 1–2)

### A1. Development Environment

```bash
# 1. Install iOS simulator
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -downloadPlatform iOS

# 2. Create simulator
xcrun simctl create "iPhone16" "iPhone 16" iOS18.5

# 3. Create Secrets.xcconfig from template
cp Secrets.xcconfig.template Secrets.xcconfig
# Fill in your Supabase URL and anon key

# 4. Full build
xcodebuild -scheme RNF -destination 'platform=iOS Simulator,name=iPhone16' build

# 5. Run tests
xcodebuild test -scheme RNF -destination 'platform=iOS Simulator,name=iPhone16'
```

### A2. Supabase Production Setup

| Step | Action |
|------|--------|
| 1 | Create project at supabase.com (Pro plan — $25/mo for production) |
| 2 | Run all 17 migrations in order (000–016) |
| 3 | Create storage bucket `reading-proof` (private) |
| 4 | Enable email auth + Apple Sign In |
| 5 | Set up Edge Functions for webhook (subscription validation) |
| 6 | Enable Point-in-Time Recovery for database backups |
| 7 | Set connection pooling mode to Transaction |

### A3. App Store Connect

| Step | Action |
|------|--------|
| 1 | Create app listing (Health & Fitness category) |
| 2 | Configure subscription group: "RNF Pro" |
| 3 | Add products: Monthly ($4.99), Yearly ($39.99) |
| 4 | Submit privacy nutrition labels |
| 5 | Upload app icon (1024x1024) |
| 6 | Prepare screenshots (6.7" iPhone 16 Pro Max) |
| 7 | Write description + keywords |
| 8 | Privacy policy URL (host on your domain) |

### A4. Xcode Project Wiring

| Target | Action |
|--------|--------|
| RNFWidget | Add target → Widget Extension → include source files from `RNFWidget/` |
| RNFWatch | Add target → watchOS App → include source files from `RNFWatch/` |
| App Groups | Enable on main app + widget: `group.com.rnf.shared` |
| HealthKit | Enable on main app target |
| Entitlements | Assign `.entitlements` files to respective targets |
| Signing | Set up provisioning profiles for all 3 targets |

---

## Phase B: Closed Beta (Weeks 3–4)

### B1. TestFlight

```bash
# Archive
xcodebuild archive -scheme RNF -archivePath RNF.xcarchive -destination 'generic/platform=iOS'

# Upload via Xcode Organizer or:
xcrun altool --upload-app -f ./export/RNF.ipa -t ios
```

- Invite 20–50 beta testers (friends, fitness community members)
- Set up TestFlight feedback collection
- Monitor crash reports daily

### B2. Beta Success Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Install → Day 1 completion | ≥ 70% | analytics: `app_opened` → `habit_completed` on same day |
| Day 1 → Day 3 retention | ≥ 50% | users with `app_opened` on day 1 AND day 3 |
| Day 7 retention | ≥ 35% | users opening app 7 days after install |
| Onboarding completion rate | ≥ 80% | `challenge_started` / total signups |
| Crash-free sessions | ≥ 99.5% | Xcode Organizer metrics |
| Avg habits completed/day | ≥ 2.5 | SUM(habits_completed) / active_users |

### B3. Beta Fixes

Based on feedback, fix:
- Confusing UX flows
- Crash bugs
- Performance issues on older devices
- Copy/messaging that doesn't resonate

---

## Phase C: Public Launch (Week 5)

### C1. Launch Day Checklist

- [ ] Submit to App Store Review (allow 2–5 days)
- [ ] Prepare launch content (social posts, community announcement)
- [ ] Enable analytics dashboards
- [ ] Set up Supabase alerts for error rates > 1%
- [ ] Pre-warm Supabase connection pool
- [ ] Verify subscription webhook is live
- [ ] Test App Store rating prompt fires at day 7

### C2. Launch Channels (Zero Budget)

| Channel | Action | Expected Users |
|---------|--------|---------------|
| Reddit | r/selfimprovement, r/getdisciplined, r/iosapps posts | 200–500 |
| Twitter/X | Personal account + habit/fitness community | 100–300 |
| Product Hunt | Launch listing | 300–1000 |
| Indie Hackers | Build in public thread | 50–200 |
| Discord communities | Fitness/self-improvement servers | 100–300 |
| Friends & network | Direct shares | 50–100 |

**Realistic Week 1 downloads (organic): 500–2000**

### C3. App Store Optimization (ASO)

```
Title: RNF — Real Life RPG Discipline
Subtitle: 90 Day Challenge • Habit Tracker
Keywords: habit tracker, discipline, streak, rpg, fitness, self improvement, 
          workout timer, reading log, level up, daily challenge
```

---

## Phase D: Growth (Months 1–3)

### D1. North Star Metrics

| Metric | Month 1 Target | Month 3 Target | Month 6 Target |
|--------|---------------|---------------|---------------|
| Monthly Active Users (MAU) | 500 | 3,000 | 15,000 |
| Day 7 Retention | 35% | 40% | 45% |
| Day 30 Retention | 15% | 20% | 25% |
| Paid Conversion | 2% | 4% | 6% |
| Monthly Recurring Revenue | $50 | $600 | $4,500 |
| Avg Session Length | 2 min | 3 min | 4 min |
| Daily Active / Monthly Active | 30% | 35% | 40% |

### D2. Revenue Projections

**Assumptions:**
- Monthly subscription: $4.99
- Annual subscription: $39.99 ($3.33/mo effective)
- Apple takes 30% (15% after year 1 for Small Business Program)
- Paid conversion: 3% average
- Churn: 8%/month on monthly, 3%/month on annual

| Month | MAU | Paying Users | MRR (after Apple cut) | Cumulative Revenue |
|-------|-----|-------------|----------------------|-------------------|
| 1 | 500 | 15 | $52 | $52 |
| 2 | 1,200 | 42 | $147 | $199 |
| 3 | 3,000 | 105 | $368 | $567 |
| 4 | 5,000 | 200 | $700 | $1,267 |
| 5 | 8,000 | 360 | $1,260 | $2,527 |
| 6 | 15,000 | 750 | $2,625 | $5,152 |
| 9 | 30,000 | 1,800 | $6,300 | $18,000 |
| 12 | 50,000 | 3,500 | $12,250 | $55,000 |

**Break-even:** ~Month 4 (covers Supabase Pro $25/mo + Apple Dev $99/yr)

### D3. Growth Levers

| Lever | When | Expected Impact |
|-------|------|-----------------|
| App Store rating prompt (7/30-day streak) | Launch | +0.3 star avg rating |
| iOS Widget (streak/progress visible) | Launch | +15% daily opens |
| Share streak screenshots | Month 1 | +10% organic installs |
| Guild challenges (social) | Month 2 | +20% Day 30 retention |
| Referral system ("invite friend, both get tokens") | Month 3 | +25% organic growth |
| Apple Watch companion | Month 3 | +10% DAU/MAU ratio |
| Content marketing (discipline blog) | Month 2+ | +SEO traffic |
| TikTok/Reels (streak transformations) | Month 2+ | Viral potential |

---

## Phase E: Scale (Months 6–12)

### E1. Infrastructure Scaling

| Trigger | Action | Cost |
|---------|--------|------|
| > 5,000 MAU | Supabase Pro plan | $25/mo |
| > 20,000 MAU | Supabase Team plan | $599/mo |
| > 100,000 MAU | Add read replicas | $100–300/mo |
| > 500,000 MAU | Custom Supabase Enterprise or migrate | Negotiate |
| High image uploads | Move reading-proof to Cloudflare R2 | $0.015/GB |
| Analytics scale | Move events to PostHog or Mixpanel | Free tier → $0+ |

### E2. Database Scaling Milestones

```
< 10K users:  Supabase Pro (shared infra) — no action needed
10K–50K:      Add connection pooling via PgBouncer (already configured)
50K–200K:     Partition analytics_events by month, archive old data
200K+:        Read replicas for leaderboard queries
1M+:          Consider dedicated Postgres or move to planet-scale
```

### E3. Cost Projections

| MAU | Supabase | Apple Dev | Storage | Total/mo | Revenue/mo | Margin |
|-----|----------|-----------|---------|----------|-----------|--------|
| 500 | $25 | $8 | $0 | $33 | $52 | 37% |
| 5K | $25 | $8 | $5 | $38 | $700 | 95% |
| 15K | $25 | $8 | $15 | $48 | $2,625 | 98% |
| 50K | $599 | $8 | $50 | $657 | $12,250 | 95% |
| 200K | $1,500 | $8 | $200 | $1,708 | $49,000 | 97% |

Software businesses have 90%+ margins at scale. RNF is no different.

---

## Phase F: Retention Optimization

### F1. Cohort Analysis Framework

Track these cohorts weekly:

```
Cohort A: Users who complete onboarding + first habit (day 0)
Cohort B: Users who hit 3-day streak
Cohort C: Users who hit 7-day streak  
Cohort D: Users who hit 30-day streak
Cohort E: Users who complete 90-day challenge
```

**Key insight:** If you get someone to day 7, the probability of day 30 jumps to 60%+. Focus all early UX on the day 1→7 journey.

### F2. Retention Interventions by Stage

| Stage | Risk | Intervention |
|-------|------|-------------|
| Day 0 → Day 1 | Didn't open next day | Push notification at preferred time |
| Day 1 → Day 3 | Lost momentum | "You're building something" encouragement |
| Day 3 → Day 7 | Finds it boring | Dynamic quest targeting weak stats |
| Day 7 → Day 14 | Plateau | First boss spawns (novelty) |
| Day 14 → Day 30 | Life gets in way | Forgiveness system + streak protection perks |
| Day 30 → Day 90 | Content exhaustion | Skill trees + mastery paths unlock |
| Day 90+ | "Now what?" | Social features, guilds, leaderboards |

### F3. Metrics That Predict Churn

| Signal | Action |
|--------|--------|
| Missed 2 consecutive days | Trigger gentle push + forgiveness reminder |
| Hasn't completed a workout in 7 days | Suggest shorter workouts |
| Daily XP dropping week over week | Generate easier quests to rebuild momentum |
| Opened app but completed 0 habits | Show "just do one" nudge |
| Reached level 10 but no skill tree interaction | Guide to skill tree with tooltip |

---

## Phase G: Key Decisions Timeline

| Decision | When | Options |
|----------|------|---------|
| Pricing model | Pre-launch | Freemium (current) vs paywall after day 7 |
| Social features release | Month 2 | Guilds first vs leaderboards first |
| Apple Watch priority | Month 3 | Ship if DAU/MAU > 35% |
| HealthKit auto-accept | Month 4 | Manual confirm vs auto (based on user feedback) |
| Android port | Month 6+ | Only if iOS proves unit economics |
| AI quest generation | Month 6+ | Only if retention data justifies complexity |
| Raise funding? | Month 6+ | Only if growth > 20% MoM and you want to accelerate |

---

## Appendix: Analytics Queries

### Daily Active Users
```sql
SELECT DATE(created_at) as day, COUNT(DISTINCT (properties->>'user_id')) as dau
FROM analytics_events
WHERE event_name = 'app_opened'
GROUP BY day ORDER BY day DESC;
```

### Day-N Retention
```sql
WITH cohort AS (
  SELECT user_id, MIN(DATE(created_at)) as install_date
  FROM analytics_events WHERE event_name = 'app_opened'
  GROUP BY user_id
)
SELECT 
  install_date,
  COUNT(*) as cohort_size,
  COUNT(*) FILTER (WHERE EXISTS (
    SELECT 1 FROM analytics_events e 
    WHERE e.properties->>'user_id' = cohort.user_id 
    AND DATE(e.created_at) = install_date + 7
  )) as retained_day7
FROM cohort GROUP BY install_date;
```

### Conversion Funnel
```sql
SELECT 
  COUNT(*) FILTER (WHERE event_name = 'app_opened') as opened,
  COUNT(*) FILTER (WHERE event_name = 'challenge_started') as started_challenge,
  COUNT(*) FILTER (WHERE event_name = 'habit_completed') as first_habit,
  COUNT(*) FILTER (WHERE event_name = 'daily_goal_completed') as first_day_complete,
  COUNT(*) FILTER (WHERE event_name = 'subscription_started') as converted
FROM analytics_events;
```

### Monthly Recurring Revenue
```sql
SELECT 
  COUNT(*) FILTER (WHERE status = 'active' AND plan = 'monthly') * 4.99 * 0.70 +
  COUNT(*) FILTER (WHERE status = 'active' AND plan = 'yearly') * 3.33 * 0.70 as mrr
FROM subscriptions;
```

---

## Summary: Your First 90 Days

| Week | Focus | Milestone |
|------|-------|-----------|
| 1–2 | Build + test + configure | Working build on device |
| 3–4 | Beta testing | 50 testers, crash-free |
| 5 | Public launch | Live on App Store |
| 6–8 | Optimize onboarding | Day 7 retention ≥ 35% |
| 9–10 | Add social sharing | Streak screenshots viral |
| 11–12 | Guild launch | Community retention boost |
| 13 | Review metrics | Decide on Watch/Android/raise |

The app is built. The code is done. Now it's execution.
