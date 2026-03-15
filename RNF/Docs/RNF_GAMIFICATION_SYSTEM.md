# RNF Gamification System

This document defines the psychological and mechanical systems that drive engagement in RNF.

RNF is not a simple habit tracker.

RNF is a **Real Life RPG progression system** where users level up their real-world discipline.

The gamification system must feel:

- calm
- structured
- rewarding
- identity driven

Avoid childish gamification.

The goal is **self-mastery progression**.

---

# Core Engagement Loop

User opens RNF
→ completes a habit
→ earns XP
→ improves character stats
→ progresses toward level up
→ streak increases
→ titles unlock
→ quests adapt to weakest stats

Loop:

Habit → XP → Level → Stats → Titles → Streak → Quests → Identity Growth

---

# XP System

XP represents personal growth.

XP sources:

Habit completion  
Workout completion  
Reading completion  
Full day completion

Example values:

Habit completion: +10 XP  
Workout completion: +15 XP  
Reading proof: +10 XP  
Daily completion bonus: +5 XP

Maximum XP per day should remain limited to avoid farming.

Suggested cap:

40–60 XP per day

---

# Level System

Levels represent overall progress.

XP accumulates toward the next level.

Example progression:

Level 1 → 0 XP  
Level 2 → 200 XP  
Level 3 → 450 XP  
Level 4 → 800 XP  
Level 5 → 1300 XP

XP carries over between levels.

Leveling should trigger:

- visual feedback
- aura glow animation
- subtle haptic feedback

Levels also unlock future features.

Example:

Level 5 → new habits unlock  
Level 10 → advanced quests

---

# Character Stats

Stats represent the player's development across different aspects of life.

Stats include:

strength  
discipline  
focus  
energy  
wisdom  
mind  
spirit

Each habit improves specific stats.

Examples:

Workout → strength +1  
Cold Shower → discipline +1  
Read 10 Pages → focus +1  
Meditation → wisdom +1  
Drink Water → energy +1

Stats influence quest generation.

---

# Streak System

Streaks represent daily consistency.

A streak increases when the user completes the daily mission.

Example daily goal:

4 habits per day.

If the daily goal is reached:

streak += 1

Missing the goal resets the streak unless forgiveness is used.

Streak milestones unlock titles.

Example:

3 days → Spark Initiate  
7 days → Ember Initiate  
30 days → Forged Disciple  
90 days → Iron Ascendant

---

# Forgiveness System

Forgiveness protects streaks.

Users earn forgiveness tokens.

Example:

1 forgiveness token earned every 30 days.

If a day is missed:

User is prompted:

Use Forgiveness  
Accept Reset

If forgiveness is used:

daily_log.status = forgiven  
streak remains unchanged

Forgiveness tokens decrease by 1.

---

# Titles System

Titles represent identity milestones.

Titles unlock through achievements.

Examples:

7 Day Streak → Ember Initiate  
30 Day Streak → Forged Disciple  
90 Day Streak → Iron Ascendant

Titles appear in AscensionView.

Titles should feel meaningful.

Avoid excessive titles.

---

# Quest System

Quests guide users toward improving weak areas.

QuestGenerator identifies the player's weakest stat.

Example:

If focus is lowest stat:

Generate quests such as:

Read 10 Pages  
Meditate  
Journal

This ensures balanced character growth.

---

# Character Visualization

Character growth is visualized using a radar chart.

Displayed stats:

strength  
discipline  
focus  
energy  
wisdom  
mind  
spirit

Users should see their character evolve over time.

---

# Long Term Systems (Phase 2)

These systems expand progression once retention is validated.

Skill Trees

Allow specialization paths.

Example:

Strength Path

Warrior  
Athlete  
Titan

Mind Path

Scholar  
Strategist  
Mastermind

---

Perk System

Perks provide passive bonuses.

Examples:

+10% XP  
Extra quest rewards  
Stat multiplier

---

Boss Battles

Users defeat bosses by completing habits.

Example bosses:

Procrastination  
Doubt  
Laziness

Boss HP decreases when habits are completed.

---

Evolution System

Major transformations unlocked at milestones.

Example:

30 Day Streak → Iron Discipline  
90 Day Streak → Ascended Form

---

AI Quest Generation

AI dynamically creates quests based on behavior patterns.

Example:

User skipping workouts → generate movement challenges.

---

# Gamification Philosophy

RNF should make users feel like they are **building themselves**.

The app must reinforce identity:

"I am becoming stronger."

Progression should feel:

earned  
visible  
meaningful
