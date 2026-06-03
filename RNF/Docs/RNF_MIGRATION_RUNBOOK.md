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
where schemaname = 'public'
order by tablename, policyname;
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
- Confirm no migration contains demo-only users, plaintext secrets, or environment-specific credentials.
- Confirm rollback SQL is reviewed and tested locally.
- Run the iOS build after migration documentation or migration files change.
- Confirm repository hygiene cleanup is complete before tightening CI gates, especially removal of tracked `RNF.xcodeproj/xcuserdata/`.
