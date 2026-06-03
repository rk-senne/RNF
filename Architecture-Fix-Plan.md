# Architecture Fix Plan

This document defines the minimum architecture cleanup needed to keep RNF scalable while preserving the current SwiftUI app direction.

It is not a feature plan. Do not use this document to add new product behavior.

## Current Verdict

The project architecture is acceptable for an early SwiftUI MVP.

The existing structure is directionally correct:

- Views live under `Features`.
- Shared UI lives under `Components`.
- App state lives under `Core`.
- Backend access lives under `Services`.
- Pure game rules live under `Systems`.
- Data contracts live under `Models`.

The main issue is not folder structure. The issue is boundary drift between state, orchestration, services, and persistence.

## Target Flow

RNF should move toward this flow:

```text
View
  -> ViewModel
  -> Engine / Use Case
  -> Service
  -> Supabase / Local Storage
```

State should return upward as typed results:

```text
Supabase / Local Storage
  -> Service
  -> Engine / Use Case
  -> ViewModel
  -> GameState
  -> View
```

## Layer Responsibilities

### Views

Views render UI and forward user intent.

Allowed:

- Read `GameState`.
- Read ViewModel state.
- Trigger ViewModel actions.

Not allowed:

- Call Supabase.
- Run progression logic.
- Mutate backend models directly.
- Own persistence decisions.

### ViewModels

ViewModels coordinate screen behavior.

Allowed:

- Own UI-only state.
- Call engines and services.
- Apply returned results to `GameState`.
- Translate errors into user-facing state.

Not allowed:

- Contain Supabase query code.
- Recalculate core progression rules.
- Mix unrelated feature workflows.

### Engines / Use Cases

Engines coordinate domain workflows.

Allowed:

- Apply game rules.
- Call services.
- Return typed results.
- Stay independent from SwiftUI views.

Preferred direction:

- Engines should return values rather than directly mutating `GameState`.
- ViewModels should decide how returned values update app state.

### Services

Services own persistence and backend access.

Allowed:

- Fetch from Supabase.
- Write to Supabase.
- Normalize database values.
- Return typed models.

Not allowed:

- Own UI state.
- Trigger SwiftUI updates.
- Contain broad cross-domain orchestration.
- Silently hide important data-integrity failures unless explicitly documented.

### Systems

Systems contain pure deterministic rules.

Allowed:

- XP math.
- streak math.
- badge/title rules.
- quest difficulty rules.
- stat reward rules.

Not allowed:

- Supabase access.
- `GameState` mutation.
- SwiftUI dependencies.

## Current Risks

### 1. `ProgressionEngine` Owns Too Much

`ProgressionEngine` currently coordinates progression rules, calls persistence services, and mutates `GameState`.

Risk:

- Harder to test.
- Harder to reuse for challenge, calendar, workout, or reading flows.
- Makes `GameState` a dependency of domain orchestration.

Fix direction:

- Keep progression orchestration in the engine.
- Return a typed result containing updated profile, daily log, quest plan, completed IDs, and UI event flags.
- Let `HabitsViewModel` apply that result to `GameState`.

### 2. `GameState` Can Become a Catch-All

`GameState` is useful as a shared app snapshot, but it should not become the owner of every feature.

Risk:

- Workouts, reading, challenges, subscriptions, and calendar state may all accumulate in one object.
- Small changes could trigger broad UI updates.

Fix direction:

- Keep `GameState` focused on shared player progression.
- Put feature-specific transient state in feature ViewModels.
- Add focused state structs when shared state grows.

### 3. `DailyLogService` Is Becoming Too Broad

`DailyLogService` currently handles daily logs, habit completion persistence, profile save passthrough, and status calculation.

Risk:

- Service becomes a broad workflow object rather than a focused persistence boundary.
- More features will make this file harder to reason about.

Fix direction:

- Keep daily-log persistence in `DailyLogService`.
- Keep habit completion persistence in either `HabitService` or a narrowly named method with one clear owner.
- Move pure status rules into a system/helper if they grow.
- Avoid profile persistence passthrough unless there is a clear daily-log transaction boundary.

### 4. Backend Field Names Leak Into Domain Models

Models currently use database-shaped names such as `user_id`, `xp_total`, and `habits_completed`.

Risk:

- Domain code becomes coupled to Supabase schema names.
- Refactors become harder once UI and systems depend on database naming.

Fix direction:

- Short term: accept existing names for task velocity.
- Medium term: add domain-facing computed properties or DTO mapping if the model layer becomes painful.
- Do not rename fields casually without a dedicated migration task.

