-- Migration: 024_retention_tables.sql
-- Phase 24: Retention Psychology & Growth/Virality tables
-- Covers: P24-RET-11/12/16/21 + P24-GRO-04/09/13

-- ============================================================
-- P24-RET-11: Add forge_tokens column to users table
-- ============================================================

alter table public.users
    add column if not exists forge_tokens integer not null default 0
    constraint forge_tokens_non_negative check (forge_tokens >= 0);

-- ============================================================
-- P24-RET-12: Token Transactions (earn/spend ledger)
-- ============================================================

create table if not exists public.token_transactions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    amount integer not null,
    reason text not null,
    reference_id uuid,
    balance_after integer not null,
    created_at timestamptz not null default timezone('utc', now())
);

create index if not exists token_transactions_user_idx
    on public.token_transactions (user_id, created_at desc);

alter table public.token_transactions enable row level security;

create policy "Users can view own token transactions"
    on public.token_transactions for select
    using (auth.uid() = user_id);

create policy "Users can insert own token transactions"
    on public.token_transactions for insert
    with check (auth.uid() = user_id);

-- ============================================================
-- P24-RET-16: Cosmetic Unlocks
-- ============================================================

create table if not exists public.cosmetic_unlocks (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    item_key text not null,
    category text not null check (category in ('border', 'streak_color', 'card_background', 'title', 'effect')),
    equipped boolean not null default false,
    unlocked_at timestamptz not null default timezone('utc', now()),
    unique (user_id, item_key)
);

create index if not exists cosmetic_unlocks_user_idx
    on public.cosmetic_unlocks (user_id, category);

alter table public.cosmetic_unlocks enable row level security;

create policy "Users can view own cosmetic unlocks"
    on public.cosmetic_unlocks for select
    using (auth.uid() = user_id);

create policy "Users can insert own cosmetic unlocks"
    on public.cosmetic_unlocks for insert
    with check (auth.uid() = user_id);

create policy "Users can update own cosmetic unlocks"
    on public.cosmetic_unlocks for update
    using (auth.uid() = user_id);

-- ============================================================
-- P24-RET-21: League Assignments
-- ============================================================

create table if not exists public.league_assignments (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    tier text not null check (tier in ('iron', 'bronze', 'silver', 'gold', 'platinum', 'diamond', 'legend')),
    season integer not null default 1,
    week integer not null default 1,
    position integer,
    weekly_xp integer not null default 0,
    promoted_at timestamptz,
    demoted_at timestamptz,
    assigned_at timestamptz not null default timezone('utc', now()),
    unique (user_id, season, week)
);

create index if not exists league_assignments_tier_idx
    on public.league_assignments (tier, season, week, weekly_xp desc);

create index if not exists league_assignments_user_idx
    on public.league_assignments (user_id, season desc, week desc);

alter table public.league_assignments enable row level security;

create policy "Users can view league assignments in same tier"
    on public.league_assignments for select
    using (true);

create policy "Users can update own league assignment"
    on public.league_assignments for update
    using (auth.uid() = user_id);

-- Service role inserts league assignments (batch process)
create policy "Service can insert league assignments"
    on public.league_assignments for insert
    with check (true);

-- ============================================================
-- P24-GRO-04: Referrals
-- ============================================================

create table if not exists public.referrals (
    id uuid primary key default gen_random_uuid(),
    referrer_id uuid not null references public.users (id) on delete cascade,
    referred_id uuid references public.users (id) on delete set null,
    referral_code text not null,
    status text not null default 'pending' check (status in ('pending', 'signed_up', 'activated', 'rewarded')),
    tokens_earned integer not null default 0,
    created_at timestamptz not null default timezone('utc', now()),
    converted_at timestamptz
);

create unique index if not exists referrals_code_idx
    on public.referrals (referral_code);

create index if not exists referrals_referrer_idx
    on public.referrals (referrer_id, status);

create index if not exists referrals_referred_idx
    on public.referrals (referred_id);

alter table public.referrals enable row level security;

create policy "Users can view own referrals"
    on public.referrals for select
    using (auth.uid() = referrer_id or auth.uid() = referred_id);

create policy "Users can insert referrals"
    on public.referrals for insert
    with check (auth.uid() = referrer_id);

create policy "Service can update referrals"
    on public.referrals for update
    using (true);

-- ============================================================
-- P24-GRO-09: Micro Challenges (1v1 daily duels)
-- ============================================================

create table if not exists public.micro_challenges (
    id uuid primary key default gen_random_uuid(),
    challenger_id uuid not null references public.users (id) on delete cascade,
    opponent_id uuid not null references public.users (id) on delete cascade,
    title text not null,
    target_completions integer not null check (target_completions > 0),
    challenger_completions integer not null default 0 check (challenger_completions >= 0),
    opponent_completions integer not null default 0 check (opponent_completions >= 0),
    status text not null default 'pending' check (status in ('pending', 'active', 'won', 'lost', 'tied', 'expired')),
    winner_id uuid references public.users (id) on delete set null,
    tokens_wagered integer not null default 0 check (tokens_wagered >= 0),
    created_at timestamptz not null default timezone('utc', now()),
    expires_at timestamptz not null,
    completed_at timestamptz,
    check (challenger_id != opponent_id),
    check (expires_at > created_at)
);

create index if not exists micro_challenges_challenger_idx
    on public.micro_challenges (challenger_id, status);

create index if not exists micro_challenges_opponent_idx
    on public.micro_challenges (opponent_id, status);

create index if not exists micro_challenges_active_idx
    on public.micro_challenges (status, expires_at)
    where status in ('pending', 'active');

alter table public.micro_challenges enable row level security;

create policy "Users can view own micro challenges"
    on public.micro_challenges for select
    using (auth.uid() = challenger_id or auth.uid() = opponent_id);

create policy "Users can create micro challenges"
    on public.micro_challenges for insert
    with check (auth.uid() = challenger_id);

create policy "Participants can update micro challenges"
    on public.micro_challenges for update
    using (auth.uid() = challenger_id or auth.uid() = opponent_id);

-- ============================================================
-- P24-GRO-13: Content Reports (community safety)
-- ============================================================

create table if not exists public.content_reports (
    id uuid primary key default gen_random_uuid(),
    reporter_id uuid not null references public.users (id) on delete cascade,
    reported_user_id uuid references public.users (id) on delete set null,
    content_type text not null check (content_type in ('guild_name', 'username', 'challenge_title', 'message', 'other')),
    content_id uuid,
    content_text text,
    reason text not null check (reason in ('inappropriate', 'spam', 'harassment', 'offensive', 'other')),
    details text,
    status text not null default 'pending' check (status in ('pending', 'reviewed', 'actioned', 'dismissed')),
    reviewed_at timestamptz,
    created_at timestamptz not null default timezone('utc', now())
);

create index if not exists content_reports_status_idx
    on public.content_reports (status, created_at desc);

create index if not exists content_reports_reporter_idx
    on public.content_reports (reporter_id);

create index if not exists content_reports_reported_user_idx
    on public.content_reports (reported_user_id)
    where reported_user_id is not null;

alter table public.content_reports enable row level security;

create policy "Users can view own reports"
    on public.content_reports for select
    using (auth.uid() = reporter_id);

create policy "Users can create reports"
    on public.content_reports for insert
    with check (auth.uid() = reporter_id);

-- Admin/service role handles review updates (no user update policy)
