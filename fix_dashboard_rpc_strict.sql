-- FORCE DROP functions with CASCADE to ensure old definitions are removed
DROP FUNCTION IF EXISTS public.get_dashboard_stats() CASCADE;
DROP FUNCTION IF EXISTS public.get_user_growth(text) CASCADE;

-- 1. Dashboard Stats (Using standard SQL language, native types)
CREATE OR REPLACE FUNCTION public.get_dashboard_stats()
RETURNS TABLE (
    total_users BIGINT,
    active_users BIGINT,
    premium_users BIGINT,
    total_revenue NUMERIC
) LANGUAGE sql SECURITY DEFINER AS $$
    SELECT
        (SELECT COUNT(*) FROM public.users),
        (SELECT COUNT(*) FROM public.users WHERE last_login_at > NOW() - INTERVAL '30 days'),
        (SELECT COUNT(*) FROM public.users WHERE role = 'premium'),
        COALESCE((SELECT SUM(amount) FROM user_transactions WHERE type = 'income'), 0)
$$;


-- 2. User Growth (Using standard SQL language)
CREATE OR REPLACE FUNCTION public.get_user_growth(period text DEFAULT '7d')
RETURNS TABLE (
    date TEXT,
    count BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
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
        to_char(date_trunc('day', created_at), 'YYYY-MM-DD'),
        COUNT(*)
    FROM public.users
    WHERE created_at >= start_date
    GROUP BY 1
    ORDER BY 1 ASC;
END;
$$;
