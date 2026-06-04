# RNF Task Graph

EXECUTION PROTOCOL

- Only ONE task is worked on at a time
- Builder implements, Verifier reviews
- No agent may modify more than one task per cycle
- No rewriting of this file is allowed
- Tasks are executed strictly in dependency order

This file is the single source of truth.

This backlog is optimized for autonomous implementation.

Execution rule:

1. Work top-to-bottom.
2. Only start a task when every dependency is already complete.
3. Prefer service tasks before engine tasks, and engine tasks before screen tasks.
4. If multiple tasks are ready, pick the earliest task ID in this file.

Status legend:

- `[x]` complete
- `[ ]` not started

 NEXT TASK TO IMPLEMENT

- [ ] P15-CONFIG-01 Confirm and document the MVP minimum iOS deployment target
Depends on:
- P15-CHORE-01

## Phase 6 – Core Gameplay Completion

### Models

- [x] P6-MDL-01 Align runtime models with the documented schema for profile progression and daily logs
Depends on:
- none

- [x] P6-MDL-02 Create `Challenge.swift` matching the `challenges` table contract
Depends on:
- P6-MDL-01

- [x] P6-MDL-03 Create a calendar-facing `DailyLogStatus` helper type for complete, partial, missed, and forgiven states
Depends on:
- P6-MDL-01

### Daily Log Service

- [x] P6-SVC-01 Add `DailyLogService.fetchTodayLog(userId:date:)` query logic in `DailyLogService.swift`
Depends on:
- P6-MDL-01

- [x] P6-SVC-02 Add `DailyLogService.createDailyLog(userId:date:)` insert logic in `DailyLogService.swift`
Depends on:
- P6-MDL-01

- [x] P6-SVC-03 Add create-if-missing behavior to `DailyLogService.getTodayLog(...)`
Depends on:
- P6-SVC-01
- P6-SVC-02

- [x] P6-SVC-04 Add duplicate completion lookup in `DailyLogService.recordHabitCompletion(...)`
Depends on:
- P6-SVC-01

- [x] P6-SVC-05 Add habit completion insert path in `DailyLogService.recordHabitCompletion(...)`
Depends on:
- P6-SVC-03
- P6-SVC-04

- [x] P6-SVC-06 Add pure daily status calculation helper in `DailyLogService.swift`
Depends on:
- P6-SVC-03

- [x] P6-SVC-07 Add `DailyLogService.updateStatus(...)` persistence logic
Depends on:
- P6-SVC-03
- P6-SVC-06

### Challenge Service

- [x] P6-SVC-08 Create `ChallengeService.swift` shell in `Services/`
Depends on:
- P6-MDL-02

- [x] P6-SVC-09 Add `ChallengeService.startChallenge(...)`
Depends on:
- P6-SVC-08

- [x] P6-SVC-10 Add `ChallengeService.getActiveChallenge(...)`
Depends on:
- P6-SVC-08

- [x] P6-SVC-11 Add `ChallengeService.completeChallenge(...)`
Depends on:
- P6-SVC-08

### Calendar Service

- [x] P6-SVC-12 Create `CalendarService.swift` shell in `Services/`
Depends on:
- P6-MDL-03

- [x] P6-SVC-13 Add `CalendarService.getMonthLogs(userId:month:)`
Depends on:
- P6-SVC-03
- P6-SVC-12

- [x] P6-SVC-14 Add `CalendarService.mapLogToCalendarStatus(...)`
Depends on:
- P6-MDL-03
- P6-SVC-13

### Engine and ViewModel Integration

- [x] P6-ENG-01 Update `ProgressionEngine` to create-or-fetch today’s log before progression writes
Depends on:
- P6-SVC-03

- [x] P6-ENG-02 Update `ProgressionEngine` to use duplicate-safe habit completion persistence
Depends on:
- P6-SVC-05
- P6-ENG-01

- [x] P6-ENG-03 Update `ProgressionEngine` to call `DailyLogService.updateStatus(...)`
Depends on:
- P6-SVC-07
- P6-ENG-02

- [x] P6-VM-01 Remove any remaining direct progression mutations from `HabitsViewModel.swift`
Depends on:
- P6-ENG-03

### UI Shell

- [x] P6-UI-01 Create `WorkoutListView.swift` placeholder screen in `Features/`
Depends on:
- none

