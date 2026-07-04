# RNF Release Branch Strategy

## Overview

The app is split into phased releases. All code currently compiles together, but features are activated in stages based on user validation.

## Branches

### `release/v1.0.0-core` (current)
**Goal:** Validate the core habit loop. Day-7 retention ≥ 40%.

**Core Services (15):**
| Service | Purpose |
|---------|---------|
| SupabaseService | DB client |
| AuthService + AuthProviding | Login/signup |
| UserService | Profile CRUD |
| HabitService | Habit CRUD |
| DailyLogService | Daily tracking backbone |
| CalendarService | Month view data |
| ChallengeService | 90-day challenge |
| WorkoutService | Workout logging |
| ReadingService | Reading proof |
| SubscriptionService | StoreKit queries |
| SubscriptionManager | Purchase/restore logic |
| NotificationScheduler | Local notifications |
| NetworkMonitor | Connectivity |
| OfflineWriteQueue + SyncFlushService | Offline support |

**Core Features:**
- Authentication (email + Apple Sign In)
- Habit tracking with XP/level progression
- 90-day challenge engine
- Workout timer
- Reading proof upload
- Calendar progress view
- Forgiveness system
- Basic subscription gate

---

### `release/v1.1.0-engagement` (future)
**Goal:** Increase D30 retention via progression depth.

**Added Services:**
- XPService, QuestService, SkillTreeService
- MasteryPathService, AchievementService
- EvolutionService, BossService
- PillarStreakService, ForgeTokenService
- SeasonalArcService, SeasonalEventService
- ChapterService, PrestigeService
- MicroChallengeService, LeagueService
- DifficultyAdvisor, AdaptiveTimingService

**Activation Criteria:**
- v1.0.0 achieves ≥40% D7 retention
- ≥100 active users

---

### `release/v1.2.0-social` (future)
**Goal:** Viral growth via social mechanics.

**Added Services:**
- GuildService, GuildXPService
- SocialChallengeService, ReferralService
- BuddyService, ContentModerationService

**Activation Criteria:**
- v1.1.0 shows engagement lift
- ≥500 active users

---

### `release/v1.3.0-platform` (future)
**Goal:** Full Apple ecosystem integration.

**Added Services:**
- HealthKitService, HealthKitWriter, HealthKitAutoTracker
- HealthImportService
- WatchSyncService, WatchMessageHandler, WatchSnapshotGenerator
- WidgetDataWriter (interactive widgets)
- AppAttestService, SentryService

**Activation Criteria:**
- Stable daily usage patterns established
- Watch/Widget demand validated through feedback

---

## Build Targets

| Branch | iOS Target | Xcode Required |
|--------|-----------|----------------|
| v1.0.0-core | 17.0 | 16.4+ |
| v1.1.0-engagement | 17.0 | 16.4+ |
| v1.2.0-social | 17.0 | 16.4+ |
| v1.3.0-platform | 17.0 | 16.4+ |

## Build Command

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild build -scheme RNF \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## Current Status

- ✅ All code compiles on `release/v1.0.0-core` with Xcode 16.4
- ✅ iOS Simulator 18.6 available for testing
- ⚠️ Non-fatal `appintentsnltrainingprocessor` warnings (Siri training data)
- 📋 Next: Run on simulator, verify basic app flow

## Notes

- Services are NOT removed from disk — they all compile together
- Feature gating (`FeatureGate`, `SubscriptionGate`) controls what users see
- The branch strategy is about *testing priorities*, not code isolation
- When ready to ship, tag from the appropriate branch
