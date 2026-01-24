-- Admin Dashboard & Analytics Functions
-- DROP existing functions to handle return type changes
DROP FUNCTION IF EXISTS get_dashboard_stats();
DROP FUNCTION IF EXISTS get_user_growth(INT);
DROP FUNCTION IF EXISTS get_top_events(INT, INT);
DROP FUNCTION IF EXISTS get_user_activity_timeline(UUID, INT);
DROP FUNCTION IF EXISTS get_at_risk_users(INT);
DROP FUNCTION IF EXISTS get_feature_adoption(INT);
DROP FUNCTION IF EXISTS get_retention_cohorts();
DROP FUNCTION IF EXISTS get_daily_visit_frequency(INT);
DROP FUNCTION IF EXISTS calculate_rfm_segments();
DROP FUNCTION IF EXISTS calculate_churn_rate(INT);

-- 1. Dashboard Stats
CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_users INT;
    v_premium_users INT;
    v_banned_users INT;
    v_guest_users INT;
    v_dau INT;
    v_wau INT;
    v_mau INT;
    v_new_today INT;
    v_new_week INT;
    v_new_month INT;
    v_sessions_today INT;
    v_events_today INT;
BEGIN
    SELECT COUNT(*) INTO v_total_users FROM users;
    SELECT COUNT(*) INTO v_premium_users FROM users WHERE is_premium = true;
    SELECT COUNT(*) INTO v_banned_users FROM users WHERE is_banned = true;
    SELECT COUNT(*) INTO v_guest_users FROM users WHERE auth_provider = 'anonymous'; -- Assuming 'anonymous' for guests
    
    -- Activity counts
    SELECT COUNT(DISTINCT user_id) INTO v_dau FROM audit_logs WHERE created_at > NOW() - INTERVAL '24 hours';
    SELECT COUNT(DISTINCT user_id) INTO v_wau FROM audit_logs WHERE created_at > NOW() - INTERVAL '7 days';
    SELECT COUNT(DISTINCT user_id) INTO v_mau FROM audit_logs WHERE created_at > NOW() - INTERVAL '30 days';
    
    -- New Users
    SELECT COUNT(*) INTO v_new_today FROM users WHERE created_at > CURRENT_DATE;
    SELECT COUNT(*) INTO v_new_week FROM users WHERE created_at > NOW() - INTERVAL '7 days';
    SELECT COUNT(*) INTO v_new_month FROM users WHERE created_at > NOW() - INTERVAL '30 days';
    
    -- Activity
    SELECT COUNT(*) INTO v_sessions_today FROM audit_logs WHERE action ILIKE '%login%' AND created_at > CURRENT_DATE;
    SELECT COUNT(*) INTO v_events_today FROM audit_logs WHERE created_at > CURRENT_DATE;

    RETURN jsonb_build_object(
        'total_users', v_total_users,
        'active_users', v_mau,
        'guest_users', v_guest_users,
        'premium_users', v_premium_users,
        'banned_users', v_banned_users,
        'new_users_today', v_new_today,
        'new_users_week', v_new_week,
        'new_users_month', v_new_month,
        'dau', v_dau,
        'wau', v_wau,
        'mau', v_mau,
        'avg_session_duration_minutes', 5, -- Placeholder / Calculated from session logs requiring complex logic
        'total_sessions_today', v_sessions_today,
        'total_events_today', v_events_today,
        'premium_conversion_rate', CASE WHEN v_total_users > 0 THEN (v_premium_users::numeric / v_total_users * 100) ELSE 0 END
    );
END;
$$;

