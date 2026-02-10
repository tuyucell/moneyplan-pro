-- Fix type mismatch in get_at_risk_users function

DROP FUNCTION IF EXISTS get_at_risk_users(INTEGER);

CREATE OR REPLACE FUNCTION get_at_risk_users(limit_count INTEGER DEFAULT 100)
RETURNS TABLE (
  user_id UUID,
  email VARCHAR(255),  -- Changed from TEXT to match users table
  display_name VARCHAR(100),  -- Changed from TEXT to match users table
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

GRANT EXECUTE ON FUNCTION get_at_risk_users(INTEGER) TO authenticated;

-- Test it
SELECT * FROM get_at_risk_users(5);
