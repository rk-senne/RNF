create table if not exists public.health_imports (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    healthkit_uuid text not null,
    workout_type text not null,
    start_date timestamptz not null,
    end_date timestamptz not null,
    duration_seconds integer not null check (duration_seconds >= 0),
    active_energy double precision,
    accepted boolean not null default false,
    created_at timestamptz not null default timezone('utc', now()),
    unique (user_id, healthkit_uuid)
);

create index if not exists health_imports_user_idx on public.health_imports (user_id, created_at desc);

alter table public.health_imports enable row level security;

create policy health_imports_own_rows on public.health_imports for all to authenticated
    using (user_id = auth.uid()) with check (user_id = auth.uid());
