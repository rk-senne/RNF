# RNF Migration Runbook

This runbook defines the manual commands used to verify and roll back RNF Supabase migrations before production promotion.

## Scope

Use this document for migrations in `supabase/migrations/`.

Migration rules:

- Do not edit migrations that have already been applied to a shared or production database.
- Add a new migration for constraints, indexes, RLS policies, schema changes, or policy changes.
- Verify generated SQL locally before applying it to a linked project.
- Treat rollback SQL as production code and review it before execution.

## Local Verification

Run from the repository root.

List migrations:

```sh
ls -1 supabase/migrations
```

Validate SQL files are present and ordered:

```sh
find supabase/migrations -maxdepth 1 -type f -name '*.sql' | sort
```

Start or reset a local Supabase database before validating migrations:

```sh
supabase start
supabase db reset
```

Check migration status against the active project:

```sh
supabase migration list
```

## SQL Structure Verification Notes

Use these checks when reviewing migration SQL without a live database, and repeat the catalog queries below after `supabase db reset`.

Required migration structure:

- migration filenames use the ordered `000_descriptive_name.sql` format
- daily idempotency is protected by `daily_logs(user_id, date)`, `habit_completions(user_id, habit_id, date)`, `workouts(user_id, date)`, and `reading_uploads(user_id, date)` uniqueness
- skill tree unlock idempotency is protected by `user_skills(user_id, skill_node_id)` uniqueness
- active challenges and subscriptions are protected by partial unique indexes on `user_id` where `status = 'active'`
- common reads have indexes for `daily_logs(user_id, date)`, `habit_completions(user_id, date)`, `challenges(user_id, status)`, `workouts(user_id, date)`, `reading_uploads(user_id, date)`, `subscriptions(user_id, status)`, `skill_nodes(stat_type, tier)`, and `user_skills(user_id, unlocked_at)`
- every user-owned table has row level security enabled
- ownership policies use `auth.uid()` against `users.id` or the table `user_id`
- `skill_nodes` has an authenticated read policy because it is global catalog data
- `reading-proof` storage objects are scoped to the authenticated user's first object path segment
- migrations do not include demo users, plaintext secrets, auth tokens, or environment-specific credentials

Current migration files satisfying these checks:

- `003_create_daily_logs.sql`: `unique (user_id, date)`, daily log status checks, and `daily_logs_user_date_idx`
- `004_create_habit_completions.sql`: `unique (user_id, habit_id, date)` and date lookup indexes
- `005_create_challenges.sql`: challenge day/status checks and active-challenge uniqueness
- `007_create_reading_uploads.sql`: `unique (user_id, date)` and date lookup index
- `009_add_production_indexes.sql`: production indexes for workout uniqueness, challenge status lookup, and subscription status lookup
- `010_enable_rls_policies.sql`: RLS enablement and authenticated ownership policies
- `011_create_skill_tree_tables.sql`: `skill_nodes`, `user_skills`, skill tree constraints, unlock uniqueness, indexes, and RLS enablement
- `012_add_skill_tree_rls_policies.sql`: authenticated skill node reads and user-owned skill unlock policies
- `013_add_reading_proof_storage.sql`: private `reading-proof` bucket and owner-folder storage object policies

For RLS migrations, verify policies exist after applying migrations:

```sql
select
    schemaname,
    tablename,
    policyname,
    cmd,
    roles,
    qual,
    with_check
from pg_policies
where schemaname in ('public', 'storage')
order by schemaname, tablename, policyname;
```

For index and uniqueness migrations, verify indexes exist after applying migrations:

```sql
select
    schemaname,
    tablename,
    indexname,
    indexdef
from pg_indexes
where schemaname = 'public'
order by tablename, indexname;
```

For storage bucket migrations, verify the bucket and object policies exist after applying migrations:

```sql
select
    id,
    name,
    public
from storage.buckets
where id = 'reading-proof';

select
    policyname,
    cmd,
    roles,
    qual,
    with_check
from pg_policies
where schemaname = 'storage'
  and tablename = 'objects'
  and policyname like 'reading_proof_%'
order by policyname;
```

Before applying to a linked remote project, inspect the pending migration diff:

```sh
supabase db diff
supabase migration list
```

Apply reviewed migrations to the linked project:

```sh
supabase db push
```

## Rollback Pattern

Supabase migrations are forward-first. Prefer a new corrective migration over editing or deleting an applied migration.

For local validation, reset the local database and rerun the full migration chain:

```sh
supabase db reset
```

For a shared or production database, create a new rollback migration:

```sh
supabase migration new rollback_<short_reason>
```

Rollback migration examples:

```sql
drop policy if exists subscriptions_own_rows on public.subscriptions;
drop index if exists public.subscriptions_user_status_idx;
alter table public.subscriptions disable row level security;
```

Only disable RLS when the table is being removed from production access or an immediate replacement policy is included in the same reviewed rollback migration.

## Production Checklist

Before production promotion:

- Confirm every user-owned table has RLS enabled.
- Confirm ownership policies use `auth.uid()` against `users.id` or the table `user_id`.
- Confirm unique daily-write indexes exist before idempotent app writes depend on them.
- Confirm `skill_nodes` and `user_skills` exist before enabling skill tree features against a fresh Supabase environment.
- Confirm the private `reading-proof` bucket and owner-folder object policies exist before enabling reading proof uploads.
- Confirm no migration contains demo-only users, plaintext secrets, or environment-specific credentials.
- Confirm rollback SQL is reviewed and tested locally.
- Run the iOS build after migration documentation or migration files change.
- Confirm repository hygiene cleanup is complete before tightening CI gates, especially removal of tracked `RNF.xcodeproj/xcuserdata/`.
