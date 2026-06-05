# RNF Repository Map

This document describes the current RNF project layout and the architecture boundaries Codex should follow when making changes.

The app is an early SwiftUI MVP. The folder structure is usable; most cleanup work should improve boundaries inside the existing structure rather than move files around.

## Target Flow

```text
View
  -> ViewModel
  -> Engine / Use Case
  -> Service
  -> Supabase / Local Storage
```

State returns upward as typed results:

```text
Supabase / Local Storage
  -> Service
  -> Engine / Use Case
  -> ViewModel
  -> GameState
  -> View
```

`GameState` is a shared progression snapshot. Feature-specific transient state belongs in feature ViewModels.

## Root Structure

```text
RNF/
  App/
  Components/
  Core/
  DesignSystem/
  Docs/
  Extensions/
  Features/
  Models/
  Navigation/
  Services/
  Systems/
  ViewModels/
  Assets.xcassets/
RNFTests/
RNFUITests/
supabase/migrations/
scripts/
```

## App

`RNF/App/`

Application entry point.

Current files:

- `RNFApp.swift`

Responsibilities:

- Create shared app-level state objects.
- Install the root app shell.
- Inject `GameState` and app-state dependencies into the SwiftUI hierarchy.

## Navigation

`RNF/Navigation/`

Application routing and authenticated shell composition.

Current files:

- `AppShellView.swift`
- `RootView.swift`

Responsibilities:

- `AppShellView` owns launch/session/onboarding routing through `AppStateManager`.
- `RootView` owns the authenticated tab experience.
- Keep navigation decisions out of feature views unless they are local to that feature.

## Features

`RNF/Features/`

Feature folders contain SwiftUI screens and screen-local components.

Current feature folders:

- `Ascension/`
- `Habits/`
- `Onboarding/`
- `Profile/`
- `Read/`
- `Workouts/`

Feature views should:

- Render state.
- Read `GameState` where needed.
- Read ViewModel state.
- Forward user intent to ViewModels.

Feature views should not:

- Call Supabase directly.
- Own persistence decisions.
- Recalculate core progression rules.
- Contain long-lived workflow state when a ViewModel exists.

## ViewModels

`RNF/ViewModels/`

Screen workflow state and UI-facing orchestration.

Current files:

- `AscensionViewModel.swift`
- `HabitsViewModel.swift`
- `ReadViewModel.swift`
- `WorkoutViewModel.swift`

Responsibilities:

- Own UI-only state such as loading, selected media, timer/finalizing state, and retryable errors.
- Call engines or services.
- Apply typed domain results to `GameState`.
- Translate failures into user-facing messages or retry states.

ViewModels should not contain Supabase query code or core game-rule calculations.

## Core

`RNF/Core/`

Application-level state, app-state routing, logging, and domain workflow engines.

Current files:

- `AppConfig.swift`
- `AppState.swift`
- `AppStateManager.swift`
- `ChallengeEngine.swift`
- `GameState.swift`
- `ProgressionEngine.swift`
- `ReadingEngine.swift`
- `RNFLogger.swift`
- `WorkoutEngine.swift`

Responsibilities:

- `GameState` stores shared player progression state.
- `AppStateManager` resolves launch/session/onboarding route state.
- Engines coordinate domain workflows and return typed result values.
- Engines should not directly mutate `GameState`; ViewModels apply returned results.

Known boundary note:

- `ProgressionEngine` still reads a configured `GameState` snapshot as input. Future cleanup should move it toward explicit input values, but broad rewrites should wait for a dedicated task.

## Services

`RNF/Services/`

Supabase, auth, persistence, analytics, and platform-facing service boundaries.

Current files include:

- `SupabaseService.swift`
- `AuthService.swift`
- `AuthProviding.swift`
- `DailyLogService.swift`
- `HabitService.swift`
- `ChallengeService.swift`
- `CalendarService.swift`
- `ReadingService.swift`
- `WorkoutService.swift`
- `UserService.swift`
- `SkillTreeService.swift`
- `SubscriptionService.swift`
- `AnalyticsService.swift`
- `EvolutionService.swift`
- `NotificationScheduler.swift`
- `QuestService.swift`
- `RNFServiceResult.swift`
- `XPService.swift`

Responsibilities:

- Own Supabase queries and writes.
- Normalize persistence-bound values.
- Return typed models and write results.
- Keep UI state out of service classes.

