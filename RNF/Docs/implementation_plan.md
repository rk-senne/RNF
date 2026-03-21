# RNF Implementation Plan

This document converts the RNF product roadmap into an execution-ready engineering backlog.

Architecture target:

UI -> ViewModel -> Engine -> Services -> Systems -> Models

Planning assumptions:

- `GameState` remains the single source of truth for active runtime state.
- Engines orchestrate multi-step gameplay flows.
- Services own persistence and Supabase communication.
- Systems remain pure and reusable.
- Features are delivered in dependency order so no task relies on missing infrastructure.

## Phase 6 – Core Gameplay Completion

Goal:

Finish the MVP gameplay backbone so habit progression, daily logs, and quest refreshes are stable and testable.

Why this phase comes first:

- Every later system depends on trustworthy daily progression.
- Challenge, calendar, workouts, and reading all build on `daily_logs`.

Ordered work:

1. Harden `DailyLogService` around real `daily_logs` semantics.
2. Normalize models and service behavior to the documented schema.
3. Add missing backend services needed by the rest of the core loop.
4. Expand navigation to the intended MVP shell.
5. Add unit and integration coverage for the core progression path.

Deliverables:

- robust `DailyLogService`
- `ChallengeService` skeleton
- `CalendarService` skeleton
- stable root tabs for Habits, Ascension/Profile, Workouts, Read
- tests for XP, streaks, quests, and duplicate completion

## Phase 7 – 90 Day Challenge Engine

Goal:

Implement the full 90-day challenge lifecycle and the app state flow that depends on it.

Why this phase comes after Phase 6:

- Challenge progression depends on working daily logs, streak logic, and shared state.
- App launch routing depends on auth state plus challenge state.

Ordered work:

1. Add `Challenge` model and challenge persistence/service methods.
2. Build `ChallengeEngine` to advance days, complete challenges, and restart challenges.
3. Build `AppStateManager` from the state-machine spec.
4. Implement challenge progress surfaces in Home and Profile.
5. Add challenge completion and restart UX.

Deliverables:

- `ChallengeEngine`
- `ChallengeService`
- `AppStateManager`
- 90-day commitment and challenge progress flow
- challenge lifecycle tests

## Phase 8 – Workouts + Reading Proof

Goal:

Add the two required daily completion pillars beyond habits: workouts and reading proof.

Why this phase comes after Phase 7:

- Both systems must update `daily_logs` and interact with challenge completion rules.
- Their completion state affects whether a day is complete.

Ordered work:

1. Implement workout persistence and timing rules.
2. Implement reading proof storage and completion logic.
3. Build the Workout and Read user flows.
4. Connect both systems into challenge-day completion.
5. Add tests for workout and reading completion paths.

Deliverables:

- `WorkoutService`
- `WorkoutEngine`
- workout list and active timer screens
- `ReadingService` completion flow
- reading proof upload screen

## Phase 9 – Calendar + Forgiveness System

Goal:

Make progress visible over time and add safe recovery for missed days.

Why this phase comes after Phase 8:

- Calendar status must reflect habits, workouts, and reading.
- Forgiveness logic depends on challenge and daily completion semantics already being stable.

Ordered work:

1. Implement calendar fetch and presentation over `daily_logs`.
2. Implement forgiveness token persistence and usage.
3. Connect missed-day handling into `ChallengeEngine` and `AppStateManager`.
4. Expose calendar and forgiveness actions in Profile.
5. Add tests for missed, forgiven, and streak-reset scenarios.

Deliverables:

- `CalendarService`
- calendar UI
- `ForgivenessService` or equivalent service support
- forgiveness UX and status handling

## Phase 10 – Auth + Onboarding

Goal:

Implement account lifecycle, notification setup, and first-run user routing.

Why this phase comes after Phase 9:

- The app can already function locally and structurally before auth is added.
- Auth and onboarding will bind the existing challenge and notification systems to real users.

Ordered work:

1. Implement `AuthService`.
2. Build splash, login, and sign-up flows.
3. Implement notification setup and scheduling.
4. Build the 90-day commitment onboarding step.
5. Connect onboarding routing through `AppStateManager`.

Deliverables:

- `AuthService`
- login/signup screens
- notification setup screen
- 90-day commitment screen
- launch/session routing

## Phase 11 – Subscription + Analytics

Goal:

Add monetization, event tracking, and product instrumentation to support launch and iteration.

Why this phase comes last:

- Subscription and analytics should measure and monetize a stable product, not shape incomplete behavior.
- Event instrumentation becomes much more useful once the main flows already exist.

Ordered work:

1. Implement StoreKit-backed subscription management.
2. Sync subscription state with Supabase.
3. Implement analytics event tracking across the main funnels.
4. Add notification and retention metrics.
5. Validate privacy, security, and performance targets.

Deliverables:

- production-ready `SubscriptionService`
- subscription management UI
- `AnalyticsService`
- event coverage for funnel, retention, and monetization

## Dependency Summary

- Phase 6 is the base for all later work.
- Phase 7 depends on Phase 6.
- Phase 8 depends on Phases 6 and 7.
- Phase 9 depends on Phases 7 and 8.
- Phase 10 depends on Phases 7 and 9.
- Phase 11 depends on Phases 8, 9, and 10.
