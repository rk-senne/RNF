-- Migration: 026_lifecycle_tables.sql
-- Phase 27: Lifecycle & Endgame tables
-- Covers: P27-LIF-01/07/19/28/33

-- ============================================================
-- P27-LIF-01: Chapters (post-90-day progression)
-- ============================================================

create table if not exists public.chapters (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    chapter_number integer not null check (chapter_number between 1 and 5),
    started_at timestamptz not null default timezone('utc', now()),
    completed_at timestamptz,
    updated_at timestamptz not null default timezone('utc', now()),
    unique (user_id, chapter_number)
);

create index if not exists chapters_user_idx
    on public.chapters (user_id, chapter_number);

alter table public.chapters enable row level security;

create policy "Users can view own chapters"
    on public.chapters for select
    using (auth.uid() = user_id);

create policy "Users can insert own chapters"
    on public.chapters for insert
    with check (auth.uid() = user_id);

create policy "Users can update own chapters"
    on public.chapters for update
    using (auth.uid() = user_id);

-- ============================================================
-- P27-LIF-07: Prestige Records (rebirth history)
-- ============================================================

create table if not exists public.prestige_records (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    rebirth_number integer not null check (rebirth_number > 0),
    performed_at timestamptz not null default timezone('utc', now()),
    level_at_rebirth integer not null,
    titles_preserved text[] default '{}',
    achievements_preserved text[] default '{}',
    xp_bonus_percent integer not null default 0,
    stat_bonus integer not null default 0,
    unique (user_id, rebirth_number)
);

create index if not exists prestige_records_user_idx
    on public.prestige_records (user_id, rebirth_number);

alter table public.prestige_records enable row level security;

create policy "Users can view own prestige records"
    on public.prestige_records for select
    using (auth.uid() = user_id);

create policy "Users can insert own prestige records"
    on public.prestige_records for insert
    with check (auth.uid() = user_id);

-- ============================================================
-- P27-LIF-19: Habit Presets (leveled progression)
-- ============================================================

create table if not exists public.habit_presets (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    preset_id text not null,
    current_level integer not null default 1 check (current_level between 1 and 5),
    total_completions integer not null default 0 check (total_completions >= 0),
    last_leveled_at timestamptz,
    updated_at timestamptz not null default timezone('utc', now()),
    unique (user_id, preset_id)
);

create index if not exists habit_presets_user_idx
    on public.habit_presets (user_id);

alter table public.habit_presets enable row level security;

create policy "Users can view own habit presets"
    on public.habit_presets for select
    using (auth.uid() = user_id);

create policy "Users can insert own habit presets"
    on public.habit_presets for insert
    with check (auth.uid() = user_id);

create policy "Users can update own habit presets"
    on public.habit_presets for update
    using (auth.uid() = user_id);

-- ============================================================
-- P27-LIF-28: Seasonal Events
-- ============================================================

create table if not exists public.seasonal_events (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    season text not null check (season in ('spring', 'summer', 'autumn', 'winter')),
    year integer not null,
    opted_in_at timestamptz not null default timezone('utc', now()),
    progress double precision not null default 0.0 check (progress between 0.0 and 1.0),
    completed_at timestamptz,
    reward_claimed boolean not null default false,
    reward_claimed_at timestamptz,
    unique (user_id, season, year)
);

create index if not exists seasonal_events_user_idx
    on public.seasonal_events (user_id, year desc);

create index if not exists seasonal_events_active_idx
    on public.seasonal_events (season, year)
    where completed_at is null;

alter table public.seasonal_events enable row level security;

create policy "Users can view own seasonal events"
    on public.seasonal_events for select
    using (auth.uid() = user_id);

create policy "Users can insert own seasonal events"
    on public.seasonal_events for insert
    with check (auth.uid() = user_id);

create policy "Users can update own seasonal events"
    on public.seasonal_events for update
    using (auth.uid() = user_id);

-- ============================================================
-- P27-LIF-33: Legacy Milestones & Time Capsules
-- ============================================================

create table if not exists public.legacy_milestones (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    milestone_id text not null,
    unlocked_at timestamptz not null default timezone('utc', now()),
    total_days_active integer,
    total_habits_completed integer,
    highest_level integer,
    longest_streak integer,
    rebirth_count integer,
    custom_title text,
    updated_at timestamptz not null default timezone('utc', now()),
    unique (user_id, milestone_id)
);

create index if not exists legacy_milestones_user_idx
    on public.legacy_milestones (user_id);

alter table public.legacy_milestones enable row level security;

create policy "Users can view own legacy milestones"
    on public.legacy_milestones for select
    using (auth.uid() = user_id);

create policy "Users can insert own legacy milestones"
    on public.legacy_milestones for insert
    with check (auth.uid() = user_id);

create policy "Users can update own legacy milestones"
    on public.legacy_milestones for update
    using (auth.uid() = user_id);

-- Time capsules

create table if not exists public.time_capsules (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    message text not null check (char_length(message) <= 500),
    created_at timestamptz not null default timezone('utc', now()),
    reveal_at timestamptz not null,
    is_revealed boolean not null default false,
    revealed_at timestamptz,
    check (reveal_at > created_at)
);

create index if not exists time_capsules_user_idx
    on public.time_capsules (user_id, reveal_at);

create index if not exists time_capsules_pending_idx
    on public.time_capsules (reveal_at)
    where is_revealed = false;

alter table public.time_capsules enable row level security;

create policy "Users can view own time capsules"
    on public.time_capsules for select
    using (auth.uid() = user_id);

create policy "Users can insert own time capsules"
    on public.time_capsules for insert
    with check (auth.uid() = user_id);

create policy "Users can update own time capsules"
    on public.time_capsules for update
    using (auth.uid() = user_id);
