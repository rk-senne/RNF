# RNF Skill Tree System

The Skill Tree System allows players to specialize their character development.

Instead of leveling all stats equally, players unlock **paths of mastery**.

Skill trees provide long-term progression and identity formation.

They should feel meaningful, strategic, and motivating.

Skill trees unlock after the user reaches **Level 10**.

---

# Purpose of Skill Trees

Skill trees allow users to:

• specialize their growth  
• unlock passive perks  
• define their personal path  

Examples:

A fitness-focused user may pursue the **Strength Path**.

A knowledge-focused user may pursue the **Mind Path**.

---

# Skill Tree Structure

Each stat has its own skill tree.

Stats include:

strength  
discipline  
focus  
energy  
wisdom  
mind  
spirit  

Each stat tree contains **three progression tiers**.

Tier 1 → early specialization  
Tier 2 → advanced mastery  
Tier 3 → ultimate mastery

---

# Example Skill Trees

## Strength Tree

Represents physical development.

Nodes:

Warrior  
Athlete  
Titan  

Unlock conditions:

Warrior → strength level 10  
Athlete → strength level 25  
Titan → strength level 50

Possible perks:

+10% workout XP  
+5% stamina growth  
+1 bonus strength per workout

---

## Discipline Tree

Represents consistency.

Nodes:

Consistent  
Structured  
Unbreakable  

Unlock conditions:

Consistent → 14-day streak  
Structured → 30-day streak  
Unbreakable → 90-day streak

Perks:

+5 XP per perfect day  
+10% streak bonus XP  
+forgiveness cooldown reduced

---

## Focus Tree

Represents concentration.

Nodes:

Thinker  
Strategist  
Mastermind  

Unlock conditions:

Thinker → focus stat 10  
Strategist → focus stat 25  
Mastermind → focus stat 50

Perks:

extra reading XP  
bonus quest rewards  
reduced distraction penalties

---

## Energy Tree

Represents vitality.

Nodes:

Activated  
Charged  
Relentless  

Unlock conditions:

hydration streak milestones  
movement consistency  

Perks:

bonus XP for workouts  
faster recovery bonuses

---

## Wisdom Tree

Represents learning.

Nodes:

Student  
Scholar  
Sage  

Unlock conditions:

reading streak milestones

Perks:

bonus XP from knowledge quests  
access to advanced reading quests

---

## Mind Tree

Represents mental resilience.

Nodes:

Resilient  
Stoic  
Unshakeable  

Unlock conditions:

journal consistency  
reflection habits

Perks:

stress resistance bonuses  
streak protection improvements

---

## Spirit Tree

Represents meaning and purpose.

Nodes:

Aware  
Grounded  
Ascended  

Unlock conditions:

gratitude actions  
forgiveness usage  
long streaks

Perks:

XP multipliers during long streaks

---

# Skill Points

Users earn skill points when leveling.

Example:

Level | Skill Points
------|--------------
10 | +1
15 | +1
20 | +1
25 | +1
30 | +1

Players spend points to unlock nodes.

---

# Unlock Rules

Nodes require:

• required stat level  
• required previous node  
• available skill points

Example:

Titan requires:

Athlete unlocked  
strength ≥ 50  
1 skill point

---

# Skill Tree Data Model

New database table:

skill_nodes

Fields:

id  
name  
stat_type  
tier  
required_stat  
required_node  
perk_type  
perk_value

---

User unlocks stored in:

user_skills

Fields:

id  
user_id  
skill_node_id  
unlocked_at

---

# UI Implementation

New screen:

SkillTreeView.swift

Displays:

stat trees  
locked nodes  
unlocked nodes

Visual style:

node graph layout

Unlocked nodes:

purple glow

Locked nodes:

grey

---

# Gameplay Impact

Skill trees modify gameplay.

Example perks:

+10% XP  
+1 stat bonus  
extra daily quest  
streak protection  

These perks should feel meaningful but balanced.

---

# Integration with Existing Systems

Skill trees interact with:

XPSystem  
StatSystem  
QuestGenerator  
BadgeSystem

Example:

Mastermind node unlocked → generate advanced quests.

---

# Future Expansion

Skill trees enable additional systems.

Examples:

Mastery paths  
Legendary titles  
Boss battle bonuses  
Evolution transformations

---

# Design Philosophy

Skill trees must reinforce identity.

The user should feel:

"I am forging a unique version of myself."

The system must remain:

clear  
purposeful  
rewarding
