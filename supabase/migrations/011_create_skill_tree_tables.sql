create table if not exists public.skill_nodes (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    stat_type text not null check (
        stat_type in (
            'strength',
            'discipline',
            'focus',
            'energy',
            'wisdom',
            'mind',
            'spirit'
        )
    ),
    tier integer not null check (tier >= 1 and tier <= 3),
    required_stat integer check (required_stat is null or required_stat >= 0),
    required_node uuid references public.skill_nodes (id) on delete restrict,
    perk_type text not null check (
        perk_type in (
            'xp_multiplier',
            'stat_bonus',
            'quest_reward_bonus',
            'streak_protection',
            'xp_bonus',
            'xp',
            'stat_multiplier',
            'quest_bonus',
            'daily_quest_bonus',
            'extra_daily_quest',
            'forgiveness',
            'streak_protect'
        )
    ),
    perk_value integer not null default 0 check (perk_value >= 0),
    created_at timestamptz not null default timezone('utc', now()),
    unique (stat_type, tier, name)
);

create index if not exists skill_nodes_stat_tier_idx
    on public.skill_nodes (stat_type, tier);

create index if not exists skill_nodes_required_node_idx
    on public.skill_nodes (required_node)
    where required_node is not null;

create table if not exists public.user_skills (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    skill_node_id uuid not null references public.skill_nodes (id) on delete cascade,
    unlocked_at timestamptz not null default timezone('utc', now()),
    unique (user_id, skill_node_id)
);

create index if not exists user_skills_user_unlocked_idx
    on public.user_skills (user_id, unlocked_at desc);

create index if not exists user_skills_node_idx
    on public.user_skills (skill_node_id);

alter table public.skill_nodes enable row level security;
alter table public.user_skills enable row level security;
