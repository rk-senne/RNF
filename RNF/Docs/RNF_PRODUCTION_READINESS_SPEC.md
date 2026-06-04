# RNF Production Readiness Specification

This document defines the work needed to make RNF scalable, secure, stable, and performant. It is a technical guardrail for future tasks, not a feature roadmap.

Codex agents must use this document when implementing or verifying changes that touch authentication, data persistence, app state, services, Supabase, background sync, dates, performance, or release readiness.

## Current Risk Summary

RNF has a viable MVP foundation, but the production risks are concentrated in these areas:

- user identity and data isolation
- Supabase row-level security
- idempotent daily actions
- offline and retry behavior
- timezone correctness
- service error contracts
- build and test reliability
- state boundary discipline
- observability
- database indexes and constraints

These must be solved incrementally. Do not perform broad rewrites.

## Production Readiness Targets

### MVP-Ready

RNF is MVP-ready when:

- users can authenticate reliably
- every user-owned query is scoped to the authenticated user
- habit completion is duplicate-safe
- daily logs are create-or-fetch safe
- challenge start/fetch/complete flows are implemented
- build succeeds from the command line
- core systems have unit tests
- service failures are visible to ViewModels

### Private Alpha Ready

RNF is private-alpha ready when:

- Supabase RLS is enabled and tested for user-owned tables
- database uniqueness constraints prevent duplicated progress
- challenge, habit, workout, and reading completion are idempotent
- timezone behavior is documented and tested
- app state boundaries are stable
- crash and diagnostic logging exist for critical flows

### Public Beta Ready

RNF is public-beta ready when:

- auth/session restoration works across app launches
- sync errors are explicit and recoverable
- retry behavior is deterministic
- migrations are complete and reproducible
- service and ViewModel tests cover critical flows
- performance is acceptable on large daily history data

## Security Specification

### Authentication

RNF must use Supabase Auth as the source of user identity.

Rules:

- never fetch a global first user in production paths
- never trust a client-provided user ID without matching the authenticated session
- every user-owned service method must use the current authenticated user context
- placeholder users are allowed only for local/demo mode and must not write production data

Required service direction:

```swift
protocol AuthProviding {
    var currentUserID: UUID? { get async }
}
```

Services that write user-owned data should either:

- receive a verified authenticated `userId`, or
- resolve the current user through an auth provider.

Do not mix placeholder profile behavior with authenticated persistence.

### Row-Level Security

RLS must be enabled on all user-owned tables:

- users
- habits
- daily_logs
- habit_completions
- challenges
- workouts
- reading_uploads
- subscriptions

Minimum policy rule:

```sql
auth.uid() = user_id
```

For the users table, the row ID must map directly to `auth.uid()` or a documented foreign key mapping must exist.

Verifier must treat missing RLS migrations as HIGH risk for production-bound auth or persistence work.

### Secrets

Rules:

- never commit service-role keys
- never put private keys in Swift files
- anon keys are acceptable only if RLS policies are correct
- `.env` must not be used as a production secret store for app-distributed secrets

## Stability Specification

### Idempotency

Daily user actions must be safe to retry. The app must not duplicate progress when the user taps twice, retries after a timeout, or resumes after a network failure.

Required uniqueness constraints:

```text
daily_logs: unique(user_id, date)
habit_completions: unique(user_id, habit_id, date)
challenges: at most one active challenge per user
workouts: unique(user_id, date) where applicable
reading_uploads: unique(user_id, date) where applicable
```

Service methods should prefer create-or-fetch or upsert semantics where duplicate insertion is expected.

### Error Contracts

Services must not silently hide important persistence failures.

Preferred direction:

```swift
enum RNFServiceError: Error {
    case unauthenticated
    case networkUnavailable
    case decodingFailed
    case duplicateRecord
    case serverRejected
    case notFound
}
```

For critical flows, ViewModels must know whether data was:

- saved remotely
- saved locally only
- not saved

Do not add generic catch-and-ignore behavior to authenticated production writes.

### Offline And Retry

RNF must choose explicit behavior for bad-network conditions.

Initial policy:

- read failures may show cached/local fallback only if marked as stale or local-only
- write failures must return an error or local-only result
- retry queues must be idempotent
- retries must not award duplicate XP or advance challenges twice

No feature should rely on silent backend failure as normal control flow.

## Date And Time Specification

Daily apps fail easily on date handling. RNF must define a single policy.

Initial policy:

- user-facing daily progress uses the user's current calendar/timezone
- persisted daily records use normalized day values
- challenge day calculations use normalized local start dates unless server-side policy later replaces this
- daylight-saving transitions must not skip or duplicate challenge days

Required tests:

- start-of-day normalization
- challenge end date from start date
- daily log lookup by normalized date
- timezone boundary behavior where practical

## Performance Specification

### SwiftUI State

`GameState` must remain a shared progression snapshot, not a dumping ground.

Allowed in `GameState`:

