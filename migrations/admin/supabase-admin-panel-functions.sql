-- ============================================
-- InvestGuide Admin Panel - Analytics Functions
-- Run AFTER supabase-admin-panel-migration.sql
-- ============================================

-- ============================================
-- DASHBOARD & CORE METRICS
-- ============================================

-- Get comprehensive dashboard stats
CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    -- Total users
    'total_users', (SELECT COUNT(*) FROM users WHERE deleted_at IS NULL),
    'active_users', (SELECT COUNT(*) FROM users WHERE is_active = TRUE AND deleted_at IS NULL),
    'guest_users', (SELECT COUNT(*) FROM users WHERE auth_provider = 'guest' AND deleted_at IS NULL),
    'premium_users', (SELECT COUNT(*) FROM users WHERE is_premium = TRUE AND deleted_at IS NULL),
    'banned_users', (SELECT COUNT(*) FROM users WHERE is_banned = TRUE),
    
    -- New users
    'new_users_today', (
      SELECT COUNT(*) FROM users 
      WHERE created_at >= CURRENT_DATE AND deleted_at IS NULL
    ),
    'new_users_week', (
      SELECT COUNT(*) FROM users 
      WHERE created_at >= CURRENT_DATE - INTERVAL '7 days' AND deleted_at IS NULL
    ),
    'new_users_month', (
      SELECT COUNT(*) FROM users 
      WHERE created_at >= CURRENT_DATE - INTERVAL '30 days' AND deleted_at IS NULL
    ),
    
    -- Active users (DAU/WAU/MAU)
    'dau', (
      SELECT COUNT(DISTINCT user_id) FROM user_events
      WHERE timestamp >= CURRENT_DATE
        AND event_category IN ('engagement', 'feature_usage', 'monetization')
    ),
    'wau', (
      SELECT COUNT(DISTINCT user_id) FROM user_events
      WHERE timestamp >= CURRENT_DATE - INTERVAL '7 days'
        AND event_category IN ('engagement', 'feature_usage', 'monetization')
    ),
    'mau', (
      SELECT COUNT(DISTINCT user_id) FROM user_events
      WHERE timestamp >= CURRENT_DATE - INTERVAL '30 days'
        AND event_category IN ('engagement', 'feature_usage', 'monetization')
    ),
    
    -- Session metrics
    'avg_session_duration_minutes', (
      SELECT ROUND(AVG(duration_seconds) / 60.0, 2) FROM user_sessions
      WHERE session_end IS NOT NULL
      AND session_start >= CURRENT_DATE - INTERVAL '7 days'
    ),
    'total_sessions_today', (
      SELECT COUNT(*) FROM user_sessions
      WHERE session_start >= CURRENT_DATE
    ),
    'total_events_today', (
      SELECT COUNT(*) FROM user_events
      WHERE timestamp >= CURRENT_DATE
    ),
    
    -- Conversion metrics
    'premium_conversion_rate', (
      SELECT ROUND(
        (COUNT(*) FILTER (WHERE is_premium = TRUE)::DECIMAL / 
         NULLIF(COUNT(*), 0) * 100), 2
      )
      FROM users
      WHERE deleted_at IS NULL AND auth_provider != 'guest'
    )
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get stickiness metrics (DAU/MAU ratios)
CREATE OR REPLACE FUNCTION get_stickiness_metrics()
RETURNS JSON AS $$
DECLARE
  result JSON;
  dau_count BIGINT;
  wau_count BIGINT;
  mau_count BIGINT;
