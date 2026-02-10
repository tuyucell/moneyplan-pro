-- Comprehensive Fix for Premium Counting and User Growth
-- Now includes 'is_premium' column check.

-- 1. Dashboard Stats V2
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
        -- Total
        (SELECT COUNT(*) FROM public.users)::NUMERIC,
        
        -- Active (Last login, update or recent creation)
        (SELECT COUNT(*) FROM public.users 
         WHERE last_login_at > NOW() - INTERVAL '30 days'
         OR updated_at > NOW() - INTERVAL '30 days'
         OR created_at > NOW() - INTERVAL '30 days'
        )::NUMERIC,
        
        -- Premium (Check role AND is_premium column)
        (SELECT COUNT(*) FROM public.users 
         WHERE role IN ('premium', 'pro', 'admin') 
         OR is_premium IS TRUE
        )::NUMERIC,
         
        -- Revenue
        COALESCE((SELECT SUM(amount) FROM user_transactions WHERE type = 'income'), 0)::NUMERIC;
END;
$$;


-- 2. User Growth V2 (Graph)
DROP FUNCTION IF EXISTS public.get_user_growth_v2(text);

CREATE OR REPLACE FUNCTION public.get_user_growth_v2(period text DEFAULT '7d')
RETURNS TABLE (
    activity_date TEXT,
    total_users NUMERIC,
    active_users NUMERIC,
    premium_users NUMERIC
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    start_date TIMESTAMPTZ;
BEGIN
    -- Period Logic
    IF period = '24h' THEN start_date := NOW() - INTERVAL '24 hours';
    ELSIF period = '7d' THEN start_date := NOW() - INTERVAL '7 days';
    ELSIF period = '30d' THEN start_date := NOW() - INTERVAL '30 days';
    ELSIF period = '90d' THEN start_date := NOW() - INTERVAL '90 days';
    ELSE start_date := NOW() - INTERVAL '7 days';
    END IF;

    RETURN QUERY
    SELECT
        to_char(date_trunc('day', created_at), 'YYYY-MM-DD') AS activity_date,
        COUNT(*)::NUMERIC AS total_users,
        
        -- Active Users count for this day
        COUNT(*) FILTER (
           WHERE last_login_at >= start_date 
           OR updated_at >= start_date
        )::NUMERIC AS active_users,
        
        -- Premium Users count for this day
        COUNT(*) FILTER (
           WHERE role IN ('premium', 'pro', 'admin') 
           OR is_premium IS TRUE
        )::NUMERIC AS premium_users

    FROM public.users
    WHERE created_at >= start_date
    GROUP BY 1
    ORDER BY 1 ASC;
END;
$$;
