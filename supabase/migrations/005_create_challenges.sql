create table if not exists public.challenges (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    start_date date not null,
    end_date date not null,
    current_day integer not null default 1 check (current_day >= 1 and current_day <= 90),
    status text not null default 'active' check (status in ('active', 'completed', 'reset')),
    created_at timestamptz not null default timezone('utc', now()),
    check (end_date >= start_date)
);

create index if not exists challenges_user_created_idx
    on public.challenges (user_id, created_at desc);

create unique index if not exists challenges_one_active_per_user_idx
    on public.challenges (user_id)
    where status = 'active';