- profile
- level and XP summary
- streak
- stats
- current quests
- daily log summary

Not allowed by default:

- screen loading flags
- modal state
- upload progress
- subscription UI state
- calendar scroll state
- workout timer transient state

Feature-specific state belongs in feature ViewModels unless multiple screens require shared state.

### Query Performance

Indexes must exist for common access patterns:

```text
daily_logs(user_id, date)
habit_completions(user_id, date)
habit_completions(user_id, habit_id, date)
challenges(user_id, status)
workouts(user_id, date)
reading_uploads(user_id, date)
```

History screens must not load unbounded data. Use month, page, or date-range queries.

### View Performance

Rules:

- do not perform network calls in computed view bodies
- do not perform heavy calculations in `body`
- avoid broad `GameState` updates for feature-local changes
- precompute display models in ViewModels when data grows

## Observability Specification

Add structured logging for critical flows using `Logger`.

Minimum categories:

- Auth
- Profile
- DailyLog
- HabitCompletion
- Challenge
- Sync

Log events should include:

- operation name
- user-safe identifiers where appropriate
- success/failure
- error category

Do not log secrets, auth tokens, raw emails, or private user content.

## Deferred Apple Platform Integrations

Apple Health and Apple Watch are explicitly deferred until the iPhone core loop is stable.

Reference specs:

- `RNF_APPLE_HEALTH_INTEGRATION_SPEC.md`
- `RNF_APPLE_WATCH_SPEC.md`

Sequencing rule:

```text
iPhone MVP -> HealthKit decision/integration -> Apple Watch companion
```

Builder must not add HealthKit or watchOS code unless the selected task explicitly references the relevant spec. Verifier must treat accidental HealthKit/watchOS work as out-of-scope feature creep.

## Build And Test Reliability

The command-line build must be reliable before automation can be trusted.

### MVP Deployment Target

RNF's iPhone MVP minimum deployment target is iOS 18.0.

Rationale:

- The current app code and resolved package dependencies do not require iOS 26-only APIs.
- The Supabase Swift dependency graph supports substantially older iOS versions.
- iOS 18.0 keeps the MVP available to more test devices while preserving a modern SwiftUI baseline.

Do not raise the minimum deployment target for app, unit test, or UI test targets unless a selected task explicitly introduces and documents an API requirement that needs a newer iOS version.

Required baseline command:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild \
  -project /Users/regosenne/Desktop/Dev/RNF/RNF.xcodeproj \
  -scheme RNF \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/RNFDerivedData \
  build
```

Build failures caused by environment setup must be fixed or documented before trusting LOW-risk automation results.

### Repository Hygiene

Tracked local IDE/user files must be cleaned up before enforcing stricter CI hygiene gates.

Known cleanup item:

```text
RNF.xcodeproj/xcuserdata/
```

Current CI intentionally blocks newly tracked `.DS_Store` and `.rnf/` files, but does not yet fail on `xcuserdata` because that state already exists in the repository history. Create a dedicated cleanup branch before enabling the stricter rule:

```text
chore/remove-xcode-userdata
```

Target outcome:

- remove tracked `xcuserdata`
- add or confirm `.gitignore` coverage for `xcuserdata/`
- update the documentation workflow to reject future tracked `xcuserdata`
- verify Xcode still opens and builds the shared scheme

Minimum test order:

1. `XPSystem`
2. `StreakSystem`
3. `QuestDifficultySystem`
4. daily status calculation
5. duplicate habit completion behavior
6. challenge lifecycle service behavior
7. ViewModel state application

## Migration Discipline

Rules:

- never edit applied migrations
- add new migrations for constraints, indexes, or policy changes
- every table change must be reflected in model/service specs
- RLS policies must be added in migrations, not only documented
- migrations must be reviewed like app code

## Agent Rules

Builder must read this document before tasks involving:

- Supabase
- auth
- user-owned data
- services
- `GameState`
- date logic
- challenge lifecycle
- background sync
- tests
- migrations

Verifier must check this document when reviewing those tasks.

Risk rules:

- Missing user scoping in authenticated persistence is HIGH risk.
- Missing or contradicted RLS for production user data is HIGH risk.
- Non-idempotent daily progress writes are HIGH risk.
- Silent failure on critical authenticated writes is at least MEDIUM risk.
- Unbounded history queries are at least MEDIUM risk.
- Broad `GameState` growth without justification is at least MEDIUM risk.
- Any task that cannot build because of code errors is HIGH risk.

## Implementation Order

Do this in order:

1. Separate automation changes from app-task changes in Git.
2. Make command-line build reliable.
3. Add database constraints and indexes for daily logs, completions, and challenges.
4. Add or verify RLS policies for user-owned tables.
5. Introduce auth/session provider boundary.
6. Replace global first-profile reads in production paths.
7. Make daily actions idempotent.
8. Refactor `ProgressionEngine` to return typed results.
9. Keep `GameState` focused on shared progression.
10. Add pure system tests, then service and ViewModel tests.
