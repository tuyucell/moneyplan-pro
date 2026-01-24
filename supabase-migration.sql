-- InvestGuide Admin Panel - Supabase Migration
-- Run this to create all necessary tables, functions, and policies

-- ============================================
-- EXTENSIONS
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- ============================================
-- TABLES
-- ============================================

-- Users table (Mobile app users)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE,
  full_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  
  -- Account type
  account_type TEXT CHECK (account_type IN ('guest', 'email', 'google', 'apple')) DEFAULT 'email',
  is_premium BOOLEAN DEFAULT FALSE,
  premium_expires_at TIMESTAMPTZ,
  premium_started_at TIMESTAMPTZ,
  
  -- Metadata
  locale TEXT DEFAULT 'tr',
  timezone TEXT DEFAULT 'Europe/Istanbul',
  device_info JSONB DEFAULT '{}'::JSONB,
  fcm_token TEXT,
  apns_token TEXT,
  
  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  is_banned BOOLEAN DEFAULT FALSE,
  ban_reason TEXT,
  banned_at TIMESTAMPTZ,
  banned_by UUID,

  -- User Demographics
  birth_year INTEGER,
  gender TEXT,
  occupation TEXT,
  financial_goal TEXT,
  risk_tolerance TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_seen_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  
  -- Constraints
  CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' OR email IS NULL)
);

-- User sessions
CREATE TABLE IF NOT EXISTS user_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  
  session_start TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  session_end TIMESTAMPTZ,
  duration_seconds INTEGER,
  
  -- Session metadata
  device_info JSONB DEFAULT '{}'::JSONB,
  app_version TEXT,
  platform TEXT CHECK (platform IN ('ios', 'android', 'web')),
  
  -- Engagement
  screens_viewed INTEGER DEFAULT 0,
  events_count INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User events (Tracking)
CREATE TABLE IF NOT EXISTS user_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  session_id UUID REFERENCES user_sessions(id) ON DELETE CASCADE,
  
  -- Event details
  event_name TEXT NOT NULL,
  event_category TEXT CHECK (event_category IN ('navigation', 'engagement', 'monetization', 'feature_usage', 'error', 'performance')),
  
  -- Event data
  properties JSONB DEFAULT '{}'::JSONB,
  screen_name TEXT,
  
  -- Context
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT valid_event_name CHECK (LENGTH(event_name) > 0)
);

-- Campaigns
CREATE TABLE IF NOT EXISTS campaigns (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Campaign details
  name TEXT NOT NULL,
  description TEXT,
  type TEXT CHECK (type IN ('discount', 'bonus', 'feature_unlock', 'trial', 'promotion')) NOT NULL,
  
  -- Targeting
  target_segment JSONB DEFAULT '{}'::JSONB,
  target_user_ids UUID[],
  
  -- Campaign configuration
  config JSONB DEFAULT '{}'::JSONB,
  
  -- Scheduling
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  
  -- Metrics (denormalized for performance)
  total_impressions INTEGER DEFAULT 0,
  total_clicks INTEGER DEFAULT 0,
  total_conversions INTEGER DEFAULT 0,
  
  -- Metadata
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT valid_dates CHECK (ends_at IS NULL OR ends_at > starts_at)
);

-- Campaign interactions
CREATE TABLE IF NOT EXISTS campaign_interactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  
  interaction_type TEXT CHECK (interaction_type IN ('impression', 'click', 'conversion', 'dismiss')) NOT NULL,
  
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ads
CREATE TABLE IF NOT EXISTS ads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Ad content
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  cta_text TEXT,
  cta_url TEXT,
  
  -- Targeting
  target_segment JSONB DEFAULT '{}'::JSONB,
  placement TEXT CHECK (placement IN ('home_banner', 'sidebar', 'modal', 'native', 'interstitial')) NOT NULL,
  
  -- Scheduling
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  
  -- Display rules
  frequency_cap INTEGER DEFAULT 3,
  priority INTEGER DEFAULT 0,
  
  -- Metrics
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT valid_dates CHECK (ends_at IS NULL OR ends_at > starts_at)
);

