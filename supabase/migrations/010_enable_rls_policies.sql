alter table public.users enable row level security;
alter table public.habits enable row level security;
alter table public.daily_logs enable row level security;
alter table public.habit_completions enable row level security;
alter table public.challenges enable row level security;
alter table public.workouts enable row level security;
alter table public.reading_uploads enable row level security;
alter table public.subscriptions enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'users'
          and policyname = 'users_own_rows'
    ) then
        create policy users_own_rows
            on public.users
            for all
            to authenticated
            using (id = auth.uid())
            with check (id = auth.uid());
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'habits'
          and policyname = 'habits_authenticated_read'
    ) then
        create policy habits_authenticated_read
            on public.habits
            for select
            to authenticated
            using (true);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'daily_logs'
          and policyname = 'daily_logs_own_rows'
    ) then
        create policy daily_logs_own_rows
            on public.daily_logs
            for all
            to authenticated
            using (user_id = auth.uid())
            with check (user_id = auth.uid());
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'habit_completions'
          and policyname = 'habit_completions_own_rows'
    ) then
        create policy habit_completions_own_rows
            on public.habit_completions
            for all
            to authenticated
            using (user_id = auth.uid())
            with check (user_id = auth.uid());
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'challenges'
          and policyname = 'challenges_own_rows'
    ) then
        create policy challenges_own_rows
            on public.challenges
            for all
            to authenticated
            using (user_id = auth.uid())
            with check (user_id = auth.uid());
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'workouts'
          and policyname = 'workouts_own_rows'
    ) then
        create policy workouts_own_rows
            on public.workouts
            for all
            to authenticated
            using (user_id = auth.uid())
            with check (user_id = auth.uid());
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'reading_uploads'
          and policyname = 'reading_uploads_own_rows'
    ) then
        create policy reading_uploads_own_rows
            on public.reading_uploads
            for all
            to authenticated
            using (user_id = auth.uid())
            with check (user_id = auth.uid());
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'subscriptions'
          and policyname = 'subscriptions_own_rows'
    ) then
        create policy subscriptions_own_rows
            on public.subscriptions
            for all
            to authenticated
            using (user_id = auth.uid())
            with check (user_id = auth.uid());
    end if;
end $$;