- [x] P6-UI-02 Create `ReadView.swift` placeholder screen in `Features/`
Depends on:
- none

- [x] P6-UI-03 Create `WorkoutViewModel.swift` placeholder in `ViewModels/`
Depends on:
- P6-UI-01

- [x] P6-UI-04 Create `ReadViewModel.swift` placeholder in `ViewModels/`
Depends on:
- P6-UI-02

- [x] P6-UI-05 Expand `RootView.swift` with Workouts and Read tabs
Depends on:
- P6-UI-01
- P6-UI-02

### Tests

- [x] P6-TST-01 Add `XPSystem` threshold and carry-over tests
Depends on:
- none

- [x] P6-TST-02 Add `DailyLogService` duplicate completion tests
Depends on:
- P6-SVC-05

- [x] P6-TST-03 Add `DailyLogService` status update tests
Depends on:
- P6-SVC-07

- [x] P6-TST-04 Add `ProgressionEngine` quest refresh tests
Depends on:
- P6-ENG-03

## Phase 7 – 90 Day Challenge Engine

### Model and Service Expansion

- [x] P7-MDL-01 Add challenge mapping helpers to `Challenge.swift`
Depends on:
- P6-MDL-02

- [x] P7-SVC-01 Add `ChallengeService.advanceDay(...)`
Depends on:
- P6-SVC-10

- [x] P7-SVC-02 Add `ChallengeService.restartChallenge(...)`
Depends on:
- P6-SVC-11

### Challenge Engine

- [x] P7-ENG-01 Create `ChallengeEngine.swift` shell in `Core/`
Depends on:
- P6-SVC-10
- P6-SVC-11
- P6-SVC-07

- [x] P7-ENG-02 Add active challenge loading in `ChallengeEngine`
Depends on:
- P7-ENG-01

- [x] P7-ENG-03 Add day progression logic in `ChallengeEngine.advanceIfDayComplete(...)`
Depends on:
- P7-SVC-01
- P7-ENG-02

- [x] P7-ENG-04 Add day-90 completion detection in `ChallengeEngine`
Depends on:
- P7-ENG-03

- [x] P7-ENG-05 Add restart flow orchestration in `ChallengeEngine`
Depends on:
- P7-SVC-02
- P7-ENG-04

### App State Manager

- [x] P7-CORE-01 Create `AppState.swift` enum for app routes
Depends on:
- none

- [x] P7-CORE-02 Create `AppStateManager.swift` shell in `Core/`
Depends on:
- P7-CORE-01

- [x] P7-CORE-03 Add launch resolution using session state, today log, and active challenge
Depends on:
- P6-SVC-03
- P6-SVC-10
- P7-CORE-02

- [x] P7-CORE-04 Add challenge-related route transitions
Depends on:
- P7-ENG-04
- P7-CORE-03

### Screens

- [x] P7-UI-01 Create `CommitmentView.swift`
Depends on:
- P7-CORE-02

- [x] P7-UI-02 Add challenge summary surface to `ContentView.swift`
Depends on:
- P7-ENG-03

- [x] P7-UI-03 Add challenge summary surface to `AscensionView.swift`
Depends on:
- P7-ENG-03

- [x] P7-UI-04 Create challenge completion screen
Depends on:
- P7-ENG-04

- [x] P7-UI-05 Add challenge restart action UI
Depends on:
- P7-ENG-05

### Tests

- [x] P7-TST-01 Add `ChallengeService.advanceDay(...)` tests
Depends on:
- P7-SVC-01

- [x] P7-TST-02 Add `ChallengeEngine` completion and restart tests
Depends on:
- P7-ENG-04
- P7-ENG-05

- [x] P7-TST-03 Add `AppStateManager` launch routing tests
Depends on:
- P7-CORE-04

## Phase 8 – Workouts + Reading Proof

### Workout Path

- [x] P8-MDL-01 Create `WorkoutSession.swift` model
Depends on:
- none

- [x] P8-SYS-01 Add workout duration validation helper in `Systems/`
Depends on:
- P8-MDL-01

- [x] P8-SVC-01 Create `WorkoutService.swift` shell
Depends on:
- P8-MDL-01
- P6-SVC-03

- [x] P8-SVC-02 Add workout daily-log fetch/create path in `WorkoutService`
Depends on:
- P8-SVC-01

- [x] P8-SVC-03 Add daily log workout-flag update in `WorkoutService`
Depends on:
- P6-SVC-07
- P8-SVC-02

