-- ============================================
-- InvestGuide Cleanup & Real User Data Fix
-- This script removes dummy data and prepares real users for the Admin Panel
-- ============================================

-- 1. Ensure engagement_score column exists in users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS engagement_score INTEGER DEFAULT 0;

-- 2. Delete Dummy Users and their associated data
-- We identify test users by their email pattern or specific IDs
DO $$
DECLARE
    dummy_user_ids UUID[];
BEGIN
    -- Collect IDs of dummy users
    SELECT array_agg(id) INTO dummy_user_ids 
    FROM users 
    WHERE email LIKE 'test_user_%@example.com' 
       OR email LIKE 'test%@example.com'
       OR display_name LIKE 'Test User%';

    IF dummy_user_ids IS NOT NULL THEN
        -- Delete from dependent tables first
        DELETE FROM user_events WHERE user_id = ANY(dummy_user_ids);
        DELETE FROM user_sessions WHERE user_id = ANY(dummy_user_ids);
        DELETE FROM audit_logs WHERE user_id = ANY(dummy_user_ids);
        DELETE FROM price_alerts WHERE user_id = ANY(dummy_user_ids);
        -- Notifications are in SQLite (Backend), skipping here.
        
        -- Delete users
        DELETE FROM users WHERE id = ANY(dummy_user_ids);
        
        RAISE NOTICE 'Deleted % dummy users and their data.', array_length(dummy_user_ids, 1);
    ELSE
        RAISE NOTICE 'No dummy users found to delete.';
    END IF;
END $$;

-- 3. Recalculate Engagement Scores for REAL users
-- This uses the logic from calculate_user_engagement_score()
UPDATE users 
SET engagement_score = calculate_user_engagement_score(id)
WHERE deleted_at IS NULL;

-- 4. Clean up generic dummy events if any (not associated with dummy users but created for testing)
-- For example, page views without a valid user ID or with hardcoded dummy paths
DELETE FROM user_events 
WHERE properties->>'page_path' LIKE '/test/%';

-- 5. Ensure the get_user_activity_timeline function is the latest version
DROP FUNCTION IF EXISTS get_user_activity_timeline(UUID, INTEGER);

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

-- 6. Grant permissions
GRANT EXECUTE ON FUNCTION get_user_activity_timeline(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_user_engagement_score(UUID) TO authenticated;

DO $$
BEGIN
  RAISE NOTICE '✅ Cleanup and Real Data Sync Completed Successfully!';
END $$;