BEGIN
  -- DAU (meaningful actions only)
  SELECT COUNT(DISTINCT user_id) INTO dau_count
  FROM user_events
  WHERE timestamp >= CURRENT_DATE
    AND event_category IN ('engagement', 'feature_usage', 'monetization');
  
  -- WAU
  SELECT COUNT(DISTINCT user_id) INTO wau_count
  FROM user_events
  WHERE timestamp >= CURRENT_DATE - INTERVAL '7 days'
    AND event_category IN ('engagement', 'feature_usage', 'monetization');
  
  -- MAU
  SELECT COUNT(DISTINCT user_id) INTO mau_count
  FROM user_events
  WHERE timestamp >= CURRENT_DATE - INTERVAL '30 days'
    AND event_category IN ('engagement', 'feature_usage', 'monetization');
  
  SELECT json_build_object(
    'dau', dau_count,
    'wau', wau_count,
    'mau', mau_count,
    'dau_mau_ratio', ROUND((dau_count::DECIMAL / NULLIF(mau_count, 0)) * 100, 2),
    'dau_wau_ratio', ROUND((dau_count::DECIMAL / NULLIF(wau_count, 0)) * 100, 2),
    'wau_mau_ratio', ROUND((wau_count::DECIMAL / NULLIF(mau_count, 0)) * 100, 2),
    'stickiness_grade', CASE 
      WHEN (dau_count::DECIMAL / NULLIF(mau_count, 0)) * 100 >= 30 THEN 'Excellent'
      WHEN (dau_count::DECIMAL / NULLIF(mau_count, 0)) * 100 >= 20 THEN 'Good'
      WHEN (dau_count::DECIMAL / NULLIF(mau_count, 0)) * 100 >= 10 THEN 'Average'
      ELSE 'Poor'
    END
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- USER ANALYTICS
-- ============================================

-- User activity timeline
CREATE OR REPLACE FUNCTION get_user_activity_timeline(
  target_user_id UUID, 
  days_back INTEGER DEFAULT 30
)
RETURNS TABLE (
  date DATE,
  sessions_count INTEGER,
  events_count INTEGER,
  total_duration_minutes INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    DATE(s.session_start) as date,
    COUNT(DISTINCT s.id)::INTEGER as sessions_count,
    COUNT(e.id)::INTEGER as events_count,
    (COALESCE(SUM(s.duration_seconds), 0) / 60)::INTEGER as total_duration_minutes
  FROM user_sessions s
  LEFT JOIN user_events e ON e.session_id = s.id
  WHERE s.user_id = target_user_id
    AND s.session_start >= CURRENT_DATE - days_back
  GROUP BY DATE(s.session_start)
  ORDER BY date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get new vs returning users breakdown
CREATE OR REPLACE FUNCTION get_new_vs_returning(days_back INTEGER DEFAULT 30)
RETURNS TABLE (
  date DATE,
  new_users INTEGER,
  returning_users INTEGER,
  total_active INTEGER,
  returning_percentage DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  WITH daily_active AS (
    SELECT 
      DATE(timestamp) as activity_date,
      user_id
    FROM user_events
    WHERE timestamp >= CURRENT_DATE - days_back
      AND event_category IN ('engagement', 'feature_usage', 'monetization')
    GROUP BY DATE(timestamp), user_id
  ),
  user_first_activity AS (
    SELECT 
      user_id,
      MIN(DATE(timestamp)) as first_seen
    FROM user_events
    GROUP BY user_id
  )
  SELECT 
    da.activity_date::DATE,
    COUNT(da.user_id) FILTER (WHERE ufa.first_seen = da.activity_date)::INTEGER as new_users,
    COUNT(da.user_id) FILTER (WHERE ufa.first_seen < da.activity_date)::INTEGER as returning_users,
    COUNT(da.user_id)::INTEGER as total_active,
    ROUND(
      COUNT(da.user_id) FILTER (WHERE ufa.first_seen < da.activity_date)::DECIMAL / 
      NULLIF(COUNT(da.user_id), 0) * 100, 2
    ) as returning_percentage
  FROM daily_active da
  LEFT JOIN user_first_activity ufa ON da.user_id = ufa.user_id
  GROUP BY da.activity_date
  ORDER BY da.activity_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- User growth over time
CREATE OR REPLACE FUNCTION get_user_growth(days_back INTEGER DEFAULT 30)
RETURNS TABLE (
  date DATE,
  new_users BIGINT,
  total_users BIGINT,
  premium_users BIGINT,
  active_users BIGINT
) AS $$
BEGIN
  RETURN QUERY
  WITH RECURSIVE date_series AS (
    SELECT (CURRENT_DATE - days_back)::DATE as date
    UNION ALL
    SELECT (date + 1)::DATE
    FROM date_series
    WHERE date < CURRENT_DATE
  ),
  daily_signups AS (
    SELECT DATE(created_at) as signup_date, COUNT(*) as count
    FROM users
    WHERE created_at >= CURRENT_DATE - days_back
      AND deleted_at IS NULL
    GROUP BY DATE(created_at)
  ),
  daily_active AS (
    SELECT DATE(timestamp) as activity_date, COUNT(DISTINCT user_id) as count
    FROM user_events
    WHERE timestamp >= CURRENT_DATE - days_back
      AND event_category IN ('engagement', 'feature_usage', 'monetization')
    GROUP BY DATE(timestamp)
  )
  SELECT 
    ds.date,
    COALESCE(dsu.count, 0)::BIGINT as new_users,
    (SELECT COUNT(*) FROM users WHERE DATE(created_at) <= ds.date AND deleted_at IS NULL)::BIGINT as total_users,
    (SELECT COUNT(*) FROM users WHERE is_premium = TRUE AND DATE(created_at) <= ds.date AND deleted_at IS NULL)::BIGINT as premium_users,
    COALESCE(da.count, 0)::BIGINT as active_users
  FROM date_series ds
  LEFT JOIN daily_signups dsu ON ds.date = dsu.signup_date
  LEFT JOIN daily_active da ON ds.date = da.activity_date
  ORDER BY ds.date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ENGAGEMENT & CHURN PREDICTION
-- ============================================

-- Calculate individual user engagement score (0-100)
CREATE OR REPLACE FUNCTION calculate_user_engagement_score(target_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  score INTEGER := 0;
  recent_sessions INTEGER;
  recent_events INTEGER;
  avg_session_duration INTEGER;
  days_since_last_active INTEGER;
BEGIN
  -- Session frequency (0-30 points)
  SELECT COUNT(*) INTO recent_sessions
  FROM user_sessions
  WHERE user_id = target_user_id
    AND session_start >= CURRENT_DATE - INTERVAL '7 days';
  score := score + LEAST(recent_sessions * 3, 30);
  
  -- Event activity (0-30 points)
  SELECT COUNT(*) INTO recent_events
  FROM user_events
  WHERE user_id = target_user_id
    AND timestamp >= CURRENT_DATE - INTERVAL '7 days'
    AND event_category IN ('engagement', 'feature_usage', 'monetization');
  score := score + LEAST(recent_events, 30);
  
  -- Session quality (0-25 points)
  SELECT COALESCE(AVG(duration_seconds), 0) INTO avg_session_duration
  FROM user_sessions
  WHERE user_id = target_user_id
    AND session_end IS NOT NULL
    AND session_start >= CURRENT_DATE - INTERVAL '7 days';
  score := score + LEAST((avg_session_duration / 60), 25);
  
  -- Recency (0-15 points)
  SELECT COALESCE(DATE_PART('day', NOW() - last_seen_at), 999) INTO days_since_last_active
  FROM users
  WHERE id = target_user_id;
  
  IF days_since_last_active = 0 THEN score := score + 15;
  ELSIF days_since_last_active <= 1 THEN score := score + 12;
  ELSIF days_since_last_active <= 3 THEN score := score + 8;
  ELSIF days_since_last_active <= 7 THEN score := score + 4;
  END IF;
  
  RETURN score;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get list of at-risk users
CREATE OR REPLACE FUNCTION get_at_risk_users(limit_count INTEGER DEFAULT 100)
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
    u.email,
    u.display_name,
    calculate_user_engagement_score(u.id) as engagement_score,
    COALESCE(DATE_PART('day', NOW() - u.last_seen_at), 0)::INTEGER as days_inactive,
    CASE 
      WHEN calculate_user_engagement_score(u.id) < 20 THEN 'HIGH'
      WHEN calculate_user_engagement_score(u.id) < 40 THEN 'MEDIUM'
      ELSE 'LOW'
    END as risk_level,
    CASE 
      WHEN calculate_user_engagement_score(u.id) < 20 AND u.is_premium THEN 'URGENT: Send win-back campaign + personal outreach'
      WHEN calculate_user_engagement_score(u.id) < 20 THEN 'Send win-back campaign'
      WHEN calculate_user_engagement_score(u.id) < 40 THEN 'Send re-engagement notification'
      ELSE 'Monitor closely'
    END as recommended_action,
    u.is_premium
  FROM users u
  WHERE u.is_active = TRUE
    AND u.deleted_at IS NULL
    AND u.auth_provider != 'guest'
    AND calculate_user_engagement_score(u.id) < 60
  ORDER BY 
    u.is_premium DESC, -- Premium users first
    engagement_score ASC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Calculate churn rate
CREATE OR REPLACE FUNCTION calculate_churn_rate(period_days INTEGER DEFAULT 30)
RETURNS JSON AS $$
DECLARE
  result JSON;
  churned_count INTEGER;
  active_start_count INTEGER;
BEGIN
  -- Users who were active at the start of the period
  SELECT COUNT(DISTINCT user_id) INTO active_start_count
  FROM user_events
  WHERE timestamp >= CURRENT_DATE - (period_days * 2)
    AND timestamp < CURRENT_DATE - period_days
    AND event_category IN ('engagement', 'feature_usage', 'monetization');
  
  -- Users who were active at start but NOT in current period (churned)
  SELECT COUNT(*) INTO churned_count
  FROM (
    SELECT DISTINCT user_id
    FROM user_events
    WHERE timestamp >= CURRENT_DATE - (period_days * 2)
      AND timestamp < CURRENT_DATE - period_days
      AND event_category IN ('engagement', 'feature_usage', 'monetization')
    EXCEPT
    SELECT DISTINCT user_id
    FROM user_events
    WHERE timestamp >= CURRENT_DATE - period_days
      AND event_category IN ('engagement', 'feature_usage', 'monetization')
  ) churned;
  
  SELECT json_build_object(
    'period_days', period_days,
    'active_at_start', active_start_count,
    'churned', churned_count,
    'retained', active_start_count - churned_count,
    'churn_rate', ROUND(churned_count::DECIMAL / NULLIF(active_start_count, 0) * 100, 2),
    'retention_rate', ROUND((active_start_count - churned_count)::DECIMAL / NULLIF(active_start_count, 0) * 100, 2)
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FEATURE ADOPTION & EVENTS
-- ============================================

-- Get top events
CREATE OR REPLACE FUNCTION get_top_events(
  days_back INTEGER DEFAULT 7,
  limit_count INTEGER DEFAULT 10
)
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
    COUNT(*)::BIGINT as count,
    COUNT(DISTINCT e.user_id)::BIGINT as unique_users
  FROM user_events e
  WHERE e.timestamp >= CURRENT_DATE - days_back
  GROUP BY e.event_name, e.event_category
  ORDER BY count DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get feature adoption metrics
CREATE OR REPLACE FUNCTION get_feature_adoption(days_back INTEGER DEFAULT 30)
RETURNS TABLE (
  feature_name TEXT,
  total_users BIGINT,
  adoption_rate DECIMAL,
  avg_uses_per_user DECIMAL,
  trend TEXT
) AS $$
BEGIN
  RETURN QUERY
  WITH feature_usage AS (
    SELECT 
      event_name as feature,
      COUNT(DISTINCT user_id) as users,
      COUNT(*) as total_uses
    FROM user_events
    WHERE timestamp >= CURRENT_DATE - days_back
      AND event_category = 'feature_usage'
    GROUP BY event_name
  ),
  total_active AS (
    SELECT COUNT(DISTINCT user_id) as total
    FROM user_events
    WHERE timestamp >= CURRENT_DATE - days_back
  ),
  previous_period AS (
    SELECT 
      event_name as feature,
      COUNT(DISTINCT user_id) as users_prev
    FROM user_events
    WHERE timestamp >= CURRENT_DATE - (days_back * 2)
      AND timestamp < CURRENT_DATE - days_back
      AND event_category = 'feature_usage'
    GROUP BY event_name
  )
  SELECT 
    fu.feature as feature_name,
    fu.users as total_users,
    ROUND((fu.users::DECIMAL / NULLIF(ta.total, 0)) * 100, 2) as adoption_rate,
    ROUND(fu.total_uses::DECIMAL / NULLIF(fu.users, 0), 2) as avg_uses_per_user,
    CASE 
      WHEN pp.users_prev IS NULL THEN 'new'
      WHEN fu.users > pp.users_prev * 1.1 THEN 'up'
      WHEN fu.users < pp.users_prev * 0.9 THEN 'down'
      ELSE 'stable'
    END as trend
  FROM feature_usage fu
  CROSS JOIN total_active ta
  LEFT JOIN previous_period pp ON fu.feature = pp.feature
  ORDER BY adoption_rate DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- COHORT & RETENTION
-- ============================================

-- Retention cohorts
CREATE OR REPLACE FUNCTION get_retention_cohorts(weeks_back INTEGER DEFAULT 12)
RETURNS TABLE (
  cohort_week DATE,
  week_0 BIGINT,
  week_1 BIGINT,
  week_2 BIGINT,
  week_3 BIGINT,
  week_4 BIGINT
) AS $$
BEGIN
  RETURN QUERY
  WITH cohorts AS (
    SELECT 
      DATE_TRUNC('week', created_at)::DATE as cohort,
      id as user_id
    FROM users
    WHERE created_at >= CURRENT_DATE - (weeks_back * 7)
      AND deleted_at IS NULL
  ),
  activity AS (
    SELECT DISTINCT
      DATE_TRUNC('week', timestamp)::DATE as activity_week,
      user_id
    FROM user_events
    WHERE timestamp >= CURRENT_DATE - (weeks_back * 7)
      AND event_category IN ('engagement', 'feature_usage', 'monetization')
  )
  SELECT 
    c.cohort as cohort_week,
    COUNT(DISTINCT c.user_id)::BIGINT as week_0,
    COUNT(DISTINCT CASE WHEN a.activity_week = c.cohort + INTERVAL '1 week' THEN a.user_id END)::BIGINT as week_1,
    COUNT(DISTINCT CASE WHEN a.activity_week = c.cohort + INTERVAL '2 weeks' THEN a.user_id END)::BIGINT as week_2,
    COUNT(DISTINCT CASE WHEN a.activity_week = c.cohort + INTERVAL '3 weeks' THEN a.user_id END)::BIGINT as week_3,
    COUNT(DISTINCT CASE WHEN a.activity_week = c.cohort + INTERVAL '4 weeks' THEN a.user_id END)::BIGINT as week_4
  FROM cohorts c
  LEFT JOIN activity a ON c.user_id = a.user_id
  GROUP BY c.cohort
  ORDER BY c.cohort DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RFM Segmentation
CREATE OR REPLACE FUNCTION calculate_rfm_segments()
RETURNS TABLE (
  segment_name TEXT,
  user_count BIGINT,
  percentage DECIMAL,
  avg_engagement_score DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  WITH user_metrics AS (
    SELECT 
      u.id as user_id,
      COALESCE(DATE_PART('day', NOW() - u.last_seen_at), 999) as days_since_last_active,
      COUNT(s.id) as session_count,
      CASE WHEN u.is_premium THEN 5 ELSE 1 END as monetary_value,
      calculate_user_engagement_score(u.id) as engagement
    FROM users u
    LEFT JOIN user_sessions s ON u.id = s.user_id
      AND s.session_start >= CURRENT_DATE - INTERVAL '90 days'
    WHERE u.deleted_at IS NULL AND u.auth_provider != 'guest'
    GROUP BY u.id, u.last_seen_at, u.is_premium
  ),
  rfm_scores AS (
    SELECT 
      user_id,
      engagement,
      CASE 
        WHEN days_since_last_active <= 7 THEN 5
        WHEN days_since_last_active <= 14 THEN 4
        WHEN days_since_last_active <= 30 THEN 3
        WHEN days_since_last_active <= 60 THEN 2
        ELSE 1
      END as recency_score,
      CASE 
        WHEN session_count >= 30 THEN 5
        WHEN session_count >= 20 THEN 4
        WHEN session_count >= 10 THEN 3
        WHEN session_count >= 5 THEN 2
        ELSE 1
      END as frequency_score,
      monetary_value as monetary_score
    FROM user_metrics
  ),
  segments AS (
    SELECT 
      user_id,
      engagement,
      CASE 
        WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 4 THEN 'Loyal Customers'
        WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New Users'
        WHEN recency_score <= 2 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'At Risk VIP'
        WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Lost'
        WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score <= 2 THEN 'Potential Premium'
        WHEN recency_score <= 3 AND frequency_score <= 3 THEN 'Needs Attention'
        ELSE 'Regular Users'
      END as segment
    FROM rfm_scores
  ),
  total_count AS (
    SELECT COUNT(*) as total FROM segments
  )
  SELECT 
    s.segment as segment_name,
    COUNT(*)::BIGINT as user_count,
    ROUND((COUNT(*)::DECIMAL / NULLIF(tc.total, 0)) * 100, 2) as percentage,
    ROUND(AVG(s.engagement), 2) as avg_engagement_score
  FROM segments s
  CROSS JOIN total_count tc
  GROUP BY s.segment, tc.total
  ORDER BY user_count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- CAMPAIGN & AD ANALYTICS
-- ============================================

-- Campaign performance
CREATE OR REPLACE FUNCTION get_campaign_performance(target_campaign_id UUID)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'impressions', COUNT(*) FILTER (WHERE interaction_type = 'impression'),
    'clicks', COUNT(*) FILTER (WHERE interaction_type = 'click'),
    'conversions', COUNT(*) FILTER (WHERE interaction_type = 'conversion'),
    'dismissals', COUNT(*) FILTER (WHERE interaction_type = 'dismiss'),
    'unique_users', COUNT(DISTINCT user_id),
    'ctr', ROUND(
      (COUNT(*) FILTER (WHERE interaction_type = 'click')::DECIMAL / 
       NULLIF(COUNT(*) FILTER (WHERE interaction_type = 'impression'), 0) * 100), 2
    ),
    'conversion_rate', ROUND(
      (COUNT(*) FILTER (WHERE interaction_type = 'conversion')::DECIMAL / 
       NULLIF(COUNT(*) FILTER (WHERE interaction_type = 'click'), 0) * 100), 2
    )
  ) INTO result
  FROM campaign_interactions
  WHERE campaign_id = target_campaign_id;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Increment session counters
CREATE OR REPLACE FUNCTION increment_session_screens(target_session_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE user_sessions 
  SET screens_viewed = screens_viewed + 1,
      events_count = events_count + 1
  WHERE id = target_session_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

GRANT EXECUTE ON FUNCTION get_dashboard_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION get_stickiness_metrics() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_activity_timeline(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_new_vs_returning(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_growth(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_user_engagement_score(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_at_risk_users(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_churn_rate(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_events(INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_feature_adoption(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_retention_cohorts(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_rfm_segments() TO authenticated;
GRANT EXECUTE ON FUNCTION get_campaign_performance(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_session_screens(UUID) TO authenticated;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$ 
BEGIN 
  RAISE NOTICE '✅ Analytics Functions Installed Successfully!';
  RAISE NOTICE '';
  RAISE NOTICE '📊 Available Functions:';
  RAISE NOTICE '  - get_dashboard_stats()';
  RAISE NOTICE '  - get_stickiness_metrics()';
  RAISE NOTICE '  - get_user_activity_timeline(user_id, days)';
  RAISE NOTICE '  - get_user_growth(days)';
  RAISE NOTICE '  - calculate_user_engagement_score(user_id)';
  RAISE NOTICE '  - get_at_risk_users(limit)';
  RAISE NOTICE '  - calculate_churn_rate(days)';
  RAISE NOTICE '  - get_feature_adoption(days)';
  RAISE NOTICE '  - get_retention_cohorts(weeks)';
  RAISE NOTICE '  - calculate_rfm_segments()';
  RAISE NOTICE '  - get_campaign_performance(campaign_id)';
  RAISE NOTICE '  - get_page_engagement_stats(days)';
  RAISE NOTICE '  - get_daily_visit_frequency(days)';
  RAISE NOTICE '';
  RAISE NOTICE '🎉 Ready to use in your admin panel!';
END $$;

-- ============================================
-- EXTRA ENGAGEMENT FUNCTIONS
-- ============================================

-- Sayfa başına geçirilen ortalama süreyi hesaplayan fonksiyon
CREATE OR REPLACE FUNCTION get_page_engagement_stats(days_back INTEGER DEFAULT 30)
RETURNS TABLE (
    page_path TEXT,
    avg_duration_seconds FLOAT,
    total_views BIGINT,
    unique_visitors BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (meta.value::TEXT) as p_path,
        AVG((metadata->>'duration_seconds')::FLOAT)::FLOAT as avg_dur,
        COUNT(*) as views,
        COUNT(DISTINCT user_id) as visitors
    FROM events, LATERAL (SELECT (metadata->>'page_path')) as meta(value)
    WHERE event_name = 'page_view'
      AND created_at > NOW() - (days_back || ' days')::INTERVAL
      AND metadata->>'page_path' IS NOT NULL
    GROUP BY 1
    ORDER BY avg_dur DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Kullanıcıların günlük giriş sıklığı dağılımını hesaplayan fonksiyon
CREATE OR REPLACE FUNCTION get_daily_visit_frequency(days_back INTEGER DEFAULT 30)
RETURNS TABLE (
    visits_per_day BIGINT,
    user_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH daily_counts AS (
        SELECT 
            user_id, 
            date_trunc('day', created_at) as day,
            COUNT(*) as visit_count
        FROM sessions
        WHERE created_at > NOW() - (days_back || ' days')::INTERVAL
        GROUP BY 1, 2
    )
    SELECT 
        visit_count::BIGINT as v_per_day,
        COUNT(DISTINCT user_id)::BIGINT as u_count
    FROM daily_counts
    GROUP BY 1
    ORDER BY 1 ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_page_engagement_stats(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_daily_visit_frequency(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_page_engagement_stats(INTEGER) TO anon;
GRANT EXECUTE ON FUNCTION get_daily_visit_frequency(INTEGER) TO anon;
GRANT EXECUTE ON FUNCTION get_page_engagement_stats(INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION get_daily_visit_frequency(INTEGER) TO service_role;
