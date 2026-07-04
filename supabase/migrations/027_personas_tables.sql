-- Migration: 027_personas_tables.sql
-- Phase 28: Personas & Inclusivity
-- Covers: P28-INC-20 (Buddy Pairs)

-- ============================================================
-- P28-INC-20: Buddy Pairs Table
-- ============================================================

create table if not exists public.buddy_pairs (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    buddy_id uuid references public.users (id) on delete set null,
    link_code text not null unique,
    bond_streak integer not null default 0
        constraint bond_streak_non_negative check (bond_streak >= 0),
    is_active boolean not null default false,
    created_at timestamptz not null default timezone('utc', now()),
    paired_at timestamptz,
    unpaired_at timestamptz
);

-- Indexes for common queries
create index if not exists buddy_pairs_user_idx
    on public.buddy_pairs (user_id) where is_active = true;

create index if not exists buddy_pairs_buddy_idx
    on public.buddy_pairs (buddy_id) where is_active = true;

create unique index if not exists buddy_pairs_link_code_idx
    on public.buddy_pairs (link_code) where buddy_id is null;

-- Enable RLS
alter table public.buddy_pairs enable row level security;

-- Users can view pairs they are part of
create policy "Users can view own buddy pairs"
    on public.buddy_pairs for select
    using (auth.uid() = user_id or auth.uid() = buddy_id);

-- Users can create invites (user_id = self)
create policy "Users can create buddy invites"
    on public.buddy_pairs for insert
    with check (auth.uid() = user_id);

-- Users can update pairs they are part of (join/unpair)
create policy "Users can update own buddy pairs"
    on public.buddy_pairs for update
    using (auth.uid() = user_id or auth.uid() = buddy_id);

-- Users can delete only their own created (unclaimed) invites
create policy "Users can delete own unclaimed invites"
    on public.buddy_pairs for delete
    using (auth.uid() = user_id and buddy_id is null);

-- ============================================================
-- P28-INC-21: Buddy Daily Status Table (privacy-safe)
-- Only stores completion flag — never habit names
-- ============================================================

create table if not exists public.buddy_daily_status (
    id uuid primary key default gen_random_uuid(),
    pair_id uuid not null references public.buddy_pairs (id) on delete cascade,
    user_id uuid not null references public.users (id) on delete cascade,
    date date not null default current_date,
    did_complete boolean not null default false,
    completion_count integer not null default 0
        constraint completion_count_non_negative check (completion_count >= 0),
    created_at timestamptz not null default timezone('utc', now()),
    constraint buddy_daily_status_unique unique (pair_id, user_id, date)
);

create index if not exists buddy_daily_status_pair_date_idx
    on public.buddy_daily_status (pair_id, date desc);

alter table public.buddy_daily_status enable row level security;

-- Both users in a pair can see each other's daily status
create policy "Pair members can view buddy status"
    on public.buddy_daily_status for select
    using (
        exists (
            select 1 from public.buddy_pairs bp
            where bp.id = pair_id
            and (bp.user_id = auth.uid() or bp.buddy_id = auth.uid())
            and bp.is_active = true
        )
    );

-- Users can insert their own status
create policy "Users can insert own daily status"
    on public.buddy_daily_status for insert
    with check (auth.uid() = user_id);

-- Users can update their own status
create policy "Users can update own daily status"
    on public.buddy_daily_status for update
    using (auth.uid() = user_id);