-- Ad impressions
CREATE TABLE IF NOT EXISTS ad_impressions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ad_id UUID REFERENCES ads(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  
  clicked BOOLEAN DEFAULT FALSE,
  clicked_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Push notifications
CREATE TABLE IF NOT EXISTS push_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Notification content
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  image_url TEXT,
  deep_link TEXT,
  action_buttons JSONB DEFAULT '[]'::JSONB,
  
  -- Targeting
  target_type TEXT CHECK (target_type IN ('all', 'segment', 'individual')) NOT NULL,
  target_segment JSONB DEFAULT '{}'::JSONB,
  target_user_ids UUID[],
  
  -- Scheduling
  scheduled_for TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  status TEXT CHECK (status IN ('draft', 'scheduled', 'sending', 'sent', 'failed')) DEFAULT 'draft',
  
  -- Metrics
  total_sent INTEGER DEFAULT 0,
  total_delivered INTEGER DEFAULT 0,
  total_failed INTEGER DEFAULT 0,
  total_opened INTEGER DEFAULT 0,
  total_clicked INTEGER DEFAULT 0,
  
  -- Metadata
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Push notification logs
CREATE TABLE IF NOT EXISTS push_notification_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  notification_id UUID REFERENCES push_notifications(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  
  -- Delivery status
  status TEXT CHECK (status IN ('sent', 'delivered', 'failed', 'opened', 'clicked')) NOT NULL,
  error_message TEXT,
  
  -- Timestamps
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  opened_at TIMESTAMPTZ,
  clicked_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Admin users
CREATE TABLE IF NOT EXISTS admin_users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  role TEXT CHECK (role IN ('super_admin', 'admin', 'analyst', 'content_manager')) NOT NULL,
  
  permissions JSONB DEFAULT '{}'::JSONB,
  is_active BOOLEAN DEFAULT TRUE,
  
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Admin activity logs
CREATE TABLE IF NOT EXISTS admin_activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID REFERENCES admin_users(id) ON DELETE SET NULL,
  
  action TEXT NOT NULL,
  resource_type TEXT,
  resource_id UUID,
  
  details JSONB DEFAULT '{}'::JSONB,
  ip_address INET,
  user_agent TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User segments (for easier targeting)
CREATE TABLE IF NOT EXISTS user_segments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  name TEXT NOT NULL,
  description TEXT,
  criteria JSONB NOT NULL,
  
  -- Cached results for performance
  cached_user_count INTEGER DEFAULT 0,
  cached_user_ids UUID[],
  cache_updated_at TIMESTAMPTZ,
  
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

-- Users
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_is_premium ON users(is_premium);
CREATE INDEX IF NOT EXISTS idx_users_account_type ON users(account_type);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_last_seen_at ON users(last_seen_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);

-- Sessions
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_start ON user_sessions(session_start DESC);
CREATE INDEX IF NOT EXISTS idx_sessions_platform ON user_sessions(platform);

-- Events
CREATE INDEX IF NOT EXISTS idx_events_user_id ON user_events(user_id);
CREATE INDEX IF NOT EXISTS idx_events_session_id ON user_events(session_id);
CREATE INDEX IF NOT EXISTS idx_events_name ON user_events(event_name);
CREATE INDEX IF NOT EXISTS idx_events_category ON user_events(event_category);
CREATE INDEX IF NOT EXISTS idx_events_timestamp ON user_events(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_events_screen ON user_events(screen_name);

-- Campaigns
CREATE INDEX IF NOT EXISTS idx_campaigns_active ON campaigns(is_active, starts_at, ends_at);
CREATE INDEX IF NOT EXISTS idx_campaigns_type ON campaigns(type);
CREATE INDEX IF NOT EXISTS idx_campaigns_created_by ON campaigns(created_by);

-- Campaign interactions
CREATE INDEX IF NOT EXISTS idx_campaign_interactions_campaign ON campaign_interactions(campaign_id);
CREATE INDEX IF NOT EXISTS idx_campaign_interactions_user ON campaign_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_campaign_interactions_type ON campaign_interactions(interaction_type);
CREATE INDEX IF NOT EXISTS idx_campaign_interactions_created ON campaign_interactions(created_at DESC);

-- Ads
CREATE INDEX IF NOT EXISTS idx_ads_active ON ads(is_active, starts_at, ends_at);
CREATE INDEX IF NOT EXISTS idx_ads_placement ON ads(placement);

-- Ad impressions
CREATE INDEX IF NOT EXISTS idx_ad_impressions_ad ON ad_impressions(ad_id);
CREATE INDEX IF NOT EXISTS idx_ad_impressions_user_date ON ad_impressions(user_id, created_at);

-- Push notifications
CREATE INDEX IF NOT EXISTS idx_push_status ON push_notifications(status, scheduled_for);
CREATE INDEX IF NOT EXISTS idx_push_created_by ON push_notifications(created_by);

-- Push notification logs
CREATE INDEX IF NOT EXISTS idx_push_logs_notification ON push_notification_logs(notification_id);
CREATE INDEX IF NOT EXISTS idx_push_logs_user ON push_notification_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_push_logs_status ON push_notification_logs(status);

-- Admin logs
CREATE INDEX IF NOT EXISTS idx_admin_logs_admin ON admin_activity_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_logs_created ON admin_activity_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_logs_action ON admin_activity_logs(action);
CREATE INDEX IF NOT EXISTS idx_admin_logs_resource ON admin_activity_logs(resource_type, resource_id);

-- ============================================
-- TRIGGERS & FUNCTIONS
-- ============================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_campaigns_updated_at BEFORE UPDATE ON campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ads_updated_at BEFORE UPDATE ON ads
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_push_notifications_updated_at BEFORE UPDATE ON push_notifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_admin_users_updated_at BEFORE UPDATE ON admin_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_segments_updated_at BEFORE UPDATE ON user_segments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Update session duration when session ends
CREATE OR REPLACE FUNCTION calculate_session_duration()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.session_end IS NOT NULL AND OLD.session_end IS NULL THEN
        NEW.duration_seconds = EXTRACT(EPOCH FROM (NEW.session_end - NEW.session_start))::INTEGER;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_session_duration BEFORE UPDATE ON user_sessions
    FOR EACH ROW EXECUTE FUNCTION calculate_session_duration();

-- Increment campaign metrics
CREATE OR REPLACE FUNCTION increment_campaign_metrics()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.interaction_type = 'impression' THEN
        UPDATE campaigns SET total_impressions = total_impressions + 1 WHERE id = NEW.campaign_id;
    ELSIF NEW.interaction_type = 'click' THEN
        UPDATE campaigns SET total_clicks = total_clicks + 1 WHERE id = NEW.campaign_id;
    ELSIF NEW.interaction_type = 'conversion' THEN
        UPDATE campaigns SET total_conversions = total_conversions + 1 WHERE id = NEW.campaign_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_campaign_metrics AFTER INSERT ON campaign_interactions
    FOR EACH ROW EXECUTE FUNCTION increment_campaign_metrics();

-- Increment ad metrics
CREATE OR REPLACE FUNCTION increment_ad_metrics()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE ads SET impressions = impressions + 1 WHERE id = NEW.ad_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_ad_impressions_count AFTER INSERT ON ad_impressions
    FOR EACH ROW EXECUTE FUNCTION increment_ad_metrics();

CREATE OR REPLACE FUNCTION increment_ad_clicks()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.clicked = TRUE AND OLD.clicked = FALSE THEN
        UPDATE ads SET clicks = clicks + 1 WHERE id = NEW.ad_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_ad_clicks_count AFTER UPDATE ON ad_impressions
    FOR EACH ROW EXECUTE FUNCTION increment_ad_clicks();

-- Update push notification metrics
CREATE OR REPLACE FUNCTION update_push_metrics()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'sent' AND (OLD.status IS NULL OR OLD.status != 'sent') THEN
        UPDATE push_notifications SET total_sent = total_sent + 1 WHERE id = NEW.notification_id;
    ELSIF NEW.status = 'delivered' AND (OLD.status IS NULL OR OLD.status != 'delivered') THEN
        UPDATE push_notifications SET total_delivered = total_delivered + 1 WHERE id = NEW.notification_id;
    ELSIF NEW.status = 'failed' AND (OLD.status IS NULL OR OLD.status != 'failed') THEN
        UPDATE push_notifications SET total_failed = total_failed + 1 WHERE id = NEW.notification_id;
    ELSIF NEW.status = 'opened' AND (OLD.status IS NULL OR OLD.status != 'opened') THEN
        UPDATE push_notifications SET total_opened = total_opened + 1 WHERE id = NEW.notification_id;
    ELSIF NEW.status = 'clicked' AND (OLD.status IS NULL OR OLD.status != 'clicked') THEN
        UPDATE push_notifications SET total_clicked = total_clicked + 1 WHERE id = NEW.notification_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_push_notification_metrics AFTER INSERT OR UPDATE ON push_notification_logs
    FOR EACH ROW EXECUTE FUNCTION update_push_metrics();

-- ============================================
-- RPC FUNCTIONS (Analytics)
-- ============================================

-- Dashboard stats
CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_users', (SELECT COUNT(*) FROM users WHERE deleted_at IS NULL),
    'active_users', (SELECT COUNT(*) FROM users WHERE is_active = TRUE AND deleted_at IS NULL),
    'guest_users', (SELECT COUNT(*) FROM users WHERE account_type = 'guest' AND deleted_at IS NULL),
    'premium_users', (SELECT COUNT(*) FROM users WHERE is_premium = TRUE AND deleted_at IS NULL),
    'banned_users', (SELECT COUNT(*) FROM users WHERE is_banned = TRUE),
    
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
    
    'dau', (
      SELECT COUNT(DISTINCT user_id) FROM user_sessions
      WHERE session_start >= CURRENT_DATE
    ),
    'wau', (
      SELECT COUNT(DISTINCT user_id) FROM user_sessions
      WHERE session_start >= CURRENT_DATE - INTERVAL '7 days'
    ),
    'mau', (
      SELECT COUNT(DISTINCT user_id) FROM user_sessions
      WHERE session_start >= CURRENT_DATE - INTERVAL '30 days'
    ),
    
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
    
    'premium_conversion_rate', (
      SELECT ROUND(
        (COUNT(*) FILTER (WHERE is_premium = TRUE)::DECIMAL / 
         NULLIF(COUNT(*), 0) * 100), 2
      )
      FROM users
      WHERE deleted_at IS NULL AND account_type != 'guest'
    )
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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

-- Top events by category
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
      DATE_TRUNC('week', session_start)::DATE as activity_week,
      user_id
    FROM user_sessions
    WHERE session_start >= CURRENT_DATE - (weeks_back * 7)
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

-- User growth over time
CREATE OR REPLACE FUNCTION get_user_growth(days_back INTEGER DEFAULT 30)
RETURNS TABLE (
  date DATE,
  new_users BIGINT,
  total_users BIGINT,
  premium_users BIGINT
) AS $$
BEGIN
  RETURN QUERY
  WITH RECURSIVE date_series AS (
    SELECT CURRENT_DATE - days_back as date
    UNION ALL
    SELECT date + 1
    FROM date_series
    WHERE date < CURRENT_DATE
  )
  SELECT 
    ds.date,
    COUNT(u.id) FILTER (WHERE DATE(u.created_at) = ds.date)::BIGINT as new_users,
    COUNT(u.id) FILTER (WHERE DATE(u.created_at) <= ds.date)::BIGINT as total_users,
    COUNT(u.id) FILTER (WHERE u.is_premium = TRUE AND DATE(u.created_at) <= ds.date)::BIGINT as premium_users
  FROM date_series ds
  LEFT JOIN users u ON DATE(u.created_at) <= ds.date AND u.deleted_at IS NULL
  GROUP BY ds.date
  ORDER BY ds.date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Increment session screens viewed counter
CREATE OR REPLACE FUNCTION increment_session_screens(target_session_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE user_sessions 
  SET screens_viewed = screens_viewed + 1
  WHERE id = target_session_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Increment session events counter
CREATE OR REPLACE FUNCTION increment_session_events(target_session_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE user_sessions 
  SET events_count = events_count + 1
  WHERE id = target_session_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ads ENABLE ROW LEVEL SECURITY;
ALTER TABLE ad_impressions ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_notification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_segments ENABLE ROW LEVEL SECURITY;

-- Admin full access policy (for all tables)
CREATE POLICY admin_all_users ON users FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND is_active = TRUE));

CREATE POLICY admin_all_sessions ON user_sessions FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND is_active = TRUE));

CREATE POLICY admin_all_events ON user_events FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND is_active = TRUE));

