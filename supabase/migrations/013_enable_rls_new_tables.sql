alter table public.bosses enable row level security;
alter table public.user_achievements enable row level security;
alter table public.mastery_paths enable row level security;
alter table public.guilds enable row level security;
alter table public.guild_members enable row level security;
alter table public.social_challenges enable row level security;

do $$
begin
    create policy bosses_own_rows on public.bosses for all to authenticated
        using (user_id = auth.uid()) with check (user_id = auth.uid());

    create policy user_achievements_own_rows on public.user_achievements for all to authenticated
        using (user_id = auth.uid()) with check (user_id = auth.uid());

    create policy mastery_paths_own_rows on public.mastery_paths for all to authenticated
        using (user_id = auth.uid()) with check (user_id = auth.uid());

    create policy guilds_read_all on public.guilds for select to authenticated using (true);
    create policy guilds_create_own on public.guilds for insert to authenticated
        with check (created_by = auth.uid());

    create policy guild_members_read_guild on public.guild_members for select to authenticated using (true);
    create policy guild_members_own on public.guild_members for insert to authenticated
        with check (user_id = auth.uid());
    create policy guild_members_delete_own on public.guild_members for delete to authenticated
        using (user_id = auth.uid());

    create policy social_challenges_guild_read on public.social_challenges for select to authenticated using (true);
    create policy social_challenges_guild_create on public.social_challenges for insert to authenticated
        with check (guild_id in (select guild_id from public.guild_members where user_id = auth.uid() and role = 'leader'));
end $$;
