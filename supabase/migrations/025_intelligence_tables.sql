-- Migration: 025_intelligence_tables.sql
-- Phase 25: Intelligence & Personalization tables
-- Covers: P25-INT-01 (completion_timestamps), P25-INT-10 (difficulty_adjustments)

-- ============================================================
-- P25-INT-01: Completion Timestamps (analytics for timing insights)
-- ============================================================

create table if not exists public.completion_timestamps (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    habit_id uuid not null references public.habits (id) on delete cascade,
    completed_at timestamptz not null default timezone('utc', now()),
    day_of_week integer not null check (day_of_week between 1 and 7),
    hour_of_day integer not null check (hour_of_day between 0 and 23),
    is_weekend boolean not null default false,
    created_at timestamptz not null default timezone('utc', now())
);

-- Index for timing analysis queries (user + time range)
create index if not exists completion_timestamps_user_time_idx
    on public.completion_timestamps (user_id, completed_at desc);

-- Index for day-of-week analysis
create index if not exists completion_timestamps_user_dow_idx
    on public.completion_timestamps (user_id, day_of_week);

-- Index for per-habit analysis
create index if not exists completion_timestamps_habit_idx
    on public.completion_timestamps (habit_id, completed_at desc);

-- Index for hour-of-day correlation
create index if not exists completion_timestamps_user_hour_idx
    on public.completion_timestamps (user_id, hour_of_day);

alter table public.completion_timestamps enable row level security;

create policy "Users can view own completion timestamps"
    on public.completion_timestamps for select
    using (auth.uid() = user_id);

create policy "Users can insert own completion timestamps"
    on public.completion_timestamps for insert
    with check (auth.uid() = user_id);

-- No update/delete policies — timestamps are append-only analytics

-- ============================================================
-- P25-INT-10: Difficulty Adjustments (track difficulty changes)
-- ============================================================

create table if not exists public.difficulty_adjustments (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    direction text not null check (direction in ('increase', 'decrease')),
    previous_target integer not null check (previous_target > 0),
    new_target integer not null check (new_target > 0),
    reason text not null,
    completion_rate_at_time numeric(5, 4),
    applied_at timestamptz not null default timezone('utc', now()),
    created_at timestamptz not null default timezone('utc', now())
);

-- Index for user's adjustment history
create index if not exists difficulty_adjustments_user_idx
    on public.difficulty_adjustments (user_id, applied_at desc);

-- Index for cooldown checking (most recent adjustment per user)
create index if not exists difficulty_adjustments_latest_idx
    on public.difficulty_adjustments (user_id, created_at desc);

alter table public.difficulty_adjustments enable row level security;

create policy "Users can view own difficulty adjustments"
    on public.difficulty_adjustments for select
    using (auth.uid() = user_id);

create policy "Users can insert own difficulty adjustments"
    on public.difficulty_adjustments for insert
    with check (auth.uid() = user_id);

-- No update/delete — adjustment history is immutable

-- ============================================================
-- Helper: Function to get user's median completion hour
-- ============================================================

create or replace function public.get_user_median_hour(p_user_id uuid, p_days integer default 14)
returns integer
language sql
stable
security definer
as $$
    select percentile_cont(0.5) within group (order by hour_of_day)::integer
    from public.completion_timestamps
    where user_id = p_user_id
      and completed_at >= now() - (p_days || ' days')::interval;
$$;
