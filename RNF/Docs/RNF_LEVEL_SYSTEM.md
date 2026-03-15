# RNF Level System

The RNF Level System defines how users progress through levels as they complete habits and earn XP.

Levels represent personal growth and long-term discipline.

Leveling must feel:

• rewarding
• visible
• meaningful
• long-term

The system must support progression for **multiple years of use**.

---

# Core Progression Loop

Habit Completed
↓
XP Awarded
↓
XP Added to Total
↓
Check Level Threshold
↓
Level Up if Threshold Reached
↓
Unlock Titles / Content

---

# XP Sources

Users earn XP from actions.

Base XP rewards:

Habit Completion = 10 XP
Workout Completion = 15 XP
Reading Completion = 10 XP
Daily Mission Complete = 25 XP

Optional bonuses:

Streak Bonus = +5 XP
Perfect Day Bonus = +15 XP

---

# XP Storage

XP is stored as a cumulative value.

Database field:

users.xp_total

Example:

User XP total = 1460

Level is derived from this value.

---

# Level Threshold Curve

RNF uses a **non-linear progression curve**.

Early levels should be fast to build momentum.

Later levels should require significant effort.

---

Level | XP Required
----- | -----------
1 | 0
2 | 200
3 | 450
4 | 800
5 | 1300
6 | 2000
7 | 2900
8 | 4000
9 | 5400
10 | 7000
11 | 9000
12 | 11500
13 | 14500
14 | 18000
15 | 22000
16 | 27000
17 | 33000
18 | 40000
19 | 48000
20 | 57000

After level 20 the system continues using a scaling formula.

---

# XP Scaling Formula

For levels above 20:

XP_required = previous_XP + (level × 1500)

This ensures progression remains meaningful for long-term users.

---

# Level Calculation

Level is determined by comparing xp_total to thresholds.

Example:

xp_total = 1450

Check thresholds:

Level 5 = 1300
Level 6 = 2000

User level = 5

---

# XP Carry Over

When leveling up:

Remaining XP carries into the next level.

Example:

Level threshold = 1300
User XP = 1380

Level = 5
XP into level = 80

---

# XP Progress Calculation

Used for UI progress bars.

Formula:

progress = xp_current_level / xp_required_next_level

Example:

Current XP = 1380
Level 5 threshold = 1300
Next level threshold = 2000

XP into level = 80
XP needed = 700

Progress = 80 / 700

---

# Level Up Rewards

Leveling up may unlock:

Titles
Skill points
New quests
Avatar upgrades

Example rewards:

Level 3 → "Disciple" title
Level 5 → radar stat upgrade
Level 10 → unlock evolution screen
Level 15 → skill tree unlock

---

# Visual Feedback

Leveling must feel impactful.

UI effects:

XP bar animation
Level aura pulse
Confetti burst
Sound feedback

---

# Level Titles

Levels correspond to rank titles.

Level Range | Title
----------- | -----
1–4 | Disciple
5–9 | Awakened
10–14 | Ascendant
15–19 | Warlord
20+ | Apex

Titles are shown in:

AscensionView

---

# System Files

Files responsible for this logic:

XPSystem.swift
GameState.swift
AscensionView.swift

XPSystem handles:

• XP addition
• level calculations
• level up detection

GameState stores:

• level
• xp_total
• xp_to_next

---

# Example XP Flow

User completes habit:

+10 XP

User XP:

1390 → 1400

Check threshold:

Next level = 2000

Progress updated.

UI updates XP bar.

---

# Design Principles

The leveling system must:

avoid instant max level
reward consistency
create long-term identity

RNF users should feel:

"I am evolving as a person."

Not:

"I am checking boxes."

---

# Future Extensions

Skill Trees
Prestige System
Boss Battles
Evolution Paths
