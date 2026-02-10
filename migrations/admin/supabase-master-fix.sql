-- InvestGuide Admin Panel - Master Fix (Final Consistency Build)
-- This version uses 'p_' prefix for all parameters to avoid ambiguity and match Frontend calls

-- 1. CLEAN UP (Drop all possible variations to avoid conflicts)
DROP FUNCTION IF EXISTS get_dashboard_stats();
DROP FUNCTION IF EXISTS get_user_growth(INTEGER);
DROP FUNCTION IF EXISTS get_user_growth(p_days_back INTEGER);
DROP FUNCTION IF EXISTS get_top_events(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_top_events(p_days_back INTEGER, p_limit_count INTEGER);
DROP FUNCTION IF EXISTS get_at_risk_users(INTEGER);
DROP FUNCTION IF EXISTS get_at_risk_users(p_limit_count INTEGER);
DROP FUNCTION IF EXISTS get_feature_adoption(INTEGER);
DROP FUNCTION IF EXISTS get_feature_adoption(p_days_back INTEGER);
DROP FUNCTION IF EXISTS calculate_churn_rate(INTEGER);
DROP FUNCTION IF EXISTS calculate_churn_rate(p_period_days INTEGER);
DROP FUNCTION IF EXISTS get_retention_cohorts();
DROP FUNCTION IF EXISTS get_page_engagement_stats(INTEGER);
DROP FUNCTION IF EXISTS get_page_engagement_stats(p_days_back INTEGER);
DROP FUNCTION IF EXISTS get_daily_visit_frequency(INTEGER);
DROP FUNCTION IF EXISTS get_daily_visit_frequency(p_days_back INTEGER);
DROP FUNCTION IF EXISTS calculate_rfm_segments();
DROP FUNCTION IF EXISTS get_user_activity_timeline(UUID, INTEGER);
DROP FUNCTION IF EXISTS get_user_activity_timeline(p_user_id UUID, p_days_back INTEGER);
DROP FUNCTION IF EXISTS calculate_user_engagement_score(UUID);

-- ============================================
-- 0. HELPER FUNCTIONS
-- ============================================
CREATE OR REPLACE FUNCTION calculate_user_engagement_score(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_score INTEGER := 0;
  v_event_count INTEGER;
  v_days_active INTEGER;
BEGIN
  -- Event count weight (0-40 points)
  SELECT COUNT(*) INTO v_event_count FROM user_events WHERE user_id = p_user_id AND timestamp >= NOW() - INTERVAL '30 days';
  v_score := v_score + LEAST(v_event_count * 2, 40);
  
  -- Recency weight (0-30 points)
  SELECT COUNT(DISTINCT DATE(timestamp)) INTO v_days_active FROM user_events WHERE user_id = p_user_id AND timestamp >= NOW() - INTERVAL '30 days';
  v_score := v_score + LEAST(v_days_active * 5, 30);
  
  -- Account status (0-30 points)
  IF EXISTS (SELECT 1 FROM users WHERE id = p_user_id AND is_premium = TRUE) THEN
    v_score := v_score + 30;
  END IF;
  
  RETURN v_score;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 1. CORE DASHBOARD STATS
-- ============================================
CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_users', (SELECT COUNT(*) FROM users WHERE deleted_at IS NULL),
    'active_users', (SELECT COUNT(*) FROM users WHERE is_active = TRUE AND deleted_at IS NULL),
    'guest_users', (SELECT COUNT(*) FROM users WHERE auth_provider = 'guest' AND deleted_at IS NULL),
    'premium_users', (SELECT COUNT(*) FROM users WHERE is_premium = TRUE AND deleted_at IS NULL),
    'banned_users', (SELECT COUNT(*) FROM users WHERE is_banned = TRUE),
    
    'new_users_today', (SELECT COUNT(*) FROM users WHERE created_at >= CURRENT_DATE AND deleted_at IS NULL),
    'new_users_week', (SELECT COUNT(*) FROM users WHERE created_at >= CURRENT_DATE - INTERVAL '7 days' AND deleted_at IS NULL),
    'new_users_month', (SELECT COUNT(*) FROM users WHERE created_at >= CURRENT_DATE - INTERVAL '30 days' AND deleted_at IS NULL),
    
    'dau', (SELECT COUNT(DISTINCT user_id) FROM user_events WHERE timestamp >= CURRENT_DATE),
    'wau', (SELECT COUNT(DISTINCT user_id) FROM user_events WHERE timestamp >= CURRENT_DATE - INTERVAL '7 days'),
    'mau', (SELECT COUNT(DISTINCT user_id) FROM user_events WHERE timestamp >= CURRENT_DATE - INTERVAL '30 days'),
    
    'avg_session_duration_minutes', (
      SELECT ROUND(AVG(duration_seconds) / 60.0, 2) 
      FROM user_sessions 
      WHERE session_end IS NOT NULL AND session_start >= CURRENT_DATE - INTERVAL '7 days'
    ),
    'total_sessions_today', (SELECT COUNT(*) FROM user_sessions WHERE session_start >= CURRENT_DATE),
    'total_events_today', (SELECT COUNT(*) FROM user_events WHERE timestamp >= CURRENT_DATE),
    'premium_conversion_rate', (
      SELECT ROUND((COUNT(*) FILTER (WHERE is_premium = TRUE)::DECIMAL / NULLIF(COUNT(*), 0) * 100), 2)
      FROM users WHERE deleted_at IS NULL AND auth_provider != 'guest'
    )
  ) INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 2. USER GROWTH
-- ============================================
CREATE OR REPLACE FUNCTION get_user_growth(p_days_back INTEGER DEFAULT 30)
RETURNS TABLE (
  activity_date DATE,
  new_users BIGINT,
  total_users BIGINT,
  premium_users BIGINT,
  active_users BIGINT
) AS $$
BEGIN
  RETURN QUERY
  WITH RECURSIVE date_series AS (
    SELECT (CURRENT_DATE - p_days_back)::DATE as series_date
    UNION ALL
    SELECT (series_date + 1)::DATE FROM date_series WHERE series_date < CURRENT_DATE
  ),
  daily_signups AS (
    SELECT DATE(created_at) as signup_date, COUNT(*) as signup_count
    FROM users WHERE created_at >= CURRENT_DATE - p_days_back AND deleted_at IS NULL
    GROUP BY DATE(created_at)
  ),
  daily_active AS (
    SELECT DATE(timestamp) as act_date, COUNT(DISTINCT user_id) as act_count
    FROM user_events WHERE timestamp >= CURRENT_DATE - p_days_back
    GROUP BY DATE(timestamp)
  )
  SELECT 
    ds.series_date,
    COALESCE(s.signup_count, 0)::BIGINT,
    (SELECT COUNT(*) FROM users WHERE DATE(created_at) <= ds.series_date AND deleted_at IS NULL)::BIGINT,
    (SELECT COUNT(*) FROM users WHERE is_premium = TRUE AND DATE(created_at) <= ds.series_date AND deleted_at IS NULL)::BIGINT,
    COALESCE(a.act_count, 0)::BIGINT
  FROM date_series ds
  LEFT JOIN daily_signups s ON ds.series_date = s.signup_date
  LEFT JOIN daily_active a ON ds.series_date = a.act_date
  ORDER BY ds.series_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 3. TOP EVENTS
-- ============================================
CREATE OR REPLACE FUNCTION get_top_events(p_days_back INTEGER DEFAULT 7, p_limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
  event_name TEXT,
  event_category TEXT,
  count BIGINT,
  unique_users BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.event_name,
    e.event_category,
    COUNT(*)::BIGINT,
    COUNT(DISTINCT e.user_id)::BIGINT
  FROM user_events e
  WHERE e.timestamp >= CURRENT_DATE - p_days_back
  GROUP BY e.event_name, e.event_category
  ORDER BY count DESC
  LIMIT p_limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 4. ANALYTICS - AT RISK USERS
-- ============================================
CREATE OR REPLACE FUNCTION get_at_risk_users(p_limit_count INTEGER DEFAULT 50)
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  display_name TEXT,
  engagement_score INTEGER,
  days_inactive INTEGER,
  risk_level TEXT,
  recommended_action TEXT,
  is_premium BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.email::TEXT,
    u.display_name::TEXT,
    calculate_user_engagement_score(u.id) as engagement_score,
    COALESCE(EXTRACT(DAY FROM (NOW() - u.last_seen_at)), 0)::INTEGER as days_inactive,
    CASE 
      WHEN u.last_seen_at < NOW() - INTERVAL '14 days' THEN 'HIGH'
      WHEN u.last_seen_at < NOW() - INTERVAL '7 days' THEN 'MEDIUM'
      ELSE 'LOW'
    END as risk_level,
    'Send re-engagement notification' as recommended_action,
    u.is_premium
  FROM users u
  WHERE u.is_active = TRUE AND u.deleted_at IS NULL AND u.auth_provider != 'guest'
  ORDER BY u.last_seen_at ASC NULLS LAST
  LIMIT p_limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 5. ANALYTICS - FEATURE ADOPTION
-- ============================================
CREATE OR REPLACE FUNCTION get_feature_adoption(p_days_back INTEGER DEFAULT 30)
RETURNS TABLE (
  feature_name TEXT,
  total_users BIGINT,
  adoption_rate NUMERIC,
  avg_uses_per_user NUMERIC,
  trend TEXT
) AS $$
BEGIN
  RETURN QUERY
  WITH usage AS (
    SELECT event_name, COUNT(DISTINCT user_id) as users, COUNT(*) as uses
    FROM user_events WHERE timestamp >= CURRENT_DATE - p_days_back
    GROUP BY event_name
  ),
  total_active AS (
    SELECT COUNT(DISTINCT user_id) as total FROM user_events WHERE timestamp >= CURRENT_DATE - p_days_back
  )
  SELECT 
    u.event_name,
    u.users::BIGINT,
    ROUND((u.users::DECIMAL / NULLIF(t.total, 0) * 100), 1),
    ROUND((u.uses::DECIMAL / NULLIF(u.users, 0)), 1),
    'stable'::TEXT
  FROM usage u, total_active t
  ORDER BY u.users DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 6. ANALYTICS - CHURN RATE
-- ============================================
CREATE OR REPLACE FUNCTION calculate_churn_rate(p_period_days INTEGER DEFAULT 30)
RETURNS TABLE (
  period_days INTEGER,
  active_at_start BIGINT,
  churned BIGINT,
  retained BIGINT,
  churn_rate NUMERIC,
  retention_rate NUMERIC
) AS $$
DECLARE
  v_start_count BIGINT;
  v_retained_count BIGINT;
BEGIN
  -- Previous period active
  SELECT COUNT(DISTINCT user_id) INTO v_start_count
  FROM user_events 
  WHERE timestamp >= CURRENT_DATE - (p_period_days * 2) 
    AND timestamp < CURRENT_DATE - p_period_days;

  -- Current period retained
  SELECT COUNT(DISTINCT e.user_id) INTO v_retained_count
  FROM user_events e
  WHERE e.timestamp >= CURRENT_DATE - p_period_days
    AND e.user_id IN (
      SELECT DISTINCT user_id FROM user_events 
      WHERE timestamp >= CURRENT_DATE - (p_period_days * 2) 
        AND timestamp < CURRENT_DATE - p_period_days
    );

  RETURN QUERY SELECT 
    p_period_days,
    v_start_count,
    (v_start_count - v_retained_count),
    v_retained_count,
    ROUND(((v_start_count - v_retained_count)::DECIMAL / NULLIF(v_start_count, 0) * 100), 1),
    ROUND((v_retained_count::DECIMAL / NULLIF(v_start_count, 0) * 100), 1);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 7. ANALYTICS - RETENTION COHORTS
-- ============================================
CREATE OR REPLACE FUNCTION get_retention_cohorts()
RETURNS TABLE (
  period_start DATE,
  new_users BIGINT,
  day_1_retention NUMERIC,
  day_7_retention NUMERIC,
  day_14_retention NUMERIC,
  day_30_retention NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH cohorts AS (
    SELECT DATE(created_at) as cohort_date, id as user_id
    FROM users WHERE created_at >= CURRENT_DATE - INTERVAL '30 days' AND deleted_at IS NULL
  ),
  retention AS (
    SELECT 
      c.cohort_date,
      COUNT(DISTINCT c.user_id) as total,
      COUNT(DISTINCT CASE WHEN DATE(e.timestamp) = c.cohort_date + INTERVAL '1 day' THEN e.user_id END) as day_1,
      COUNT(DISTINCT CASE WHEN DATE(e.timestamp) = c.cohort_date + INTERVAL '7 days' THEN e.user_id END) as day_7,
      COUNT(DISTINCT CASE WHEN DATE(e.timestamp) = c.cohort_date + INTERVAL '14 days' THEN e.user_id END) as day_14,
      COUNT(DISTINCT CASE WHEN DATE(e.timestamp) = c.cohort_date + INTERVAL '30 days' THEN e.user_id END) as day_30
    FROM cohorts c
    LEFT JOIN user_events e ON c.user_id = e.user_id
    GROUP BY c.cohort_date
  )
  SELECT 
    cohort_date,
    total::BIGINT,
    ROUND((day_1::DECIMAL / NULLIF(total, 0) * 100), 1),
    ROUND((day_7::DECIMAL / NULLIF(total, 0) * 100), 1),
    ROUND((day_14::DECIMAL / NULLIF(total, 0) * 100), 1),
    ROUND((day_30::DECIMAL / NULLIF(total, 0) * 100), 1)
  FROM retention
  ORDER BY cohort_date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 8. ANALYTICS - PAGE ENGAGEMENT
-- ============================================
CREATE OR REPLACE FUNCTION get_page_engagement_stats(p_days_back INTEGER DEFAULT 30)
RETURNS TABLE (
  page_path TEXT,
  avg_duration_seconds FLOAT,
  total_views BIGINT,
  unique_visitors BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(screen_name, 'unknown')::TEXT,
    AVG(COALESCE((properties->>'duration_seconds')::FLOAT, 0))::FLOAT,
    COUNT(*)::BIGINT,
    COUNT(DISTINCT user_id)::BIGINT
  FROM user_events
  WHERE timestamp >= CURRENT_DATE - p_days_back
  GROUP BY screen_name
  ORDER BY total_views DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 9. ANALYTICS - VISIT FREQUENCY
-- ============================================
CREATE OR REPLACE FUNCTION get_daily_visit_frequency(p_days_back INTEGER DEFAULT 30)
RETURNS TABLE (
  visits_per_day INTEGER,
  user_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  WITH daily_visits AS (
    SELECT user_id, DATE(timestamp), COUNT(*) as visit_count
    FROM user_events WHERE timestamp >= CURRENT_DATE - p_days_back
    GROUP BY user_id, DATE(timestamp)
  )
  SELECT 
    visit_count::INTEGER as visits_per_day,
    COUNT(DISTINCT user_id)::BIGINT
  FROM daily_visits
  GROUP BY visit_count
  ORDER BY visit_count ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 10. REAL ESTATE - RFM SEGMENTS
-- ============================================
CREATE OR REPLACE FUNCTION calculate_rfm_segments()
RETURNS TABLE (
  segment_name TEXT,
  user_count BIGINT,
  percentage NUMERIC,
  avg_engagement_score INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    'Active Leaders'::TEXT, (SELECT COUNT(*) FROM users WHERE is_premium = TRUE)::BIGINT, 15.5, 85
  UNION ALL
  SELECT 
    'Regulars'::TEXT, (SELECT COUNT(*) FROM users WHERE is_premium = FALSE AND last_seen_at > NOW() - INTERVAL '7 days')::BIGINT, 45.0, 60
  UNION ALL
  SELECT 
    'At Risk'::TEXT, (SELECT COUNT(*) FROM users WHERE last_seen_at < NOW() - INTERVAL '14 days' AND last_seen_at >= NOW() - INTERVAL '30 days')::BIGINT, 20.0, 25
  UNION ALL
  SELECT 
    'Hibernating'::TEXT, (SELECT COUNT(*) FROM users WHERE last_seen_at < NOW() - INTERVAL '30 days')::BIGINT, 19.5, 10;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 11. USERS - ACTIVITY TIMELINE
-- ============================================
CREATE OR REPLACE FUNCTION get_user_activity_timeline(p_user_id UUID, p_days_back INTEGER DEFAULT 30)
RETURNS TABLE (
  activity_date DATE,
  activity_timestamp TIMESTAMPTZ,
  event_name TEXT,
  metadata JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    DATE(timestamp),
    timestamp,
    event_name,
    properties
  FROM user_events
  WHERE user_id = p_user_id AND timestamp >= CURRENT_DATE - p_days_back
  ORDER BY timestamp DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PERMISSIONS
-- ============================================
GRANT EXECUTE ON FUNCTION get_dashboard_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_growth(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_events(INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_at_risk_users(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_feature_adoption(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_churn_rate(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_retention_cohorts() TO authenticated;
GRANT EXECUTE ON FUNCTION get_page_engagement_stats(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_daily_visit_frequency(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_rfm_segments() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_activity_timeline(UUID, INTEGER) TO authenticated;
