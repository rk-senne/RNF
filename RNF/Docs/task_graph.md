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

- [x] P6-SVC-04 Add duplicate completion lookup in `DailyLogService.recordHabitCompletion(...)`
Depends on:
- P6-SVC-01

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

- [ ] P6-SVC-06 Add pure daily status calculation helper in `DailyLogService.swift`
Depends on:
- P6-SVC-03

- [ ] P6-SVC-07 Add `DailyLogService.updateStatus(...)` persistence logic
Depends on:
- P6-SVC-03
- P6-SVC-06

### Challenge Service

- [ ] P6-SVC-08 Create `ChallengeService.swift` shell in `Services/`
Depends on:
- P6-MDL-02

- [ ] P6-SVC-09 Add `ChallengeService.startChallenge(...)`
Depends on:
- P6-SVC-08

- [ ] P6-SVC-10 Add `ChallengeService.getActiveChallenge(...)`
Depends on:
- P6-SVC-08

- [ ] P6-SVC-11 Add `ChallengeService.completeChallenge(...)`
Depends on:
- P6-SVC-08

### Calendar Service

- [ ] P6-SVC-12 Create `CalendarService.swift` shell in `Services/`
Depends on:
- P6-MDL-03

- [ ] P6-SVC-13 Add `CalendarService.getMonthLogs(userId:month:)`
Depends on:
- P6-SVC-03
- P6-SVC-12

- [ ] P6-SVC-14 Add `CalendarService.mapLogToCalendarStatus(...)`
Depends on:
- P6-MDL-03
- P6-SVC-13

### Engine and ViewModel Integration

- [ ] P6-ENG-01 Update `ProgressionEngine` to create-or-fetch today’s log before progression writes
Depends on:
- P6-SVC-03

- [ ] P6-ENG-02 Update `ProgressionEngine` to use duplicate-safe habit completion persistence
Depends on:
- P6-SVC-05
- P6-ENG-01

- [ ] P6-ENG-03 Update `ProgressionEngine` to call `DailyLogService.updateStatus(...)`
Depends on:
- P6-SVC-07
- P6-ENG-02

- [ ] P6-VM-01 Remove any remaining direct progression mutations from `HabitsViewModel.swift`
Depends on:
- P6-ENG-03

### UI Shell

- [ ] P6-UI-01 Create `WorkoutListView.swift` placeholder screen in `Features/`
Depends on:
- none

- [ ] P6-UI-02 Create `ReadView.swift` placeholder screen in `Features/`
Depends on:
- none

- [ ] P6-UI-03 Create `WorkoutViewModel.swift` placeholder in `ViewModels/`
Depends on:
- P6-UI-01

- [ ] P6-UI-04 Create `ReadViewModel.swift` placeholder in `ViewModels/`
Depends on:
- P6-UI-02

- [ ] P6-UI-05 Expand `RootView.swift` with Workouts and Read tabs
Depends on:
- P6-UI-01
- P6-UI-02

### Tests

- [ ] P6-TST-01 Add `XPSystem` threshold and carry-over tests
Depends on:
- none

- [ ] P6-TST-02 Add `DailyLogService` duplicate completion tests
Depends on:
- P6-SVC-05

- [ ] P6-TST-03 Add `DailyLogService` status update tests
Depends on:
- P6-SVC-07

- [ ] P6-TST-04 Add `ProgressionEngine` quest refresh tests
Depends on:
- P6-ENG-03

## Phase 7 – 90 Day Challenge Engine

### Model and Service Expansion

- [ ] P7-MDL-01 Add challenge mapping helpers to `Challenge.swift`
Depends on:
- P6-MDL-02

- [ ] P7-SVC-01 Add `ChallengeService.advanceDay(...)`
Depends on:
- P6-SVC-10

- [ ] P7-SVC-02 Add `ChallengeService.restartChallenge(...)`
Depends on:
- P6-SVC-11

### Challenge Engine

- [ ] P7-ENG-01 Create `ChallengeEngine.swift` shell in `Core/`
Depends on:
- P6-SVC-10
- P6-SVC-11
- P6-SVC-07

- [ ] P7-ENG-02 Add active challenge loading in `ChallengeEngine`
Depends on:
- P7-ENG-01

- [ ] P7-ENG-03 Add day progression logic in `ChallengeEngine.advanceIfDayComplete(...)`
Depends on:
- P7-SVC-01
- P7-ENG-02

- [ ] P7-ENG-04 Add day-90 completion detection in `ChallengeEngine`
Depends on:
- P7-ENG-03

- [ ] P7-ENG-05 Add restart flow orchestration in `ChallengeEngine`
Depends on:
- P7-SVC-02
- P7-ENG-04

### App State Manager

- [ ] P7-CORE-01 Create `AppState.swift` enum for app routes
Depends on:
- none

