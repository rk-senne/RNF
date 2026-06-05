# RNF Database Schema

This document defines the Supabase PostgreSQL schema for RNF.

The schema supports:

- habit tracking
- XP progression
- streak tracking
- quests
- skill trees
- reading verification
- subscriptions

Most persistence tables include:

created_at timestamp.

Join/unlock tables may omit `created_at` when the runtime model uses a more specific timestamp such as `unlocked_at`.

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

Objects are stored under:

reading-proof/{user_id}/{yyyy-MM-dd}.jpg

The bucket is private. Storage object policies scope access to the authenticated user's first path segment.

---

# Table: skill_nodes

Stores global skill tree nodes.

Fields:

id (uuid primary key)

name (text)

stat_type (text)

Values:

- strength
- discipline
- focus
- energy
- wisdom
- mind
- spirit

tier (integer)

Values:

- 1
- 2
- 3

required_stat (integer, nullable)

required_node (uuid foreign key -> skill_nodes.id, nullable)

perk_type (text)

Values:

- xp_multiplier
- stat_bonus
- quest_reward_bonus
- streak_protection

Compatibility aliases are allowed for older perk names used by the app mapper.

perk_value (integer)

created_at (timestamp)

---

# Table: user_skills

Stores user-owned skill node unlocks.

Fields:

id (uuid primary key)

user_id (uuid foreign key -> users.id)

skill_node_id (uuid foreign key -> skill_nodes.id)

unlocked_at (timestamp)

Uniqueness:

user_id + skill_node_id

---

# Data Relationships

users → daily_logs

users → habit_completions

users → subscriptions

users → challenges

users → reading_uploads

users → user_skills

habits → habit_completions

skill_nodes → user_skills

quests used by QuestGenerator.

---

# Calendar Logic

Calendar colors map to daily_logs.status.

complete → green  
partial → light green  
missed → grey  
forgiven → green with marker

---

# Security

Supabase Row Level Security is enabled by migrations.

Ownership policy shape:

users.id = auth.uid()

All user-owned tables use:

auth.uid() = user_id

Global catalog tables:

skill_nodes can be read by authenticated users.

Storage:

reading-proof objects are private and scoped to:

(storage.foldername(name))[1] = auth.uid()
