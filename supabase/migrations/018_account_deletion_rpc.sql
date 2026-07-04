-- P21-FIX-07: Account deletion RPC function with cascade logic
-- Deletes all user data across all tables in the correct order.

CREATE OR REPLACE FUNCTION delete_user_account(target_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Verify the caller is the user being deleted (or an admin)
    IF auth.uid() != target_user_id THEN
        RAISE EXCEPTION 'Unauthorized: can only delete own account';
    END IF;

    -- Delete in dependency order (child tables first)
    DELETE FROM habit_completions WHERE user_id = target_user_id;
    DELETE FROM daily_logs WHERE user_id = target_user_id;
    DELETE FROM challenges WHERE user_id = target_user_id;
    DELETE FROM workouts WHERE user_id = target_user_id;
    DELETE FROM reading_uploads WHERE user_id = target_user_id;
    DELETE FROM user_achievements WHERE user_id = target_user_id;
    DELETE FROM bosses WHERE user_id = target_user_id;
    DELETE FROM guild_members WHERE user_id = target_user_id;
    DELETE FROM social_challenges WHERE challenger_id = target_user_id OR challengee_id = target_user_id;
    DELETE FROM subscriptions WHERE user_id = target_user_id;
    DELETE FROM health_imports WHERE user_id = target_user_id;
    DELETE FROM analytics_events WHERE user_id = target_user_id;
    DELETE FROM habits WHERE user_id = target_user_id;

    -- Delete storage objects (reading proofs)
    DELETE FROM storage.objects WHERE bucket_id = 'reading-proofs' AND (storage.foldername(name))[1] = target_user_id::text;

    -- Finally delete the user profile
    DELETE FROM users WHERE id = target_user_id;

    -- Delete from auth.users (triggers Supabase auth cleanup)
    DELETE FROM auth.users WHERE id = target_user_id;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION delete_user_account(UUID) TO authenticated;
