-- Migration 015: Security & schema fixes from audit
-- Addresses: CRITICAL-2, HIGH-1, HIGH-2, MEDIUM-1, MEDIUM-2, MEDIUM-3, MEDIUM-4
-- Also: Migration audit findings 1, 3, 5

-- =============================================================================
-- CRITICAL-2: Lock down subscriptions table (prevent client-side subscription fraud)
-- =============================================================================
DO $$
BEGIN
    -- Drop the overly permissive FOR ALL policy
    IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='subscriptions' AND policyname='subscriptions_own_rows') THEN
        DROP POLICY subscriptions_own_rows ON public.subscriptions;
    END IF;

    -- Users can only READ their own subscriptions
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='subscriptions' AND policyname='subscriptions_read_own') THEN
        CREATE POLICY subscriptions_read_own ON public.subscriptions
            FOR SELECT TO authenticated
            USING (user_id = auth.uid());
    END IF;

    -- Only service_role (server-side webhook) can insert/update
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='subscriptions' AND policyname='subscriptions_server_write') THEN
        CREATE POLICY subscriptions_server_write ON public.subscriptions
            FOR ALL TO service_role
            USING (true) WITH CHECK (true);
    END IF;
END $$;

-- =============================================================================
-- HIGH-1: Storage bucket RLS for reading-proof
-- =============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('reading-proof', 'reading-proof', false)
ON CONFLICT DO NOTHING;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='objects' AND policyname='reading_proof_upload') THEN
        CREATE POLICY reading_proof_upload ON storage.objects
            FOR INSERT TO authenticated
            WITH CHECK (
                bucket_id = 'reading-proof'
                AND (storage.foldername(name))[1] = auth.uid()::text
            );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='objects' AND policyname='reading_proof_read') THEN
        CREATE POLICY reading_proof_read ON storage.objects
            FOR SELECT TO authenticated
            USING (
                bucket_id = 'reading-proof'
                AND (storage.foldername(name))[1] = auth.uid()::text
            );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='objects' AND policyname='reading_proof_delete') THEN
        CREATE POLICY reading_proof_delete ON storage.objects
            FOR DELETE TO authenticated
            USING (
                bucket_id = 'reading-proof'
                AND (storage.foldername(name))[1] = auth.uid()::text
            );
    END IF;
END $$;

-- =============================================================================
-- HIGH-2: Atomic guild XP increment (prevents race condition / XP inflation)
-- =============================================================================
CREATE OR REPLACE FUNCTION public.increment_guild_xp(guild_uuid UUID, amount INT)
RETURNS void AS $$
BEGIN
    UPDATE public.guilds SET total_xp = total_xp + amount WHERE id = guild_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- MEDIUM-1: Guilds table scoped UPDATE policy
-- =============================================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='guilds' AND policyname='guilds_update_own') THEN
        CREATE POLICY guilds_update_own ON public.guilds
            FOR UPDATE TO authenticated
            USING (created_by = auth.uid())
            WITH CHECK (created_by = auth.uid());
    END IF;
END $$;

-- =============================================================================
-- MEDIUM-3: Atomic forgiveness token decrement (prevents TOCTOU race)
-- =============================================================================
CREATE OR REPLACE FUNCTION public.use_forgiveness_token(uid UUID)
RETURNS integer AS $$
DECLARE new_count integer;
BEGIN
    UPDATE public.users
    SET forgiveness_tokens = forgiveness_tokens - 1
    WHERE id = uid AND forgiveness_tokens > 0
    RETURNING forgiveness_tokens INTO new_count;

    IF NOT FOUND THEN RETURN -1; END IF;
    RETURN new_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- MEDIUM-4: Add display_name column to users for leaderboard privacy
-- =============================================================================
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS display_name text;

-- =============================================================================
-- Migration Audit #1 (CRITICAL): Create skill_nodes and user_skills tables
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.skill_nodes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    stat_type text NOT NULL CHECK (stat_type IN ('strength','discipline','focus','energy','wisdom','mind','spirit')),
    tier integer NOT NULL CHECK (tier >= 1 AND tier <= 3),
    required_stat integer,
    required_node uuid REFERENCES public.skill_nodes (id) ON DELETE SET NULL,
    perk_type text NOT NULL,
    perk_value integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE TABLE IF NOT EXISTS public.user_skills (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.users (id) ON DELETE CASCADE,
    skill_node_id uuid NOT NULL REFERENCES public.skill_nodes (id) ON DELETE CASCADE,
    unlocked_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
    UNIQUE (user_id, skill_node_id)
);

CREATE INDEX IF NOT EXISTS user_skills_user_idx ON public.user_skills (user_id);

ALTER TABLE public.skill_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_skills ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='skill_nodes' AND policyname='skill_nodes_read') THEN
        CREATE POLICY skill_nodes_read ON public.skill_nodes FOR SELECT TO authenticated USING (true);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='user_skills' AND policyname='user_skills_own_rows') THEN
        CREATE POLICY user_skills_own_rows ON public.user_skills FOR ALL TO authenticated
            USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
    END IF;
END $$;

-- =============================================================================
-- Migration Audit #3 (HIGH): Allow NULL email (Apple Sign In may not provide)
-- =============================================================================
ALTER TABLE public.users ALTER COLUMN email DROP NOT NULL;

-- =============================================================================
-- Migration Audit #5 (MEDIUM): Index on mastery_paths(user_id)
-- =============================================================================
CREATE INDEX IF NOT EXISTS mastery_paths_user_idx ON public.mastery_paths (user_id);

-- =============================================================================
-- MEDIUM-2: Daily XP cap constraint (prevent XP farming via unlimited habits)
-- =============================================================================
ALTER TABLE public.daily_logs ADD CONSTRAINT daily_xp_cap
    CHECK (xp_earned <= 500) NOT VALID;
