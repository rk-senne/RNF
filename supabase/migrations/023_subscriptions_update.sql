-- P23-MON-03/05: Update subscriptions table for StoreKit 2 + Apple Server Notifications V2
-- Adds columns needed for server-side subscription management and webhook processing.

-- Step 1: Add new columns for full StoreKit 2 subscription lifecycle tracking

ALTER TABLE public.subscriptions
    ADD COLUMN IF NOT EXISTS product_id text,
    ADD COLUMN IF NOT EXISTS original_transaction_id text,
    ADD COLUMN IF NOT EXISTS purchase_date timestamptz,
    ADD COLUMN IF NOT EXISTS expiry_date timestamptz,
    ADD COLUMN IF NOT EXISTS environment text CHECK (environment IN ('sandbox', 'production')),
    ADD COLUMN IF NOT EXISTS auto_renew_enabled boolean DEFAULT true,
    ADD COLUMN IF NOT EXISTS auto_renew_product_id text,
    ADD COLUMN IF NOT EXISTS revocation_date timestamptz,
    ADD COLUMN IF NOT EXISTS revocation_reason text,
    ADD COLUMN IF NOT EXISTS grace_period_expires_date timestamptz,
    ADD COLUMN IF NOT EXISTS billing_retry_period boolean DEFAULT false,
    ADD COLUMN IF NOT EXISTS price_increase_consent text CHECK (price_increase_consent IN ('consented', 'declined', 'pending')),
    ADD COLUMN IF NOT EXISTS offer_type text CHECK (offer_type IN ('introductory', 'promotional', 'offer_code', 'win_back')),
    ADD COLUMN IF NOT EXISTS offer_identifier text,
    ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT timezone('utc', now());

-- Step 2: Update status check constraint to include new lifecycle states

ALTER TABLE public.subscriptions
    DROP CONSTRAINT IF EXISTS subscriptions_status_check;

ALTER TABLE public.subscriptions
    ADD CONSTRAINT subscriptions_status_check
    CHECK (status IN ('active', 'expired', 'grace_period', 'billing_retry', 'cancelled', 'refunded', 'revoked'));

-- Step 3: Create unique index on original_transaction_id for webhook upserts

CREATE UNIQUE INDEX IF NOT EXISTS subscriptions_original_txn_idx
    ON public.subscriptions (original_transaction_id)
    WHERE original_transaction_id IS NOT NULL;

-- Step 4: Index for fast entitlement lookups (active, grace period, billing retry)

DROP INDEX IF EXISTS subscriptions_one_active_per_user_idx;

CREATE INDEX IF NOT EXISTS subscriptions_user_entitlement_idx
    ON public.subscriptions (user_id)
    WHERE status IN ('active', 'grace_period', 'billing_retry');

-- Step 5: Index for Apple Server Notifications webhook processing

CREATE INDEX IF NOT EXISTS subscriptions_product_id_idx
    ON public.subscriptions (product_id)
    WHERE status = 'active';

-- Step 6: Create webhook event log table for Apple Server Notifications V2

CREATE TABLE IF NOT EXISTS public.subscription_webhook_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_type text NOT NULL,
    subtype text,
    notification_uuid text UNIQUE NOT NULL,
    signed_payload text NOT NULL,
    original_transaction_id text,
    product_id text,
    environment text CHECK (environment IN ('sandbox', 'production')),
    processed boolean DEFAULT false,
    processing_error text,
    received_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
    processed_at timestamptz
);

-- Index for finding unprocessed events
CREATE INDEX IF NOT EXISTS webhook_events_unprocessed_idx
    ON public.subscription_webhook_events (processed, received_at)
    WHERE processed = false;

-- Index for lookup by transaction
CREATE INDEX IF NOT EXISTS webhook_events_txn_idx
    ON public.subscription_webhook_events (original_transaction_id);

-- Step 7: RLS policies for webhook events table

ALTER TABLE public.subscription_webhook_events ENABLE ROW LEVEL SECURITY;

-- Only service role can insert/update webhook events (not end users)
CREATE POLICY "Service role manages webhook events"
    ON public.subscription_webhook_events
    FOR ALL
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

-- Step 8: Update RLS on subscriptions to allow service role full access

CREATE POLICY "Service role manages subscriptions"
    ON public.subscriptions
    FOR ALL
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

-- Step 9: Function to update updated_at timestamp automatically

CREATE OR REPLACE FUNCTION public.update_subscriptions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc', now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER subscriptions_updated_at_trigger
    BEFORE UPDATE ON public.subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION public.update_subscriptions_updated_at();

-- Step 10: Create trial tracking table

CREATE TABLE IF NOT EXISTS public.user_trials (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.users (id) ON DELETE CASCADE,
    trial_start_date timestamptz NOT NULL DEFAULT timezone('utc', now()),
    trial_end_date timestamptz NOT NULL,
    converted boolean DEFAULT false,
    converted_at timestamptz,
    converted_product_id text,
    created_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE UNIQUE INDEX IF NOT EXISTS user_trials_user_idx
    ON public.user_trials (user_id);

ALTER TABLE public.user_trials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own trial"
    ON public.user_trials
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Service role manages trials"
    ON public.user_trials
    FOR ALL
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');