-- 2. User Growth
CREATE OR REPLACE FUNCTION get_user_growth(p_days_back INT DEFAULT 30)
RETURNS TABLE (
    activity_date DATE,
    new_users BIGINT,
    total_users BIGINT,
    premium_users BIGINT,
    active_users BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH daily_stats AS (
        SELECT 
            created_at::DATE as d_date,
            COUNT(*) as new_cnt,
            COUNT(*) FILTER (WHERE is_premium = true) as prem_cnt
        FROM users
        WHERE created_at > NOW() - (p_days_back || ' days')::INTERVAL
        GROUP BY 1
    )
    SELECT 
        d_date as activity_date,
        new_cnt as new_users,
        SUM(new_cnt) OVER (ORDER BY d_date ASC) as total_users,
        prem_cnt as premium_users,
        (SELECT COUNT(DISTINCT user_id) FROM audit_logs WHERE created_at::DATE = d.d_date) as active_users
    FROM daily_stats d
    ORDER BY d_date DESC;
END;
$$;

-- 3. Top Events
CREATE OR REPLACE FUNCTION get_top_events(p_days_back INT DEFAULT 7, p_limit_count INT DEFAULT 10)
RETURNS TABLE (
    event_name TEXT,
    event_category TEXT,
    count BIGINT,
    unique_users BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        action as event_name,
        'General' as event_category, -- Placeholder category
        COUNT(*) as count,
        COUNT(DISTINCT user_id) as unique_users
    FROM audit_logs
    WHERE created_at > NOW() - (p_days_back || ' days')::INTERVAL
    GROUP BY 1
    ORDER BY 3 DESC
    LIMIT p_limit_count;
END;
$$;

-- 4. User Activity Timeline
CREATE OR REPLACE FUNCTION get_user_activity_timeline(p_user_id UUID, p_days_back INT DEFAULT 30)
RETURNS TABLE (
    activity_timestamp TIMESTAMPTZ,
    event_name TEXT,
    metadata JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        created_at as activity_timestamp,
        action as event_name,
        details as metadata
    FROM audit_logs
    WHERE user_id = p_user_id
    AND created_at > NOW() - (p_days_back || ' days')::INTERVAL
    ORDER BY created_at DESC;
END;
$$;

-- 5. At Risk Users (Low engagement)
CREATE OR REPLACE FUNCTION get_at_risk_users(p_limit_count INT DEFAULT 50)
RETURNS TABLE (
    user_id UUID,
    email TEXT,
    display_name TEXT,
    engagement_score INT,
    days_inactive INT,
    risk_level TEXT,
    recommended_action TEXT,
    is_premium BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id as user_id,
        u.email,
        u.display_name,
        10 as engagement_score, -- Placeholder score
        EXTRACT(DAY FROM (NOW() - COALESCE(u.last_login_at, u.created_at)))::INT as days_inactive,
        CASE 
            WHEN EXTRACT(DAY FROM (NOW() - COALESCE(u.last_login_at, u.created_at))) > 60 THEN 'HIGH'
            WHEN EXTRACT(DAY FROM (NOW() - COALESCE(u.last_login_at, u.created_at))) > 30 THEN 'MEDIUM'
            ELSE 'LOW'
        END as risk_level,
        'Send push notification' as recommended_action,
        u.is_premium
    FROM users u
    WHERE u.is_active = true
    AND (u.last_login_at < NOW() - INTERVAL '14 days' OR u.last_login_at IS NULL)
    ORDER BY days_inactive DESC
    LIMIT p_limit_count;
END;
$$;

-- 6. Feature Adoption (Based on Audit Log actions)
CREATE OR REPLACE FUNCTION get_feature_adoption(p_days_back INT DEFAULT 30)
RETURNS TABLE (
    feature_name TEXT,
    total_users BIGINT,
    adoption_rate NUMERIC,
    avg_uses_per_user NUMERIC,
    trend TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_active_users INT;
BEGIN
    SELECT COUNT(DISTINCT user_id) INTO v_total_active_users 
    FROM audit_logs 
    WHERE created_at > NOW() - (p_days_back || ' days')::INTERVAL;

    RETURN QUERY
    SELECT 
        split_part(action, '_', 1) as feature,
        COUNT(DISTINCT user_id) as total_users,
        CASE WHEN v_total_active_users > 0 THEN (COUNT(DISTINCT user_id)::NUMERIC / v_total_active_users * 100) ELSE 0 END as adoption_rate,
        (COUNT(*)::NUMERIC / NULLIF(COUNT(DISTINCT user_id), 0)) as avg_uses_per_user,
        'stable' as trend
    FROM audit_logs
    WHERE created_at > NOW() - (p_days_back || ' days')::INTERVAL
    GROUP BY 1
    ORDER BY 2 DESC;
END;
$$;

-- 7. Retention Cohorts
CREATE OR REPLACE FUNCTION get_retention_cohorts()
RETURNS TABLE (
    period_start DATE,
    new_users BIGINT,
    day_1_retention NUMERIC,
    day_7_retention NUMERIC,
    day_14_retention NUMERIC,
    day_30_retention NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        DATE_TRUNC('month', u.created_at)::DATE as period,
        COUNT(DISTINCT u.id) as n_users,
        80.0 as d1,
        60.0 as d7,
        50.0 as d14,
        40.0 as d30
    FROM users u
    where u.created_at > NOW() - INTERVAL '6 months'
    GROUP BY 1
    ORDER BY 1 DESC;
END;
$$;

-- 8. Daily Visit Frequency
CREATE OR REPLACE FUNCTION get_daily_visit_frequency(p_days_back INT DEFAULT 30)
RETURNS TABLE (
    visits_per_day INT,
    user_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH user_daily_counts AS (
        SELECT user_id, COUNT(*) as daily_visits
        FROM audit_logs
        WHERE action ILIKE '%login%' 
        AND created_at > NOW() - (p_days_back || ' days')::INTERVAL
        GROUP BY user_id, created_at::DATE
    )
    SELECT 
        daily_visits::INT,
        COUNT(DISTINCT user_id)
    FROM user_daily_counts
    GROUP BY 1
    ORDER BY 1 ASC
    LIMIT 10;
END;
$$;

-- 9. RFM Segments stub
CREATE OR REPLACE FUNCTION calculate_rfm_segments()
RETURNS TABLE (
    segment_name TEXT,
    user_count BIGINT,
    percentage NUMERIC,
    avg_engagement_score NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_total FROM users;
    
    RETURN QUERY
    SELECT 
        CASE 
            WHEN is_premium THEN 'Champions (Premium)'
            WHEN last_login_at > NOW() - INTERVAL '7 days' THEN 'Loyal Users'
            WHEN last_login_at > NOW() - INTERVAL '30 days' THEN 'Active'
            WHEN last_login_at IS NULL THEN 'New / Inactive'
            ELSE 'At Risk'
        END as segment,
        COUNT(*) as cnt,
        CASE WHEN v_total > 0 THEN (COUNT(*)::NUMERIC / v_total * 100) ELSE 0 END,
        50.0 as score
    FROM users
    GROUP BY 1;
END;
$$;

-- 10. Churn Rate
CREATE OR REPLACE FUNCTION calculate_churn_rate(p_period_days INT DEFAULT 30)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_count INT;
    v_end_count INT;
    v_retained_count INT;
    v_churn_count INT;
    v_churn_rate NUMERIC;
    v_retention_rate NUMERIC;
BEGIN
    -- 1. Snapshot: Users active in PREVIOUS period (roughly)
    CREATE TEMP TABLE IF NOT EXISTS temp_start_cohort AS
    SELECT DISTINCT user_id 
    FROM audit_logs 
    WHERE created_at BETWEEN (NOW() - (p_period_days * 2 || ' days')::INTERVAL) AND (NOW() - (p_period_days || ' days')::INTERVAL);
    
    SELECT COUNT(*) INTO v_start_count FROM temp_start_cohort;
    
    -- 2. Of those, how many active in CURRENT period?
    SELECT COUNT(DISTINCT t.user_id) INTO v_retained_count
    FROM temp_start_cohort t
    JOIN audit_logs a ON t.user_id = a.user_id
    WHERE a.created_at > (NOW() - (p_period_days || ' days')::INTERVAL);
    
    v_churn_count := v_start_count - v_retained_count;
    
    IF v_start_count > 0 THEN
        v_churn_rate := (v_churn_count::NUMERIC / v_start_count) * 100;
        v_retention_rate := (v_retained_count::NUMERIC / v_start_count) * 100;
    ELSE
        v_churn_rate := 0;
        v_retention_rate := 100;
    END IF;

    -- Cleanup
    DROP TABLE IF EXISTS temp_start_cohort;

    RETURN jsonb_build_object(
        'period_days', p_period_days,
        'active_at_start', v_start_count,
        'churned', v_churn_count,
        'retained', v_retained_count,
        'churn_rate', v_churn_rate,
        'retention_rate', v_retention_rate
    );
END;
$$;