- [x] P8-ENG-01 Create `WorkoutEngine.swift` shell
Depends on:
- P8-SVC-03

- [x] P8-ENG-02 Add XP award path in `WorkoutEngine.completeWorkout(...)`
Depends on:
- P8-SYS-01
- P8-ENG-01

- [x] P8-ENG-03 Add challenge day evaluation hook for workouts
Depends on:
- P7-ENG-03
- P8-ENG-02

- [x] P8-UI-01 Build workout list screen content
Depends on:
- P8-SVC-01
- P6-UI-01

- [x] P8-UI-02 Build active workout timer screen
Depends on:
- P8-ENG-02
- P8-UI-01

- [x] P8-TST-01 Add workout validation and reward tests
Depends on:
- P8-ENG-02

### Reading Path

- [x] P8-MDL-02 Create `ReadingUpload.swift` model
Depends on:
- none

- [x] P8-SVC-04 Add proof file upload path in `ReadingService.swift`
Depends on:
- P8-MDL-02

- [x] P8-SVC-05 Add `reading_uploads` insert path in `ReadingService.swift`
Depends on:
- P8-SVC-04

- [x] P8-SVC-06 Add daily log reading-flag update in `ReadingService.swift`
Depends on:
- P6-SVC-07
- P8-SVC-05

- [x] P8-ENG-04 Create `ReadingEngine.swift` shell
Depends on:
- P8-SVC-06

- [x] P8-ENG-05 Add XP award path in `ReadingEngine.completeReading(...)`
Depends on:
- P8-ENG-04

- [x] P8-ENG-06 Add challenge day evaluation hook for reading
Depends on:
- P7-ENG-03
- P8-ENG-05

- [x] P8-UI-03 Build read screen content
Depends on:
- P8-SVC-04
- P6-UI-02

- [x] P8-UI-04 Build reading proof upload flow
Depends on:
- P8-SVC-05
- P8-UI-03

- [x] P8-TST-02 Add reading upload and daily-log update tests
Depends on:
- P8-SVC-06

## Phase 9 – Calendar + Forgiveness System

### Calendar

- [x] P9-SVC-01 Add month grouping helper in `CalendarService.swift`
Depends on:
- P6-SVC-13

- [x] P9-SVC-02 Add calendar cell status mapping in `CalendarService.swift`
Depends on:
- P6-SVC-14
- P9-SVC-01

- [x] P9-UI-01 Create calendar grid component
Depends on:
- P9-SVC-02

- [x] P9-UI-02 Add calendar section to profile-facing UI
Depends on:
- P9-UI-01

### Forgiveness

- [x] P9-SVC-03 Add forgiveness token fetch path in `UserService.swift`
Depends on:
- P6-MDL-01

- [x] P9-SVC-04 Add forgiveness token decrement path in `UserService.swift`
Depends on:
- P9-SVC-03

- [x] P9-SYS-01 Create `ForgivenessSystem.swift` shell
Depends on:
- none

- [x] P9-SYS-02 Add pure forgiveness rule evaluation
Depends on:
- P9-SYS-01

- [x] P9-ENG-01 Add forgiveness handling in `ChallengeEngine`
Depends on:
- P7-ENG-03
- P9-SVC-04
- P9-SYS-02

- [x] P9-ENG-02 Add forgiven status handling in `DailyLogService`
Depends on:
- P6-SVC-07
- P9-ENG-01

- [x] P9-UI-03 Add forgiveness recovery action UI
Depends on:
- P9-ENG-01

- [x] P9-TST-01 Add calendar status mapping tests
Depends on:
- P9-SVC-02

- [x] P9-TST-02 Add forgiveness token and streak preservation tests
Depends on:
- P9-ENG-02

## Phase 10 – Auth + Onboarding

### Auth Service

- [x] P10-SVC-01 Create `AuthService.swift` shell
Depends on:
- none

- [x] P10-SVC-02 Add sign-up path in `AuthService`
Depends on:
- P10-SVC-01

- [x] P10-SVC-03 Add sign-in path in `AuthService`
Depends on:
- P10-SVC-01

- [x] P10-SVC-04 Add sign-out path in `AuthService`
Depends on:
- P10-SVC-01

- [x] P10-SVC-05 Add restore-session path in `AuthService`
Depends on:
- P10-SVC-01

