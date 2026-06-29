create table if not exists public.bosses (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    boss_type text not null check (boss_type in ('procrastination', 'doubt', 'laziness', 'distraction', 'apathy')),
    max_hp integer not null check (max_hp > 0),
    current_hp integer not null check (current_hp >= 0),
    status text not null default 'active' check (status in ('locked', 'active', 'defeated')),
    defeated_at timestamptz,
    created_at timestamptz not null default timezone('utc', now())
);

create index if not exists bosses_user_status_idx on public.bosses (user_id, status);

create table if not exists public.user_achievements (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    achievement_id text not null,
    unlocked_at timestamptz not null default timezone('utc', now()),
    unique (user_id, achievement_id)
);

create index if not exists user_achievements_user_idx on public.user_achievements (user_id);

create table if not exists public.mastery_paths (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    path_type text not null check (path_type in ('warrior', 'scholar', 'monk', 'athlete', 'strategist')),
    tier integer not null default 1 check (tier >= 1 and tier <= 3),
    xp_in_path integer not null default 0 check (xp_in_path >= 0),
    started_at timestamptz not null default timezone('utc', now()),
    unique (user_id, path_type)
);