Date policy:

- Daily records and proof paths must use `DayBoundaryPolicy`.
- Services that need timezone control should accept an injected `Calendar`.

## Systems

`RNF/Systems/`

Pure deterministic rules and helper policies.

Current files include:

- `XPSystem.swift`
- `StreakSystem.swift`
- `BadgeSystem.swift`
- `StatSystem.swift`
- `QuestDifficultySystem.swift`
- `QuestGenerator.swift`
- `QuestMapper.swift`
- `QuestRepository.swift`
- `QuestRewardSystem.swift`
- `DisciplineSystem.swift`
- `EvolutionSystem.swift`
- `ForgivenessSystem.swift`
- `PerkSystem.swift`
- `SkillTreeSystem.swift`
- `WorkoutDurationValidator.swift`
- `DayBoundaryPolicy.swift`

Responsibilities:

- XP math.
- Streak and forgiveness rules.
- Badge/title rules.
- Quest selection and reward mapping.
- Skill/perk calculations.
- Workout duration validation.
- Shared date-boundary policy.

Systems should not call Supabase or mutate SwiftUI state.

## Models

`RNF/Models/`

Codable app/database contracts with small mapping or factory helpers where useful.

Current files include:

- `Profile.swift`
- `Stats.swift`
- `Habit.swift`
- `HabitCompletion.swift`
- `DailyLog.swift`
- `DailyLogStatus.swift`
- `Challenge.swift`
- `WorkoutSession.swift`
- `ReadingUpload.swift`
- `Quest.swift`
- `Perk.swift`
- `SkillTree.swift`
- `Evolution.swift`

Many model fields intentionally mirror Supabase column names. Do not rename database-shaped fields without a dedicated migration and mapping task.

## Components

`RNF/Components/`

Reusable UI components shared across screens.

Current files include:

- `DailyMissionBar.swift`
- `XPBar.swift`
- `HabitRow.swift`
- `CalendarGridView.swift`
- `DisciplineRadarChart.swift`

Components should stay presentational. They may format display state, but they should not own persistence workflows or business rules.

## Design System

`RNF/DesignSystem/`

Shared visual tokens.

Current files:

- `Colors.swift`
- `Typography.swift`
- `Spacing.swift`
- `Animations.swift`

## Extensions

`RNF/Extensions/`

Small Swift extensions.

Current files:

- `Color+Hex.swift`
- `Date+Helpers.swift`

Date helpers should delegate daily boundaries to `DayBoundaryPolicy` so services, proof paths, and resets stay consistent.

## Docs

`RNF/Docs/`

Product, architecture, schema, security, and operating documentation.

Important architecture docs:

- `RNF_ARCHITECTURE_FIX_PLAN.md`
- `RNF_ARCHITECTURE_AUDIT_2026_06_04.md`
- `RNF_SERVICE_LAYER_SPEC.md`
- `RNF_PRODUCTION_READINESS_SPEC.md`
- `RNF_DATABASE_SCHEMA.md`
- `RNF_MIGRATION_RUNBOOK.md`
- `RNF_SECURITY.md`
- `task_graph.md`

`task_graph.md` is the source of truth for Builder task order.

## Supabase Migrations

`supabase/migrations/`

Migrations define reproducible backend state for core app tables, RLS, indexes, skill tree tables, and reading proof storage.

Current migration chain includes:

- core user/progression tables
- daily logs and habit completions
- challenge, workout, reading upload, and subscription tables
- production indexes
- RLS policies
- `skill_nodes` and `user_skills`
- private `reading-proof` storage bucket and owner-folder policies

## Tests

`RNFTests/`

Unit and integration-style tests for systems, services, engines, ViewModels, navigation shell, and critical workflows.

`RNFUITests/`

UI test target scaffold.

## Codex Guardrails

When changing RNF:

- Work from `RNF/Docs/task_graph.md`.
- Keep each cycle to one task.
- Put UI in `Features/` or `Components/`.
- Put screen workflow state in `ViewModels/`.
- Put app state and engines in `Core/`.
- Put Supabase access in `Services/`.
- Put pure rules in `Systems/`.
- Put data contracts in `Models/`.
- Do not add broad architecture layers without an explicit task.
- Do not move files for cosmetic reasons.
- Preserve the existing SwiftUI direction.
