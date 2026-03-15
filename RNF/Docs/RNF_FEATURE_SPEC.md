# RNF Feature Specification

This document defines all systems required for the RNF application.

Architecture must always follow:

Models → Systems → UI

This ensures separation of logic and interface.

---

# Feature 1 — Habit Completion

## Description

Users complete daily habits to gain XP and stat rewards.

Habit completion is the core interaction of the application.

## Requirements

When a habit is tapped:

1. Mark habit as completed
2. Add XP to the player
3. Increase the daily mission counter
4. Update character stats
5. Trigger XP animation
6. Check for level up
7. Update streak if daily goal reached
8. Persist progress

## Flow

Habit Tap
→ CompleteHabit()
→ XPSystem.applyXP()
→ StatSystem.applyReward()
→ DailyMission update
→ Level check
→ Streak update

## Files

ContentView.swift  
XPSystem.swift  
StatSystem.swift  
StreakSystem.swift  
GameState.swift

---

# Feature 2 — XP and Leveling

## Description

XP is earned from habits and increases the player's level.

Level represents the player's growth.

## Rules

XP adds to totalXP.

If:

totalXP >= xpToNext

Then:

level += 1

XP carries over to next level.

xpToNext increases every level.

## Example

Level 1 → 200 XP  
Level 2 → 300 XP  
Level 3 → 450 XP  

## Files

XPSystem.swift  
GameState.swift

---

# Feature 3 — Character Stats

## Description

Habits increase character stats.

Stats represent personal development.

Stats include:

strength  
discipline  
focus  
energy  
wisdom  
mind  
spirit  

## Example

Workout → strength +1  
Cold Shower → discipline +1  
Reading → focus +1  
Meditation → wisdom +1  

## Rules

Stats increase only when habits are completed.

Stats persist between sessions.

## Files

Stats.swift  
StatSystem.swift  
GameState.swift

---

# Feature 4 — Daily Missions

## Description

Users must complete a daily goal.

Example:

4 habits per day.

Completing the daily goal increases streak.

## Rules

dailyCompleted += 1

If:

dailyCompleted >= dailyGoal

Then:

streak += 1

## Files

ContentView.swift  
StreakSystem.swift  
GameState.swift

---

# Feature 5 — Titles

## Description

Titles represent milestones and identity progression.

Titles unlock based on streaks or achievements.

## Examples

7 Day Streak → Ember Initiate  
30 Day Streak → Forged Disciple  
90 Day Streak → Iron Ascendant  

Titles appear in AscensionView.

## Files

BadgeSystem.swift  
AscensionView.swift  
GameState.swift

---

# Feature 6 — Character Stats Visualization

## Description

Stats are visualized using a radar chart.

This helps users see their development.

Displayed stats:

strength  
discipline  
focus  
energy  
wisdom  
mind  
spirit  

## Files

DisciplineRadarChart.swift  
AscensionView.swift

---

# Feature 7 — Quest Generator

## Description

Quests are generated dynamically based on player weaknesses.

The system identifies the lowest stat and recommends habits.

## Example

If focus is lowest:

Generate:

Read 10 pages  
Meditate  
Deep work

## Files

QuestGenerator.swift  
QuestRepository.swift  
QuestMapper.swift

---

# Feature 8 — GameState (Global Player State)

## Description

GameState is the central data model that holds the player's progress.

It allows multiple screens to share the same state.

GameState is injected into the UI using EnvironmentObject.

## Stored Data

level  
xp  
xpToNext  
streak  
stats  
titles  

## Files

GameState.swift  
RNFApp.swift

---

# Feature 9 — Streak System

## Description

Tracks consecutive days where the daily mission goal is completed.

Streaks unlock titles and achievements.

## Example

3 Day Streak  
7 Day Streak  
30 Day Streak  
90 Day Streak

## Files

StreakSystem.swift  
BadgeSystem.swift

---

# Feature 10 — Persistence

## Description

User progress must persist between sessions.

Player data must be saved locally.

## Stored Data

level  
xp  
stats  
streak  
titles  
completed habits  

## Storage Options

UserDefaults (Phase 1)  
Supabase (Phase 2)

## Files

GameState.swift  
SupabaseManager.swift

---

# Feature 11 — Animations

## Description

Animations increase dopamine and engagement.

Animations include:

XP gain
Level up glow
Habit completion check
Radar chart growth

## Files

ContentView.swift  
AscensionView.swift  
XPBar.swift

---

# Future Systems (Phase 2)

These systems are planned but not yet implemented.

---

# Feature 12 — Skill Trees

Skill trees allow players to specialize their development.

Example paths:

Strength Path

Warrior  
Athlete  
Titan  

Mind Path

Scholar  
Strategist  
Mastermind  

Spirit Path

Aware  
Grounded  
Ascended  

Skill trees unlock abilities and perks.

Files:

SkillTreeSystem.swift  
SkillTreeView.swift

---

# Feature 13 — Perk System

Perks provide bonuses.

Examples:

+10% XP  
Double stat gain  
Daily quest bonus  

Files:

PerkSystem.swift

---

# Feature 14 — Boss Battles

Users fight bosses using completed habits.

Example bosses:

Procrastination  
Doubt  
Laziness  

Boss HP decreases as habits are completed.

Files:

BossSystem.swift  
BossView.swift

---

# Feature 15 — Evolution System

Major transformations unlocked at milestones.

Example:

30 Day Streak → Iron Discipline  
90 Day Streak → Ascended Form  

Files:

EvolutionSystem.swift  
EvolutionView.swift

---

# Feature 16 — AI Quest Generation

AI dynamically creates quests.

Example:

User weak in focus → reading challenges

Files:

AIQuestSystem.swift