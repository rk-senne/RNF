create table if not exists public.users (
    id uuid primary key references auth.users (id) on delete cascade,
    email text not null unique,
    xp_total integer not null default 0 check (xp_total >= 0),
    level integer not null default 1 check (level >= 1),
    current_streak integer not null default 0 check (current_streak >= 0),
    strength integer not null default 0 check (strength >= 0),
    discipline integer not null default 0 check (discipline >= 0),
    focus integer not null default 0 check (focus >= 0),
    energy integer not null default 0 check (energy >= 0),
    wisdom integer not null default 0 check (wisdom >= 0),
    mind integer not null default 0 check (mind >= 0),
    spirit integer not null default 0 check (spirit >= 0),
    forgiveness_tokens integer not null default 0 check (forgiveness_tokens >= 0),
    morning_notification_time time,
    evening_notification_time time,
    created_at timestamptz not null default timezone('utc', now())
);

create index if not exists users_level_idx
    on public.users (level);

create index if not exists users_created_at_idx
    on public.users (created_at desc);
