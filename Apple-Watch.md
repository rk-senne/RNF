# Apple Watch

This document defines the intended Apple Watch direction for RNF. It is a deferred companion-app spec. Do not implement watchOS support until the iPhone core loop, sync behavior, and HealthKit decision are stable.

## Decision

RNF should eventually support Apple Watch as a companion client, not as the source of truth.

Implementation order:

1. Complete iPhone MVP.
2. Stabilize auth, daily logs, challenge lifecycle, workouts, reading, and sync/error handling.
3. Add Apple Health integration if selected.
4. Add Apple Watch companion app.

## Product Goals

Apple Watch should make RNF faster to use in moments where opening the phone is friction.

Primary use cases:

- quick habit completion
- view daily mission progress
- start/stop workout timer
- mark workout completion
- see challenge day status
- receive haptic reminders
- show streak/challenge status in complications or widgets

Non-goals for first Watch phase:

- full onboarding
- account creation
- subscription management
- reading proof upload
- complete analytics dashboard
- complex quest editing

## Architecture

Apple Watch must be a companion client.

Correct flow:

```text
Watch UI action
  -> Watch local intent/state
  -> WatchConnectivity message
  -> iPhone app service/engine layer
  -> Supabase
  -> synced result back to Watch
```

If direct watch-to-network support is added later, it must still use the same domain rules and idempotent service contracts as the iPhone app.

Rules:

- Watch app must not become a separate source of truth.
- Watch actions must be idempotent.
- Watch state must tolerate delayed iPhone/Supabase sync.
- Watch UI must stay minimal.
- Watch must not duplicate XP, daily completions, or challenge advancement.

## Expected Targets

When implemented, the project may need:

```text
RNF Watch App
RNF Watch App Extension
Shared model/domain module or shared source group
```

Decision before implementation:

- either keep shared code in app target groups carefully included in both targets
- or extract pure models/systems into a shared Swift package/framework

Preferred long-term direction:

```text
Shared RNFCore module for pure models, systems, and message DTOs.
```

Do not extract a shared module until there is concrete Watch or widget pressure.

## Communication

Initial communication technology:

```text
WatchConnectivity
```

Message categories:

```text
completeHabit
startWorkout
stopWorkout
requestDailySnapshot
syncSnapshot
```

Messages must include stable IDs and idempotency keys.

Example direction:

```swift
struct WatchHabitCompletionMessage: Codable {
    let idempotencyKey: UUID
    let habitID: UUID
    let completedAt: Date
}
```

## Watch State Model

The Watch should receive a compact daily snapshot.

Suggested shape:

```swift
struct WatchDailySnapshot: Codable {
    let date: Date
    let level: Int
    let streak: Int
    let dailyCompleted: Int
    let dailyGoal: Int
    let challengeDay: Int?
    let habits: [WatchHabitSummary]
}
```

Watch state should not mirror full `GameState`.

## Offline Behavior

The Watch may be used when the phone is unavailable.

Initial policy:

- allow local optimistic UI for simple actions
- queue actions with idempotency keys
- sync to iPhone when available
- show pending state until confirmed
- rollback or mark failed if rejected

No queued Watch action may award XP twice.

## HealthKit Relationship

Apple Watch and Apple Health overlap but are separate integrations.

Rules:

- Watch workout timer is an RNF interaction feature
- HealthKit workout import is a data integration feature
- do not assume Watch support requires writing Health workouts
- do not assume HealthKit support requires a Watch app

If RNF writes workouts to HealthKit, that requires the Apple Health spec and an additional privacy review.

## Notifications And Haptics

Watch reminders should be lightweight.

Allowed:

- daily mission reminder
- streak warning
- workout timer haptic
- challenge day reminder

Not allowed:

- excessive nagging
- manipulative urgency loops
- notification behavior that bypasses user settings

## Performance Constraints

Watch app constraints:

- small payloads
- short interactions
- minimal background work
- no heavy calculations in Watch views
- avoid unbounded history on Watch

Watch should display summaries, not full analytics.

## Security And Privacy

Rules:

- do not show sensitive user details on complications by default
- do not send secrets through WatchConnectivity
- do not log private health/workout details
- respect locked-device privacy where applicable

## Testing Requirements

Minimum tests when implemented:

- message encoding/decoding
- duplicate action prevention
- queued action replay
- iPhone unavailable state
- daily snapshot mapping
- habit completion confirmation path
- workout timer sync path

## Agent Guardrails

Builder must not add Watch targets or WatchConnectivity unless the selected task explicitly references this document.

Verifier risk rules:

- Watch directly mutating Supabase without shared idempotent rules is HIGH risk
- duplicate-prone Watch actions are HIGH risk
- full `GameState` mirroring to Watch is MEDIUM risk
- adding Watch targets before the core iPhone loop is stable is MEDIUM risk
- HealthKit writes from Watch without the Health spec are HIGH risk

## Readiness Checklist

Apple Watch work can start only when:

- iPhone core loop is stable
- auth/session restoration is stable
- daily logs are idempotent
- challenge lifecycle is stable
- workout flow exists
- service errors are explicit
- sync/offline policy is defined
- HealthKit direction is decided


---

_Source: `RNF/Docs/RNF_APPLE_WATCH_SPEC.md`_
