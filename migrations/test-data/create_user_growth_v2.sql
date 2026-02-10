-- Create a V2 version of the user growth function to bypass any stale cache issues
-- get_user_growth_v2

DROP FUNCTION IF EXISTS public.get_user_growth_v2(text);

CREATE OR REPLACE FUNCTION public.get_user_growth_v2(period text DEFAULT '7d')
RETURNS TABLE (
    date TEXT,
    count NUMERIC -- Using NUMERIC to avoid any BigInt/Integer mismatch errors
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
        to_char(date_trunc('day', created_at), 'YYYY-MM-DD') AS date_label,
        COUNT(*)::NUMERIC AS total_count
    FROM public.users
    WHERE created_at >= start_date
    GROUP BY 1
    ORDER BY 1 ASC;
END;
$$;
