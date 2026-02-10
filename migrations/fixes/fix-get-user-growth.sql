-- Fix for get_user_growth function
-- Replace the existing function

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

-- Verify it works
SELECT * FROM get_user_growth(7) LIMIT 3;