- [x] P10-SVC-06 Add post-sign-up user bootstrap in `AuthService`
Depends on:
- P10-SVC-02
- P6-MDL-01

### Notifications

- [x] P10-SVC-07 Create `NotificationScheduler.swift` shell
Depends on:
- none

- [x] P10-SVC-08 Add notification permission request
Depends on:
- P10-SVC-07

- [x] P10-SVC-09 Add morning schedule path
Depends on:
- P10-SVC-08

- [x] P10-SVC-10 Add evening schedule path
Depends on:
- P10-SVC-08

### Screens and Routing

- [x] P10-UI-01 Create splash screen
Depends on:
- none

- [x] P10-UI-02 Create login screen
Depends on:
- P10-SVC-03

- [x] P10-UI-03 Create sign-up screen
Depends on:
- P10-SVC-02

- [x] P10-UI-04 Create notification setup screen
Depends on:
- P10-SVC-08

- [x] P10-CORE-01 Add auth states to `AppStateManager`
Depends on:
- P7-CORE-04
- P10-SVC-05

- [x] P10-CORE-02 Add onboarding states to `AppStateManager`
Depends on:
- P10-CORE-01
- P10-UI-04
- P7-UI-01

- [x] P10-TST-01 Add auth restore and onboarding routing tests
Depends on:
- P10-CORE-02

## Phase 11 – Subscription + Analytics

### Subscription

- [x] P11-SVC-01 Create `SubscriptionService` StoreKit shell
Depends on:
- P10-SVC-05

- [x] P11-SVC-02 Add product fetch path in `SubscriptionService`
Depends on:
- P11-SVC-01

- [x] P11-SVC-03 Add entitlement validation path in `SubscriptionService`
Depends on:
- P11-SVC-01

- [x] P11-SVC-04 Add Supabase subscription sync path
Depends on:
- P11-SVC-03

- [x] P11-UI-01 Build subscription management screen
Depends on:
- P11-SVC-02
- P11-SVC-03

### Analytics

- [x] P11-SVC-05 Create `AnalyticsService.swift` shell
Depends on:
- P10-SVC-05

- [x] P11-SVC-06 Define typed event names in `AnalyticsService`
Depends on:
- P11-SVC-05

- [x] P11-SVC-07 Add funnel tracking hooks
Depends on:
- P11-SVC-06
- P10-CORE-02
- P7-ENG-03

- [x] P11-SVC-08 Add engagement tracking hooks
Depends on:
- P11-SVC-06
- P8-ENG-03
- P8-ENG-06
- P9-ENG-01

- [x] P11-SVC-09 Add monetization and notification tracking hooks
Depends on:
- P11-SVC-06
- P11-SVC-04
- P10-SVC-09
- P10-SVC-10

### Hardening

- [x] P11-OPS-01 Validate RLS, user scoping, and storage path assumptions
Depends on:
- P10-SVC-06
- P11-SVC-04

- [x] P11-OPS-02 Validate performance of habit completion, reading upload, workout completion, and month log fetch
Depends on:
- P6-ENG-03
- P8-ENG-03
- P8-ENG-06
- P9-SVC-02

## Phase 12 – Engagement Expansion

### Architecture Stabilization

- [x] P12-ARCH-01 Expand `ProgressionResult` into a full state transition payload
Depends on:
- P11-OPS-02

- [x] P12-ARCH-02 Move habit `GameState.apply(...)` responsibility from `ProgressionEngine` to `HabitsViewModel`
Depends on:
- P12-ARCH-01

- [x] P12-ARCH-03 Add regression tests for the progression transition payload
Depends on:
- P12-ARCH-02

- [x] P12-ARCH-04 Classify `DailyLogService` methods by persistence responsibility in docs
Depends on:
- P11-OPS-02

### Dynamic Quest System

- [x] P12-MDL-01 Add quest difficulty and cadence metadata to `Quest`
Depends on:
- P12-ARCH-03

- [x] P12-SYS-01 Add weak-stat quest selection helper in `QuestGenerator`
Depends on:
- P12-MDL-01

- [x] P12-SYS-02 Add weekly habit unlock selection helper
Depends on:
- P12-MDL-01

- [x] P12-SVC-01 Update `QuestService` to expose dynamic daily and weekly quest plans
Depends on:
- P12-SYS-01
- P12-SYS-02

