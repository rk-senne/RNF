create unique index if not exists workouts_user_date_unique_idx
    on public.workouts (user_id, date);

create index if not exists challenges_user_status_idx
    on public.challenges (user_id, status);

create index if not exists subscriptions_user_status_idx
    on public.subscriptions (user_id, status);

