# RNF Project Conventions

## Stack
- **Language:** Swift 5.0 (iOS 26.2+)
- **UI:** SwiftUI (declarative, MVVM)
- **Backend:** Supabase (PostgreSQL + Auth + Storage)
- **Concurrency:** Swift structured concurrency (async/await, @MainActor)
- **Testing:** XCTest (unit + integration)
- **Package Manager:** Swift Package Manager
- **CI:** GitHub Actions

## Architecture

```
View → ViewModel → Engine/UseCase → Service → Supabase/Local Storage
```

- **Views** never call Supabase directly
- **ViewModels** coordinate screen behavior, apply domain results to GameState
- **Engines** contain business logic, accept services via DI, return typed results
- **Services** own persistence boundaries (Supabase queries, UserDefaults)
- **Systems** contain pure deterministic game rules (XP math, streak calc, etc.)
- **GameState** is shared via @EnvironmentObject — the single source of truth for player progression

## File Organization

```
RNF/
├── App/          — App entry point
├── Core/         — Engines, managers, shared logic
├── Services/     — Supabase queries, auth, persistence
├── Systems/      — Pure game rule calculations
├── Models/       — Data models (Codable)
├── ViewModels/   — ObservableObject screen coordinators
├── Features/     — Feature-scoped views (subdirectories per feature)
├── Components/   — Reusable SwiftUI components
├── DesignSystem/ — Tokens (colors, spacing, typography, radius)
├── Navigation/   — App routing (RootView, StateRoutingView)
├── Extensions/   — Swift extensions
├── Docs/         — Specs, task graph, project docs
├── LiveActivity/ — Dynamic Island / Lock Screen
RNFWatch/         — Apple Watch companion
RNFWidget/        — Home screen widgets
RNFTests/         — Unit + integration tests
```

## Coding Conventions

- `@MainActor` on all ObservableObjects, engines, and state managers
- Dependency injection via initializers (not singletons where possible)
- `AuthProviding` protocol for testable auth boundaries
- `RNFServiceResult<T>` for typed write operations
- Error handling: do/catch with RNFLogger, never empty catch blocks
- No force unwraps in business logic
- Guard-let for early returns
- One blank line between logical sections

## Naming

- Files named after their primary type: `ChallengeEngine.swift`
- Tests named: `{Type}Tests.swift`
- Services suffix: `*Service`
- Engines suffix: `*Engine`
- Systems suffix: `*System`
- Views: descriptive name (no suffix needed)

## Testing

- Use `MockURLProtocol` for network isolation (shared test utility)
- Test deterministic game logic exhaustively
- Integration tests verify full engine → service → response flow
- XCTest with async test support

## Build & Test Commands

```bash
xcodebuild build -scheme RNF -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild test -scheme RNF -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Task Execution

- Source of truth: `RNF/Docs/task_graph.md`
- Specs: `RNF/Docs/specs/SPEC_*.md`
- One task per mission
- Run build + tests before marking complete
- Respect dependency chains

## Design System Tokens

- Colors: `RNFColors.*`
- Spacing: `RNFSpacing.*`
- Radius: `RNFRadius.*`
- Typography: `RNFFont.*`
- Elevation: `RNFShadow.*`
- Animation: `Animations.animationIfAllowed()`

## Database

- Supabase with Row Level Security on all tables
- Migrations in `supabase/migrations/` (sequential numbered)
- Always include RLS policies with new tables
- Include indexes for foreign keys and common query patterns

## Git

- Branch per phase: `phase-21`, `phase-22`, etc.
- Tag per release: `v1.0-phase21`
- Commit messages: `P21-FIX-01: description of change`
- Never force push to main