- [x] P12-UI-01 Create dedicated quest screen content for daily and weekly quests
Depends on:
- P12-SVC-01

- [x] P12-TST-01 Add quest generation and weekly unlock tests
Depends on:
- P12-SVC-01

### Skill Trees

- [x] P12-MDL-02 Create skill tree models for paths, nodes, tiers, and unlock state
Depends on:
- P12-ARCH-03

- [x] P12-SYS-03 Create `SkillTreeSystem` unlock and point calculation helpers
Depends on:
- P12-MDL-02

- [x] P12-SVC-02 Create skill tree persistence shell
Depends on:
- P12-SYS-03

- [x] P12-UI-02 Build skill tree screen shell
Depends on:
- P12-SVC-02

- [x] P12-TST-02 Add skill tree unlock and skill point tests
Depends on:
- P12-SYS-03

### Evolution Milestones

- [x] P12-MDL-03 Create evolution tier model
Depends on:
- P12-ARCH-03

- [x] P12-SYS-04 Create `EvolutionSystem` milestone evaluation helper
Depends on:
- P12-MDL-03
- P12-SYS-03

- [x] P12-SVC-03 Add evolution state derivation path
Depends on:
- P12-SYS-04

- [x] P12-UI-03 Expand profile evolution surface with derived milestones
Depends on:
- P12-SVC-03

- [x] P12-TST-03 Add evolution milestone tests
Depends on:
- P12-SYS-04

### Navigation and Retention

- [x] P12-UI-04 Add quest and skill tree navigation entry points
Depends on:
- P12-UI-01
- P12-UI-02

- [x] P12-SVC-04 Add engagement analytics events for weekly quest, skill tree, and evolution milestones
Depends on:
- P12-UI-04
- P12-UI-03
- P11-SVC-06

- [x] P12-TST-04 Add navigation smoke tests for engagement screens
Depends on:
- P12-UI-04

## Phase 13 – Perk System

### Models

- [x] P13-MDL-01 Create perk effect models for XP multipliers, stat bonuses, quest rewards, and streak protection
Depends on:
- P12-MDL-02

- [x] P13-MDL-02 Add active perk summary state for unlocked skill tree bonuses
Depends on:
- P13-MDL-01

### Perk Engine

- [x] P13-SYS-01 Create `PerkSystem` active perk aggregation helper
Depends on:
- P13-MDL-02
- P12-SYS-03

- [x] P13-SYS-02 Add XP reward modifier calculation with daily cap safety
Depends on:
- P13-SYS-01

- [x] P13-SYS-03 Add stat bonus and quest reward modifier helpers
Depends on:
- P13-SYS-01

- [x] P13-SYS-04 Add streak protection eligibility helper
Depends on:
- P13-SYS-01
- P9-SYS-02

### Service Layer

- [x] P13-SVC-01 Add active perk derivation path to `SkillTreeService`
Depends on:
- P13-SYS-01
- P12-SVC-02

- [x] P13-SVC-02 Add perk analytics events for applied bonuses and streak protection
Depends on:
- P13-SVC-01
- P12-SVC-04

### Engine Integration

- [x] P13-ENG-01 Apply XP perk modifiers to habit completion rewards
Depends on:
- P13-SYS-02
- P13-SVC-01
- P7-ENG-01

- [x] P13-ENG-02 Apply XP perk modifiers to workout and reading rewards
Depends on:
- P13-SYS-02
- P8-ENG-02
- P8-ENG-05

- [x] P13-ENG-03 Apply stat bonus perk modifiers to progression updates
Depends on:
- P13-SYS-03
- P7-ENG-01

- [x] P13-ENG-04 Apply quest reward perk modifiers to generated quest rewards
Depends on:
- P13-SYS-03
- P12-SVC-01

- [x] P13-ENG-05 Connect streak protection perks to forgiveness evaluation
Depends on:
- P13-SYS-04
- P9-ENG-01

### UI

- [x] P13-UI-01 Surface active perks in `SkillTreeView`
Depends on:
- P13-SVC-01
- P12-UI-02

- [x] P13-UI-02 Add active perk summary to the ascension surface
Depends on:
- P13-UI-01
- P12-UI-04

### Tests

- [x] P13-TST-01 Add perk aggregation and modifier unit tests
Depends on:
- P13-SYS-01
- P13-SYS-02
- P13-SYS-03

