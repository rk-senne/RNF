-- Fix: analytics_events missing INSERT policy
CREATE POLICY analytics_events_insert_own ON public.analytics_events
    FOR INSERT TO authenticated
    WITH CHECK (true);

CREATE POLICY analytics_events_no_read ON public.analytics_events
    FOR SELECT TO authenticated
    USING (false);
