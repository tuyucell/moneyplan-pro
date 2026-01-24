-- InvestGuide Admin Panel - Live Monitor Functions
-- Fixed version to avoid PostgreSQL reserved keyword issues

-- 1. Live Stats Function
CREATE OR REPLACE FUNCTION get_live_active_users()
RETURNS TABLE (
  active_count INTEGER,
  premium_count INTEGER,
  latest_event_time TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT u.id)::INTEGER as active_count,
    COUNT(DISTINCT u.id) FILTER (WHERE u.is_premium = TRUE)::INTEGER as premium_count,
    MAX(e.timestamp) as latest_event_time
  FROM users u
  JOIN user_events e ON e.user_id = u.id
  WHERE e.timestamp >= NOW() - INTERVAL '5 minutes';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Live Event Feed Function
CREATE OR REPLACE FUNCTION get_live_event_feed(p_limit INTEGER DEFAULT 30)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  email TEXT,
  event_name TEXT,
  screen_name TEXT,
  properties JSONB,
  event_timestamp TIMESTAMPTZ -- Renamed from 'timestamp' to avoid keyword conflict
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id,
    e.user_id,
    u.email,
    e.event_name,
    e.screen_name,
    e.properties,
    e.timestamp as event_timestamp
  FROM user_events e
  JOIN users u ON e.user_id = u.id
  ORDER BY e.timestamp DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add indexes if they don't exist to speed up live queries
CREATE INDEX IF NOT EXISTS idx_user_events_timestamp_desc ON user_events(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_users_is_premium_id ON users(is_premium, id);