- [x] P13-TST-02 Add perk integration tests for XP, stats, quests, and streak protection
Depends on:
- P13-ENG-01
- P13-ENG-02
- P13-ENG-03
- P13-ENG-04
- P13-ENG-05

- [x] P13-TST-03 Add active perk UI smoke tests
Depends on:
- P13-UI-02

## Phase 14 – Production Readiness Guardrails

### Database Guardrails

- [x] P14-MIG-01 Add production uniqueness constraints and query indexes
Depends on:
- P13-TST-03

- [x] P14-MIG-02 Add Supabase RLS policies for user-owned tables
Depends on:
- P14-MIG-01

- [x] P14-MIG-03 Document migration rollback and verification commands
Depends on:
- P14-MIG-02

### Auth Boundary

- [x] P14-AUTH-01 Create `AuthProviding` boundary for current authenticated user identity
Depends on:
- P14-MIG-02

- [x] P14-AUTH-02 Wire authenticated user resolution into production user-owned services
Depends on:
- P14-AUTH-01

- [x] P14-AUTH-03 Replace global first-profile reads in production launch paths
Depends on:
- P14-AUTH-02

### Idempotency And Error Contracts

- [x] P14-SVC-01 Add typed service result/error contract for critical authenticated writes
Depends on:
- P14-AUTH-02

- [x] P14-SVC-02 Harden habit completion retries against duplicate XP and duplicate writes
Depends on:
- P14-SVC-01
- P14-MIG-01

- [x] P14-SVC-03 Harden workout and reading retries against duplicate daily rewards
Depends on:
- P14-SVC-02

- [x] P14-SVC-04 Surface critical authenticated persistence failures to ViewModels
Depends on:
- P14-SVC-01

### Date And Time Safety

- [x] P14-TIME-01 Add normalized-date tests for daily logs and challenge day boundaries
Depends on:
- P14-MIG-01

- [x] P14-TIME-02 Document timezone policy in service and state docs
Depends on:
- P14-TIME-01

### Observability

- [x] P14-OBS-01 Add `Logger` categories for auth, daily log, habit completion, challenge, and sync
Depends on:
- P14-SVC-01

- [x] P14-OBS-02 Add user-safe logging to critical service and engine flows
Depends on:
- P14-OBS-01

### Production Tests

- [x] P14-TST-01 Add migration SQL structure tests or verification notes
Depends on:
- P14-MIG-03

- [x] P14-TST-02 Add auth user-scoping service tests
Depends on:
- P14-AUTH-03

- [x] P14-TST-03 Add idempotent retry integration tests for daily actions
Depends on:
- P14-SVC-03

- [x] P14-TST-04 Add ViewModel failure-state tests for critical persistence errors
Depends on:
- P14-SVC-04

## Phase 15 – Audit-Driven Production Cleanup

### Backend Reproducibility

- [x] P15-MIG-01 Add skill tree table migrations for reproducible backend setup
Depends on:
- P14-TST-04

- [x] P15-MIG-02 Add skill tree RLS policies and verification coverage
Depends on:
- P15-MIG-01

- [x] P15-MIG-03 Add reading proof storage bucket and object policy migration
Depends on:
- P15-MIG-02

- [x] P15-DOC-01 Update database schema and migration runbook for skill tree and storage setup
Depends on:
- P15-MIG-03

### Launch And Workflow Boundaries

- [x] P15-APP-01 Wire `AppStateManager` into the root app shell
Depends on:
- P15-DOC-01

- [x] P15-VM-01 Move reading proof workflow state into `ReadViewModel`
Depends on:
- P15-APP-01

- [x] P15-VM-02 Move workout finalizing state into `WorkoutViewModel`
Depends on:
- P15-VM-01

- [x] P15-ENG-01 Move workout and reading `GameState.apply(...)` calls out of engines
Depends on:
- P15-VM-02

### Date, Docs, And Hygiene

- [x] P15-TIME-01 Centralize day boundary handling for services and daily reset logic
Depends on:
- P15-ENG-01

- [x] P15-DOC-02 Refresh stale repository map and architecture docs
Depends on:
- P15-TIME-01

- [x] P15-CHORE-01 Remove tracked Xcode user data and confirm ignore coverage
Depends on:
- P15-DOC-02

- [ ] P15-CONFIG-01 Confirm and document the MVP minimum iOS deployment target
Depends on:
- P15-CHORE-01
