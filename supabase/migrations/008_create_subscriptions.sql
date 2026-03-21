create table if not exists public.subscriptions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    plan_type text not null check (plan_type in ('full_access', 'maintenance')),
    status text not null check (status in ('active', 'expired')),
    renewal_date timestamptz,
    created_at timestamptz not null default timezone('utc', now())
);

create index if not exists subscriptions_user_created_idx
    on public.subscriptions (user_id, created_at desc);

create unique index if not exists subscriptions_one_active_per_user_idx
    on public.subscriptions (user_id)
    where status = 'active';
