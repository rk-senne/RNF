create table if not exists public.reading_uploads (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    image_url text not null,
    date date not null,
    created_at timestamptz not null default timezone('utc', now()),
    unique (user_id, date)
);

create index if not exists reading_uploads_user_date_idx
    on public.reading_uploads (user_id, date desc);
