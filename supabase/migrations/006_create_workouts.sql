create table if not exists public.workouts (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    date date not null,
    workout_type text not null,
    target_duration_seconds integer not null check (target_duration_seconds > 0),
    completed_duration_seconds integer not null default 0 check (completed_duration_seconds >= 0),
    completed boolean not null default false,
    xp_awarded integer not null default 0 check (xp_awarded >= 0),
    created_at timestamptz not null default timezone('utc', now()),
    check (completed_duration_seconds <= target_duration_seconds)
);

create index if not exists workouts_user_date_idx
    on public.workouts (user_id, date desc);

create index if not exists workouts_completed_idx
    on public.workouts (user_id, completed, date desc);
