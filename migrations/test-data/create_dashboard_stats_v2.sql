-- Create a NEW function version to bypass any stale cache issues
-- get_dashboard_stats_v2

CREATE OR REPLACE FUNCTION public.get_dashboard_stats_v2()
RETURNS TABLE (
    total_users BIGINT,
    active_users BIGINT,
    premium_users BIGINT,
    total_revenue NUMERIC
) LANGUAGE sql SECURITY DEFINER AS $$
    SELECT
        (SELECT COUNT(*) FROM public.users),
        (SELECT COUNT(*) FROM public.users WHERE last_login_at > NOW() - INTERVAL '30 days'),
        -- Ensure role check is safe
        (SELECT COUNT(*) FROM public.users WHERE role = 'premium'),
        -- Ensure transactions sum is safe
        COALESCE((SELECT SUM(amount) FROM user_transactions WHERE type = 'income'), 0)
$$;
