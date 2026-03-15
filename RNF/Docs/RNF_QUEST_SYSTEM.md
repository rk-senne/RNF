# RNF Quest System

The Quest System generates daily tasks that help users improve their weakest areas.

Quests transform habits into structured objectives.

Instead of a static habit list, the system dynamically recommends actions based on the user's stats.

---

# Purpose

The quest system exists to:

• guide user improvement  
• target weak stats  
• create variety in habits  
• maintain engagement  

---

# Quest Categories

Each quest maps to a stat.

Stat | Example Quests
---- | --------------
strength | workout, push-ups, squats
discipline | cold shower, no junk food
focus | reading, meditation
energy | hydration, walking
wisdom | journaling, reflection
mind | deep learning
spirit | gratitude, connection

---

# Quest Types

## Core Quests

Required every day.

Examples:

Drink Water  
No Junk Food  

Core quests are fixed during early progression.

---

## Generated Quests

Generated dynamically based on weak stats.

Example:

If focus is lowest stat:

Possible quests:

Read 10 pages  
Meditate 5 minutes

---

## Weekly Habit Quests

Unlocked after week 1.

User chooses 1 new habit to maintain for 7 days.

Examples:

Daily Walk  
Stretch Routine  
Morning Journaling

---

# Quest Difficulty

Difficulty influences XP reward.

Difficulty | XP Reward
---------- | ----------
Easy | 10 XP
Medium | 15 XP
Hard | 20 XP

Difficulty depends on:

time required  
effort required  
consistency required

---

# Quest Generation Logic

QuestGenerator analyzes user stats.

Example algorithm:

1. find lowest stat
2. filter quests improving that stat
3. select quest randomly
4. assign difficulty

Pseudo logic:

lowestStat = min(stats)

availableQuests = quests where quest.targets == lowestStat

dailyQuest = random(availableQuests)

---

# Quest Repository

All quest definitions are stored locally in:

QuestRepository.swift

Each quest includes:

id  
title  
description  
difficulty  
xp_reward  
stat_strength  
stat_discipline  
stat_focus  
stat_energy  
stat_wisdom  
stat_mind  
stat_spirit  

---

# Quest Completion

When a quest is completed:

system must:

• mark quest complete  
• award XP  
• update stats  
• update daily mission progress  
• check for level up  

---

# Quest Rewards

Rewards include:

XP  
stat growth  
progress toward streak

Some quests may unlock titles.

---

# Future Quest Systems

Planned expansions:

AI-generated quests  
adaptive difficulty quests  
boss quests  
community quests