- [ ] P7-CORE-02 Create `AppStateManager.swift` shell in `Core/`
Depends on:
- P7-CORE-01

- [ ] P7-CORE-03 Add launch resolution using session state, today log, and active challenge
Depends on:
- P6-SVC-03
- P6-SVC-10
- P7-CORE-02

- [ ] P7-CORE-04 Add challenge-related route transitions
Depends on:
- P7-ENG-04
- P7-CORE-03

### Screens

- [ ] P7-UI-01 Create `CommitmentView.swift`
Depends on:
- P7-CORE-02

- [ ] P7-UI-02 Add challenge summary surface to `ContentView.swift`
Depends on:
- P7-ENG-03

- [ ] P7-UI-03 Add challenge summary surface to `AscensionView.swift`
Depends on:
- P7-ENG-03

- [ ] P7-UI-04 Create challenge completion screen
Depends on:
- P7-ENG-04

- [ ] P7-UI-05 Add challenge restart action UI
Depends on:
- P7-ENG-05

### Tests

- [ ] P7-TST-01 Add `ChallengeService.advanceDay(...)` tests
Depends on:
- P7-SVC-01

- [ ] P7-TST-02 Add `ChallengeEngine` completion and restart tests
Depends on:
- P7-ENG-04
- P7-ENG-05

- [ ] P7-TST-03 Add `AppStateManager` launch routing tests
Depends on:
- P7-CORE-04

## Phase 8 – Workouts + Reading Proof

### Workout Path

- [ ] P8-MDL-01 Create `WorkoutSession.swift` model
Depends on:
- none

- [ ] P8-SYS-01 Add workout duration validation helper in `Systems/`
Depends on:
- P8-MDL-01

- [ ] P8-SVC-01 Create `WorkoutService.swift` shell
Depends on:
- P8-MDL-01
- P6-SVC-03

- [ ] P8-SVC-02 Add workout completion persistence in `WorkoutService`
Depends on:
- P8-SVC-01

- [ ] P8-SVC-03 Add daily log workout-flag update in `WorkoutService`
Depends on:
- P6-SVC-07
- P8-SVC-02

- [ ] P8-ENG-01 Create `WorkoutEngine.swift` shell
Depends on:
- P8-SVC-03

- [ ] P8-ENG-02 Add XP award path in `WorkoutEngine.completeWorkout(...)`
Depends on:
- P8-SYS-01
- P8-ENG-01

- [ ] P8-ENG-03 Add challenge day evaluation hook for workouts
Depends on:
- P7-ENG-03
- P8-ENG-02

- [ ] P8-UI-01 Build workout list screen content
Depends on:
- P8-SVC-01
- P6-UI-01

- [ ] P8-UI-02 Build active workout timer screen
Depends on:
- P8-ENG-02
- P8-UI-01

- [ ] P8-TST-01 Add workout validation and reward tests
Depends on:
- P8-ENG-02

### Reading Path

- [ ] P8-MDL-02 Create `ReadingUpload.swift` model
Depends on:
- none

- [ ] P8-SVC-04 Add proof file upload path in `ReadingService.swift`
Depends on:
- P8-MDL-02

- [ ] P8-SVC-05 Add `reading_uploads` insert path in `ReadingService.swift`
Depends on:
- P8-SVC-04

- [ ] P8-SVC-06 Add daily log reading-flag update in `ReadingService.swift`
Depends on:
- P6-SVC-07
- P8-SVC-05

- [ ] P8-ENG-04 Create `ReadingEngine.swift` shell
Depends on:
- P8-SVC-06

- [ ] P8-ENG-05 Add XP award path in `ReadingEngine.completeReading(...)`
Depends on:
- P8-ENG-04

- [ ] P8-ENG-06 Add challenge day evaluation hook for reading
Depends on:
- P7-ENG-03
- P8-ENG-05

- [ ] P8-UI-03 Build read screen content
Depends on:
- P8-SVC-04
- P6-UI-02

- [ ] P8-UI-04 Build reading proof upload flow
Depends on:
- P8-SVC-05
- P8-UI-03

- [ ] P8-TST-02 Add reading upload and daily-log update tests
Depends on:
- P8-SVC-06

## Phase 9 – Calendar + Forgiveness System

### Calendar

- [ ] P9-SVC-01 Add month grouping helper in `CalendarService.swift`
Depends on:
- P6-SVC-13

- [ ] P9-SVC-02 Add calendar cell status mapping in `CalendarService.swift`
Depends on:
- P6-SVC-14
- P9-SVC-01

- [ ] P9-UI-01 Create calendar grid component
Depends on:
- P9-SVC-02

- [ ] P9-UI-02 Add calendar section to profile-facing UI
Depends on:
- P9-UI-01

### Forgiveness

- [ ] P9-SVC-03 Add forgiveness token fetch path in `UserService.swift`
Depends on:
- P6-MDL-01

