# RNF Database Schema

This document defines the Supabase PostgreSQL schema for RNF.

The schema supports:

- habit tracking
- XP progression
- streak tracking
- quests
- reading verification
- subscriptions

All tables must include:

created_at timestamp.

---

# Table: users

This table extends Supabase Auth users.

Fields:

id (uuid primary key)  
email (text)

xp_total (integer)  
level (integer)

current_streak (integer)

strength (integer)  
discipline (integer)  
focus (integer)  
energy (integer)  
wisdom (integer)  
mind (integer)  
spirit (integer)

forgiveness_tokens (integer)

morning_notification_time (time)  
evening_notification_time (time)

created_at (timestamp)

---

# Table: subscriptions

Tracks subscription state.

Fields:

id (uuid primary key)  
user_id (uuid foreign key → users.id)

plan_type (text)

Values:

full_access  
maintenance

status (text)

Values:

active  
expired

renewal_date (timestamp)

created_at (timestamp)

---

# Table: challenges

Represents a user's 90-day challenge.

Fields:

id (uuid primary key)  
user_id (uuid)

start_date (date)  
end_date (date)

current_day (integer)

status (text)

Values:

active  
completed  
reset

created_at (timestamp)

---

# Table: daily_logs

The most important table.

Each day generates a record.

Fields:

id (uuid primary key)

user_id (uuid)

date (date)

habits_completed (integer)  
habits_required (integer)

workout_completed (boolean)

reading_completed (boolean)

forgiveness_used (boolean)

xp_earned (integer)

status (text)

Values:

complete  
partial  
missed  
forgiven

created_at (timestamp)

This table drives the calendar system.

---

# Table: habits

Stores available habits.

Fields:

id (uuid primary key)

name (text)

description (text)

xp_reward (integer)

is_core (boolean)

Examples:

Drink Water  
No Junk Food  
Read 10 Pages  
Journal  
Workout

Core habits appear automatically.

Other habits unlock later.

---

# Table: habit_completions

Tracks habit completion per day.

Fields:

id (uuid primary key)

user_id (uuid)

habit_id (uuid)

date (date)

completed_at (timestamp)

xp_awarded (integer)

created_at (timestamp)

---

# Table: quests

Stores available quests.

Fields:

id (uuid primary key)

title (text)

description (text)

difficulty (integer)

stat_strength (integer)  
stat_discipline (integer)  
stat_focus (integer)  
stat_energy (integer)  
stat_wisdom (integer)  
stat_mind (integer)  
stat_spirit (integer)

created_at (timestamp)

QuestGenerator uses these values.

---

# Table: reading_uploads

Stores book proof images.

Fields:

id (uuid primary key)

user_id (uuid)

image_url (text)

date (date)

created_at (timestamp)

Images stored in:

Supabase Storage bucket:

reading-proof

---

# Data Relationships

users → daily_logs

users → habit_completions

users → subscriptions

users → challenges

users → reading_uploads

users → workouts

users → bosses

users → user_achievements

users → mastery_paths

users → user_skills

users → guild_members

guilds → guild_members

guilds → social_challenges

skill_nodes → user_skills

habits → habit_completions

quests used by QuestGenerator.

---

# Table: workouts

Stores individual workout sessions.

Fields:

id (uuid primary key)

user_id (uuid foreign key → users.id)

date (date)

workout_type (text)

target_duration_seconds (integer)

completed_duration_seconds (integer, default 0)

completed (boolean, default false)

xp_awarded (integer, default 0)

created_at (timestamptz)

Note: Pre-provisioned for Phase 2. Phase 1 uses daily_logs.workout_completed.

---

# Table: bosses

Symbolic boss battles for discipline reinforcement.

Fields:

id (uuid primary key)

user_id (uuid foreign key → users.id)

boss_type (text: procrastination, doubt, laziness, distraction, apathy)

max_hp (integer)

current_hp (integer)

status (text: locked, active, defeated)

defeated_at (timestamptz, nullable)

created_at (timestamptz)

---

# Table: user_achievements

Tracks unlocked achievements per user.

Fields:

id (uuid primary key)

user_id (uuid foreign key → users.id)

achievement_id (text)

unlocked_at (timestamptz)

Constraint: unique (user_id, achievement_id)

---

# Table: mastery_paths

Tracks mastery path specialization progress.

Fields:

id (uuid primary key)

user_id (uuid foreign key → users.id)

path_type (text: warrior, scholar, monk, athlete, strategist)

tier (integer, 1–3)

xp_in_path (integer, default 0)

started_at (timestamptz)

Constraint: unique (user_id, path_type)

---

# Table: guilds

Social accountability groups.

Fields:

id (uuid primary key)

name (text)

description (text, nullable)

member_count (integer, default 1)

total_xp (integer, default 0)

created_by (uuid foreign key → users.id)

created_at (timestamptz)

---

# Table: guild_members

Guild membership join table.

Fields:

id (uuid primary key)

guild_id (uuid foreign key → guilds.id)

user_id (uuid foreign key → users.id)

role (text: leader, member)

joined_at (timestamptz)

Constraint: unique (guild_id, user_id)

---

# Table: social_challenges

Guild-level shared challenges.

Fields:

id (uuid primary key)

guild_id (uuid foreign key → guilds.id)

title (text)

description (text, nullable)

target_completions (integer)

current_completions (integer, default 0)

status (text: active, completed, expired)

start_date (date)

end_date (date)

created_at (timestamptz)

Constraint: end_date >= start_date

---

# Table: skill_nodes

Skill tree node definitions.

Fields:

id (uuid primary key)

name (text)

stat_type (text: strength, discipline, focus, energy, wisdom, mind, spirit)

tier (integer, 1–3)

required_stat (integer, nullable)

required_node (uuid foreign key → skill_nodes.id, nullable)

perk_type (text)

perk_value (integer, default 0)

created_at (timestamptz)

---

# Table: user_skills

Tracks user skill tree unlocks.

Fields:

id (uuid primary key)

user_id (uuid foreign key → users.id)

skill_node_id (uuid foreign key → skill_nodes.id)

unlocked_at (timestamptz)

Constraint: unique (user_id, skill_node_id)

---

# Calendar Logic

Calendar colors map to daily_logs.status.

complete → green  
partial → light green  
missed → grey  
forgiven → green with marker

---

# Security (Future Phase)

Enable Supabase Row Level Security.

Example policy:

Users can only access their own records.

auth.uid() = user_id
