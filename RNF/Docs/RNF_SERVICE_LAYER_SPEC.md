# RNF Service Layer Specification

Production-readiness reference:

See `RNF_PRODUCTION_READINESS_SPEC.md` for service error contracts, user scoping, idempotency, retry behavior, and persistence guardrails. Service tasks must satisfy both documents.

---

This document defines the responsibilities of each service in the RNF application.

Services act as the bridge between:

ViewModels
↓
Backend (Supabase)

Views and ViewModels must never directly interact with Supabase.

All backend communication occurs through services.

---

# Service Architecture

Each service has three responsibilities:

1. Fetch data from Supabase
2. Transform raw data into models
3. Return strongly typed objects

Services must not contain UI logic.

---

# Service Layer Overview

RNF uses the following services:

AuthService  
UserService  
HabitService  
DailyLogService  
XPService  
QuestService  
ReadingService  
WorkoutService  
ChallengeService  
SubscriptionService  
AnalyticsService

Each service is responsible for a specific domain.

---

# AuthService

Handles authentication.

Responsibilities:

Sign up user  
Log in user  
Log out user  
Maintain session  
Restore session on launch

Functions:

signUp(email, password)

login(email, password)

logout()

getCurrentUser()

refreshSession()

Supabase APIs used:

supabase.auth.signUp  
supabase.auth.signInWithPassword  
supabase.auth.signOut

---

# UserService

Manages user profile data.

Responsibilities:

Fetch user profile  
Update profile settings  
Update notification times  
Update stat values

Functions:

fetchProfile(userID)

updateNotificationTimes(morningTime, eveningTime)

updateStats(stats)

updateLevel(level)

Database table:

users

---

# HabitService

Manages available habits and habit completion.

Responsibilities:

Fetch active habits  
Record habit completion  
Return XP rewards

Functions:

getActiveHabits()

completeHabit(habitID)

getHabitHistory()

Tables used:

habits  
habit_completions

---

# DailyLogService

Manages daily progress.

This is the backbone of the system.

Responsibilities:

Create daily log  
Fetch daily log  
Update habit progress  
Update workout completion  
Update reading completion  
Calculate day status

Functions:

getTodayLog()

createDailyLog()

updateHabitProgress()

completeWorkout()

completeReading()

updateDayStatus()

Table:

daily_logs

---

# XPService

Manages XP calculations and level progression.

Responsibilities:

Add XP to user  
Recalculate level  
Return level progression state

Functions:

addXP(amount)

calculateLevel(xpTotal)

checkLevelUp()

Database table:

users

---

# QuestService

Manages dynamic quest generation.

Responsibilities:

Generate quests based on user stats  
Return available quests  
Map quests to habits

Functions:

generateDailyQuests(profile)

getAvailableQuests()

mapQuestToHabit()

Tables used:

quests  
habits

---

# ReadingService

Handles reading proof uploads.

Responsibilities:

Upload reading images  
Insert database record  
Update daily log

Functions:

uploadReadingProof(image)

getReadingHistory()

Storage:

Supabase Storage

Bucket:

reading-proof

Table:

reading_uploads

---

# WorkoutService

Handles workout completion and timers.

Responsibilities:

Ensure the daily log exists for workout completion  
Update daily log workout completion  
Return XP reward

Functions:

completeWorkout()

startTimer(duration)

cancelWorkout()

No dedicated database table required for Phase 1.

Phase 1 does not persist individual workout sessions. Workout completion persistence means updating the user's `daily_logs` row for the completion date.

Completion sequence:

1. Fetch or create the target `daily_logs` row.
2. Set `daily_logs.workout_completed = true`.
3. Refresh daily log status.

---

# ChallengeService

Manages the 90-day challenge system.

Responsibilities:

Start challenge  
Fetch active challenge  
Update challenge progress  
Complete challenge

Functions:

startChallenge()

getActiveChallenge()

advanceDay()

completeChallenge()

Table:

challenges

---

# SubscriptionService

Handles subscription validation.

Responsibilities:

Fetch subscription state  
Update subscription state  
Validate StoreKit receipts

Functions:

getSubscription()

updateSubscription()

validateReceipt()

Table:

subscriptions

---

# AnalyticsService

Handles event tracking.

Responsibilities:

Track events  
Send analytics data

Functions:

trackEvent(name, properties)

Events include:

habit_completed  
workout_completed  
reading_completed  
level_up  
streak_increased

Analytics tools:

PostHog  
Amplitude

---

# Service Communication Flow

Example: Habit Completion

View
↓
ViewModel
↓
HabitService.completeHabit()

HabitService calls:

DailyLogService.updateHabitProgress()

XPService.addXP()

AnalyticsService.trackEvent()

---

# Error Handling Rules

Services must never crash the UI.

If network error occurs:

Return retry state.

If database error occurs:

Log error.

Return safe fallback.

---

# Offline Behavior

Services must support offline completion.

Rules:

User actions update local state immediately.

Network calls are queued.

Sync occurs when connection is restored.

---

# Performance Goals

Habit completion response < 100ms

Daily log fetch < 200ms

Reading upload < 2 seconds

Calendar fetch < 300ms

## Local Performance Validation

Validated against the current service-layer call graph.

Habit completion:

Current path fetches or creates the daily log, checks duplicate habit completion, inserts the completion, saves the daily log, refreshes daily-log status, saves the profile, and then updates local state.

Result:

The current implementation prioritizes persistence correctness. It is not expected to meet the `< 100ms` response target on real networked Supabase calls until offline queueing or optimistic local completion is introduced.

Workout completion:

Current path fetches or creates the daily log, updates the workout flag, refreshes daily-log status, saves the daily log, saves the profile, and evaluates challenge advancement.

Result:

The path is bounded and has no unbounded loops, but it still awaits multiple backend operations.

Reading upload:

Current path uploads one image to `reading-proof`, inserts one `reading_uploads` row, updates the daily-log reading flag, refreshes status, saves the daily log, saves the profile, and evaluates challenge advancement.

Result:

The upload target depends on image size and network conditions. The storage path is deterministic and does not add extra listing or lookup calls.

Month log fetch:

Current path performs a single `daily_logs` query filtered by `user_id` and month date range, ordered by date.

Result:

This path is structurally aligned with the `< 300ms` calendar fetch target, assuming an index on `(user_id, date)`.

---

# Security

All queries must include user_id filters.

Before production:

Enable Supabase Row Level Security.

Example policy:

auth.uid() = user_id
