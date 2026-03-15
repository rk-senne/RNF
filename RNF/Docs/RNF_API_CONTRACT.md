# RNF API Contract

This document defines the interface between the RNF iOS application and the Supabase backend.

All database interactions must go through the Service Layer.

Views must never directly query Supabase.

Architecture:

View
↓
ViewModel
↓
Service Layer
↓
Supabase API
↓
PostgreSQL

---

# Naming Conventions

All service functions follow:

ServiceName.action()

Example:

UserService.fetchProfile()
HabitService.completeHabit()
DailyLogService.getTodayLog()

Database tables use snake_case.

---

# Response Models

All service calls must return typed models.

Examples:

Profile  
DailyLog  
HabitCompletion  
Subscription

Services must never return raw JSON.

---

# Authentication API

Handled by Supabase Auth.

---

## Sign Up

Function

AuthService.signUp(email, password)

Supabase call

supabase.auth.signUp()

Returns

session  
user_id

After signup:

Create user profile record.

Insert into users table.

---

## Login

Function

AuthService.login(email, password)

Supabase call

supabase.auth.signInWithPassword()

Returns

authenticated session

Session stored in iOS Keychain.

---

## Logout

Function

AuthService.logout()

Supabase call

supabase.auth.signOut()

Clears local session.

---

# User Profile API

Table

users

---

## Fetch User Profile

Function

UserService.fetchProfile(userID)

Query

SELECT *
FROM users
WHERE id = userID

Returns

Profile model.

---

## Update Notification Times

Function

UserService.updateNotificationTimes()

Query

UPDATE users
SET

morning_notification_time
evening_notification_time

WHERE id = userID

---

# Challenge API

Table

challenges

---

## Start Challenge

Function

ChallengeService.startChallenge()

Insert

INSERT INTO challenges

Fields

user_id
start_date
current_day = 1
status = active

---

## Fetch Active Challenge

Function

ChallengeService.getActiveChallenge()

Query

SELECT *
FROM challenges
WHERE user_id = userID
AND status = 'active'
LIMIT 1

Returns

Challenge model.

---

# Daily Logs API

Table

daily_logs

This table drives:

calendar  
daily progress  
streak logic

---

## Get Today Log

Function

DailyLogService.getTodayLog()

Query

SELECT *
FROM daily_logs
WHERE user_id = userID
AND date = today

If record does not exist:

Create automatically.

---

## Create Daily Log

Function

DailyLogService.createDailyLog()

Insert

INSERT INTO daily_logs

Fields

user_id
date

habits_completed = 0
habits_required = 2

workout_completed = false
reading_completed = false

xp_earned = 0

status = partial

---

## Update Day Status

Function

DailyLogService.updateStatus()

Logic

If

habits_completed == habits_required  
AND workout_completed == true  
AND reading_completed == true

status = complete

Else if

habits_completed > 0

status = partial

Else

status = missed

---

# Habit API

Tables

habits  
habit_completions

---

## Fetch Habit List

Function

HabitService.getActiveHabits()

Query

SELECT *
FROM habits
WHERE is_core = true

Returns

Habit[]

---

## Complete Habit

Function

HabitService.completeHabit(habitID)

Steps

1 Insert habit completion

INSERT INTO habit_completions

Fields

user_id
habit_id
date
completed_at
xp_awarded

2 Update daily log

daily_logs.habits_completed += 1

3 Return XP reward

XP default

10 XP

---

# Workout API

Workouts use the daily_logs table.

No separate table required for Phase 1.

---

## Complete Workout

Function

WorkoutService.completeWorkout()

Update

daily_logs.workout_completed = true

XP reward

15 XP

---

# Reading API

Table

reading_uploads

---

## Upload Reading Proof

Function

ReadingService.uploadReadingProof(image)

Step 1

Upload image to Supabase Storage

Bucket

reading-proof

Path

reading-proof/{user_id}/{date}.jpg

---

Step 2

Insert record

INSERT INTO reading_uploads

Fields

user_id
image_url
date

---

Step 3

Update daily log

reading_completed = true

XP reward

10 XP

---

# XP API

XP stored in users table.

---

## Add XP

Function

XPService.addXP(amount)

Query

UPDATE users
SET xp_total = xp_total + amount
WHERE id = userID

---

## Recalculate Level

Function

XPService.updateLevel()

Level thresholds

Level 1 = 0  
Level 2 = 500  
Level 3 = 1200  
Level 4 = 2500  

If xp_total crosses threshold

update level field.

---

# Calendar API

Calendar reads daily_logs.

---

## Fetch Month Logs

Function

CalendarService.getMonthLogs(month)

Query

SELECT *
FROM daily_logs
WHERE user_id = userID
AND date BETWEEN startOfMonth AND endOfMonth

Returns

DailyLog[]

---

# Forgiveness API

Forgiveness stored in users table.

Field

forgiveness_tokens

---

## Use Forgiveness

Function

ForgivenessService.useForgiveness()

Logic

If forgiveness_tokens > 0

UPDATE users
SET forgiveness_tokens = forgiveness_tokens - 1

UPDATE daily_logs
SET status = forgiven

Streak preserved.

---

# Subscription API

Table

subscriptions

---

## Fetch Subscription

Function

SubscriptionService.getSubscription()

Query

SELECT *
FROM subscriptions
WHERE user_id = userID

---

## Update Subscription Status

Called after StoreKit validation.

Query

UPDATE subscriptions
SET

plan_type
status
renewal_date

WHERE user_id = userID

---

# Offline Behavior

RNF must support offline completion.

Habit completion must:

1 update local state immediately
2 queue network sync
3 retry when network available

---

# Error Handling

Network error

Return retry state.

Database error

Log error.

Never crash UI.

---

# Performance Targets

Daily log fetch < 200ms

Habit completion response < 100ms

Image upload < 2 seconds

Calendar load < 300ms

---

# Security

Before production release:

Enable Supabase Row Level Security.

Example policy

auth.uid() = user_id
