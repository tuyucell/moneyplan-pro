-- Drop the existing function first to avoid parameter name conflict errors
DROP FUNCTION IF EXISTS get_page_engagement_stats(integer);

-- Fix get_page_engagement_stats function to use correct table and columns
-- Using p_days_back to match the frontend/client call signature
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
        (properties->>'page_path')::TEXT as p_path,
        AVG((properties->>'duration_seconds')::FLOAT)::FLOAT as avg_dur,
        COUNT(*) as views,
        COUNT(DISTINCT user_id) as visitors
    FROM user_events
    WHERE event_name = 'page_view'
      AND timestamp > NOW() - (p_days_back || ' days')::INTERVAL
      AND properties->>'page_path' IS NOT NULL
      AND properties->>'duration_seconds' IS NOT NULL
    GROUP BY 1
    ORDER BY avg_dur DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Generate Test Data for Demographics
-- We will update existing users with random demographics to ensure we have diverse data
UPDATE users 
SET 
  gender = (ARRAY['Male', 'Female', 'Non-binary', 'Not Specified'])[floor(random() * 4 + 1)],
  risk_tolerance = (ARRAY['Conservative', 'Moderate', 'Aggressive', 'Very Aggressive'])[floor(random() * 4 + 1)],
  financial_goal = (ARRAY['Retirement', 'Home Purchase', 'Wealth Building', 'Education', 'Travel'])[floor(random() * 5 + 1)],
  occupation = (ARRAY['Engineer', 'Doctor', 'Teacher', 'Designer', 'Manager', 'Student', 'Freelancer'])[floor(random() * 7 + 1)],
  birth_year = floor(random() * (2005 - 1960 + 1) + 1960)::int
WHERE gender IS NULL OR risk_tolerance IS NULL;

-- If we don't have enough users, let's create some dummy users
DO $$
DECLARE
  new_user_id UUID;
  i INTEGER;
BEGIN
  FOR i IN 1..50 LOOP
    -- Use display_name instead of full_name
    INSERT INTO users (email, display_name, is_active, is_premium, created_at, last_seen_at)
    VALUES (
      'test_user_' || i || '_' || floor(random()*1000)::text || '@example.com',
      'Test User ' || i,
      true,
      (random() > 0.8), -- 20% premium
      NOW() - (random() * 30 || ' days')::INTERVAL,
      NOW() - (random() * 7 || ' days')::INTERVAL
    ) RETURNING id INTO new_user_id;
    
    -- Add demographics for this new user
    UPDATE users SET
      gender = (ARRAY['Male', 'Female', 'Non-binary', 'Not Specified'])[floor(random() * 4 + 1)],
      risk_tolerance = (ARRAY['Conservative', 'Moderate', 'Aggressive', 'Very Aggressive'])[floor(random() * 4 + 1)],
      financial_goal = (ARRAY['Retirement', 'Home Purchase', 'Wealth Building', 'Education', 'Travel'])[floor(random() * 5 + 1)],
      occupation = (ARRAY['Engineer', 'Doctor', 'Teacher', 'Designer', 'Manager', 'Student', 'Freelancer'])[floor(random() * 7 + 1)],
      birth_year = floor(random() * (2005 - 1960 + 1) + 1960)::int
    WHERE id = new_user_id;
    
    -- Generate Page View Events for this user
    -- Dashboard views
    INSERT INTO user_events (user_id, event_name, event_category, properties, timestamp)
    SELECT 
      new_user_id,
      'page_view',
      'navigation',
      jsonb_build_object(
        'page_path', '/dashboard',
        'duration_seconds', floor(random() * 300 + 30) -- 30s to 5m
      ),
      NOW() - (random() * 7 || ' days')::INTERVAL
    FROM generate_series(1, floor(random() * 10 + 1)::int);

    -- Analytics views
    INSERT INTO user_events (user_id, event_name, event_category, properties, timestamp)
    SELECT 
      new_user_id,
      'page_view',
      'navigation',
      jsonb_build_object(
        'page_path', '/analytics',
        'duration_seconds', floor(random() * 600 + 60) -- 1m to 10m
      ),
      NOW() - (random() * 7 || ' days')::INTERVAL
    FROM generate_series(1, floor(random() * 5 + 1)::int);

    -- Settings views
    INSERT INTO user_events (user_id, event_name, event_category, properties, timestamp)
    SELECT 
      new_user_id,
      'page_view',
      'navigation',
      jsonb_build_object(
        'page_path', '/settings',
        'duration_seconds', floor(random() * 120 + 20) -- 20s to 2m
      ),
      NOW() - (random() * 7 || ' days')::INTERVAL
    FROM generate_series(1, floor(random() * 3 + 1)::int);
    
    -- Portfolio views
    INSERT INTO user_events (user_id, event_name, event_category, properties, timestamp)
    SELECT 
      new_user_id,
      'page_view',
      'navigation',
      jsonb_build_object(
        'page_path', '/portfolio',
        'duration_seconds', floor(random() * 900 + 120) -- 2m to 15m
      ),
      NOW() - (random() * 7 || ' days')::INTERVAL
    FROM generate_series(1, floor(random() * 8 + 1)::int);

  END LOOP;
END $$;
