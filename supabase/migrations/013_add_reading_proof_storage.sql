insert into storage.buckets (id, name, public)
values ('reading-proof', 'reading-proof', false)
on conflict (id) do update
set
    name = excluded.name,
    public = false;

alter table storage.objects enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies
        where schemaname = 'storage'
          and tablename = 'objects'
          and policyname = 'reading_proof_own_objects_select'
    ) then
        create policy reading_proof_own_objects_select
            on storage.objects
            for select
            to authenticated
            using (
                bucket_id = 'reading-proof'
                and (storage.foldername(name))[1] = (select auth.uid()::text)
            );
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'storage'
          and tablename = 'objects'
          and policyname = 'reading_proof_own_objects_insert'
    ) then
        create policy reading_proof_own_objects_insert
            on storage.objects
            for insert
            to authenticated
            with check (
                bucket_id = 'reading-proof'
                and (storage.foldername(name))[1] = (select auth.uid()::text)
            );
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'storage'
          and tablename = 'objects'
          and policyname = 'reading_proof_own_objects_update'
    ) then
        create policy reading_proof_own_objects_update
            on storage.objects
            for update
            to authenticated
            using (
                bucket_id = 'reading-proof'
                and (storage.foldername(name))[1] = (select auth.uid()::text)
            )
            with check (
                bucket_id = 'reading-proof'
                and (storage.foldername(name))[1] = (select auth.uid()::text)
            );
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'storage'
          and tablename = 'objects'
          and policyname = 'reading_proof_own_objects_delete'
    ) then
        create policy reading_proof_own_objects_delete
            on storage.objects
            for delete
            to authenticated
            using (
                bucket_id = 'reading-proof'
                and (storage.foldername(name))[1] = (select auth.uid()::text)
            );
    end if;
end $$;
