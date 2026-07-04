# Contributing to RNF

Thank you for your interest in contributing to RNF! This guide will help you get started.

## Prerequisites

- **macOS 14+** (Sonoma or later)
- **Xcode 16+** with iOS 18+ SDK
- **Swift 5.9+**
- **Git** (latest stable)
- A Supabase project (for backend integration testing)

## Getting Started

### 1. Fork & Clone

```bash
git clone https://github.com/YOUR_USERNAME/RNF.git
cd RNF
```

### 2. Configure Secrets

Copy the secrets template and fill in your Supabase credentials:

```bash
cp Secrets.xcconfig.template Secrets.xcconfig
```

Edit `Secrets.xcconfig` with your values:

```
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = your_anon_key_here
SENTRY_DSN = your_sentry_dsn_here
```

> **Note:** `Secrets.xcconfig` is gitignored and must never be committed.

Alternatively, use the generation script:

```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your_anon_key"
./scripts/generate_xcconfig.sh
```

### 3. Open in Xcode

```bash
open RNF.xcodeproj
```

Xcode will resolve Swift Package Manager dependencies automatically.

### 4. Build & Run

```bash
xcodebuild build -scheme RNF -destination 'platform=iOS Simulator,name=iPhone 16'
```

### 5. Run Tests

```bash
xcodebuild test -scheme RNF -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RNFTests
```

## Project Architecture

```
View → ViewModel → Engine/UseCase → Service → Supabase/Local Storage
```

| Layer | Responsibility |
|-------|---------------|
| **Views** | SwiftUI declarative UI — never call Supabase directly |
| **ViewModels** | Screen coordination, state management (`@MainActor`, `ObservableObject`) |
| **Engines** | Business logic, accept services via DI |
| **Services** | Persistence boundaries (Supabase, UserDefaults, Keychain) |
| **Systems** | Pure deterministic game rules (XP math, streak calculations) |
| **GameState** | Shared via `@EnvironmentObject` — single source of truth |

## Coding Standards

### Swift Conventions

- `@MainActor` on all `ObservableObject` types, engines, and state managers
- Dependency injection via initializers (avoid singletons where possible)
- `guard let` for early returns
- No force unwraps (`!`) in business logic
- Never use empty `catch` blocks — log errors with `RNFLogger`
- One blank line between logical sections

### Naming

| Type | Convention | Example |
|------|-----------|---------|
| Services | `*Service` suffix | `AuthService`, `DailyLogService` |
| Engines | `*Engine` suffix | `ChallengeEngine`, `InsightEngine` |
| Systems | `*System` suffix | `XPSystem`, `PerkSystem` |
| Tests | `{Type}Tests.swift` | `ChallengeEngineTests.swift` |
| Views | Descriptive name (no suffix) | `HabitRow`, `CalendarGridView` |

### Design System

Use design tokens — never hardcode colors, spacing, or typography:

- Colors: `RNFColors.*`
- Spacing: `RNFSpacing.*`
- Radius: `RNFRadius.*`
- Typography: `RNFFont.*`
- Animation: `Animations.animationIfAllowed()`

## Pull Request Process

### Branch Naming

```
phase-{number}     # Phase branches
fix/{description}  # Bug fixes
feature/{name}     # New features
```

### Before Opening a PR

1. **Build passes:** `xcodebuild build -scheme RNF ...`
2. **Tests pass:** `xcodebuild test -scheme RNF ... -only-testing:RNFTests`
3. **No force unwraps** added in business logic
4. **Tests written** for new functionality
5. **Commit messages** follow format: `P{phase}-{type}-{number}: description`

### PR Description

Use the [PR template](/.github/pull_request_template.md). Include:

- Summary of changes
- Which tasks from `task_graph.md` are addressed
- What was tested
- Screenshots (for UI changes)

### Review Criteria

- [ ] Code follows project conventions
- [ ] Tests cover new behavior
- [ ] No regressions in existing tests
- [ ] Accessibility considered for UI changes
- [ ] No secrets or PII in code

## Testing Guidelines

- **Unit tests:** Test deterministic game logic exhaustively
- **Integration tests:** Verify engine → service → response flow
- **Use `MockURLProtocol`** for network isolation
- **Async tests:** Use Swift's async/await test support
- **Coverage target:** 60% minimum (enforced in CI)

## Database Changes

If your contribution requires database changes:

1. Create a new migration in `supabase/migrations/` with sequential numbering
2. Always include RLS policies for new tables
3. Add indexes for foreign keys and common query patterns
4. Document the migration in your PR description

## Getting Help

- Check existing specs in `RNF/Docs/specs/`
- Review the task graph: `RNF/Docs/task_graph.md`
- Open a discussion for architectural questions

## Code of Conduct

Be respectful, constructive, and collaborative. We're building something meaningful together.