- [ ] P9-SVC-04 Add forgiveness token decrement path in `UserService.swift`
Depends on:
- P9-SVC-03

- [ ] P9-SYS-01 Create `ForgivenessSystem.swift` shell
Depends on:
- none

- [ ] P9-SYS-02 Add pure forgiveness rule evaluation
Depends on:
- P9-SYS-01

- [ ] P9-ENG-01 Add forgiveness handling in `ChallengeEngine`
Depends on:
- P7-ENG-03
- P9-SVC-04
- P9-SYS-02

- [ ] P9-ENG-02 Add forgiven status handling in `DailyLogService`
Depends on:
- P6-SVC-07
- P9-ENG-01

- [ ] P9-UI-03 Add forgiveness recovery action UI
Depends on:
- P9-ENG-01

- [ ] P9-TST-01 Add calendar status mapping tests
Depends on:
- P9-SVC-02

- [ ] P9-TST-02 Add forgiveness token and streak preservation tests
Depends on:
- P9-ENG-02

## Phase 10 – Auth + Onboarding

### Auth Service

- [ ] P10-SVC-01 Create `AuthService.swift` shell
Depends on:
- none

- [ ] P10-SVC-02 Add sign-up path in `AuthService`
Depends on:
- P10-SVC-01

- [ ] P10-SVC-03 Add sign-in path in `AuthService`
Depends on:
- P10-SVC-01

- [ ] P10-SVC-04 Add sign-out path in `AuthService`
Depends on:
- P10-SVC-01

- [ ] P10-SVC-05 Add restore-session path in `AuthService`
Depends on:
- P10-SVC-01

- [ ] P10-SVC-06 Add post-sign-up user bootstrap in `AuthService`
Depends on:
- P10-SVC-02
- P6-MDL-01

### Notifications

- [ ] P10-SVC-07 Create `NotificationScheduler.swift` shell
Depends on:
- none

- [ ] P10-SVC-08 Add notification permission request
Depends on:
- P10-SVC-07

- [ ] P10-SVC-09 Add morning schedule path
Depends on:
- P10-SVC-08

- [ ] P10-SVC-10 Add evening schedule path
Depends on:
- P10-SVC-08

### Screens and Routing

- [ ] P10-UI-01 Create splash screen
Depends on:
- none

- [ ] P10-UI-02 Create login screen
Depends on:
- P10-SVC-03

- [ ] P10-UI-03 Create sign-up screen
Depends on:
- P10-SVC-02

- [ ] P10-UI-04 Create notification setup screen
Depends on:
- P10-SVC-08

- [ ] P10-CORE-01 Add auth states to `AppStateManager`
Depends on:
- P7-CORE-04
- P10-SVC-05

- [ ] P10-CORE-02 Add onboarding states to `AppStateManager`
Depends on:
- P10-CORE-01
- P10-UI-04
- P7-UI-01

- [ ] P10-TST-01 Add auth restore and onboarding routing tests
Depends on:
- P10-CORE-02

## Phase 11 – Subscription + Analytics

### Subscription

- [ ] P11-SVC-01 Create `SubscriptionService` StoreKit shell
Depends on:
- P10-SVC-05

- [ ] P11-SVC-02 Add product fetch path in `SubscriptionService`
Depends on:
- P11-SVC-01

- [ ] P11-SVC-03 Add entitlement validation path in `SubscriptionService`
Depends on:
- P11-SVC-01

- [ ] P11-SVC-04 Add Supabase subscription sync path
Depends on:
- P11-SVC-03

- [ ] P11-UI-01 Build subscription management screen
Depends on:
- P11-SVC-02
- P11-SVC-03

### Analytics

- [ ] P11-SVC-05 Create `AnalyticsService.swift` shell
Depends on:
- P10-SVC-05

- [ ] P11-SVC-06 Define typed event names in `AnalyticsService`
Depends on:
- P11-SVC-05

- [ ] P11-SVC-07 Add funnel tracking hooks
Depends on:
- P11-SVC-06
- P10-CORE-02
- P7-ENG-03

- [ ] P11-SVC-08 Add engagement tracking hooks
Depends on:
- P11-SVC-06
- P8-ENG-03
- P8-ENG-06
- P9-ENG-01

- [ ] P11-SVC-09 Add monetization and notification tracking hooks
Depends on:
- P11-SVC-06
- P11-SVC-04
- P10-SVC-09
- P10-SVC-10

### Hardening

- [ ] P11-OPS-01 Validate RLS, user scoping, and storage path assumptions
Depends on:
- P10-SVC-06
- P11-SVC-04

- [ ] P11-OPS-02 Validate performance of habit completion, reading upload, workout completion, and month log fetch
Depends on:
- P6-ENG-03
- P8-ENG-03
- P8-ENG-06
- P9-SVC-02
