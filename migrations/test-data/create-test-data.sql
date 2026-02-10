-- ============================================
-- Test Data for Admin Panel
-- Create sample users, sessions, and events
-- ============================================

-- Insert sample users (use existing users table structure)
DO $$ 
DECLARE
  user_ids UUID[] := ARRAY[]::UUID[];
  sample_user_id UUID;
  i INTEGER;
BEGIN
  -- Create 50 sample users
  FOR i IN 1..50 LOOP
    INSERT INTO users (
      email,
      display_name,
      auth_provider,
      is_premium,
      is_active,
      preferred_language,
      preferred_currency,
      created_at,
      last_seen_at,
      device_info
    ) VALUES (
      'user' || i || '@test.com',
      'Test User ' || i,
      CASE 
        WHEN i % 4 = 0 THEN 'google'
        WHEN i % 4 = 1 THEN 'email'
        WHEN i % 4 = 2 THEN 'apple'
        ELSE 'guest'
      END,
      i % 5 = 0, -- Every 5th user is premium
      TRUE,
      CASE WHEN i % 3 = 0 THEN 'en' ELSE 'tr' END,
      'TRY',
      NOW() - (random() * INTERVAL '30 days'), -- Random creation date in last 30 days
      NOW() - (random() * INTERVAL '7 days'),  -- Random last seen in last 7 days
      jsonb_build_object(
        'platform', CASE WHEN random() > 0.5 THEN 'ios' ELSE 'android' END,
        'app_version', '1.0.0',
        'device_model', 'Test Device'
      )
    )
    RETURNING id INTO sample_user_id;
    
    user_ids := array_append(user_ids, sample_user_id);
  END LOOP;

  RAISE NOTICE '✅ Created 50 sample users';

  -- Create sessions for users
  FOR i IN 1..array_length(user_ids, 1) LOOP
    -- Each user has 2-10 sessions
    FOR j IN 1..(2 + floor(random() * 8)::INTEGER) LOOP
      DECLARE
        session_id UUID;
        session_start TIMESTAMPTZ;
        session_duration INTEGER;
      BEGIN
        session_start := NOW() - (random() * INTERVAL '30 days');
        session_duration := 60 + floor(random() * 600)::INTEGER; -- 1-11 minutes
        
        INSERT INTO user_sessions (
          user_id,
          session_start,
          session_end,
          duration_seconds,
          platform,
          app_version,
          screens_viewed,
          events_count
        ) VALUES (
          user_ids[i],
          session_start,
          session_start + (session_duration || ' seconds')::INTERVAL,
          session_duration,
          CASE WHEN random() > 0.5 THEN 'ios' ELSE 'android' END,
          '1.0.' || floor(random() * 10)::TEXT,
          floor(random() * 20)::INTEGER,
          floor(random() * 30)::INTEGER
        )
        RETURNING id INTO session_id;
        
        -- Create events for this session
        FOR k IN 1..(5 + floor(random() * 15)::INTEGER) LOOP
          INSERT INTO user_events (
            user_id,
            session_id,
            event_name,
            event_category,
            screen_name,
            properties,
            timestamp
          ) VALUES (
            user_ids[i],
            session_id,
            CASE floor(random() * 10)::INTEGER
              WHEN 0 THEN 'ai_chat_message'
              WHEN 1 THEN 'portfolio_updated'
              WHEN 2 THEN 'market_data_viewed'
              WHEN 3 THEN 'asset_searched'
              WHEN 4 THEN 'price_alert_created'
              WHEN 5 THEN 'exchange_viewed'
              WHEN 6 THEN 'transaction_added'
              WHEN 7 THEN 'reminder_created'
              WHEN 8 THEN 'settings_changed'
              ELSE 'screen_view'
            END,
            CASE floor(random() * 4)::INTEGER
              WHEN 0 THEN 'navigation'
              WHEN 1 THEN 'engagement'
              WHEN 2 THEN 'feature_usage'
              ELSE 'monetization'
            END,
            CASE floor(random() * 6)::INTEGER
              WHEN 0 THEN 'HomeScreen'
              WHEN 1 THEN 'PortfolioScreen'
              WHEN 2 THEN 'MarketScreen'
              WHEN 3 THEN 'AIAssistantScreen'
              WHEN 4 THEN 'ProfileScreen'
              ELSE 'SettingsScreen'
            END,
            jsonb_build_object(
              'source', 'test_data',
              'value', floor(random() * 100)::INTEGER
            ),
            session_start + (floor(random() * session_duration)::INTEGER || ' seconds')::INTERVAL
          );
        END LOOP;
      END;
    END LOOP;
  END LOOP;

  RAISE NOTICE '✅ Created sessions and events';

  -- Create sample campaigns
  FOR i IN 1..5 LOOP
    DECLARE
      campaign_id UUID;
    BEGIN
      INSERT INTO campaigns (
        name,
        description,
        type,
        starts_at,
        ends_at,
        is_active,
        config,
        total_impressions,
        total_clicks,
        total_conversions
      ) VALUES (
        'Campaign ' || i,
        'Sample campaign ' || i || ' description',
        CASE i % 5
          WHEN 0 THEN 'discount'
          WHEN 1 THEN 'bonus'
          WHEN 2 THEN 'feature_unlock'
          WHEN 3 THEN 'trial'
          ELSE 'promotion'
        END,
        NOW() - INTERVAL '15 days',
        NOW() + INTERVAL '15 days',
        i <= 3, -- First 3 active
        jsonb_build_object(
          'discount_percent', 20,
          'duration_days', 30
        ),
        floor(random() * 1000)::INTEGER,
        floor(random() * 100)::INTEGER,
        floor(random() * 20)::INTEGER
      )
      RETURNING id INTO campaign_id;
      
      -- Add some interactions
      FOR j IN 1..10 LOOP
        INSERT INTO campaign_interactions (
          campaign_id,
          user_id,
          interaction_type,
          created_at
        ) VALUES (
          campaign_id,
          user_ids[1 + floor(random() * array_length(user_ids, 1))::INTEGER],
          CASE floor(random() * 4)::INTEGER
            WHEN 0 THEN 'impression'
            WHEN 1 THEN 'click'
            WHEN 2 THEN 'conversion'
            ELSE 'dismiss'
          END,
          NOW() - (random() * INTERVAL '15 days')
        );
      END LOOP;
    END;
  END LOOP;

  RAISE NOTICE '✅ Created 5 campaigns with interactions';

  -- Create sample ads
  FOR i IN 1..3 LOOP
    DECLARE
      ad_id UUID;
    BEGIN
      INSERT INTO ads (
        title,
        description,
        cta_text,
        placement,
        starts_at,
        ends_at,
        is_active,
        impressions,
        clicks
      ) VALUES (
        'Ad ' || i,
        'Sample ad ' || i || ' compelling description',
        'Learn More',
        CASE i % 5
          WHEN 0 THEN 'home_banner'
          WHEN 1 THEN 'sidebar'
          WHEN 2 THEN 'modal'
          WHEN 3 THEN 'native'
          ELSE 'interstitial'
        END,
        NOW() - INTERVAL '10 days',
        NOW() + INTERVAL '20 days',
        TRUE,
        floor(random() * 500)::INTEGER,
        floor(random() * 50)::INTEGER
      )
      RETURNING id INTO ad_id;
      
      -- Add impressions
      FOR j IN 1..5 LOOP
        INSERT INTO ad_impressions (
          ad_id,
          user_id,
          clicked,
          clicked_at,
          created_at
        ) VALUES (
          ad_id,
          user_ids[1 + floor(random() * array_length(user_ids, 1))::INTEGER],
          random() > 0.7,
          CASE WHEN random() > 0.7 THEN NOW() - (random() * INTERVAL '10 days') ELSE NULL END,
          NOW() - (random() * INTERVAL '10 days')
        );
      END LOOP;
    END;
  END LOOP;

  RAISE NOTICE '✅ Created 3 ads with impressions';

  -- Create sample push notifications
  FOR i IN 1..4 LOOP
    INSERT INTO push_notifications (
      title,
      body,
      target_type,
      status,
      scheduled_for,
      sent_at,
      total_sent,
      total_delivered,
      total_opened,
      total_clicked
    ) VALUES (
      'Notification ' || i,
      'Sample push notification ' || i || ' body text',
      CASE i % 3
        WHEN 0 THEN 'all'
        WHEN 1 THEN 'segment'
        ELSE 'individual'
      END,
      CASE i % 4
        WHEN 0 THEN 'sent'
        WHEN 1 THEN 'draft'
        WHEN 2 THEN 'scheduled'
        ELSE 'sent'
      END,
      NOW() + (i || ' days')::INTERVAL,
      CASE WHEN i % 2 = 0 THEN NOW() - INTERVAL '5 days' ELSE NULL END,
      CASE WHEN i % 2 = 0 THEN floor(random() * 100)::INTEGER ELSE 0 END,
      CASE WHEN i % 2 = 0 THEN floor(random() * 90)::INTEGER ELSE 0 END,
      CASE WHEN i % 2 = 0 THEN floor(random() * 40)::INTEGER ELSE 0 END,
      CASE WHEN i % 2 = 0 THEN floor(random() * 20)::INTEGER ELSE 0 END
    );
  END LOOP;

  RAISE NOTICE '✅ Created 4 push notifications';
  RAISE NOTICE '';
  RAISE NOTICE '🎉 Test data creation complete!';
  RAISE NOTICE '📊 Summary:';
  RAISE NOTICE '  - 50 users (10 premium, 40 free)';
  RAISE NOTICE '  - ~300 sessions';
  RAISE NOTICE '  - ~3000 events';
  RAISE NOTICE '  - 5 campaigns';
  RAISE NOTICE '  - 3 ads';
  RAISE NOTICE '  - 4 push notifications';
END $$;

-- Update users table last_seen_at based on latest event
UPDATE users u
SET last_seen_at = (
  SELECT MAX(timestamp)
  FROM user_events e
  WHERE e.user_id = u.id
)
WHERE EXISTS (
  SELECT 1 FROM user_events WHERE user_id = u.id
);

-- Verify test data
SELECT 
  'Users' as table_name,
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE is_premium = TRUE) as premium_count
FROM users
UNION ALL
SELECT 
  'Sessions',
  COUNT(*),
  NULL
FROM user_sessions
UNION ALL
SELECT 
  'Events',
  COUNT(*),
  NULL
FROM user_events
UNION ALL
SELECT 
  'Campaigns',
  COUNT(*),
  COUNT(*) FILTER (WHERE is_active = TRUE)
FROM campaigns
UNION ALL
SELECT 
  'Ads',
  COUNT(*),
  COUNT(*) FILTER (WHERE is_active = TRUE)
FROM ads;

-- Test dashboard stats with real data
SELECT get_dashboard_stats();
