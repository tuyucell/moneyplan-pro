-- Advanced Analytics Functions
-- Add these to your Supabase migration after the main migration

-- ============================================
-- ENHANCED ENGAGEMENT METRICS
-- ============================================

-- Get stickiness metrics (DAU/MAU, WAU/MAU, etc.)
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

-- ============================================
-- CHURN PREDICTION & AT-RISK USERS
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
  SELECT COALESCE(DATE_PART('day', NOW() - MAX(timestamp)), 999) INTO days_since_last_active
  FROM user_events
  WHERE user_id = target_user_id;
  
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
  full_name TEXT,
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
    u.full_name,
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
    AND u.account_type != 'guest'
    AND calculate_user_engagement_score(u.id) < 60
  ORDER BY 
    u.is_premium DESC, -- Premium users first
    engagement_score ASC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Calculate churn rate for a given period
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

-- Resurrection rate (users who came back after being inactive)
CREATE OR REPLACE FUNCTION get_resurrection_rate(lookback_days INTEGER DEFAULT 30)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  WITH inactive_users AS (
    -- Users who were inactive for 30+ days
    SELECT DISTINCT u.id as user_id
    FROM users u
    LEFT JOIN user_events e ON u.id = e.user_id 
      AND e.timestamp >= CURRENT_DATE - INTERVAL '60 days'
      AND e.timestamp < CURRENT_DATE - INTERVAL '30 days'
    WHERE e.user_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM user_events e2 
        WHERE e2.user_id = u.id 
          AND e2.timestamp >= CURRENT_DATE - INTERVAL '30 days'
          AND e2.timestamp < CURRENT_DATE - lookback_days
      )
  ),
  resurrected AS (
    -- Those who came back in the last lookback period
    SELECT DISTINCT iu.user_id
    FROM inactive_users iu
    INNER JOIN user_events e ON iu.user_id = e.user_id
    WHERE e.timestamp >= CURRENT_DATE - lookback_days
  )
  SELECT json_build_object(
    'total_inactive', (SELECT COUNT(*) FROM inactive_users),
    'resurrected', (SELECT COUNT(*) FROM resurrected),
    'resurrection_rate', ROUND(
      (SELECT COUNT(*) FROM resurrected)::DECIMAL / 
      NULLIF((SELECT COUNT(*) FROM inactive_users), 0) * 100, 2
    ),
    'lookback_days', lookback_days
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FEATURE ADOPTION TRACKING
-- ============================================

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
-- RFM SEGMENTATION
-- ============================================

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
    WHERE u.deleted_at IS NULL AND u.account_type != 'guest'
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
-- CONVERSION FUNNEL ANALYSIS
-- ============================================

CREATE OR REPLACE FUNCTION get_conversion_funnel()
RETURNS TABLE (
  step_name TEXT,
  step_order INTEGER,
  user_count BIGINT,
  conversion_rate DECIMAL,
  drop_off_rate DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  WITH funnel_steps AS (
    SELECT 1 as step, 'App Opens' as name, 
      (SELECT COUNT(DISTINCT user_id) FROM user_sessions WHERE session_start >= CURRENT_DATE - 30) as users
    UNION ALL
    SELECT 2, 'Viewed Content',
      (SELECT COUNT(DISTINCT user_id) FROM user_events 
       WHERE event_name = 'screen_view' AND timestamp >= CURRENT_DATE - 30)
    UNION ALL
    SELECT 3, 'Used Feature',
      (SELECT COUNT(DISTINCT user_id) FROM user_events 
       WHERE event_category = 'feature_usage' AND timestamp >= CURRENT_DATE - 30)
    UNION ALL
    SELECT 4, 'Viewed Paywall',
      (SELECT COUNT(DISTINCT user_id) FROM user_events 
       WHERE event_name = 'viewed_paywall' AND timestamp >= CURRENT_DATE - 30)
    UNION ALL
    SELECT 5, 'Premium Upgrade',
      (SELECT COUNT(*) FROM users WHERE is_premium = TRUE 
       AND premium_started_at >= CURRENT_DATE - 30)
  ),
  with_conversion AS (
    SELECT 
      name,
      step,
      users,
      users::DECIMAL / NULLIF(FIRST_VALUE(users) OVER (ORDER BY step), 0) * 100 as conv_rate,
      LAG(users) OVER (ORDER BY step) as prev_users
    FROM funnel_steps
  )
  SELECT 
    name as step_name,
    step as step_order,
    users as user_count,
    ROUND(conv_rate, 2) as conversion_rate,
    ROUND(
      CASE 
        WHEN prev_users IS NOT NULL AND prev_users > 0
        THEN ((prev_users - users)::DECIMAL / prev_users * 100)
        ELSE 0 
      END, 2
    ) as drop_off_rate
  FROM with_conversion
  ORDER BY step;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PREDICTIVE ANALYTICS
-- ============================================

-- Predict user LTV (simplified version - can be ML-based in production)
CREATE OR REPLACE FUNCTION predict_user_ltv(target_user_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  avg_session_count DECIMAL;
  engagement_score INTEGER;
  is_premium BOOLEAN;
  days_active INTEGER;
  predicted_ltv DECIMAL := 0;
BEGIN
  SELECT 
    COUNT(s.id)::DECIMAL,
    calculate_user_engagement_score(target_user_id),
    u.is_premium,
    DATE_PART('day', NOW() - u.created_at)
  INTO avg_session_count, engagement_score, is_premium, days_active
  FROM users u
  LEFT JOIN user_sessions s ON u.id = s.user_id
  WHERE u.id = target_user_id
  GROUP BY u.id, u.is_premium, u.created_at;
  
  IF is_premium THEN
    predicted_ltv := 50; -- Base premium value
    predicted_ltv := predicted_ltv + (engagement_score * 0.5);
    predicted_ltv := predicted_ltv + (avg_session_count * 0.1);
    predicted_ltv := predicted_ltv + (days_active * 0.05);
  ELSE
    predicted_ltv := 5; -- Base free user value
    predicted_ltv := predicted_ltv + (engagement_score * 0.1);
    
    -- High engagement free users have conversion potential
    IF engagement_score > 60 THEN
      predicted_ltv := predicted_ltv + 15;
    END IF;
  END IF;
  
  RETURN ROUND(predicted_ltv, 2);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Predict conversion probability (0-100)
CREATE OR REPLACE FUNCTION predict_conversion_probability(target_user_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  engagement INTEGER;
  session_count INTEGER;
  days_since_signup INTEGER;
  viewed_paywall BOOLEAN;
  used_premium_feature BOOLEAN;
  probability DECIMAL := 0;
BEGIN
  SELECT 
    calculate_user_engagement_score(target_user_id),
    COUNT(s.id),
    DATE_PART('day', NOW() - u.created_at),
    EXISTS(
      SELECT 1 FROM user_events 
      WHERE user_id = target_user_id 
        AND event_name = 'viewed_paywall'
    ),
    EXISTS(
      SELECT 1 FROM user_events 
      WHERE user_id = target_user_id 
        AND properties->>'is_premium_feature' = 'true'
    )
  INTO engagement, session_count, days_since_signup, viewed_paywall, used_premium_feature
  FROM users u
  LEFT JOIN user_sessions s ON u.id = s.user_id
  WHERE u.id = target_user_id
  GROUP BY u.id, u.created_at;
  
  -- Base probability
  probability := 5;
  
  -- Engagement multiplier
  IF engagement > 70 THEN probability := probability + 35;
  ELSIF engagement > 50 THEN probability := probability + 25;
  ELSIF engagement > 30 THEN probability := probability + 15;
  END IF;
  
  -- Session frequency
  IF session_count > 30 THEN probability := probability + 20;
  ELSIF session_count > 15 THEN probability := probability + 12;
  ELSIF session_count > 5 THEN probability := probability + 5;
  END IF;
  
  -- Intent signals
  IF viewed_paywall THEN probability := probability + 25; END IF;
  IF used_premium_feature THEN probability := probability + 15; END IF;
  
  -- Sweet spot for conversion (days 3-14)
  IF days_since_signup BETWEEN 3 AND 14 THEN 
    probability := probability + 15;
  ELSIF days_since_signup BETWEEN 15 AND 30 THEN
    probability := probability + 8;
  END IF;
  
  RETURN LEAST(ROUND(probability, 2), 100);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ANOMALY DETECTION
-- ============================================

CREATE OR REPLACE FUNCTION detect_metric_anomalies()
RETURNS TABLE (
  metric_name TEXT,
  current_value DECIMAL,
  expected_min DECIMAL,
  expected_max DECIMAL,
  severity TEXT,
  deviation_percentage DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  WITH dau_history AS (
    SELECT 
      DATE(timestamp) as date,
      COUNT(DISTINCT user_id)::DECIMAL as value
    FROM user_events
    WHERE timestamp >= CURRENT_DATE - INTERVAL '30 days'
      AND timestamp < CURRENT_DATE
      AND event_category IN ('engagement', 'feature_usage', 'monetization')
    GROUP BY DATE(timestamp)
  ),
  dau_stats AS (
    SELECT 
      AVG(value) as mean,
      STDDEV(value) as stddev
    FROM dau_history
  ),
  current_dau AS (
    SELECT 
      COUNT(DISTINCT user_id)::DECIMAL as value
    FROM user_events
    WHERE timestamp >= CURRENT_DATE
      AND event_category IN ('engagement', 'feature_usage', 'monetization')
  )
  SELECT 
    'DAU'::TEXT as metric_name,
    cd.value as current_value,
    (ds.mean - 2 * ds.stddev) as expected_min,
    (ds.mean + 2 * ds.stddev) as expected_max,
    CASE 
      WHEN cd.value < (ds.mean - 2 * ds.stddev) OR cd.value > (ds.mean + 2 * ds.stddev) THEN 'HIGH'
      WHEN cd.value < (ds.mean - ds.stddev) OR cd.value > (ds.mean + ds.stddev) THEN 'MEDIUM'
      ELSE 'LOW'
    END as severity,
    ROUND(((cd.value - ds.mean) / NULLIF(ds.mean, 0)) * 100, 2) as deviation_percentage
  FROM current_dau cd
  CROSS JOIN dau_stats ds
  WHERE cd.value < (ds.mean - ds.stddev) OR cd.value > (ds.mean + ds.stddev);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_stickiness_metrics() TO authenticated;
GRANT EXECUTE ON FUNCTION get_new_vs_returning(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_user_engagement_score(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_at_risk_users(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_churn_rate(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_resurrection_rate(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_feature_adoption(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_rfm_segments() TO authenticated;
GRANT EXECUTE ON FUNCTION get_conversion_funnel() TO authenticated;
GRANT EXECUTE ON FUNCTION predict_user_ltv(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION predict_conversion_probability(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION detect_metric_anomalies() TO authenticated;
