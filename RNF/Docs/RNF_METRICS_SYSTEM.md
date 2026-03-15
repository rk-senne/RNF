# RNF Metrics System

This document defines the analytics and metrics used to evaluate RNF performance.

RNF analytics must focus on **behavior and retention**, not vanity metrics.

The goal is to understand:

- why users return
- where users drop off
- what habits users complete
- what features drive retention

Analytics should remain minimal and privacy respectful.

---

# Analytics Tools

Recommended tools:

PostHog
or
Amplitude

These tools support event tracking and retention analysis.

Do not track unnecessary personal information.

---

# Core Product Metrics

RNF success depends on retention.

Primary metrics:

Day 1 retention
Day 7 retention
Day 30 retention

Phase 1 target:

Day 7 retention ≥ 40%

If this target is reached, RNF has strong product-market fit potential.

---

# Engagement Metrics

Track how users interact with the system.

Key metrics:

Daily Active Users (DAU)

Average habits completed per day

Average XP earned per user

Average streak length

Reading completion rate

Workout completion rate

---

# Core Events

The following events must be tracked.

---

## App Opened

Event:

app_opened

Properties:

user_id
timestamp
device_type

Purpose:

Measure daily activity.

---

## Habit Completed

Event:

habit_completed

Properties:

user_id
habit_id
habit_name
xp_awarded
timestamp

Purpose:

Measure habit engagement.

---

## Daily Goal Completed

Event:

daily_goal_completed

Properties:

user_id
habits_completed
daily_goal
timestamp

Purpose:

Measure discipline success rate.

---

## Workout Completed

Event:

workout_completed

Properties:

user_id
duration
xp_awarded
timestamp

Purpose:

Measure movement engagement.

---

## Reading Completed

Event:

reading_completed

Properties:

user_id
proof_uploaded (true/false)
xp_awarded
timestamp

Purpose:

Measure reading consistency.

---

## Level Up

Event:

level_up

Properties:

user_id
new_level
xp_total
timestamp

Purpose:

Track long-term progression.

---

## Streak Increased

Event:

streak_increased

Properties:

user_id
new_streak_length
timestamp

Purpose:

Track consistency growth.

---

## Forgiveness Used

Event:

forgiveness_used

Properties:

user_id
streak_length
timestamp

Purpose:

Understand streak recovery behavior.

---

## Challenge Started

Event:

challenge_started

Properties:

user_id
start_date

Purpose:

Measure onboarding success.

---

## Challenge Completed

Event:

challenge_completed

Properties:

user_id
end_date
total_xp
final_streak

Purpose:

Measure long-term retention.

---

# Funnel Metrics

RNF onboarding funnel:

Install
→ Account Created
→ Challenge Started
→ First Habit Completed
→ First Day Completed
→ Day 7 Retained

Track conversion rates between each stage.

---

# Retention Analysis

Key retention questions:

How many users return after 1 day?

How many users return after 7 days?

How many users complete a full week?

How many reach 30 days?

This determines the strength of the habit system.

---

# Habit Analysis

Track completion rates per habit.

Example metrics:

Workout completion rate

Reading completion rate

Cold shower completion rate

Habits with low completion rates may need redesign.

---

# XP Economy Monitoring

Monitor XP distribution.

Questions:

Are users leveling too fast?

Are users leveling too slowly?

Average XP per user per week.

Adjust XP rewards if necessary.

---

# Streak Behavior Analysis

Track streak length distribution.

Example:

Average streak length
Longest streaks achieved

This helps understand consistency patterns.

---

# Notification Effectiveness

Track whether notifications trigger engagement.

Event:

notification_opened

Properties:

user_id
notification_type (morning / evening)
timestamp

This helps optimize notification timing.

---

# Subscription Metrics

Track monetization performance.

Events:

trial_started
subscription_started
subscription_canceled

Properties:

user_id
plan_type
timestamp

Metrics:

Trial conversion rate
Monthly churn rate

---

# Performance Metrics

Monitor performance to ensure smooth UX.

Key metrics:

Daily log load time

Habit completion response time

Image upload duration

App crash rate

---

# Privacy Principles

RNF analytics must respect user privacy.

Rules:

Do not track private messages.

Do not track unnecessary personal data.

Use anonymized user identifiers.

Users should feel safe using the app.

---

# Metrics Philosophy

Analytics should guide product improvement.

The goal is not manipulation.

The goal is understanding behavior.

RNF must remain a **discipline tool**, not an addiction machine.
