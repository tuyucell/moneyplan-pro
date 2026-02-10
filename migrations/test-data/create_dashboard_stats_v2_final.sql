-- Final Fix for Dashboard Stats
-- 1. Updates logic to catch 'Active Users' using updated_at/created_at if last_login_at is null.
-- 2. Checks for 'premium' role.

DROP FUNCTION IF EXISTS public.get_dashboard_stats_v2();

CREATE OR REPLACE FUNCTION public.get_dashboard_stats_v2()
RETURNS TABLE (
    total_users NUMERIC,
    active_users NUMERIC,
    premium_users NUMERIC,
    total_revenue NUMERIC
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT
        -- 1. Total Users
        (SELECT COUNT(*) FROM public.users)::NUMERIC,
        
        -- 2. Active Users (Broader logic: Login OR Last Update OR Created recently)
        (SELECT COUNT(*) FROM public.users 
         WHERE last_login_at > NOW() - INTERVAL '30 days'
         OR updated_at > NOW() - INTERVAL '30 days'
         OR created_at > NOW() - INTERVAL '30 days'
        )::NUMERIC,
        
        -- 3. Premium Users
        -- Checks for role='premium' OR role='pro' OR role='admin' (Admins are usually premium-like)
        -- Adjust this WHERE clause based on how you actually set premium users.
        (SELECT COUNT(*) FROM public.users WHERE role IN ('premium', 'pro', 'admin'))::NUMERIC,
        
        -- 4. Revenue
        COALESCE((SELECT SUM(amount) FROM user_transactions WHERE type = 'income'), 0)::NUMERIC;
END;
$$;
