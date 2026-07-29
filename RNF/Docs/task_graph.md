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

 ALL TASKS COMPLETE
- P14-TST-04

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

## Phase 15 – Launch Enhancements

### Haptic Feedback and Micro-Animations

- [x] P15-UX-01 Add haptic feedback on habit completion (success tap)
Depends on:
- P14-TST-04

- [x] P15-UX-02 Add XP gain animation with haptic pulse on level-up
Depends on:
- P15-UX-01

- [x] P15-UX-03 Add streak milestone haptic and celebration animation
Depends on:
- P15-UX-01

### iOS Widget

- [x] P15-WGT-01 Create WidgetKit extension target with shared data model
Depends on:
- P14-TST-04

- [x] P15-WGT-02 Add App Group for shared UserDefaults between app and widget
Depends on:
- P15-WGT-01

- [x] P15-WGT-03 Build small widget showing streak count and daily progress ring
Depends on:
- P15-WGT-02

- [x] P15-WGT-04 Build medium widget showing today's quest list with completion state
Depends on:
- P15-WGT-03

- [x] P15-WGT-05 Add widget timeline refresh on habit completion and app foreground
Depends on:
- P15-WGT-04

### Data Export

- [x] P15-EXP-01 Create `ExportService` that serializes user progress to JSON
Depends on:
- P14-TST-04

- [x] P15-EXP-02 Add CSV export option for daily logs and habit completions
Depends on:
- P15-EXP-01

- [x] P15-EXP-03 Add share sheet integration for exported files
Depends on:
- P15-EXP-02

### Onboarding Friction Reduction

- [x] P15-ONB-01 Add guest tryout mode allowing one day of habit tracking without account creation
Depends on:
- P14-TST-04

- [x] P15-ONB-02 Add account creation gate after first day completion with data migration to authenticated user
Depends on:
- P15-ONB-01

### Error UX

- [x] P15-ERR-01 Create toast/banner error component for transient failures
Depends on:
- P14-SVC-04

- [x] P15-ERR-02 Add retry action to error banners for failed persistence
Depends on:
- P15-ERR-01

- [x] P15-ERR-03 Add offline indicator banner when network is unreachable
Depends on:
- P15-ERR-01

### Offline Handling

- [x] P15-OFF-01 Add `NetworkMonitor` service using NWPathMonitor
Depends on:
- P14-SVC-04

- [x] P15-OFF-02 Add local-first write queue for habit completions when offline
Depends on:
- P15-OFF-01

- [x] P15-OFF-03 Add background sync flush when connectivity restores
Depends on:
- P15-OFF-02

- [x] P15-OFF-04 Add idempotent deduplication on sync flush to prevent duplicate XP
Depends on:
- P15-OFF-03
- P14-SVC-03

### Session Restoration Robustness

- [x] P15-SES-01 Add token expiry detection and silent refresh in `AuthService`
Depends on:
- P14-AUTH-03

- [x] P15-SES-02 Add graceful fallback state when Supabase is unreachable during launch
Depends on:
- P15-SES-01

- [x] P15-SES-03 Add cached last-known state display while session restoration is in progress
Depends on:
- P15-SES-02

### Accessibility Audit

- [x] P15-A11Y-01 Audit all interactive elements for 44pt minimum tap targets
Depends on:
- P14-TST-04
Details:
- Scan every Button, Toggle, and tappable view in Features/, Components/, and Navigation/
- Verify frame sizes meet 44x44pt minimum
- Fix any undersized targets by adding .frame(minWidth:minHeight:) or padding
- Priority screens: ContentView (habit rows), WorkoutListView (start buttons), ReadView (upload button)

- [x] P15-A11Y-02 Add VoiceOver labels and hints to all custom components
Depends on:
- P15-A11Y-01
Details:
- Add .accessibilityLabel() to XPBar (current XP, level, progress percentage)
- Add .accessibilityLabel() to DailyMissionBar (completed count, goal, percentage)
- Add .accessibilityLabel() to DisciplineRadarChart (stat values as text summary)
- Add .accessibilityLabel() to CalendarGridView (day status: complete, partial, missed, forgiven)
- Add .accessibilityHint() to action buttons explaining what they do
- Add .accessibilityValue() to progress indicators

- [x] P15-A11Y-03 Verify Dynamic Type support across all screens
Depends on:
- P15-A11Y-01
Details:
- Test all screens at accessibility font sizes (AX1 through AX5)
- Ensure no text truncation without .lineLimit or .minimumScaleFactor
- Verify layout doesn't break at largest Dynamic Type sizes
- Fix any hardcoded font sizes not using the DesignSystem/Typography.swift scale
- Ensure ScrollView wraps content that would overflow at large sizes

