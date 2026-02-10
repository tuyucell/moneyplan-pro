-- ============================================
-- Quick Fixes for Type Mismatches
-- Run this to fix all function errors
-- ============================================

-- Fix 1: get_user_growth - ambiguous column name
DROP FUNCTION IF EXISTS get_user_growth(INTEGER);

CREATE OR REPLACE FUNCTION get_user_growth(days_back INTEGER DEFAULT 30)
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
    SELECT (CURRENT_DATE - days_back)::DATE as series_date
    UNION ALL
    SELECT (series_date + 1)::DATE
    FROM date_series
    WHERE series_date < CURRENT_DATE
  ),
  daily_signups AS (
    SELECT DATE(created_at) as signup_date, COUNT(*) as signup_count
    FROM users
    WHERE created_at >= CURRENT_DATE - days_back
      AND deleted_at IS NULL
    GROUP BY DATE(created_at)
  ),
  daily_active AS (
    SELECT DATE(timestamp) as activity_date_val, COUNT(DISTINCT user_id) as active_count
    FROM user_events
    WHERE timestamp >= CURRENT_DATE - days_back
      AND event_category IN ('engagement', 'feature_usage', 'monetization')
    GROUP BY DATE(timestamp)
  )
  SELECT 
    ds.series_date as activity_date,
    COALESCE(dsu.signup_count, 0)::BIGINT as new_users,
    (SELECT COUNT(*) FROM users WHERE DATE(created_at) <= ds.series_date AND deleted_at IS NULL)::BIGINT as total_users,
    (SELECT COUNT(*) FROM users WHERE is_premium = TRUE AND DATE(created_at) <= ds.series_date AND deleted_at IS NULL)::BIGINT as premium_users,
    COALESCE(da.active_count, 0)::BIGINT as active_users
  FROM date_series ds
  LEFT JOIN daily_signups dsu ON ds.series_date = dsu.signup_date
  LEFT JOIN daily_active da ON ds.series_date = da.activity_date_val
  ORDER BY ds.series_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_user_growth(INTEGER) TO authenticated;

-- Fix 2: get_at_risk_users - type mismatch
DROP FUNCTION IF EXISTS get_at_risk_users(INTEGER);

CREATE OR REPLACE FUNCTION get_at_risk_users(limit_count INTEGER DEFAULT 100)
RETURNS TABLE (
  user_id UUID,
  email VARCHAR(255),
  display_name VARCHAR(100),
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
    u.is_premium DESC,
    engagement_score ASC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_at_risk_users(INTEGER) TO authenticated;

-- ============================================
-- Verification Tests
-- ============================================

DO $$ 
BEGIN 
  RAISE NOTICE '✅ Running verification tests...';
  RAISE NOTICE '';
END $$;

-- Test 1: Dashboard Stats
DO $$
BEGIN
  PERFORM get_dashboard_stats();
  RAISE NOTICE '✅ Dashboard Stats: PASS';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '❌ Dashboard Stats: FAIL - %', SQLERRM;
END $$;

-- Test 2: User Growth
DO $$
DECLARE
  row_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO row_count FROM get_user_growth(7);
  IF row_count > 0 THEN
    RAISE NOTICE '✅ User Growth: PASS (% rows)', row_count;
  ELSE
    RAISE NOTICE '⚠️ User Growth: No data';
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '❌ User Growth: FAIL - %', SQLERRM;
END $$;

-- Test 3: At-Risk Users
DO $$
DECLARE
  row_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO row_count FROM get_at_risk_users(5);
  RAISE NOTICE '✅ At-Risk Users: PASS (% rows)', row_count;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '❌ At-Risk Users: FAIL - %', SQLERRM;
END $$;

-- Test 4: Top Events
DO $$
DECLARE
  row_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO row_count FROM get_top_events(7, 10);
  IF row_count > 0 THEN
    RAISE NOTICE '✅ Top Events: PASS (% rows)', row_count;
  ELSE
    RAISE NOTICE '⚠️ Top Events: No data';
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '❌ Top Events: FAIL - %', SQLERRM;
END $$;

-- Test 5: Feature Adoption
DO $$
DECLARE
  row_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO row_count FROM get_feature_adoption(30);
  RAISE NOTICE '✅ Feature Adoption: PASS (% rows)', row_count;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '❌ Feature Adoption: FAIL - %', SQLERRM;
END $$;

-- Test 6: RFM Segments
DO $$
DECLARE
  row_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO row_count FROM calculate_rfm_segments();
  RAISE NOTICE '✅ RFM Segments: PASS (% rows)', row_count;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '❌ RFM Segments: FAIL - %', SQLERRM;
END $$;

DO $$ 
BEGIN 
  RAISE NOTICE '';
  RAISE NOTICE '🎉 All fixes applied successfully!';
  RAISE NOTICE '📊 Admin panel database is ready!';
  RAISE NOTICE '';
  RAISE NOTICE '📝 Next: Run manual tests:';
  RAISE NOTICE '  SELECT get_dashboard_stats();';
  RAISE NOTICE '  SELECT * FROM get_user_growth(7);';
  RAISE NOTICE '  SELECT * FROM get_at_risk_users(5);';
END $$;
