# RNF Apple Health Integration Specification

This document defines the intended Apple Health integration for RNF. It is a deferred integration spec. Do not implement HealthKit until the core RNF iPhone app data model is stable.

## Decision

RNF should support Apple Health later, but Apple Health must not be part of the initial MVP.

Implementation order:

1. Complete iPhone core loop.
2. Stabilize auth, daily logs, challenge lifecycle, workout flow, reading flow, and sync/error handling.
3. Add HealthKit integration.
4. Add Apple Watch companion behavior after HealthKit decisions are stable.

## Goals

Apple Health should improve trust and reduce manual entry. It should not replace RNF's own source of truth.

Primary goals:

- import workouts where appropriate
- verify workout completion signals
- optionally use step count or active energy as workout evidence
- support future wellness signals such as sleep or mindful minutes only after core workout use cases are stable
- reduce duplicate logging between RNF and Apple Fitness/Health

Non-goals for the first HealthKit phase:

- medical diagnosis
- health scoring
- heart-rate coaching
- sleep coaching
- nutrition tracking
- automatic XP farming from passive data

## Architecture

Correct flow:

```text
HealthKitService
  -> WorkoutService / DailyLogService
  -> Engine / Use Case
  -> ViewModel
  -> GameState
  -> View
```

Rules:

- HealthKit must not directly mutate `GameState`.
- HealthKit must not directly award XP.
- HealthKit imports must go through RNF domain services and engines.
- HealthKit data must be treated as evidence, not unquestioned truth.
- The app must remain usable if HealthKit is denied or unavailable.

## Required Files

Expected implementation files when this feature starts:

```text
RNF/Services/HealthKitService.swift
RNF/Models/HealthWorkoutSummary.swift
RNF/ViewModels/HealthPermissionsViewModel.swift
RNF/Features/Health/HealthPermissionsView.swift
```

Names may change, but responsibilities must stay separated.

## Entitlements And Privacy

Required Xcode capability:

```text
HealthKit
```

Required `Info.plist` keys:

```text
NSHealthShareUsageDescription
NSHealthUpdateUsageDescription
```

Initial recommendation:

- request read access only unless RNF has a clear reason to write workouts or mindfulness data
- do not request broad Health permissions upfront
- request only the minimum types required by the active feature

Privacy copy must clearly explain what RNF reads and why.

## Initial Data Types

Phase 1 HealthKit read types:

```text
HKWorkoutType
HKQuantityTypeIdentifier.stepCount
HKQuantityTypeIdentifier.activeEnergyBurned
HKQuantityTypeIdentifier.appleExerciseTime
```

Deferred data types:

```text
HKQuantityTypeIdentifier.heartRate
HKCategoryTypeIdentifier.sleepAnalysis
HKCategoryTypeIdentifier.mindfulSession
```

Deferred types require separate product justification and privacy review.

## Permission Strategy

Rules:

- ask for Health permissions only when the user reaches a Health-enabled feature
- explain value before showing the system prompt
- support denial gracefully
- allow users to continue manual workout completion without HealthKit
- expose a settings path to retry authorization

Verifier must treat mandatory HealthKit permission for core app usage as MEDIUM or HIGH risk unless the selected task explicitly requires it.

## Data Mapping

Initial mapping:

```text
HealthKit workout
  -> HealthWorkoutSummary
  -> WorkoutService imported workout candidate
  -> user confirmation or rule-based completion
  -> DailyLog update
  -> Challenge/day status update
```

RNF must decide whether imported workouts are:

- automatically accepted
- suggested for confirmation
- accepted only if they meet duration/type thresholds

Initial decision:

```text
Require explicit user confirmation for imported workouts in the first HealthKit release.
```

This avoids accidental XP or challenge progress from unrelated activity.

## Idempotency

Health imports must be duplicate-safe.

Required uniqueness direction:

```text
health_imports: unique(user_id, healthkit_workout_uuid)
```

If RNF does not create a separate `health_imports` table, the workout table must store enough source metadata to prevent duplicate import.

Required fields for imported workout records:

```text
source = healthkit
source_id = HealthKit UUID
start_date
end_date
workout_type
duration_seconds
active_energy
```

## Offline And Sync

HealthKit is local to the device. Supabase is remote. RNF must handle split-brain behavior.

Rules:

- local HealthKit reads may succeed while Supabase writes fail
- failed remote sync must be visible to the ViewModel
- retry must not duplicate workout completion or XP
- HealthKit import history must survive app restart once accepted

## Security And Privacy

Rules:

- never send raw HealthKit data to analytics
- never log raw workout details unless sanitized
- never expose Health data across users
- never upload Health data before user consent
- allow manual mode without HealthKit

## Testing Requirements

Minimum tests:

- permission denied path
- no HealthKit available path
- workout mapping to RNF summary
- duplicate import prevention
- imported workout does not auto-award XP without confirmation
- failed Supabase sync is surfaced

## Agent Guardrails

Builder must not implement HealthKit unless the selected task explicitly references this document.

Verifier risk rules:

- direct `GameState` mutation from HealthKit is HIGH risk
- automatic XP from passive Health data without confirmation is HIGH risk
- broad Health permission requests without feature need are MEDIUM risk
- missing privacy strings for HealthKit code is HIGH risk
- duplicate-prone imports are HIGH risk

## Readiness Checklist

HealthKit work can start only when:

- auth is stable
- daily logs are stable
- workout flow exists
- challenge lifecycle exists
- service error contracts are established
- idempotency rules exist for workout completion
- command-line build is reliable
