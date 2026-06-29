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
