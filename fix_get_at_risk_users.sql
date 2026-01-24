-- Fix get_at_risk_users RPC Type Mismatch Error
-- Casts the email column (varchar) to TEXT to match the return signature.

DROP FUNCTION IF EXISTS public.get_at_risk_users();

CREATE OR REPLACE FUNCTION public.get_at_risk_users()
RETURNS TABLE (
    id UUID,
    email TEXT,
    inactive_days INTEGER,
    risk_level TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.id,
        u.email::TEXT, -- Explicit cast to TEXT to fix varchar mismatch error
        EXTRACT(DAY FROM (NOW() - COALESCE(u.last_login_at, u.created_at)))::INTEGER AS inactive_days,
        CASE
            WHEN u.last_login_at < NOW() - INTERVAL '90 days' THEN 'Critical'::TEXT
            WHEN u.last_login_at < NOW() - INTERVAL '60 days' THEN 'High'::TEXT
            WHEN u.last_login_at < NOW() - INTERVAL '30 days' THEN 'Medium'::TEXT
            ELSE 'Low'::TEXT
        END AS risk_level
    FROM public.users u
    WHERE u.last_login_at < NOW() - INTERVAL '30 days'
       OR (u.last_login_at IS NULL AND u.created_at < NOW() - INTERVAL '30 days')
    ORDER BY inactive_days DESC
    LIMIT 100;
END;
$$;
