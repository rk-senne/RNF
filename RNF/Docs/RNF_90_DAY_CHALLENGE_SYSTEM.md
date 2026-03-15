# RNF 90-Day Challenge System

The 90-Day Challenge is the core behavioral framework of RNF.

Users commit to a structured 90-day discipline journey where daily habits build long-term consistency.

The system provides:

• structure
• progression
• accountability
• transformation milestones

The challenge is the backbone of RNF’s habit system.

---

# Purpose

The 90-Day Challenge exists to:

• create long-term commitment
• reinforce daily discipline
• provide measurable transformation
• structure the user journey

Research shows habit change stabilizes around 60–90 days.

RNF therefore uses a 90-day structure.

---

# Challenge Lifecycle

The challenge lifecycle has five phases.

1. Commitment
2. Active Progress
3. Missed Day Handling
4. Completion
5. Restart or Continue

---

# Phase 1 — Commitment

Users must explicitly commit before beginning.

Commitment screen:

Title:
Commit to 90 Days

Explanation:

This is structured progression.
Consistency matters more than perfection.

User must confirm:

"I understand this requires daily consistency."

Button:

Begin Day 1

System actions:

Create challenge record
Initialize day counter
Initialize streak

---

# Phase 2 — Active Challenge

Each day includes:

• daily habits
• workout
• reading
• XP rewards
• stat progression

Daily completion updates the challenge progress.

Fields tracked:

current_day
streak
daily_log

Example:

Day 14 / 90

---

# Challenge Progression

Challenge progress increases daily.

Logic:

If daily log complete:

current_day += 1

Streak increases.

If day missed:

Streak resets unless forgiveness used.

---

# Daily Structure

A day is considered complete when:

All required habits complete
Workout complete
Reading complete

Example:

Drink Water
No Junk Food
Workout
Reading

Daily completion awards bonus XP.

---

# Challenge Tracking

The system tracks:

daily_logs
habit_completions
reading_uploads
workout completion

The daily_logs table drives progress.

Fields:

date
habits_completed
workout_completed
reading_completed
xp_earned
status

Status values:

complete
partial
missed
forgiven

---

# Forgiveness System

Users earn forgiveness tokens.

Rule:

1 forgiveness every 30 days.

Purpose:

Prevent discouragement.

If a day is missed:

User can use forgiveness.

Outcome:

Streak preserved
Day marked forgiven

Calendar indicator:

Green with dot.

---

# Missed Day Logic

If day incomplete:

Daily log status = missed

Streak resets unless forgiveness used.

Missed days appear grey in calendar.

---

# Challenge Completion

When user reaches:

Day 90

Challenge is complete.

System actions:

Unlock special title
Generate Discipline Card
Display completion screen

Example:

You completed the 90-Day Challenge.

You forged discipline.

---

# Completion Rewards

Rewards include:

Title unlock
Evolution milestone
Special badge
Shareable Discipline Card

---

# Challenge Restart

After completion users may:

Restart challenge
Continue progression

Restart resets:

calendar
streak
day counter

Historical data preserved.

---

# Data Model

Table:

challenges

Fields:

id
user_id
start_date
end_date
current_day
status

Status:

active
completed
reset

---

# UI Integration

Displayed in:

Home screen
Profile screen
Calendar

Example UI:

Day 14 / 90
Progress bar

---

# Behavioral Design

The 90-Day Challenge reinforces:

long-term thinking
daily consistency
identity formation

Users should feel:

"I am forging discipline."

The system must remain calm and structured.

No aggressive gamification.
