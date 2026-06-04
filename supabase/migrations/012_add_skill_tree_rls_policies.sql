alter table public.skill_nodes enable row level security;
alter table public.user_skills enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'skill_nodes'
          and policyname = 'skill_nodes_authenticated_read'
    ) then
        create policy skill_nodes_authenticated_read
            on public.skill_nodes
            for select
            to authenticated
            using (true);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'user_skills'
          and policyname = 'user_skills_own_rows'
    ) then
        create policy user_skills_own_rows
            on public.user_skills
            for all
            to authenticated
            using (user_id = auth.uid())
            with check (user_id = auth.uid());
    end if;
end $$;
