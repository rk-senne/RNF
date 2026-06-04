# RNF Architecture Audit - 2026-06-04

This document records the current architecture, migration, test, and repo-hygiene status after the Phase 15 cleanup work.

This is not a feature spec. Use it to prioritize cleanup before broad feature work.

## Current Verdict

RNF has a workable early-MVP SwiftUI architecture. The folder structure is no longer the main risk.

Current architecture risk: **MEDIUM**

Current production-readiness risk: **MEDIUM**

The highest remaining risks are boundary and hygiene issues:

- `ProgressionEngine` still reads a configured `GameState` snapshot.
- Authenticated service methods still expose broad caller-supplied `userId` overloads.
- `DailyLogService` remains broad.
- Some large SwiftUI views should be split before more feature work piles on top.

## Current Validation

Recent validation from `/Users/regosenne/Desktop/Dev/RNF`:

| Check | Result | Notes |
| --- | --- | --- |
| `xcodebuild -project RNF.xcodeproj -scheme RNF -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/RNFDerivedData build` | PASS | App build succeeded. |
| `xcodebuild -project RNF.xcodeproj -scheme RNF -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -derivedDataPath /tmp/RNFDerivedData -only-testing:RNFTests test` | PASS | Full unit target succeeded. |

Historical automation checks from the original audit also passed:

- GitHub YAML parse.
- `bash -n scripts/rnf_cycle.sh`.

## Architecture Strengths

### Folder Structure Is Directionally Correct

The project has a coherent split between screens, ViewModels, services, systems, models, docs, and app/core state.

Current direction:

- `Features/` owns screens.
- `ViewModels/` owns UI workflow state.
- `Core/` owns shared app state, app-state routing, and engines.
- `Services/` owns Supabase and persistence access.
- `Systems/` owns pure deterministic game rules and shared policies.
- `Models/` owns Codable app/database contracts.
- `supabase/migrations/` owns reproducible backend setup.

### App Shell Routing Exists

`RNF/App/RNFApp.swift` now installs `AppShellView`, and `AppShellView` uses `AppStateManager` to route launch/auth/onboarding states before entering the authenticated `RootView`.

### Read And Workout Workflow Boundaries Improved

`ReadViewModel` and `WorkoutViewModel` now own the main reading-proof and workout-finalization workflows. Views render state and forward intent instead of owning the persistence workflow directly.

### Reading And Workout Engines Return Results

`ReadingEngine` and `WorkoutEngine` return typed completion results. Their ViewModels apply those results to `GameState`.

### Backend Reproducibility Improved

Migrations now include:

- core table constraints and RLS
- skill tree tables and policies
- reading proof storage bucket and owner-folder object policies

Important files:

- `supabase/migrations/011_create_skill_tree_tables.sql`
- `supabase/migrations/012_add_skill_tree_rls_policies.sql`
- `supabase/migrations/013_add_reading_proof_storage.sql`
- `RNF/Docs/RNF_DATABASE_SCHEMA.md`
- `RNF/Docs/RNF_MIGRATION_RUNBOOK.md`
- `RNF/Docs/RNF_SECURITY.md`

### Date Boundary Handling Is Centralized

Daily date normalization and reading proof day identifiers now use `DayBoundaryPolicy`.

Services that need timezone control accept an injected `Calendar`.

## Resolved Findings Since Original Audit

### RESOLVED - Skill Tree Migrations Were Missing

Skill tree tables and policies are now represented in migrations and documented in schema/runbook docs.

### RESOLVED - Reading Proof Storage Was Missing

The private `reading-proof` bucket and owner-folder storage policies are now represented in migration/runbook/security docs.

### RESOLVED - Unit Test Suite Had A Failing Perk Integration Test

The full `RNFTests` target is currently green.

### RESOLVED - Root Auth/App State Was Not Wired Into App Shell

`AppShellView` now owns launch-state routing and `RNFApp` installs it.

### RESOLVED - Read And Workout ViewModels Were Empty

Read and workout workflow state now lives in `ReadViewModel` and `WorkoutViewModel`.

