create table if not exists public.daily_logs (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    date date not null,
    habits_completed integer not null default 0 check (habits_completed >= 0),
    habits_required integer not null default 0 check (habits_required >= 0),
    workout_completed boolean not null default false,
    reading_completed boolean not null default false,
    forgiveness_used boolean not null default false,
    xp_earned integer not null default 0 check (xp_earned >= 0),
    status text not null default 'partial' check (status in ('complete', 'partial', 'missed', 'forgiven')),
    habit_complete boolean generated always as (
        habits_required > 0 and habits_completed >= habits_required
    ) stored,
    workout_complete boolean generated always as (workout_completed) stored,
    reading_complete boolean generated always as (reading_completed) stored,
    created_at timestamptz not null default timezone('utc', now()),
    unique (user_id, date)
);

create index if not exists daily_logs_user_date_idx
    on public.daily_logs (user_id, date desc);

create index if not exists daily_logs_status_idx
    on public.daily_logs (user_id, status, date desc);