### 5. Error Handling Is Too Soft For Production

Several service methods catch backend failures and continue with local state.

Risk:

- Data may look correct locally while persistence failed.
- Verifier may miss backend consistency problems.

Fix direction:

- Keep graceful fallback for unauthenticated or placeholder users.
- For authenticated users, return typed errors where data integrity matters.
- Let ViewModels decide whether to show an error, retry, or continue locally.

## Refactor Order

Follow this order. Do not do broad architecture rewrites.

### Step 1: Stabilize Progression Result Boundaries

Create or expand a typed progression result that can carry:

- updated profile
- updated daily log
- updated quest plan
- completed habit IDs
- XP gained
- level-up flag
- mission-complete flag
- unlocked badge

Then move `GameState.apply(...)` out of `ProgressionEngine` and into `HabitsViewModel`.

### Step 2: Narrow `DailyLogService`

Review each method in `DailyLogService` and classify it as:

- daily log persistence
- habit completion persistence
- status calculation
- profile persistence passthrough

Current method classification:

| Method | Responsibility | Boundary note |
| --- | --- | --- |
| `normalizedDay(_:)` | date normalization helper | Keep private to persistence methods unless shared date normalization becomes explicit. |
| `fetchTodayLog(userId:date:)` | daily log persistence | Reads one `daily_logs` record for a user and normalized day. |
| `createDailyLog(userId:date:)` | daily log persistence | Inserts one `daily_logs` record and falls back to the existing record on duplicate creation. |
| `getTodayLog(for:dailyGoal:)` | daily log persistence | Fetch-or-create convenience for the current daily log; returns a local placeholder log for placeholder profiles. |
| `saveDailyLog(_:)` | daily log persistence | Upserts one `daily_logs` record and intentionally ignores backend failure to preserve local state. |
| `recordCompletion(_:)` | habit completion persistence passthrough | Delegates directly to `HabitService`; should be removed or renamed once habit-completion ownership is narrowed. |
| `recordHabitCompletion(_:)` | habit completion persistence | Performs duplicate-safe `habit_completions` lookup and insert. |
| `calculateStatus(for:)` | status calculation | Pure daily-log status derivation; safe to test independently or extract later. |
| `updateStatus(userId:date:)` | daily log persistence plus status calculation | Reads a daily log, derives status with `calculateStatus(for:)`, then persists only the status field. |
| `saveProfile(_:)` | profile persistence passthrough | Delegates to `UserService`; should stay only if a future task defines a daily-log transaction boundary. |

Only move code when a task explicitly calls for it. The goal is controlled narrowing, not churn.

### Step 3: Define Feature State Boundaries

Before adding challenge, workout, reading, or calendar screens, decide whether state belongs in:

- `GameState`
- a feature ViewModel
- a small feature state struct

Default rule:

- Shared player progression belongs in `GameState`.
- Screen-only state belongs in the ViewModel.
- Feature-specific shared state gets its own focused state object only when multiple screens need it.

### Step 4: Add Tests Around Pure Systems First

Test the deterministic parts before refactoring persistence:

- `XPSystem`
- `StreakSystem`
- `QuestDifficultySystem`
- `DailyLogService.calculateStatus(...)` or any extracted status helper

Then add ViewModel/engine tests after boundaries are cleaner.

### Step 5: Improve Service Error Contracts

Replace silent persistence failures with explicit results where correctness matters.

Preferred result shape:

```swift
enum PersistenceResult<Value> {
    case saved(Value)
    case localOnly(Value)
    case failed(Error)
}
```

Only introduce this if it removes ambiguity in a concrete workflow.

## Guardrails For Codex

Codex must follow these rules:

- Do one task at a time.
- Do not rewrite folder structure.
- Do not rename models unless the task explicitly requires it.
- Do not introduce a new architecture framework.
- Do not move files just to make the tree look cleaner.
- Prefer small boundary improvements over large refactors.
- Preserve existing SwiftUI behavior unless the selected task says otherwise.

## Definition Of Improved Architecture

The architecture is considered improved when:

- Views do not contain business logic.
- ViewModels own UI state and apply domain results.
- Engines return typed results and do not directly mutate `GameState`.
- Services are focused on persistence and backend boundaries.
- Systems remain pure and deterministic.
- `GameState` remains a shared progression snapshot, not a dumping ground.
- Tests cover pure rules and critical progression paths.


---

_Source: `RNF/Docs/RNF_ARCHITECTURE_FIX_PLAN.md`_
