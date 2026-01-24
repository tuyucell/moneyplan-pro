-- Create V2 At-Risk Users RPC with full field compatibility
-- Includes extra columns (display_name, engagement_score, etc.) expected by Frontend.

DROP FUNCTION IF EXISTS public.get_at_risk_users_v2();

CREATE OR REPLACE FUNCTION public.get_at_risk_users_v2()
RETURNS TABLE (
    user_id UUID,
    email_addr TEXT,
    days_inactive INTEGER,
    risk_status TEXT,
    display_name TEXT,
    engagement_score INTEGER,
    recommended_action TEXT,
    is_premium BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.id,
        u.email::TEXT,
        COALESCE(EXTRACT(DAY FROM (NOW() - COALESCE(u.last_login_at, u.created_at))), 0)::INTEGER AS days_inactive,
        
        -- Risk Logic
        (CASE
            WHEN COALESCE(u.last_login_at, u.created_at) < NOW() - INTERVAL '90 days' THEN 'HIGH'
            WHEN COALESCE(u.last_login_at, u.created_at) < NOW() - INTERVAL '60 days' THEN 'MEDIUM'
            ELSE 'LOW'
        END)::TEXT AS risk_status,
        
        COALESCE(u.display_name, 'User')::TEXT,
        
        -- Dummy Engagement Score (Can be improved later)
        10::INTEGER AS engagement_score,
        
        -- Recommendation
        'Send Push Notification / Email'::TEXT AS recommended_action,
        
        COALESCE(u.is_premium, false)::BOOLEAN

    FROM public.users u
    -- Filter: Users inactive for > 30 days
    WHERE COALESCE(u.last_login_at, u.created_at) < NOW() - INTERVAL '30 days'
    ORDER BY 3 DESC -- Order by inactive days
    LIMIT 100;
END;
$$;