### RESOLVED - Workout UI Could Show Completion Before Persistence

Workout finalization now shows completion after the completion workflow succeeds and exposes retryable failure state.

### RESOLVED - Reading And Workout Engines Applied `GameState` Directly

Reading and workout engines now return typed result values. ViewModels apply those values to `GameState`.

### RESOLVED - Date Normalization Was Split Across Multiple Helpers

`DayBoundaryPolicy` is the shared day-normalization policy for services, proof paths, and daily reset checks.

### RESOLVED - Xcode User Data Was Tracked

Tracked `xcuserdata` files have been removed. Ignore coverage should remain in place so user-specific Xcode state does not return.

### RESOLVED - Minimum iOS Deployment Target Needed A Decision

The MVP iPhone deployment target is documented as iOS 18.0, and the app, unit test, and UI test targets now use `IPHONEOS_DEPLOYMENT_TARGET = 18.0`.

## Current Findings

### MEDIUM - `ProgressionEngine` Still Reads `GameState`

Evidence:

- `ProgressionEngine` stores `private weak var gameState: GameState?`.
- `ProgressionEngine.configure(gameState:)` is required before processing habit completion.
- `processHabitCompletion(...)` reads profile, quest, completed-habit, and daily-goal state from `GameState`.

Why this matters:

The target architecture says engines should operate from explicit inputs and return typed results. `ProgressionEngine` already returns a typed `ProgressionResult`, but it still depends on a shared UI state object for inputs.

Fix direction:

- Replace `configure(gameState:)` with explicit input values or a focused input snapshot.
- Keep `HabitsViewModel` responsible for applying returned results to `GameState`.
- Avoid changing this during unrelated feature work.

### MEDIUM - Manual `userId` Service Overloads Are Broad Escape Hatches

Evidence:

- `DailyLogService`, `ChallengeService`, `ReadingService`, `WorkoutService`, and `UserService` expose methods that accept a caller-supplied `userId`.
- Some app workflows still pass `gameState.profile.id`.

Why this matters:

RLS protects the backend, but app code can still attempt cross-user reads or writes if a wrong `userId` is passed. That can produce hard-to-debug failures and weakens the service contract.

Fix direction:

- Prefer authenticated no-argument methods for production paths.
- Keep caller-supplied `userId` overloads for tests or clearly internal workflows.
- If public overloads remain, verify that the supplied `userId` matches the authenticated user.

### MEDIUM - `DailyLogService` Is Still Broad

Evidence:

- `DailyLogService` owns daily-log reads/writes, habit-completion duplicate handling, status calculation, and profile-save passthrough.

Why this matters:

The service can become a workflow object rather than a focused persistence boundary.

Fix direction:

- Keep daily-log persistence in `DailyLogService`.
- Move or clarify habit-completion ownership when a task explicitly calls for it.
- Extract pure status calculation only if it grows or needs reuse.
- Remove profile-save passthrough unless a future transaction boundary requires it.

### LOW - Large SwiftUI Views Should Be Split Before More Feature Work

Evidence:

- `AscensionView.swift` remains large.
- `ContentView.swift` and some feature screens still mix multiple subviews in one file.

Why this matters:

Large SwiftUI files are harder to review and can accumulate workflow logic.

Fix direction:

- Split large screens into private subviews or feature components.
- Move workflow state into ViewModels before cosmetic file moves.

## Recommended Fix Order

1. Move `ProgressionEngine` toward explicit input snapshots.
2. Narrow authenticated service contracts around caller-supplied `userId`.
3. Narrow `DailyLogService` responsibilities when a concrete workflow calls for it.
4. Split large SwiftUI views only after workflow state is safely in ViewModels.

## Builder Guidance

Future Builder tasks should follow these rules:

- Do not continue if the unit suite has a known failure.
- Do not add new direct `GameState.apply(...)` calls inside engines.
- Do not put new persistence workflows directly in views.
- Do not introduce new backend tables or storage buckets without migrations and docs.
- Keep date-boundary logic routed through `DayBoundaryPolicy`.
- Keep `RNF/Docs/task_graph.md` as the task-order source of truth.
