create table if not exists public.habits (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    description text,
    xp_reward integer not null default 10 check (xp_reward >= 0),
    is_core boolean not null default true,
    created_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists habits_name_unique_idx
    on public.habits (lower(name));

create index if not exists habits_core_idx
    on public.habits (is_core, created_at desc);
