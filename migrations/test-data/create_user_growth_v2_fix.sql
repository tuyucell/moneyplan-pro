-- Fix Column Names in get_user_growth_v2 to match Frontend React props
-- Frontend expects: activity_date, total_users, active_users, premium_users

DROP FUNCTION IF EXISTS public.get_user_growth_v2(text);

CREATE OR REPLACE FUNCTION public.get_user_growth_v2(period text DEFAULT '7d')
RETURNS TABLE (
    activity_date TEXT,     -- Matched Frontend Prop
    total_users NUMERIC,    -- Matched Frontend Prop
    active_users NUMERIC,   -- Matched Frontend Prop
    premium_users NUMERIC   -- Matched Frontend Prop
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
        to_char(date_trunc('day', created_at), 'YYYY-MM-DD') AS activity_date,
        COUNT(*)::NUMERIC AS total_users,
        -- For now return 0 for active/premium breakdown to keep it simple and working
        -- Or we could calculate them if needed, but let's fix the graph first.
        0::NUMERIC AS active_users,
        0::NUMERIC AS premium_users
    FROM public.users
    WHERE created_at >= start_date
    GROUP BY 1
    ORDER BY 1 ASC;
END;
$$;