- [x] P15-A11Y-04 Verify WCAG AA contrast ratios for all text and interactive elements
Depends on:
- P15-A11Y-01
Details:
- Check RNF Purple (#6E2BD9) against dark background (#121212) — must be ≥ 4.5:1 for body text
- Check success green (#1F8A4D) against both dark and light backgrounds
- Check missed grey (#2A2A2A on dark, #DADADA on light) for sufficient contrast
- Check caption text (13pt) meets 4.5:1 ratio
- Check large text (H1/H2) meets 3:1 ratio minimum
- Document any failing combinations and fix in DesignSystem/Colors.swift

- [x] P15-A11Y-05 Add Reduce Motion support for all animations
Depends on:
- P15-UX-02
- P15-UX-03
Details:
- Query @Environment(\.accessibilityReduceMotion) in views with animations
- Replace XP gain animation with instant state change when Reduce Motion is on
- Replace streak celebration animation with static badge display
- Replace level-up glow with simple text announcement
- Ensure no .animation() modifier runs without checking reduce motion preference

### App Store Rating Prompt

- [x] P15-RATE-01 Add SKStoreReviewController trigger at streak milestones
Depends on:
- P14-TST-04
Details:
- Import StoreKit and call AppStore.requestReview(in:) at appropriate moments
- Trigger conditions (pick first matching, max once per 90 days):
  - User hits 7-day streak for the first time
  - User hits 30-day streak
  - User completes 50th habit
- Track last prompt date in UserDefaults to enforce 90-day cooldown
- Never prompt during onboarding or within first 3 days
- Never prompt immediately after a failure or missed day
- Respect Apple's system-level throttling (max 3 prompts per 365 days)

### Theme Toggle

- [x] P15-THM-01 Add theme preference model and persistence
Depends on:
- P14-TST-04
Details:
- Create ThemePreference enum: .light, .dark, .system
- Store selection in UserDefaults (key: "rnf_theme_preference")
- Default to .system on first launch
- Load preference at app startup in RNFApp.swift

- [x] P15-THM-02 Apply theme preference to the app window
Depends on:
- P15-THM-01
Details:
- Add .preferredColorScheme() modifier to RootView based on stored preference
- Map .system → nil (follows device), .light → .light, .dark → .dark
- Ensure change takes effect immediately without app restart

- [x] P15-THM-03 Add theme selection UI in profile settings
Depends on:
- P15-THM-02
Details:
- Add a "Theme" row in the profile/settings area
- Show segmented picker or menu with Light / Dark / System options
- Update UserDefaults on selection
- Show immediate visual preview of the selected theme
## Phase 16 – Advanced Progression (Gated by User Readiness)

### Feature Gating System

- [x] P16-SYS-01 Create `FeatureGate` unlock evaluation system
Depends on:
- none

### Boss Challenges (unlocked at Level 10+, 14-day streak)

- [x] P16-MDL-01 Create `Boss` model with type, HP, status
Depends on:
- P16-SYS-01

- [x] P16-SYS-02 Create `BossSystem` damage and spawn logic
Depends on:
- P16-MDL-01

- [x] P16-SVC-01 Create `BossService` with CRUD operations
Depends on:
- P16-MDL-01

- [x] P16-ENG-01 Create `BossEngine` orchestrating damage on habit/workout completion
Depends on:
- P16-SYS-02
- P16-SVC-01

- [x] P16-UI-01 Create boss battle screen with HP bar and damage animation
Depends on:
- P16-ENG-01

- [x] P16-UI-02 Add boss status to daily progress view (gated by FeatureGate)
Depends on:
- P16-UI-01
- P16-SYS-01

### Achievements (unlocked at Level 5+, 7-day streak)

- [x] P16-MDL-02 Create `Achievement` model with category and requirements
Depends on:
- P16-SYS-01

- [x] P16-SVC-02 Create `AchievementService` with evaluation and persistence
Depends on:
- P16-MDL-02

- [x] P16-ENG-02 Add achievement evaluation hook to ProgressionEngine
Depends on:
- P16-SVC-02

- [x] P16-UI-03 Create achievements gallery screen
Depends on:
- P16-SVC-02

- [x] P16-UI-04 Add achievement unlock toast notification
Depends on:
- P16-ENG-02

### Mastery Paths (unlocked at Level 15+, 30-day streak, challenge complete)

- [x] P16-MDL-03 Create `MasteryPath` model with tiers and XP
Depends on:
- P16-SYS-01

- [x] P16-SVC-03 Create `MasteryPathService` with path selection and tier progression
Depends on:
- P16-MDL-03

- [x] P16-SYS-03 Add mastery XP routing logic (habits contribute to selected path)
Depends on:
- P16-SVC-03

- [x] P16-UI-05 Create mastery path selection screen
Depends on:
- P16-SVC-03

- [x] P16-UI-06 Create mastery progress and tier advancement screen
Depends on:
- P16-SYS-03

### Database

- [x] P16-MIG-01 Add bosses, user_achievements, and mastery_paths tables
Depends on:
- none

- [x] P16-MIG-02 Add RLS policies for Phase 16 tables
Depends on:
- P16-MIG-01

### Tests

- [x] P16-TST-01 Add FeatureGate unlock evaluation tests
Depends on:
- P16-SYS-01

- [x] P16-TST-02 Add BossSystem damage and spawn tests
Depends on:
- P16-SYS-02

- [x] P16-TST-03 Add achievement evaluation tests
Depends on:
- P16-SVC-02

## Phase 17 – Social Expansion

### Models

- [x] P17-MDL-01 Create Guild, GuildMember, LeaderboardEntry, SocialChallenge models
Depends on:
- none

### Services

- [x] P17-SVC-01 Create `GuildService` with create, join, fetch operations
Depends on:
- P17-MDL-01

- [x] P17-SVC-02 Add leaderboard fetch with ranking in `GuildService`
Depends on:
- P17-SVC-01

- [x] P17-SVC-03 Create `SocialChallengeService` with CRUD and progress tracking
Depends on:
- P17-MDL-01

- [x] P17-SVC-04 Add guild XP contribution tracking on habit/workout completion
Depends on:
- P17-SVC-01

### UI

- [x] P17-UI-01 Create guild screen (create/join/view members)
Depends on:
- P17-SVC-01

- [x] P17-UI-02 Create leaderboard screen with weekly/monthly filters
Depends on:
- P17-SVC-02

- [x] P17-UI-03 Create social challenge screen with progress bar
Depends on:
- P17-SVC-03

- [x] P17-UI-04 Add social tab to RootView (gated by FeatureGate)
Depends on:
- P17-UI-01
- P17-UI-02
- P16-SYS-01

### Database

- [x] P17-MIG-01 Add guilds, guild_members, and social_challenges tables
Depends on:
- none

- [x] P17-MIG-02 Add RLS policies for social tables
Depends on:
- P17-MIG-01

### Tests

- [x] P17-TST-01 Add guild creation and membership tests
Depends on:
- P17-SVC-01

- [x] P17-TST-02 Add leaderboard ranking tests
Depends on:
- P17-SVC-02

- [x] P17-TST-03 Add social challenge progress tests
Depends on:
- P17-SVC-03

## Phase 18 – Apple Platform Expansion

### HealthKit Integration

- [x] P18-MDL-01 Create HealthWorkoutSummary and Apple platform shared models
Depends on:
- none

- [x] P18-SVC-01 Create `HealthKitService` with authorization and workout fetch
Depends on:
- P18-MDL-01

- [x] P18-SVC-02 Add health workout import confirmation path
Depends on:
- P18-SVC-01

- [x] P18-SVC-03 Add duplicate import prevention (healthkit UUID uniqueness)
Depends on:
- P18-SVC-02

- [x] P18-UI-01 Create health permissions request screen
Depends on:
- P18-SVC-01

- [x] P18-UI-02 Create imported workout review/accept screen
Depends on:
- P18-SVC-02

- [x] P18-UI-03 Add HealthKit settings toggle in profile
Depends on:
- P18-UI-01

### Apple Watch Companion

- [x] P18-MDL-02 Create Watch message DTOs (completion, workout, snapshot)
Depends on:
- none

- [x] P18-SVC-04 Create `WatchSyncService` with WCSession communication
Depends on:
- P18-MDL-02

- [x] P18-SVC-05 Add Watch habit completion handler with idempotency
Depends on:
- P18-SVC-04

- [x] P18-SVC-06 Add Watch daily snapshot generation and push
Depends on:
- P18-SVC-04

- [x] P18-WATCH-01 Create Watch app target with shared models
Depends on:
- P18-MDL-02

- [x] P18-WATCH-02 Create Watch habit list view
Depends on:
- P18-WATCH-01

- [x] P18-WATCH-03 Create Watch workout timer view
Depends on:
- P18-WATCH-01

- [x] P18-WATCH-04 Create Watch daily progress complication
Depends on:
- P18-WATCH-01

- [x] P18-WATCH-05 Add Watch-to-iPhone message handling for completions
Depends on:
- P18-SVC-05
- P18-WATCH-02

### Tests

- [x] P18-TST-01 Add HealthKit workout mapping tests
Depends on:
- P18-SVC-01

- [x] P18-TST-02 Add duplicate import prevention tests
Depends on:
- P18-SVC-03

- [x] P18-TST-03 Add Watch message encoding/decoding tests
Depends on:
- P18-MDL-02

- [x] P18-TST-04 Add Watch idempotent completion tests
Depends on:
- P18-SVC-05

## Phase 19 – UX Polish

### Design System Foundation

- [x] P19-UX-05a Expand RNFColors with semantic surface, text, border, status, and stat tokens
Depends on:
- P18-TST-04

- [x] P19-UX-05b Create RNFRadius constant set for all corner radii
Depends on:
- P19-UX-05a

- [x] P19-UX-05c Create RNFShadow elevation utility
Depends on:
- P19-UX-05a

- [x] P19-UX-05d Expand RNFSpacing with semantic card and section spacing values
Depends on:
- P19-UX-05a

### Dark Mode Fix (SEV-1)

- [x] P19-UX-01a Replace hardcoded Color.white.opacity surfaces in AscensionView with semantic tokens
Depends on:
- P19-UX-05a

- [x] P19-UX-01b Replace hardcoded Color.white.opacity surfaces in ContentView with semantic tokens
Depends on:
- P19-UX-05a

- [x] P19-UX-01c Replace hardcoded Color.white.opacity surfaces in EvolutionView and SkillTreeView
Depends on:
- P19-UX-05a

- [x] P19-UX-01d Audit and fix remaining hardcoded opacity colors across all view files
Depends on:
- P19-UX-01a
- P19-UX-01b
- P19-UX-01c

### Typography Consolidation

- [x] P19-UX-02a Expand RNFFont with display, overline, metric, pill, and bodyBold tokens
Depends on:
- P19-UX-05a

- [x] P19-UX-02b Create View+Overline modifier for uppercase tracking header pattern
Depends on:
- P19-UX-02a

- [x] P19-UX-02c Migrate all overline and section header patterns to RNFFont tokens
Depends on:
- P19-UX-02b

- [x] P19-UX-02d Migrate all pill, metric, and body font declarations to RNFFont tokens
Depends on:
- P19-UX-02c

### Celebration Animations

- [x] P19-UX-03a Create XPGainToast component (top-anchored non-blocking toast)
Depends on:
- P19-UX-05a

- [x] P19-UX-03b Create CelebrationOverlay component (full-screen milestone takeover)
Depends on:
- P19-UX-03a

- [x] P19-UX-03c Create ConfettiView particle system respecting Reduce Motion
Depends on:
- P19-UX-03b

- [x] P19-UX-03d Refactor ContentView to use new overlay components removing DispatchQueue timing
Depends on:
- P19-UX-03c
- P19-UX-13a

### Loading States

- [x] P19-UX-04a Create ShimmerModifier in DesignSystem with Reduce Motion support
Depends on:
- P19-UX-05a

- [x] P19-UX-04b Add shimmer loading states to AscensionView async sections
Depends on:
- P19-UX-04a
- P19-UX-01a

- [x] P19-UX-04c Add shimmer loading state to ContentView challenge summary
Depends on:
- P19-UX-04a
- P19-UX-01b

### Workout Timer

- [x] P19-UX-06a Create CircularProgressRing component with color interpolation
Depends on:
- P19-UX-05a

- [x] P19-UX-06b Replace linear ProgressView with CircularProgressRing in ActiveWorkoutTimerView
Depends on:
- P19-UX-06a
- P19-UX-02a

- [x] P19-UX-06c Add 80% threshold pulse and ambient gradient to workout timer
Depends on:
- P19-UX-06b

### Tab Bar

- [x] P19-UX-07a Create RNFTabBar component with active pill indicator and badge
Depends on:
- P19-UX-05a

- [x] P19-UX-07b Replace stock TabView in RootView with RNFTabBar
Depends on:
- P19-UX-07a

### Scroll Effects

- [x] P19-UX-08a Create ScrollEffects utility with cardScrollEntrance modifier
Depends on:
- P19-UX-05a

- [x] P19-UX-08b Add parallax and scroll entrance effects to ContentView and AscensionView
Depends on:
- P19-UX-08a

### Card Press Interaction

- [x] P19-UX-09a Create RNFCardButtonStyle with press scale and Reduce Motion support
Depends on:
- P19-UX-05a

- [x] P19-UX-09b Apply RNFCardButtonStyle to WorkoutListView, ReadView, and AscensionView cards
Depends on:
- P19-UX-09a

### Onboarding Warmth

- [x] P19-UX-10a Create StepIndicator component for onboarding flow
Depends on:
- P19-UX-05a

- [x] P19-UX-10b Add breathing glow animation to SplashView flame icon
Depends on:
- P19-UX-10a

- [x] P19-UX-10c Add ambient gradient pulse to CommitmentView
Depends on:
- P19-UX-10a
- P19-UX-01a

- [x] P19-UX-10d Add motivational subtext to LoginView and SignUpView
Depends on:
- P19-UX-10a

### Calendar Interactivity

- [x] P19-UX-11a Add tap handler to CalendarDayCell with date callback
Depends on:
- P19-UX-05a

- [x] P19-UX-11b Create DayDetailSheet component for tapped day summary
Depends on:
- P19-UX-11a

- [x] P19-UX-11c Add streak connector visual between consecutive completed days
Depends on:
- P19-UX-11a

- [x] P19-UX-11d Add today pulse animation and best-week highlight
Depends on:
- P19-UX-11c

### Radar Chart Enhancement

- [x] P19-UX-12a Add Animatable conformance and axis labels to DisciplineRadarChart
Depends on:
- P19-UX-02a

- [x] P19-UX-12b Add data point dots, gradient fill, and entry animation
Depends on:
- P19-UX-12a

### Toast System Architecture

- [x] P19-UX-13a Create NotificationManager ObservableObject with toast queue
Depends on:
- P19-UX-05a

- [x] P19-UX-13b Create RNFToast and RNFCelebration overlay components
Depends on:
- P19-UX-13a

- [x] P19-UX-13c Wire NotificationManager into RootView and refactor HabitsViewModel notifications
Depends on:
- P19-UX-13b

### Micro-Interactions

- [x] P19-UX-14a Add completion shimmer to DailyMissionBar at 100%
Depends on:
- P19-UX-05a

- [x] P19-UX-14b Add spring animation to XPBar progress fill on value change
Depends on:
- P19-UX-05a

- [x] P19-UX-14c Add streak pill bounce and calendar forgiveness flash
Depends on:
- P19-UX-14a

### Haptic Expansion

- [x] P19-UX-15a Create RNFHaptics utility with semantic haptic methods
Depends on:
- P18-TST-04

- [x] P19-UX-15b Wire haptics into workout timer lifecycle (start, pause, threshold, complete)
Depends on:
- P19-UX-15a

- [x] P19-UX-15c Wire haptics into reading proof, forgiveness, and primary button actions
Depends on:
- P19-UX-15a

## Phase 20 – Experience Elevation

### EXP-01: Dynamic Daily Narrative

- [x] P20-EXP-01a Create NarrativeEngine with 50+ templates organized by state bucket
Depends on:
- P19-UX-15c

- [x] P20-EXP-01b Integrate narrative display into ContentView above quest list
Depends on:
- P20-EXP-01a

### EXP-02: Reward Moment Redesign

- [x] P20-EXP-02a Create FloatingXPText component with upward drift animation
Depends on:
- P19-UX-15c

- [x] P20-EXP-02b Redesign HabitRow completion to multi-stage choreographed sequence
Depends on:
- P20-EXP-02a

- [x] P20-EXP-02c Add combo detection for rapid sequential completions in HabitsViewModel
Depends on:
- P20-EXP-02b

- [x] P20-EXP-02d Create CompletionSoundPlayer with optional audio cue
Depends on:
- P20-EXP-02b

### EXP-03: Morning Intention & Evening Reflection

- [x] P20-EXP-03a Create RitualManager for tracking daily intention state
Depends on:
- P20-EXP-01a

- [x] P20-EXP-03b Create MorningIntentionView with stat focus selection
Depends on:
- P20-EXP-03a

- [x] P20-EXP-03c Create EveningReflectionView with daily summary
Depends on:
- P20-EXP-03a

- [x] P20-EXP-03d Wire ritual presentation into RootView lifecycle
Depends on:
- P20-EXP-03b
- P20-EXP-03c

### EXP-04: Discipline Card

- [x] P20-EXP-04a Create DisciplineCardView with tier-adaptive gradient design
Depends on:
- P20-EXP-01a

- [x] P20-EXP-04b Create DisciplineCardRenderer using ImageRenderer for sharing
Depends on:
- P20-EXP-04a

- [x] P20-EXP-04c Create MilestoneCardTrigger and wire into celebration flow
Depends on:
- P20-EXP-04b

- [x] P20-EXP-04d Add Discipline Card entry point in ProfileView
Depends on:
- P20-EXP-04b

### EXP-05: Power Streaks

- [x] P20-EXP-05a Create StreakTierSystem with multiplier calculation
Depends on:
- P19-UX-15c

- [x] P20-EXP-05b Integrate streak multiplier into PerkSystem XP calculations
Depends on:
- P20-EXP-05a

- [x] P20-EXP-05c Add streak tier display to ContentView and multiplier to XP awards
Depends on:
- P20-EXP-05b

- [x] P20-EXP-05d Add tier-up celebration trigger in ProgressionEngine
Depends on:
- P20-EXP-05c

### EXP-06: Living UI

- [x] P20-EXP-06a Create UIEvolutionProvider deriving visual state from level
Depends on:
- P19-UX-15c

- [x] P20-EXP-06b Create EvolvingStyles with conditional surface and accent modifiers
Depends on:
- P20-EXP-06a

- [x] P20-EXP-06c Apply evolution styles to ContentView and AscensionView surfaces
Depends on:
- P20-EXP-06b

- [x] P20-EXP-06d Add ambient particles to Ascension at Apex level
Depends on:
- P20-EXP-06c

### EXP-07: Journey Map

- [x] P20-EXP-07a Create JourneyArc model and JourneyMapView scrollable path
Depends on:
- P20-EXP-09a

- [x] P20-EXP-07b Create JourneyMilestoneView nodes with tap-to-memory
Depends on:
- P20-EXP-07a

- [x] P20-EXP-07c Integrate journey map navigation from challenge summary and Ascension
Depends on:
- P20-EXP-07b

- [x] P20-EXP-07d Add post-90 "New Arc" flow and arc archive
Depends on:
- P20-EXP-07c

### EXP-08: Immersive Workout

- [x] P20-EXP-08a Create WorkoutPhase system with intensity-based state
Depends on:
- P19-UX-15c

- [x] P20-EXP-08b Add phase-based background gradient and encouragement text to timer
Depends on:
- P20-EXP-08a

- [x] P20-EXP-08c Create BreathingPacer component for longer sessions
Depends on:
- P20-EXP-08b

### EXP-09: Milestone Memories

- [x] P20-EXP-09a Create ProgressSnapshot model and MemoryService for persistence
Depends on:
- P19-UX-15c

- [x] P20-EXP-09b Create MemoryCardView with before/after radar comparison
Depends on:
- P20-EXP-09a

- [x] P20-EXP-09c Wire snapshot saving into ProgressionEngine at milestone triggers
Depends on:
- P20-EXP-09b

### EXP-10: Social Presence Layer

- [x] P20-EXP-10a Create SocialPresenceProvider with cached guild activity fetch
Depends on:
- P19-UX-15c

- [x] P20-EXP-10b Create GuildPulseBar component for daily member count
Depends on:
- P20-EXP-10a

- [x] P20-EXP-10c Integrate social presence into ContentView and AscensionView
Depends on:
- P20-EXP-10b

### EXP-11: Reading Experience Upgrade

- [x] P20-EXP-11a Create ReadingProfile model and ReadingProfileService
Depends on:
- P19-UX-15c

- [x] P20-EXP-11b Add current book, page tracking, and reading stats to ReadView
Depends on:
- P20-EXP-11a

- [x] P20-EXP-11c Add book completion flow with celebration
Depends on:
- P20-EXP-11b

### EXP-12: Seasonal Arcs

- [x] P20-EXP-12a Create SeasonalArc model and SeasonalArcSystem
Depends on:
- P20-EXP-05a

- [x] P20-EXP-12b Add arc progress display to ContentView
Depends on:
- P20-EXP-12a

- [x] P20-EXP-12c Create ArcArchiveView with completed and missed arcs
Depends on:
- P20-EXP-12b

### EXP-13: Focus Timer

- [x] P20-EXP-13a Create FocusSessionType definitions and FocusTimerView
Depends on:
- P19-UX-15c

- [x] P20-EXP-13b Wire Focus completion into ProgressionEngine for Mind/Focus XP
Depends on:
- P20-EXP-13a

- [x] P20-EXP-13c Add Focus quest generation to QuestGenerator for weak Mind/Focus
Depends on:
- P20-EXP-13b

### EXP-14: Passive Discovery Rewards (Easter Egg)

- [x] P20-EXP-14a Create Discovery model and PassiveDiscoverySystem with threshold evaluation
Depends on:
- P19-UX-15c

- [x] P20-EXP-14b Create DiscoveryService with HealthKit check on foreground and history persistence
Depends on:
- P20-EXP-14a

- [x] P20-EXP-14c Add discovery toast variant to NotificationManager (gold tint, sparkle icon)
Depends on:
- P20-EXP-14b

- [x] P20-EXP-14d Create DiscoveryLogView with earned and locked discoveries in Profile
Depends on:
- P20-EXP-14c

- [x] P20-EXP-14e Wire foreground discovery check into RootView app lifecycle
Depends on:
- P20-EXP-14c

### EXP-15: Discipline Quotes Engine

- [x] P20-EXP-15a Create QuoteEngine with 365 curated stoic/discipline quotes indexed by day
Depends on:
- P19-UX-15c

- [x] P20-EXP-15b Create QuoteFavoritesService for saving and loading favorite quotes
Depends on:
- P20-EXP-15a

- [x] P20-EXP-15c Integrate daily quote into MorningIntention, EveningReflection, Widget, and DisciplineCard
Depends on:
- P20-EXP-15b
- P20-EXP-03b

### EXP-16: Multi-Pillar Streak Dashboard

- [x] P20-EXP-16a Create PillarStreakSystem tracking independent streaks per discipline
Depends on:
- P19-UX-15c

- [x] P20-EXP-16b Create PillarStreakRow compact display component
Depends on:
- P20-EXP-16a

- [x] P20-EXP-16c Integrate pillar streaks into ContentView and wire update triggers
Depends on:
- P20-EXP-16b

### EXP-17: Weekly Discipline Report

- [x] P20-EXP-17a Create WeeklyReportService aggregating past 7 days from local data
Depends on:
- P19-UX-15c

- [x] P20-EXP-17b Create WeeklyReportView full-screen summary card
Depends on:
- P20-EXP-17a

- [x] P20-EXP-17c Add share-as-image rendering and weekly presentation trigger in RootView
Depends on:
- P20-EXP-17b

### EXP-18: Habit Agency System

- [x] P20-EXP-18a Create HabitPreset model with 12 curated options across 3 categories
Depends on:
- P19-UX-15c

- [x] P20-EXP-18b Create HabitSelectionView for onboarding pick-3 flow
Depends on:
- P20-EXP-18a

- [x] P20-EXP-18c Create HabitAgencyService managing selections, unlocks, and custom slots
Depends on:
- P20-EXP-18b

- [x] P20-EXP-18d Create CustomHabitCreationView with free text and stat assignment
Depends on:
- P20-EXP-18c

- [x] P20-EXP-18e Wire habit selections into QuestGenerator and onboarding AppStateManager flow
Depends on:
- P20-EXP-18d

### EXP-19: Live Activity & Ambient Presence

- [x] P20-EXP-19a Create RNFLiveActivity with ActivityAttributes and content state
Depends on:
- P19-UX-15c

- [x] P20-EXP-19b Create Live Activity lock screen and Dynamic Island views
Depends on:
- P20-EXP-19a

- [x] P20-EXP-19c Wire Activity updates on habit completion and daily goal reached
Depends on:
- P20-EXP-19b

- [x] P20-EXP-19d Upgrade Watch complication with streak tier icon and progress ring
Depends on:
- P20-EXP-19a

### The Forge Voice

- [x] P20-VOX-01 Create ForgeVoice utility with AVSpeechSynthesizer, rate 0.42, pitch 0.85, daily limit 2
Depends on:
- P19-UX-15c

- [x] P20-VOX-02 Add voice selection setting in Profile (Off/System/Oracle) with "Activated" confirmation
Depends on:
- P20-VOX-01

- [x] P20-VOX-03 Wire voice triggers into morning ritual, celebrations, boss spawn, discovery, and streak milestones
Depends on:
- P20-VOX-02

## Phase 21 – Production Blockers & UI/UX Fixes

### Critical Safety Fixes

- [x] P21-FIX-01 Replace fatalError in AppConfig with graceful Optional return and add runtime validation
Depends on:
- P20-VOX-03

- [x] P21-FIX-02 Update SupabaseService.init to handle nil URL gracefully with error state instead of crash
Depends on:
- P21-FIX-01

- [x] P21-FIX-03 Refactor FocusCompletionHandler to route XP updates through gameState.apply(updatedProfile:)
Depends on:
- P20-VOX-03

- [x] P21-FIX-04 Add WCSessionDelegate to RNFWatch target with didReceiveMessageData handler calling WatchAppState.update
Depends on:
- P20-VOX-03

- [x] P21-FIX-05 Update WatchComplicationProvider to read real data from WatchAppState instead of hardcoded values
Depends on:
- P21-FIX-04

- [x] P21-FIX-06 Create AccountDeletionService with cascade delete across all user tables and storage cleanup
Depends on:
- P21-FIX-02

- [x] P21-FIX-07 Add Supabase migration for account deletion RPC function with cascade logic
Depends on:
- P21-FIX-06

- [x] P21-FIX-08 Create AccountDeletionView with confirmation flow, 7-day grace period, and danger zone UI
Depends on:
- P21-FIX-07

- [x] P21-FIX-09 Add ASAuthorizationAppleIDProvider integration to AuthService with credential state handling
Depends on:
- P21-FIX-02

- [x] P21-FIX-10 Create AppleSignInButton component and integrate into LoginView and SignUpView
Depends on:
- P21-FIX-09

- [x] P21-FIX-11 Add credential revocation observer for Sign in with Apple in AppDelegate lifecycle
Depends on:
- P21-FIX-10

### Navigation & Discoverability

- [x] P21-NAV-01 Create ProfileTabView with sectioned NavigationStack (Identity, Progress, Social, Tools, Settings)
Depends on:
- P21-FIX-03

- [x] P21-NAV-02 Add 5th tab to RNFTabBar with profile/menu icon and update RootView TabView
Depends on:
- P21-NAV-01

- [x] P21-NAV-03 Add NavigationLinks in ProfileTabView to SkillTreeView, EvolutionView, AchievementsGalleryView
Depends on:
- P21-NAV-02

- [x] P21-NAV-04 Add NavigationLinks in ProfileTabView to SocialTabView, FocusTimerView, DiscoveryLogView, ArcArchiveView
Depends on:
- P21-NAV-02

- [x] P21-NAV-05 Replace .tabViewStyle(.page) with .tabViewStyle(.automatic) in RootView to fix gesture conflicts
Depends on:
- P21-NAV-02

- [x] P21-NAV-06 Add LoginView "Create Account" button navigating to SignUpView and vice versa
Depends on:
- P21-FIX-10

### Accessibility & Dynamic Type

- [x] P21-A11Y-01 Refactor Typography.swift to use @ScaledMetric for all RNFFont size tokens
Depends on:
- P21-NAV-05

- [x] P21-A11Y-02 Add .dynamicTypeSize range limits to prevent extreme sizes breaking layouts
Depends on:
- P21-A11Y-01

- [x] P21-A11Y-03 Add accessibilityLabel to FocusTimerView countdown display with minutes and seconds
Depends on:
- P21-NAV-05

- [x] P21-A11Y-04 Add accessibilityLabel to ActiveWorkoutTimerView countdown display
Depends on:
- P21-NAV-05

- [x] P21-A11Y-05 Add accessibilityLabel to GuildPulseBar with member count context
Depends on:
- P21-NAV-05

### UI Quality Fixes

- [x] P21-UI-01 Add .refreshable modifier to ContentView calling viewModel.load
Depends on:
- P21-NAV-05

- [x] P21-UI-02 Add .refreshable modifier to AscensionView with reload of calendar and challenge data
Depends on:
- P21-NAV-05

- [x] P21-UI-03 Add .refreshable modifier to WorkoutListView and ReadView
Depends on:
- P21-NAV-05

- [x] P21-UI-04 Add ErrorStateView display in ContentView when loadErrorMessage is set and habits are empty
Depends on:
- P21-UI-01

- [x] P21-UI-05 Create ContentUnavailableView-based empty states for SocialTabView, AchievementsGalleryView, DiscoveryLogView
Depends on:
- P21-NAV-04

- [x] P21-UI-06 Replace hardcoded Color literals in HabitRow with RNFColors semantic tokens
Depends on:
- P21-A11Y-01

- [x] P21-UI-07 Replace hardcoded Color literals in DailyMissionBar and FocusTimerView with RNFColors tokens
Depends on:
- P21-A11Y-01

- [x] P21-UI-08 Replace all hardcoded cornerRadius values across Components/ with RNFRadius tokens
Depends on:
- P21-A11Y-01

- [x] P21-UI-09 Fix Task leak in AmbientParticleView by storing handle in @State and cancelling in onDisappear
Depends on:
- P21-NAV-05

- [x] P21-UI-10 Move service objects out of view struct stored properties into @StateObject ViewModels or static lets
Depends on:
- P21-NAV-05

- [x] P21-UI-11 Move DiscoveryLogView data loading from init to .task modifier with @State storage
Depends on:
- P21-UI-10

- [x] P21-UI-12 Replace Array VectorArithmetic retroactive conformance with dedicated AnimatableVector wrapper type
Depends on:
- P21-NAV-05

- [x] P21-UI-13 Add WidgetCenter.shared.reloadAllTimelines() call after state changes in ProgressionEngine
Depends on:
- P21-FIX-03

### Data Integrity

- [x] P21-DATA-01 Extend OfflineWriteQueue to support generic PendingWrite operations for workouts and reading
Depends on:
- P21-FIX-03

- [x] P21-DATA-02 Add retry with exponential backoff to SyncFlushService for failed flush operations
Depends on:
- P21-DATA-01

- [x] P21-DATA-03 Add max queue size (500 items) and 30-day TTL eviction to OfflineWriteQueue
Depends on:
- P21-DATA-02

- [x] P21-DATA-04 Create discoveries Supabase migration table for server-side persistence
Depends on:
- P21-FIX-07

- [x] P21-DATA-05 Update DiscoveryService to persist discoveries to Supabase with local cache fallback
Depends on:
- P21-DATA-04

- [x] P21-DATA-06 Create custom_habits Supabase migration table with user_id and habit definition
Depends on:
- P21-FIX-07

- [x] P21-DATA-07 Update HabitAgencyService to sync custom habits to Supabase instead of UserDefaults only
Depends on:
- P21-DATA-06

- [x] P21-DATA-08 Create pillar_streaks Supabase migration table for server-side persistence
Depends on:
- P21-FIX-07

- [x] P21-DATA-09 Update PillarStreakService to sync to Supabase with local cache fallback
Depends on:
- P21-DATA-08

- [x] P21-DATA-10 Align WorkoutSession Swift model fields with workouts DB table columns via DTO mapping
Depends on:
- P21-DATA-01

- [x] P21-DATA-11 Fix WeeklyReportService to query real completion data from DailyLogService instead of approximations
Depends on:
- P21-UI-01

- [x] P21-DATA-12 Fix WatchSyncService data race by marking closure properties @Sendable and gating access on MainActor
Depends on:
- P21-FIX-04

### Tests

- [x] P21-TST-01 Add unit tests for AppConfig graceful nil handling and SupabaseService error state
Depends on:
- P21-FIX-02

- [x] P21-TST-02 Add unit tests for FocusCompletionHandler verifying profile XP consistency after apply
Depends on:
- P21-FIX-03

- [x] P21-TST-03 Add unit tests for AccountDeletionService cascade delete logic
Depends on:
- P21-FIX-08

- [x] P21-TST-04 Add unit tests for OfflineWriteQueue generic operations, TTL eviction, and retry backoff
Depends on:
- P21-DATA-03

- [x] P21-TST-05 Add unit tests for Watch incoming message handler and complication real data display
Depends on:
- P21-FIX-05

## Phase 22 – Onboarding Redesign & Emotional Design

### Try-Before-Commit Flow

- [x] P22-ONB-01 Create GuestSessionManager handling anonymous local state with 3-day TTL
Depends on:
- P21-TST-05

- [x] P22-ONB-02 Create TryHabitView allowing single habit completion with XP animation before signup
Depends on:
- P22-ONB-01

- [x] P22-ONB-03 Create GuestDataMigrationService to transfer anonymous progress to authenticated profile on signup
Depends on:
- P22-ONB-01

- [x] P22-ONB-04 Update AppStateManager to route first-launch users to try-before-commit flow instead of direct auth
Depends on:
- P22-ONB-02

### Identity & Archetype

- [x] P22-ONB-05 Create ArchetypeQuiz model with 3 questions and 27 archetype combinations mapping
Depends on:
- P22-ONB-04

- [x] P22-ONB-06 Create ArchetypeQuizView with animated question cards and stat distribution preview
Depends on:
- P22-ONB-05

- [x] P22-ONB-07 Create ForgeNameView replacing commitment checkbox with name input and forge ignition animation
Depends on:
- P22-ONB-06

- [x] P22-ONB-08 Persist archetype and forge name to Profile model and Supabase users table
Depends on:
- P22-ONB-07

### First-Session Victory

- [x] P22-ONB-09 Create FirstVictoryView showing earned XP, level, and Spark Initiate title after first completion
Depends on:
- P22-ONB-04

- [x] P22-ONB-10 Create Day1ShareCard rendered milestone image with branding and App Store link
Depends on:
- P22-ONB-09

- [x] P22-ONB-11 Add share prompt in FirstVictoryView with UIActivityViewController for milestone card
Depends on:
- P22-ONB-10

### Progressive Onboarding

- [x] P22-ONB-12 Create FeatureRevealSchedule mapping features to unlock days (streaks Day 3, quests Day 7, skills Day 14)
Depends on:
- P22-ONB-08

- [x] P22-ONB-13 Integrate TipKit for contextual feature discovery on first encounter with each unlocked feature
Depends on:
- P22-ONB-12

- [x] P22-ONB-14 Update FeatureGate to check both level requirements AND day-since-install for progressive unlock
Depends on:
- P22-ONB-12

### Low-Commitment 7-Day Mode

- [x] P22-ONB-15 Add CommitmentStage enum (.exploration, .foundation, .full) to Profile model
Depends on:
- P22-ONB-08

- [x] P22-ONB-16 Create 7DayExplorationView entry path with no-commitment framing and amber forge variant
Depends on:
- P22-ONB-15

- [x] P22-ONB-17 Create Day7UpsellView showing user's own data as proof of consistency with upgrade prompt
Depends on:
- P22-ONB-16

- [x] P22-ONB-18 Create Day30FoundationUpsellView promoting full 90-day commitment with streak preservation
Depends on:
- P22-ONB-17

### Welcome-Back Flow

- [x] P22-EMO-01 Add days_since_last_activity detection in AppStateManager foreground handler
Depends on:
- P22-ONB-18

- [x] P22-EMO-02 Create WelcomeBackView with reduced 1-habit goal, hidden calendar, and warm narrative copy
Depends on:
- P22-EMO-01

- [x] P22-EMO-03 Add routing logic to show WelcomeBackView when absence >= 2 days and no active streak freeze
Depends on:
- P22-EMO-02

- [x] P22-EMO-04 Restore normal home view the day after welcome-back completion
Depends on:
- P22-EMO-03

### Graduated Success

- [x] P22-EMO-05 Add completion_ratio computed property to DailyLog model (completed/total habits)
Depends on:
- P22-EMO-04

- [x] P22-EMO-06 Create GraduatedSuccessView with tier-appropriate narrative (1/4, 2/4, 3/4, 4/4)
Depends on:
- P22-EMO-05

- [x] P22-EMO-07 Update CalendarGridView to show gradient fill intensity based on completion ratio instead of binary
Depends on:
- P22-EMO-06

### Life Happened Pause

- [x] P22-EMO-08 Create pause_periods Supabase migration table (user_id, start_date, end_date, cycle_id)
Depends on:
- P22-EMO-04

- [x] P22-EMO-09 Create PauseService with activate, validate (1/cycle max 14 days), and query methods
Depends on:
- P22-EMO-08

- [x] P22-EMO-10 Create LifeHappenedView prompt shown on return after 7+ missed days offering retroactive pause
Depends on:
- P22-EMO-09

- [x] P22-EMO-11 Update StreakSystem to skip paused days in consecutive calculation
Depends on:
- P22-EMO-09

- [x] P22-EMO-12 Update CalendarGridView to render paused days as blue with lotus icon
Depends on:
- P22-EMO-11

### Streak-Free & Rest Days

- [x] P22-EMO-13 Add streakDisplayMode (.streak, .totalDays, .hidden) to Profile model
Depends on:
- P22-EMO-04

- [x] P22-EMO-14 Create StreakDisplayToggle setting in ProfileView respecting display mode
Depends on:
- P22-EMO-13

- [x] P22-EMO-15 Add rest day status case to DailyLog.Status and update streak calculation to skip rest days
Depends on:
- P22-EMO-13

- [x] P22-EMO-16 Create RestDayView banner shown when user activates intentional rest (1 per 7 days limit)
Depends on:
- P22-EMO-15

### Humor & Sensitivity

- [x] P22-EMO-17 Add 20 light-tone narrative templates to NarrativeEngine tagged with tone: .light
Depends on:
- P22-EMO-04

- [x] P22-EMO-18 Add light-tone selection rule: 5% random when streak > 14, never on failure states
Depends on:
- P22-EMO-17

- [x] P22-EMO-19 Add bossDisplayMode (.full, .neutral) to Profile model with setting toggle
Depends on:
- P22-EMO-13

- [x] P22-EMO-20 Create neutral BossBattleView variant replacing adversary names with "Consistency Check" framing
Depends on:
- P22-EMO-19

### Tests

- [x] P22-TST-01 Add unit tests for GuestSessionManager TTL expiry and data migration
Depends on:
- P22-ONB-03

- [x] P22-TST-02 Add unit tests for ArchetypeQuiz combination mapping correctness
Depends on:
- P22-ONB-05

- [x] P22-TST-03 Add unit tests for PauseService validation (1/cycle, 14-day max, streak preservation)
Depends on:
- P22-EMO-11

- [x] P22-TST-04 Add unit tests for StreakSystem with rest days and paused days skipped correctly
Depends on:
- P22-EMO-15

- [x] P22-TST-05 Add unit tests for graduated completion ratio calculation and narrative tier selection
Depends on:
- P22-EMO-06

## Phase 23 – Monetization (StoreKit 2)

### Subscription Infrastructure

- [x] P23-MON-01 Create StoreKit configuration file with product IDs (com.rnf.pro.monthly, yearly, lifetime)
Depends on:
- P22-TST-05

- [x] P23-MON-02 Implement SubscriptionManager with Product loading, purchase, and Transaction.currentEntitlements
Depends on:
- P23-MON-01

- [x] P23-MON-03 Add subscription state persistence to local Keychain and Supabase subscriptions table
Depends on:
- P23-MON-02

- [x] P23-MON-04 Implement Transaction.updates listener for real-time entitlement changes and renewal handling
Depends on:
- P23-MON-03

- [x] P23-MON-05 Create Supabase edge function for Apple Server Notifications V2 webhook verification
Depends on:
- P23-MON-03

- [x] P23-MON-06 Add grace period and billing retry handling in SubscriptionManager
Depends on:
- P23-MON-04

### Feature Gating

- [x] P23-MON-07 Create SubscriptionGate utility checking entitlement before Pro feature access
Depends on:
- P23-MON-04

- [x] P23-MON-08 Add free tier limits: cap level at 10, limit to 3 habits, restrict skill tree access
Depends on:
- P23-MON-07

- [x] P23-MON-09 Add locked state overlays to Pro features (skill tree, focus timer, weekly report, boss battles)
Depends on:
- P23-MON-08

### Trial System

- [x] P23-MON-10 Implement 14-day full trial activation on first signup with trial_end_date tracking
Depends on:
- P23-MON-07

- [x] P23-MON-11 Create TrialExpiryBanner shown from Day 12 with loss-aversion messaging referencing user's streak
Depends on:
- P23-MON-10

- [x] P23-MON-12 Create soft paywall transition on Day 15 showing features being locked with upgrade CTA
Depends on:
- P23-MON-11

### Paywall UI

- [x] P23-MON-13 Create RNFPaywallView with SubscriptionStoreView integration showing all 3 tiers
Depends on:
- P23-MON-02

- [x] P23-MON-14 Add contextual paywall trigger points (locked feature tap, trial expiry, settings)
Depends on:
- P23-MON-13

- [x] P23-MON-15 Add current streak display in paywall UI for loss-aversion framing
Depends on:
- P23-MON-14

- [x] P23-MON-16 Create SubscriptionManagementView in Profile settings with plan details and cancel flow
Depends on:
- P23-MON-13

### Restore & Migration

- [x] P23-MON-17 Implement restore purchases flow with AppStore.sync() and UI feedback
Depends on:
- P23-MON-02

- [x] P23-MON-18 Create migration plan for existing users: 30-day extended trial + Founding Forger badge
Depends on:
- P23-MON-10

### Tests

- [x] P23-TST-01 Add unit tests for SubscriptionManager entitlement resolution and state transitions
Depends on:
- P23-MON-06

- [x] P23-TST-02 Add unit tests for feature gating logic (free vs pro access per feature)
Depends on:
- P23-MON-09

- [x] P23-TST-03 Add unit tests for trial expiry calculation and paywall trigger timing
Depends on:
- P23-MON-12

- [x] P23-TST-04 Add StoreKit testing configuration for sandbox purchase verification
Depends on:
- P23-MON-17

## Phase 24 – Retention Psychology & Growth

### Variable Rewards (Critical Hits)

- [x] P24-RET-01 Create CriticalHitEngine with seeded RNG per user+day+habitID and 20% base crit rate
Depends on:
- P23-TST-04

- [x] P24-RET-02 Integrate CriticalHitEngine into ProgressionEngine XP calculation with 2x-3x multiplier
Depends on:
- P24-RET-01

- [x] P24-RET-03 Create CriticalHitAnimation component with gold flash, screen shake, and distinct haptic
Depends on:
- P24-RET-02

- [x] P24-RET-04 Wire critical hit visual into HabitRow completion sequence when crit triggers
Depends on:
- P24-RET-03

- [x] P24-RET-05 Add streak tier crit chance bonus (Ember +5%, Flame +10%, Blaze +15%, Inferno +20%)
Depends on:
- P24-RET-04

### Endowed Progress

- [x] P24-RET-06 Update streak display logic to show "1" immediately on first-ever habit completion (not end-of-day)
Depends on:
- P24-RET-05

- [x] P24-RET-07 Update challenge progress bar to show 1/90 filled on Day 1 first completion
Depends on:
- P24-RET-06

### Social Proof

- [x] P24-RET-08 Create Supabase edge function aggregating today's total habit_completions count with 5-min cache
Depends on:
- P24-RET-07

- [x] P24-RET-09 Create CommunityCounterView component displaying "X habits completed today" with CountUp animation
Depends on:
- P24-RET-08

- [x] P24-RET-10 Integrate CommunityCounterView at bottom of ContentView home screen
Depends on:
- P24-RET-09

### Forge Tokens Economy

- [x] P24-RET-11 Add forge_tokens column to users table via Supabase migration
Depends on:
- P24-RET-07

- [x] P24-RET-12 Create token_transactions table migration for ledger (user_id, amount, reason, created_at)
Depends on:
- P24-RET-11

- [x] P24-RET-13 Create ForgeTokenService with earn, spend, and balance query methods
Depends on:
- P24-RET-12

- [x] P24-RET-14 Wire token earning into: challenge completion (+5), boss defeat (+3), weekly streak (+2), daily login (+1)
Depends on:
- P24-RET-13

- [x] P24-RET-15 Create ForgeTokenShopView with cosmetic items (profile borders, streak colors, card backgrounds)
Depends on:
- P24-RET-14

- [x] P24-RET-16 Create cosmetic_unlocks table migration and persist purchased cosmetics per user
Depends on:
- P24-RET-15

### Streak Freezes

- [x] P24-RET-17 Add streak_freezes field to Profile model and Supabase users table
Depends on:
- P24-RET-13

- [x] P24-RET-18 Implement auto-apply streak freeze on missed day before streak breaks
Depends on:
- P24-RET-17

- [x] P24-RET-19 Add Pro subscriber monthly freeze allocation (3/month) in SubscriptionManager
Depends on:
- P24-RET-18

- [x] P24-RET-20 Add Forge Token purchase path for additional freezes (10 tokens = 1 freeze, max 2/month)
Depends on:
- P24-RET-18

### Leaderboard Leagues

- [x] P24-RET-21 Create league_assignments Supabase migration (user_id, tier, instance_id, week_start, weekly_xp)
Depends on:
- P24-RET-11

- [x] P24-RET-22 Create LeagueService with join, weekly XP update, and tier query methods
Depends on:
- P24-RET-21

- [x] P24-RET-23 Create Supabase edge function for weekly league recalculation (top 5 promote, bottom 5 demote)
Depends on:
- P24-RET-22

- [x] P24-RET-24 Create LeagueView with current tier, position, promotion/demotion zones highlighted
Depends on:
- P24-RET-23

- [x] P24-RET-25 Add league tier badge display in Profile and Discipline Card
Depends on:
- P24-RET-24

### Shareable Milestones

- [x] P24-GRO-01 Create MilestoneCardGenerator producing branded 9:16 images for streak 7, 14, 30, level milestones
Depends on:
- P24-RET-07

- [x] P24-GRO-02 Create SharePromptView triggered on milestone with UIActivityViewController
Depends on:
- P24-GRO-01

- [x] P24-GRO-03 Wire milestone card generation into ProgressionEngine tier-up and level-up triggers
Depends on:
- P24-GRO-02

### Referral System

- [x] P24-GRO-04 Create referrals Supabase migration table (referrer_id, referee_id, code, status, rewarded_at)
Depends on:
- P24-RET-11

- [x] P24-GRO-05 Create ReferralService with code generation, validation, and reward distribution
Depends on:
- P24-GRO-04

- [x] P24-GRO-06 Create InviteFriendView in Profile with unique code display and share action
Depends on:
- P24-GRO-05

- [x] P24-GRO-07 Add deep link handler for rnf://invite/{code} auto-applying referral on signup
Depends on:
- P24-GRO-06

- [x] P24-GRO-08 Wire referral reward (+1 forgiveness token + 5 Forge Tokens) on referee Day 3 completion
Depends on:
- P24-GRO-07

### 1v1 Micro-Challenges

- [x] P24-GRO-09 Create micro_challenges Supabase migration table (challenger, challengee, scores, dates, winner)
Depends on:
- P24-RET-11

- [x] P24-GRO-10 Create MicroChallengeService with create, join, update score, and resolve winner methods
Depends on:
- P24-GRO-09

- [x] P24-GRO-11 Create MicroChallengeView with comparison card showing both users' daily completions
Depends on:
- P24-GRO-10

- [x] P24-GRO-12 Create challenge invite flow via share link and acceptance handler
Depends on:
- P24-GRO-11

### Content Moderation

- [x] P24-GRO-13 Create content_reports Supabase migration table (reporter_id, content_type, content_id, reason, status)
Depends on:
- P24-RET-11

- [x] P24-GRO-14 Create ContentModerationService with report submission, client-side profanity filter, and block user
Depends on:
- P24-GRO-13

- [x] P24-GRO-15 Add long-press "Report" action on guild names, social challenge titles, and display names
Depends on:
- P24-GRO-14

- [x] P24-GRO-16 Create Supabase edge function for auto-hide on 3 reports and escalation rules
Depends on:
- P24-GRO-15

### Notifications Enhancement

- [x] P24-GRO-17 Create NotificationContentRotator with 20+ message variants per notification type
Depends on:
- P24-RET-07

- [x] P24-GRO-18 Add streak-at-risk notification (sent at 8 PM if 0 completions today)
Depends on:
- P24-GRO-17

- [x] P24-GRO-19 Add milestone celebration push notification on streak 7, 14, 30, and level-ups
Depends on:
- P24-GRO-17

- [x] P24-GRO-20 Add comeback notification after 3 days of absence with warm re-engagement copy
Depends on:
- P24-GRO-17

### Tests

- [x] P24-TST-01 Add unit tests for CriticalHitEngine seeded RNG determinism and crit rate distribution
Depends on:
- P24-RET-05

- [x] P24-TST-02 Add unit tests for ForgeTokenService earn/spend/balance with insufficient funds handling
Depends on:
- P24-RET-15

- [x] P24-TST-03 Add unit tests for streak freeze auto-apply and monthly allocation limits
Depends on:
- P24-RET-20

- [x] P24-TST-04 Add unit tests for LeagueService weekly recalculation and tier transitions
Depends on:
- P24-RET-25

- [x] P24-TST-05 Add unit tests for ReferralService code validation and reward timing
Depends on:
- P24-GRO-08

## Phase 25 – Intelligence & Personalization

### Adaptive Notification Timing

- [x] P25-INT-01 Create completion_timestamps analytics table tracking habit completion times per user
Depends on:
- P24-TST-05

- [x] P25-INT-02 Create AdaptiveTimingService computing median completion time from 14+ days of data
Depends on:
- P25-INT-01

- [x] P25-INT-03 Add weekday vs weekend split to adaptive timing model
Depends on:
- P25-INT-02

- [x] P25-INT-04 Update NotificationScheduler to use adaptive timing when available, fallback to user-set time
Depends on:
- P25-INT-03

- [x] P25-INT-05 Add drift detection: re-adapt when median shifts 30+ minutes over 7 days
Depends on:
- P25-INT-04

### Dynamic Daily Goal

- [x] P25-INT-06 Create DifficultyAdvisor service computing trailing 7-day completion rate
Depends on:
- P25-INT-01

- [x] P25-INT-07 Add suggest-increase logic when completion rate > 90% for 7 consecutive days
Depends on:
- P25-INT-06

- [x] P25-INT-08 Add suggest-decrease logic when completion rate < 50% for 3 consecutive days
Depends on:
- P25-INT-06

- [x] P25-INT-09 Create DifficultyBanner UI component for goal adjustment suggestions with accept/dismiss
Depends on:
- P25-INT-07

- [x] P25-INT-10 Create difficulty_adjustments table to persist user responses to suggestions
Depends on:
- P25-INT-09

- [x] P25-INT-11 Add cooldown rules: no increase suggestion in first 14 days, no decrease in first 7 days
Depends on:
- P25-INT-08

### Behavioral Insights

- [x] P25-INT-12 Create InsightEngine analyzing 28-day completion data for patterns
Depends on:
- P25-INT-06

- [x] P25-INT-13 Implement best/worst day of week insight with statistical significance threshold
Depends on:
- P25-INT-12

- [x] P25-INT-14 Implement time-of-day correlation insight (morning completions vs full day success)
Depends on:
- P25-INT-12

- [x] P25-INT-15 Implement stat growth rate insight highlighting fastest-growing pillar
Depends on:
- P25-INT-12

- [x] P25-INT-16 Create weekly_insights table and integrate top 1-2 insights into WeeklyReportView
Depends on:
- P25-INT-15

### Churn Prediction

- [x] P25-INT-17 Create EngagementStateManager with 5 states (Engaged, AtRisk, Drifting, Lapsed, Churned)
Depends on:
- P25-INT-06

- [x] P25-INT-18 Implement state transition rules based on app open frequency and completion rate
Depends on:
- P25-INT-17

- [x] P25-INT-19 Wire AtRisk state to show "Just do one" in-app banner with reduced daily goal
Depends on:
- P25-INT-18

- [x] P25-INT-20 Wire Drifting state to escalated push notification with streak-at-risk messaging
Depends on:
- P25-INT-18

- [x] P25-INT-21 Wire Lapsed state to final warm push notification (max 1 per lapse cycle)
Depends on:
- P25-INT-20

- [x] P25-INT-22 Add safeguard: max 5 re-engagement pushes per 30-day period, never push after Churned
Depends on:
- P25-INT-21

### Quest Personalization

- [x] P25-INT-23 Add quest completion tracking per type to QuestRepository
Depends on:
- P25-INT-12

- [x] P25-INT-24 Update QuestGenerator with multi-factor scoring: stat_weakness 50% + preference 30% + freshness 20%
Depends on:
- P25-INT-23

- [x] P25-INT-25 Add quest fatigue rule: rotate to different type after 3 consecutive days of same type
Depends on:
- P25-INT-24

### Habit Difficulty Profiling

- [x] P25-INT-26 Create HabitDifficultyProfiler computing per-habit completion rate over 30 days
Depends on:
- P25-INT-12

- [x] P25-INT-27 Classify habits as Easy (>90%), Moderate (60-90%), Hard (<60%) with weekly recomputation
Depends on:
- P25-INT-26

- [x] P25-INT-28 Add +3 bonus XP for Hard-classified habits in ProgressionEngine
Depends on:
- P25-INT-27

- [x] P25-INT-29 Add difficulty indicator icon to HabitRow based on classification
Depends on:
- P25-INT-27

- [x] P25-INT-30 Add "habit ordering" setting: hardest-first (eat the frog) or easiest-first (momentum)
Depends on:
- P25-INT-29

### Tests

- [x] P25-TST-01 Add unit tests for AdaptiveTimingService median calculation and drift detection
Depends on:
- P25-INT-05

- [x] P25-TST-02 Add unit tests for DifficultyAdvisor thresholds and cooldown rules
Depends on:
- P25-INT-11

- [x] P25-TST-03 Add unit tests for InsightEngine pattern detection with minimum variance requirements
Depends on:
- P25-INT-16

- [x] P25-TST-04 Add unit tests for EngagementStateManager transitions and push safeguards
Depends on:
- P25-INT-22

- [x] P25-TST-05 Add unit tests for HabitDifficultyProfiler classification boundaries and XP bonus
Depends on:
- P25-INT-28

## Phase 26 – Apple Platform Integration

### App Intents & Shortcuts

- [x] P26-APL-01 Create CompleteHabitIntent AppIntent with habit name parameter and perform() logic
Depends on:
- P25-TST-05

- [x] P26-APL-02 Create StartFocusIntent AppIntent with duration parameter triggering focus session
Depends on:
- P26-APL-01

- [x] P26-APL-03 Create StartWorkoutIntent AppIntent with workout type parameter
Depends on:
- P26-APL-01

- [x] P26-APL-04 Create CheckStreakIntent AppIntent returning current streak and tier as spoken result
Depends on:
- P26-APL-01

- [x] P26-APL-05 Create RNFShortcutsProvider with suggested shortcuts for each intent
Depends on:
- P26-APL-04

- [x] P26-APL-06 Add Spotlight donations for recently completed habits via CSSearchableItem
Depends on:
- P26-APL-05

### Background App Refresh

- [x] P26-APL-07 Register BGAppRefreshTaskRequest (com.rnf.refresh) in app init for hourly widget data update
Depends on:
- P26-APL-01

- [x] P26-APL-08 Register BGProcessingTaskRequest (com.rnf.sync) for offline queue flush on WiFi
Depends on:
- P26-APL-07

- [x] P26-APL-09 Register BGProcessingTaskRequest (com.rnf.analytics) for batched analytics upload
Depends on:
- P26-APL-07

- [x] P26-APL-10 Create BackgroundTaskManager coordinating registration, scheduling, and handlers
Depends on:
- P26-APL-09

### Interactive Widgets

- [x] P26-APL-11 Create CompleteHabitFromWidgetIntent using AppIntent for widget button interaction
Depends on:
- P26-APL-01

- [x] P26-APL-12 Create medium interactive widget with habit checkboxes using Button(intent:) pattern
Depends on:
- P26-APL-11

- [x] P26-APL-13 Create large interactive widget with habits + quest status + streak display
Depends on:
- P26-APL-12

- [x] P26-APL-14 Add .accessoryCircular and .accessoryRectangular Lock Screen widget families
Depends on:
- P26-APL-12

- [x] P26-APL-15 Add StandBy-optimized layout for rectangular widget (dark background, large type)
Depends on:
- P26-APL-14

### Control Center (iOS 18+)

- [x] P26-APL-16 Create ControlWidget with ControlWidgetButton triggering CompleteHabitIntent
Depends on:
- P26-APL-11

- [x] P26-APL-17 Add Control Center widget showing next uncompleted habit name with tap-to-complete
Depends on:
- P26-APL-16

### HealthKit Auto-Tracking

- [x] P26-APL-18 Create HealthKitAutoTracker with HKObserverQuery background delivery for steps
Depends on:
- P26-APL-10

- [x] P26-APL-19 Add auto-complete logic for step-count habit when daily threshold met
Depends on:
- P26-APL-18

- [x] P26-APL-20 Add HKObserverQuery for appleExerciseTime with auto-complete on threshold
Depends on:
- P26-APL-18

- [x] P26-APL-21 Add HKObserverQuery for sleepAnalysis with auto-complete on duration threshold
Depends on:
- P26-APL-18

- [x] P26-APL-22 Add user toggle "Auto-track from Health" per habit with threshold configuration
Depends on:
- P26-APL-21

### HealthKit Write-Back

- [x] P26-APL-23 Create HealthKitWriter for saving RNF workouts as HKWorkout samples
Depends on:
- P26-APL-22

- [x] P26-APL-24 Create HealthKitWriter for saving focus sessions as HKCategoryType.mindfulSession
Depends on:
- P26-APL-23

- [x] P26-APL-25 Add opt-in prompt "Sync to Apple Health?" on first workout completion with setting toggle
Depends on:
- P26-APL-24

### App Attest

- [x] P26-APL-26 Implement DCAppAttestService key generation and attestation on first launch
Depends on:
- P26-APL-10

- [x] P26-APL-27 Create assertion generator for leaderboard and XP submission requests
Depends on:
- P26-APL-26

- [x] P26-APL-28 Create Supabase edge function for server-side attestation verification
Depends on:
- P26-APL-27

- [x] P26-APL-29 Add graceful degradation: mark unverified submissions when attestation unavailable
Depends on:
- P26-APL-28

### Live Activities Expansion

- [x] P26-APL-30 Create WorkoutTimerLiveActivity with elapsed time and progress to completion threshold
Depends on:
- P26-APL-10

- [x] P26-APL-31 Create FocusSessionLiveActivity with countdown timer and session name
Depends on:
- P26-APL-30

- [x] P26-APL-32 Add Dynamic Island compact and expanded views for workout and focus activities
Depends on:
- P26-APL-31

- [x] P26-APL-33 Wire Live Activity start/update/end into WorkoutEngine and FocusTimerView lifecycle
Depends on:
- P26-APL-32

### Deep Linking

- [x] P26-APL-34 Create DeepLinkRouter parsing rnf:// URL scheme into navigation destinations
Depends on:
- P26-APL-01

- [x] P26-APL-35 Add Associated Domains entitlement and apple-app-site-association for Universal Links
Depends on:
- P26-APL-34

- [x] P26-APL-36 Wire onOpenURL handler in RNFApp routing to DeepLinkRouter
Depends on:
- P26-APL-35

- [x] P26-APL-37 Add widgetURL to all widget families for tap-to-navigate-to-specific-screen
Depends on:
- P26-APL-36

### Tests

- [x] P26-TST-01 Add unit tests for all AppIntents perform() logic and error handling
Depends on:
- P26-APL-05

- [x] P26-TST-02 Add unit tests for BackgroundTaskManager scheduling and handler coordination
Depends on:
- P26-APL-10

- [x] P26-TST-03 Add unit tests for HealthKitAutoTracker threshold evaluation and auto-complete
Depends on:
- P26-APL-22

- [x] P26-TST-04 Add unit tests for DeepLinkRouter URL parsing for all route patterns
Depends on:
- P26-APL-37

## Phase 27 – Lifecycle & Endgame

### Post-90 Chapters

- [x] P27-LIF-01 Create chapters Supabase migration table (user_id, chapter_number, objective_type, target, progress, dates)
Depends on:
- P26-TST-04

- [x] P27-LIF-02 Create ChapterService managing chapter creation, progress updates, and completion detection
Depends on:
- P27-LIF-01

- [x] P27-LIF-03 Define Chapter 2-5 objectives: new pillar (stat>25), balanced (all>15), specialist (one>40), complete (all>25)
Depends on:
- P27-LIF-02

- [x] P27-LIF-04 Create ChapterBannerView replacing challenge day counter after Day 90 completion
Depends on:
- P27-LIF-03

- [x] P27-LIF-05 Wire chapter progress tracking into ProgressionEngine stat update logic
Depends on:
- P27-LIF-04

- [x] P27-LIF-06 Create ChapterCompletionView celebration with narrative shift and next chapter prompt
Depends on:
- P27-LIF-05

### Prestige / Rebirth

- [x] P27-LIF-07 Create prestige_records Supabase migration table (user_id, prestige_level, rebirth_date, bonuses_earned)
Depends on:
- P27-LIF-01

- [x] P27-LIF-08 Create PrestigeService with canRebirth validation (Chapter 2 complete OR Level 20 + challenge done)
Depends on:
- P27-LIF-07

- [x] P27-LIF-09 Implement rebirth logic: reset stats/level/XP, preserve titles/achievements/tokens/prestige count
Depends on:
- P27-LIF-08

- [x] P27-LIF-10 Define permanent prestige bonuses: +5% XP per rebirth, +1 starting stat point at rebirth 2+
Depends on:
- P27-LIF-09

- [x] P27-LIF-11 Integrate prestige XP multiplier into XPSystem and ProgressionEngine calculations
Depends on:
- P27-LIF-10

- [x] P27-LIF-12 Create RebirthConfirmationView with 3-step safety flow showing what resets vs what's kept
Depends on:
- P27-LIF-11

- [x] P27-LIF-13 Add prestige star icon to Profile and Discipline Card based on prestige_level
Depends on:
- P27-LIF-12

### Habit Leveling

- [x] P27-LIF-14 Add habit_level computed property to Habit model based on total completions from habit_completions count
Depends on:
- P27-LIF-06

- [x] P27-LIF-15 Define habit level thresholds: L2=10, L3=25, L4=50, L5=100 (Mastered), L6=200 (Legendary)
Depends on:
- P27-LIF-14

- [x] P27-LIF-16 Add per-level XP bonus (+1 per habit level) to ProgressionEngine habit completion reward
Depends on:
- P27-LIF-15

- [x] P27-LIF-17 Add star indicators to HabitRow showing habit level (1-5 stars, gold shimmer on Mastered)
Depends on:
- P27-LIF-16

- [x] P27-LIF-18 Create HabitLevelUpToast triggered when habit crosses a level threshold
Depends on:
- P27-LIF-17

### Monthly Habit Injection

- [x] P27-LIF-19 Create habit_presets Supabase migration table with available_from date and level_gate
Depends on:
- P27-LIF-01

- [x] P27-LIF-20 Seed initial 6 months of monthly habits (cold exposure, digital sunset, skill practice, etc.)
Depends on:
- P27-LIF-19

- [x] P27-LIF-21 Update HabitAgencyService to query available presets filtered by current month and user level
Depends on:
- P27-LIF-20

- [x] P27-LIF-22 Create NewHabitAvailableBanner notification and badge on Habits tab when new preset unlocks
Depends on:
- P27-LIF-21

### Mastery Mode

- [x] P27-LIF-23 Add mastery_focus_habit_id field to Profile model (nullable, max 1 at a time)
Depends on:
- P27-LIF-14

- [x] P27-LIF-24 Create MasteryFocusView with detailed per-habit stats (best streak, total count, daily chart)
Depends on:
- P27-LIF-23

- [x] P27-LIF-25 Add 1.5x XP multiplier for mastery focus habit in ProgressionEngine
Depends on:
- P27-LIF-24

- [x] P27-LIF-26 Create mastery milestones (7-day streak, 30-day streak, 100 total) with toast rewards
Depends on:
- P27-LIF-25

- [x] P27-LIF-27 Add monthly change limit: mastery focus can only be changed once per 30 days
Depends on:
- P27-LIF-26

### Seasonal Events

- [x] P27-LIF-28 Create seasonal_events Supabase migration table (event_id, name, start, end, objectives, rewards)
Depends on:
- P27-LIF-01

- [x] P27-LIF-29 Create SeasonalEventService with opt-in, progress tracking, and reward distribution
Depends on:
- P27-LIF-28

- [x] P27-LIF-30 Seed 4 quarterly events: Awakening (spring), Crucible (summer), Harvest (autumn), Deep Forge (winter)
Depends on:
- P27-LIF-29

- [x] P27-LIF-31 Create SeasonalEventBannerView with opt-in prompt and progress display during active events
Depends on:
- P27-LIF-30

- [x] P27-LIF-32 Create event-exclusive badge rewards and Forge Token bonuses for event completion
Depends on:
- P27-LIF-31

### Legacy System

- [x] P27-LIF-33 Create legacy_milestones table migration for Day 365+ achievements and custom titles
Depends on:
- P27-LIF-01

- [x] P27-LIF-34 Create LegacyProfileGenerator aggregating full journey stats (total habits, XP, longest streak)
Depends on:
- P27-LIF-33

- [x] P27-LIF-35 Create LegacyProfileView shareable infographic with Year One badge and journey summary
Depends on:
- P27-LIF-34

- [x] P27-LIF-36 Add custom Legacy Title text input for Day 365+ users displayed in Profile
Depends on:
- P27-LIF-35

- [x] P27-LIF-37 Create TimeCapsuleService for writing and scheduling future message delivery at Day 730
Depends on:
- P27-LIF-36

### Tests

- [x] P27-TST-01 Add unit tests for ChapterService objective progress and completion detection
Depends on:
- P27-LIF-06

- [x] P27-TST-02 Add unit tests for PrestigeService rebirth validation, reset logic, and bonus stacking
Depends on:
- P27-LIF-13

- [x] P27-TST-03 Add unit tests for habit level threshold calculation and XP bonus integration
Depends on:
- P27-LIF-18

- [x] P27-TST-04 Add unit tests for SeasonalEventService opt-in, progress, and reward distribution
Depends on:
- P27-LIF-32

- [x] P27-TST-05 Add unit tests for MasteryFocusService monthly change limit and XP multiplier
Depends on:
- P27-LIF-27

## Phase 28 – Personas & Inclusivity

### Alternative Themes

- [x] P28-INC-01 Create ThemeProvider enum (.warrior, .garden, .scholar) with display string dictionaries
Depends on:
- P27-TST-05

- [x] P28-INC-02 Create theme-specific naming tables for evolution tiers, streak tiers, and boss names
Depends on:
- P28-INC-01

- [x] P28-INC-03 Create theme-specific accent color sets in Asset Catalog (forge gold, garden green, scholar blue)
Depends on:
- P28-INC-01

- [x] P28-INC-04 Add theme_preference field to Profile model and Supabase users table
Depends on:
- P28-INC-03

- [x] P28-INC-05 Create ThemeSelectionView in onboarding and settings with preview of each theme's look
Depends on:
- P28-INC-04

- [x] P28-INC-06 Update NarrativeEngine to read display strings from ThemeProvider instead of hardcoded copy
Depends on:
- P28-INC-05

- [x] P28-INC-07 Update ForgeVoice, evolution tier names, and boss battle copy to reference ThemeProvider
Depends on:
- P28-INC-06

- [x] P28-INC-08 Update streak tier display names and icons per theme (flame/plant/scroll variants)
Depends on:
- P28-INC-07

### Adaptive Difficulty Mode

- [x] P28-INC-09 Add difficultyMode (.standard, .adaptive) to Profile model with setting toggle
Depends on:
- P28-INC-08

- [x] P28-INC-10 Implement adaptive mode defaults: 2 habits/day, shorter workout options (5min, 10min)
Depends on:
- P28-INC-09

- [x] P28-INC-11 Implement adaptive mode forgiveness: 2 tokens/month instead of 1
Depends on:
- P28-INC-10

- [x] P28-INC-12 Implement adaptive mode streak calculation: 1+ completion counts as streak day
Depends on:
- P28-INC-11

- [x] P28-INC-13 Add more frequent micro-reward animations in adaptive mode (every completion, not just milestones)
Depends on:
- P28-INC-12

- [x] P28-INC-14 Create AdaptiveDifficultyInfoView explaining mode benefits with inclusive framing (not deficit language)
Depends on:
- P28-INC-13

### Progressive Commitment

- [x] P28-INC-15 Add commitmentStage (.exploration, .foundation, .full) to Profile model
Depends on:
- P28-INC-09

- [x] P28-INC-16 Implement exploration stage behavior: no streak tracking, no commitment language, 7-day scope
Depends on:
- P28-INC-15

- [x] P28-INC-17 Implement foundation stage behavior: gentle streak with extra forgiveness, 30-day scope
Depends on:
- P28-INC-16

- [x] P28-INC-18 Create StageTransitionView celebrating graduation between commitment stages
Depends on:
- P28-INC-17

- [x] P28-INC-19 Wire automatic stage upgrade prompts at Day 7 (exploration→foundation) and Day 30 (foundation→full)
Depends on:
- P28-INC-18

### Buddy System

- [x] P28-INC-20 Create buddy_pairs Supabase migration table (user_a, user_b, pair_code, connected_at, bond_streak)
Depends on:
- P28-INC-08

- [x] P28-INC-21 Create BuddyService with link via code, daily completion sharing, and bond streak tracking
Depends on:
- P28-INC-20

- [x] P28-INC-22 Create BuddyLinkView with code generation and input for pairing
Depends on:
- P28-INC-21

- [x] P28-INC-23 Create BuddyStatusView small avatar + checkmark component for home screen corner
Depends on:
- P28-INC-22

- [x] P28-INC-24 Implement shared bonus: +5 XP each when both buddies complete all habits on same day
Depends on:
- P28-INC-23

- [x] P28-INC-25 Add privacy constraint: buddy only sees completion status (checkmark/X), never habit names
Depends on:
- P28-INC-24

### Age-Inclusive Design

- [x] P28-INC-26 Add "Classic Navigation" setting using .tabViewStyle(.automatic) instead of page style
Depends on:
- P28-INC-09

- [x] P28-INC-27 Audit and enforce 44pt minimum tap target on all interactive elements across the app
Depends on:
- P28-INC-26

- [x] P28-INC-28 Add longer onboarding screen pause duration when Reduce Motion or larger text is enabled
Depends on:
- P28-INC-27

### Cultural Sensitivity

- [x] P28-INC-29 Extract all user-facing strings to String Catalog (.xcstrings) for localization readiness
Depends on:
- P28-INC-06

- [x] P28-INC-30 Review and tag quote pool for cultural neutrality, removing culture-specific assumptions
Depends on:
- P28-INC-29

- [x] P28-INC-31 Add culturally neutral habit preset alternatives (contemplative practice vs meditation, movement vs specific exercises)
Depends on:
- P28-INC-30

### Tests

- [x] P28-TST-01 Add unit tests for ThemeProvider display string completeness (all keys covered per theme)
Depends on:
- P28-INC-08

- [x] P28-TST-02 Add unit tests for adaptive mode streak calculation (1+ completion = streak day)
Depends on:
- P28-INC-12

- [x] P28-TST-03 Add unit tests for commitment stage transitions and behavior differences
Depends on:
- P28-INC-19

- [x] P28-TST-04 Add unit tests for BuddyService pairing, privacy constraints, and bond streak logic
Depends on:
- P28-INC-25

## Phase 29 – Infrastructure & DevOps

### CI Secret Injection

- [x] P29-INF-01 Add CI step to ios-build.yml generating Secrets.xcconfig from GitHub Secrets
Depends on:
- P28-TST-04

- [x] P29-INF-02 Add CI step to ios-tests.yml generating Secrets.xcconfig from GitHub Secrets
Depends on:
- P29-INF-01

- [x] P29-INF-03 Add Xcode build phase script validating Secrets.xcconfig values are not placeholder strings
Depends on:
- P29-INF-02

### Release Pipeline

- [x] P29-INF-04 Create Fastlane Matchfile for certificate and provisioning profile management
Depends on:
- P29-INF-03

- [x] P29-INF-05 Create Fastlane Gymfile for archive configuration (scheme, export method, output directory)
Depends on:
- P29-INF-04

- [x] P29-INF-06 Create Fastlane Fastfile with lanes: build_for_testing, archive, upload_to_testflight
Depends on:
- P29-INF-05

- [x] P29-INF-07 Create ios-deploy.yml workflow triggered by tag push with archive and TestFlight upload
Depends on:
- P29-INF-06

- [x] P29-INF-08 Add manual dispatch option to ios-deploy.yml for staging builds from develop branch
Depends on:
- P29-INF-07

### Version Automation

- [x] P29-INF-09 Add build number automation using github.run_number in CI workflows
Depends on:
- P29-INF-07

- [x] P29-INF-10 Add marketing version extraction from git tag in release workflow
Depends on:
- P29-INF-09

- [x] P29-INF-11 Create version bump script using agvtool for local development
Depends on:
- P29-INF-10

### SPM & Caching

- [x] P29-INF-12 Add actions/cache step to ios-build.yml keyed on Package.resolved hash
Depends on:
- P29-INF-03

- [x] P29-INF-13 Add swift package-ecosystem to .github/dependabot.yml with weekly interval
Depends on:
- P29-INF-12

- [x] P29-INF-14 Commit Package.resolved to repository for reproducible builds
Depends on:
- P29-INF-13

### Crash Reporting

- [x] P29-INF-15 Add Sentry iOS SDK as SPM dependency with pinned version
Depends on:
- P29-INF-14

- [x] P29-INF-16 Create SentryService wrapper with initialization, breadcrumbs, and user context (hashed ID only)
Depends on:
- P29-INF-15

- [x] P29-INF-17 Add dSYM upload build phase for release builds in Xcode project
Depends on:
- P29-INF-16

- [x] P29-INF-18 Wire SentryService.addBreadcrumb into screen transitions and service call errors
Depends on:
- P29-INF-17

### Environment Separation

- [x] P29-INF-19 Create Secrets.debug.xcconfig and Secrets.release.xcconfig templates
Depends on:
- P29-INF-03

- [x] P29-INF-20 Create separate Xcode build schemes: RNF-Dev, RNF-Staging, RNF-Production
Depends on:
- P29-INF-19

- [x] P29-INF-21 Configure each scheme to use corresponding xcconfig for environment-specific Supabase endpoints
Depends on:
- P29-INF-20

### Database Deployment

- [x] P29-INF-22 Add supabase db push step to CI triggered on merge to develop (staging auto-deploy)
Depends on:
- P29-INF-21

- [x] P29-INF-23 Add supabase db push step for production with manual approval gate on merge to main
Depends on:
- P29-INF-22

### Code Coverage

- [x] P29-INF-24 Add -enableCodeCoverage YES to xcodebuild test command in ios-tests.yml
Depends on:
- P29-INF-12

- [x] P29-INF-25 Add lcov export and upload to Codecov with 60% minimum threshold enforcement
Depends on:
- P29-INF-24

- [x] P29-INF-26 Add coverage badge to README and PR comment with delta reporting
Depends on:
- P29-INF-25

### Portable Automation

- [x] P29-INF-27 Replace hardcoded ROOT_DIR in rnf_cycle.sh with dynamic path detection
Depends on:
- P29-INF-03

- [x] P29-INF-28 Extract rnf_cycle.sh configuration into .env.automation file with documented variables
Depends on:
- P29-INF-27

- [x] P29-INF-29 Add shellcheck validation step to CI for all scripts/ files
Depends on:
- P29-INF-28

### Additional DevOps

- [x] P29-INF-30 Create SECURITY.md with responsible disclosure instructions and security contact
Depends on:
- P29-INF-03

- [x] P29-INF-31 Create CONTRIBUTING.md with setup instructions, PR process, and coding standards
Depends on:
- P29-INF-30

- [x] P29-INF-32 Add actions/labeler workflow for auto-labeling PRs based on file paths changed
Depends on:
- P29-INF-31

- [x] P29-INF-33 Add config.yml to ISSUE_TEMPLATE disabling blank issues and enforcing structured creation
Depends on:
- P29-INF-32

- [x] P29-INF-34 Add UI test workflow (ios-uitests.yml) running RNFUITests target on nightly schedule
Depends on:
- P29-INF-12

### Tests

- [x] P29-TST-01 Add integration test verifying Secrets.xcconfig generation script produces valid output
Depends on:
- P29-INF-03

- [x] P29-TST-02 Add test verifying DeepLinkRouter handles all documented URL patterns
Depends on:
- P29-INF-21

- [x] P29-TST-03 Add test verifying SentryService breadcrumb capture without PII leakage
Depends on:
- P29-INF-18

## Phase 30 – Streak Survival & Day-1 Wins (Competitive Gaps)

### Streak Shield System

- [x] P30-RET-01 Create StreakShieldSystem.swift in Systems/ with equip/consume/auto-protect pure logic
Depends on:
- P29-INF-31

- [x] P30-RET-02 Add equippedShields field to Profile model and create Supabase migration 028_add_streak_shields.sql
Depends on:
- P30-RET-01

- [x] P30-RET-03 Create StreakShieldService.swift in Services/ for shield count read/write persistence
Depends on:
- P30-RET-02

- [x] P30-RET-04 Integrate shield auto-consumption into StreakSystem missed-day evaluation path
Depends on:
- P30-RET-03

- [x] P30-RET-05 Create StreakShieldEquipView component with equip button and shield icon on streak display
Depends on:
- P30-RET-04

### Day-1 Spark Achievements

- [x] P30-RET-06 Define 5 SparkAchievement cases in Achievement model (firstHabit, quizComplete, goalSet, firstRead, firstWorkout)
Depends on:
- P29-INF-31

- [x] P30-RET-07 Create SparkAchievementTrigger.swift in Core/ with event-to-achievement mapping logic
Depends on:
- P30-RET-06

- [x] P30-RET-08 Wire SparkAchievementTrigger into onboarding flow and first-session completion handlers
Depends on:
- P30-RET-07

### Tests

- [x] P30-TST-01 Add unit tests for StreakShieldSystem (equip cap, consume on miss, auto-protect, forge token cost)
Depends on:
- P30-RET-04

- [x] P30-TST-02 Add unit tests for SparkAchievementTrigger event→achievement firing correctness
Depends on:
- P30-RET-07

## Phase 31 – Flexible Intensity & Progress Forecast

### Intensity System

- [x] P31-FLX-01 Create IntensitySystem.swift in Systems/ with level calculation (ember/flame/blaze/inferno) and XP multiplier
Depends on:
- P30-TST-02

- [x] P31-FLX-02 Add intensityLevel computed property to DailyLog model based on completion ratio + extras
Depends on:
- P31-FLX-01

- [x] P31-FLX-03 Update DailyLogService.updateStatus to persist calculated intensity level
Depends on:
- P31-FLX-02

- [x] P31-FLX-04 Update StreakSystem to accept any IntensityLevel >= .ember as streak-valid day
Depends on:
- P31-FLX-01

- [x] P31-FLX-05 Update CalendarGridView to render intensity gradient colors (grey→amber→orange→red→gold)
Depends on:
- P31-FLX-03

### Progress Forecast

- [x] P31-FLX-06 Create ProgressForecast.swift struct in Core/ with pure pace calculation and level projection
Depends on:
- P30-TST-02

- [x] P31-FLX-07 Create ForecastCardView.swift component showing projected level date and pace trend arrow
Depends on:
- P31-FLX-06

- [x] P31-FLX-08 Integrate ForecastCardView into ProfileView or WeeklyReportService output
Depends on:
- P31-FLX-07

### Tests

- [x] P31-TST-01 Add unit tests for IntensitySystem boundary cases (0 completions, partial, full, extras)
Depends on:
- P31-FLX-04

- [x] P31-TST-02 Add unit tests for ProgressForecast calculation accuracy (linear projection, pace changes)
Depends on:
- P31-FLX-06

## Phase 32 – Social Enhancement & League Urgency

### Bond Streak Enhancement

- [x] P32-SOC-01 Update BuddyService bond_streak increment logic to fire on EITHER buddy's 1+ daily completion
Depends on:
- P31-TST-02

- [x] P32-SOC-02 Create BondStreakView shared flame component with growing animation for home screen
Depends on:
- P32-SOC-01

- [x] P32-SOC-03 Add bond streak milestone notifications at 7, 14, 30, 60, 90 days via NotificationScheduler
Depends on:
- P32-SOC-01

### League Urgency

- [x] P32-SOC-04 Create LeagueUrgencyService.swift with demotion risk calculation based on weekly XP vs pool
Depends on:
- P31-TST-02

- [x] P32-SOC-05 Add mid-week league threat notification (Thursday) via NotificationScheduler when at risk
Depends on:
- P32-SOC-04

- [x] P32-SOC-06 Create LeagueWeekRecapCard showing position delta and promotion/demotion result
Depends on:
- P32-SOC-04

### Impact Narrative

- [x] P32-SOC-07 Create ImpactNarrativeSystem.swift in Systems/ with milestone→message mapping (7d, 30d, 90d, 365 habits)
Depends on:
- P31-TST-02

- [x] P32-SOC-08 Integrate impact messages into MilestoneCardTrigger celebration overlay display
Depends on:
- P32-SOC-07

### Tests

- [x] P32-TST-01 Add unit tests for BuddyService bond streak increment (either-completes logic, reset on gap)
Depends on:
- P32-SOC-01

- [x] P32-TST-02 Add unit tests for LeagueUrgencyService demotion risk classification
Depends on:
- P32-SOC-04
