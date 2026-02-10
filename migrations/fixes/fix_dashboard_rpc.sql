-- FIX: Switch all return types to NUMERIC to avoid mismatches
-- BIGINT vs NUMERIC casting issues are common in Supabase RPCs

-- 1. Dashboard Stats (The one failing at column 3)
DROP FUNCTION IF EXISTS public.get_dashboard_stats();

CREATE OR REPLACE FUNCTION public.get_dashboard_stats()
RETURNS TABLE (
    total_users NUMERIC,
    active_users NUMERIC,
    premium_users NUMERIC,
    total_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*) FROM public.users)::NUMERIC,
        (SELECT COUNT(*) FROM public.users WHERE last_login_at > NOW() - INTERVAL '30 days')::NUMERIC,
        (SELECT COUNT(*) FROM public.users WHERE role = 'premium')::NUMERIC,
        COALESCE((SELECT SUM(amount) FROM user_transactions WHERE type = 'income'), 0)::NUMERIC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 2. User Growth (Update to numeric as well for consistency)
DROP FUNCTION IF EXISTS public.get_user_growth(text);

CREATE OR REPLACE FUNCTION public.get_user_growth(period text DEFAULT '7d')
RETURNS TABLE (
    date TEXT,
    count NUMERIC -- Changed to NUMERIC
) AS $$
DECLARE
    start_date TIMESTAMPTZ;
BEGIN
    IF period = '24h' THEN start_date := NOW() - INTERVAL '24 hours';
    ELSIF period = '7d' THEN start_date := NOW() - INTERVAL '7 days';
    ELSIF period = '30d' THEN start_date := NOW() - INTERVAL '30 days';
    ELSIF period = '90d' THEN start_date := NOW() - INTERVAL '90 days';
    ELSE start_date := NOW() - INTERVAL '7 days';
    END IF;

    RETURN QUERY
    SELECT
        to_char(date_trunc('day', created_at), 'YYYY-MM-DD') AS date_label,
        COUNT(*)::NUMERIC AS total_count -- Cast to NUMERIC
    FROM public.users
    WHERE created_at >= start_date
    GROUP BY 1
    ORDER BY 1 ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