CREATE POLICY admin_all_campaigns ON campaigns FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND is_active = TRUE));

CREATE POLICY admin_all_campaign_interactions ON campaign_interactions FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND is_active = TRUE));

CREATE POLICY admin_all_ads ON ads FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND is_active = TRUE));

CREATE POLICY admin_all_ad_impressions ON ad_impressions FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND is_active = TRUE));

CREATE POLICY admin_all_push ON push_notifications FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND is_active = TRUE));

CREATE POLICY admin_all_push_logs ON push_notification_logs FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND is_active = TRUE));

CREATE POLICY admin_all_admin_users ON admin_users FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND is_active = TRUE));

CREATE POLICY admin_all_admin_logs ON admin_activity_logs FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND is_active = TRUE));

CREATE POLICY admin_all_segments ON user_segments FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND is_active = TRUE));

-- ============================================
-- SAMPLE DATA (for testing)
-- ============================================

-- Insert a super admin (Update with your actual admin email)
-- Note: This user should be created through Supabase Auth first
-- INSERT INTO admin_users (id, email, full_name, role, is_active)
-- VALUES 
--   ('YOUR-AUTH-USER-UUID', 'admin@investguide.com', 'Super Admin', 'super_admin', TRUE);

-- Example: Create some sample users for testing
-- INSERT INTO users (email, full_name, account_type, is_premium)
-- VALUES 
--   ('test1@example.com', 'Test User 1', 'email', FALSE),
--   ('test2@example.com', 'Test User 2', 'email', TRUE),
--   ('guest@example.com', 'Guest User', 'guest', FALSE);

COMMENT ON TABLE users IS 'Mobile app users';
COMMENT ON TABLE user_sessions IS 'User session tracking';
COMMENT ON TABLE user_events IS 'Granular event tracking for analytics';
COMMENT ON TABLE campaigns IS 'Marketing campaigns';
COMMENT ON TABLE ads IS 'In-app advertisements';
COMMENT ON TABLE push_notifications IS 'Push notification campaigns';
COMMENT ON TABLE admin_users IS 'Admin panel users';
COMMENT ON TABLE admin_activity_logs IS 'Audit trail for admin actions';
