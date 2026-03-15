# RNF Evolution System

The Evolution System defines major character transformations that occur as users progress through RNF.

While levels represent incremental growth, evolutions represent **identity shifts**.

Evolutions occur rarely and must feel significant.

Users should remember the moment they evolve.

---

# Purpose

The Evolution System exists to:

• mark major milestones
• reinforce identity transformation
• provide long-term motivation
• celebrate discipline achievements

Evolutions connect:

levels
streaks
stat growth
titles

---

# Evolution Ladder

RNF includes five evolution tiers.

Tier | Evolution | Description
---- | --------- | -----------
1 | Disciple | Beginning the discipline journey
2 | Awakened | Conscious commitment to improvement
3 | Ascendant | Mastery of personal habits
4 | Warlord | Command of discipline across life
5 | Apex | Elite long-term consistency

These ranks represent **identity evolution**, not just skill.

---

# Evolution Requirements

Evolution occurs when specific milestones are reached.

---

## Disciple

Default starting state.

Requirements:

Create account
Begin 90-day challenge

---

## Awakened

Represents first true commitment.

Requirements:

Level ≥ 5
Streak ≥ 7 days

Rewards:

New title unlocked
Minor XP bonus

---

## Ascendant

Represents mastery of daily habits.

Requirements:

Level ≥ 10
Streak ≥ 30 days

Rewards:

Skill tree unlock
Advanced quests unlocked

---

## Warlord

Represents elite discipline.

Requirements:

Level ≥ 15
Streak ≥ 90 days

Rewards:

Major title unlock
Avatar upgrade
New challenge types

---

## Apex

Represents long-term mastery.

Requirements:

Level ≥ 20
Streak ≥ 180 days

Rewards:

Legendary title
Profile badge
Special recognition

---

# Evolution Rewards

Each evolution may unlock:

titles
skill trees
quests
visual upgrades
profile badges

Rewards should feel meaningful but not overpowering.

---

# Evolution Visual Effects

Evolution must feel impactful.

Recommended effects:

screen glow animation
character aura upgrade
sound cue
haptic feedback

These effects should be subtle but memorable.

Avoid excessive animation.

---

# UI Integration

Evolution state is displayed in:

AscensionView

Example display:

LEVEL 12
Ascendant

The evolution title appears below the level number.

Aura color may change based on evolution.

Example:

Disciple → yellow
Awakened → purple
Ascendant → red
Warlord → blue
Apex → white

---

# Data Model

Evolution is derived from player data.

Fields used:

users.level
users.current_streak

Optional database field:

users.evolution_rank

Values:

disciple
awakened
ascendant
warlord
apex

---

# Evolution Check Logic

Evolution is checked after key events.

Trigger events:

level up
streak increase
daily completion

If new evolution threshold reached:

update evolution_rank
trigger evolution animation

---

# Example Flow

User completes daily habits.

XP increases.

Level increases to 10.

System checks evolution conditions.

Conditions met:

Level ≥ 10
Streak ≥ 30

User evolves to:

Ascendant

UI displays evolution message.

---

# Integration with Other Systems

Evolution interacts with:

XPSystem
StreakSystem
SkillTreeSystem
QuestGenerator

Example:

Ascendant unlocks advanced quests.

---

# Future Evolution Paths

In future versions, users may choose different evolution paths.

Example paths:

Warrior Path
Scholar Path
Strategist Path

Each path provides unique rewards.

---

# Design Philosophy

Evolution represents personal transformation.

Users should feel:

"I am becoming stronger."

The system should reinforce long-term commitment.

RNF is not just tracking habits.

RNF is shaping identity.
