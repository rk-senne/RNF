create table if not exists public.guilds (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    description text,
    member_count integer not null default 1 check (member_count >= 0),
    total_xp integer not null default 0 check (total_xp >= 0),
    created_by uuid not null references public.users (id) on delete cascade,
    created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.guild_members (
    id uuid primary key default gen_random_uuid(),
    guild_id uuid not null references public.guilds (id) on delete cascade,
    user_id uuid not null references public.users (id) on delete cascade,
    role text not null default 'member' check (role in ('leader', 'member')),
    joined_at timestamptz not null default timezone('utc', now()),
    unique (guild_id, user_id)
);

create index if not exists guild_members_user_idx on public.guild_members (user_id);
create index if not exists guild_members_guild_idx on public.guild_members (guild_id);

create table if not exists public.social_challenges (
    id uuid primary key default gen_random_uuid(),
    guild_id uuid not null references public.guilds (id) on delete cascade,
    title text not null,
    description text,
    target_completions integer not null check (target_completions > 0),
    current_completions integer not null default 0 check (current_completions >= 0),
    status text not null default 'active' check (status in ('active', 'completed', 'expired')),
    start_date date not null,
    end_date date not null,
    created_at timestamptz not null default timezone('utc', now()),
    check (end_date >= start_date)
);

create index if not exists social_challenges_guild_idx on public.social_challenges (guild_id, status);
