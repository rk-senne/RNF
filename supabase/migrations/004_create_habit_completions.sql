create table if not exists public.habit_completions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    habit_id uuid not null references public.habits (id) on delete cascade,
    date date not null,
    completed_at timestamptz not null default timezone('utc', now()),
    xp_awarded integer not null default 0 check (xp_awarded >= 0),
    created_at timestamptz not null default timezone('utc', now()),
    unique (user_id, habit_id, date)
);

create index if not exists habit_completions_user_date_idx
    on public.habit_completions (user_id, date desc);

create index if not exists habit_completions_habit_idx
    on public.habit_completions (habit_id, date desc);
