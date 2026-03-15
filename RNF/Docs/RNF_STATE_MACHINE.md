# RNF State Machine

This document defines the user state transitions within the RNF application.

RNF uses a state machine to ensure the app always knows the user's current progression stage.

States represent the user's position in the lifecycle of the app.

Transitions occur when specific events happen.

This prevents invalid states such as:

- accessing the app without authentication
- skipping onboarding
- entering the challenge without initialization

---

# High-Level User Lifecycle

The RNF user lifecycle follows this progression:

logged_out
→ authenticated
→ onboarding_notifications
→ onboarding_commitment
→ challenge_active
→ daily_progress
→ day_complete
→ challenge_complete

Each state has defined entry conditions and exit transitions.

---

# State Definitions

---

## State: logged_out

User is not authenticated.

Entry Conditions:

- first app launch
- user logged out
- session expired

Allowed Actions:

- login
- create account

Transition Events:

login_success → authenticated
signup_success → authenticated

---

## State: authenticated

User has a valid session.

Next step is determining if onboarding is complete.

Logic:

If user has no active challenge

→ onboarding_notifications

If user has active challenge

→ challenge_active

---

## State: onboarding_notifications

User configures notification schedule.

Actions:

set morning notification time
set evening notification time

Transition:

notifications_saved → onboarding_commitment

---

## State: onboarding_commitment

User commits to the 90-day system.

Screen:

"Commit to 90 Days"

Requirement:

User must confirm commitment checkbox.

Transition:

commit_confirmed → challenge_active

On transition:

Create challenge record.

Insert into challenges table.

Initialize:

current_day = 1

---

## State: challenge_active

User is actively participating in the 90-day challenge.

Entry Conditions:

active challenge exists.

The system loads:

daily_log for today.

If daily log does not exist:

create daily_log.

Next state:

daily_progress

---

## State: daily_progress

User completes daily activities.

Possible actions:

complete habit
complete workout
upload reading proof

Each action updates daily_logs.

Transitions:

daily_goal_reached → day_complete

---

## State: day_complete

User finished required tasks.

Effects:

streak increases
xp bonus awarded

Next state occurs automatically on next calendar day.

Transition:

new_day_started → challenge_active

---

## State: challenge_complete

User finishes 90-day challenge.

Entry Condition:

current_day = 90

Actions:

show transformation screen
unlock title

Possible transitions:

restart_challenge → onboarding_commitment

---

# State Diagram

High-level flow:

logged_out
→ authenticated
→ onboarding_notifications
→ onboarding_commitment
→ challenge_active
→ daily_progress
→ day_complete
→ challenge_complete

---

# Daily State Transitions

Each day follows a mini state loop.

challenge_active
→ daily_progress
→ day_complete
→ challenge_active (next day)

---

# Failure Conditions

If a day ends without completing daily goals:

Transition:

daily_progress → missed_day

System response:

Prompt forgiveness option.

If forgiveness used:

status = forgiven
streak preserved

Else:

streak reset

Return to:

challenge_active

---

# Edge Case Handling

---

## App Reinstall

If user reinstalls app:

Auth session restored.

App queries:

users table
active challenge

State restored to:

challenge_active

---

## Offline Mode

If user completes habits offline:

Update local state.

Queue database sync.

State transitions must still function locally.

---

## Multiple Devices

State determined by database values.

Primary source of truth:

daily_logs
challenges

---

# State Source of Truth

States are derived from backend data.

Primary tables:

users
challenges
daily_logs

The application must never rely only on local UI state.

---

# App Launch State Resolution

When the app launches:

Step 1

Check authentication session.

If none:

state = logged_out

Step 2

Fetch active challenge.

If none:

state = onboarding_notifications

Step 3

Fetch today's daily_log.

If none:

create record.

state = daily_progress

---

# State Machine Implementation

State machine should exist inside:

AppStateManager.swift

Responsibilities:

determine current state
handle state transitions
coordinate navigation

Views should only react to state.

---

# Design Principle

RNF must always know:

where the user is
what the user should do next

Users should never feel lost.

The system should always guide the next action.
