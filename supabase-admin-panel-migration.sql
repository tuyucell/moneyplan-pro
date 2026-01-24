-- ============================================
-- InvestGuide Admin Panel Migration
-- Compatible with existing database
-- ============================================

-- STEP 1: Add missing columns to existing users table
-- ============================================

ALTER TABLE users 
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS is_premium BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS premium_expires_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS premium_started_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS ban_reason TEXT,
  ADD COLUMN IF NOT EXISTS banned_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS banned_by UUID,
  ADD COLUMN IF NOT EXISTS device_info JSONB DEFAULT '{}'::JSONB,
  ADD COLUMN IF NOT EXISTS fcm_token TEXT,
  ADD COLUMN IF NOT EXISTS apns_token TEXT,
  ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- Add indexes for new columns
CREATE INDEX IF NOT EXISTS idx_users_is_premium ON users(is_premium);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_is_banned ON users(is_banned);
CREATE INDEX IF NOT EXISTS idx_users_last_seen ON users(last_seen_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_deleted_at ON users(deleted_at) WHERE deleted_at IS NOT NULL;

-- Add comment
COMMENT ON COLUMN users.is_premium IS 'Premium subscription status';
COMMENT ON COLUMN users.last_seen_at IS 'Last activity timestamp for analytics';
COMMENT ON COLUMN users.device_info IS 'Device metadata: {platform, os_version, app_version, device_model}';

-- ============================================
-- STEP 2: Create new tracking tables
-- ============================================

-- User sessions for analytics
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
  
  -- Engagement metrics
  screens_viewed INTEGER DEFAULT 0,
  events_count INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_sessions_start ON user_sessions(session_start DESC);
CREATE INDEX idx_sessions_platform ON user_sessions(platform);
CREATE INDEX idx_sessions_user_start ON user_sessions(user_id, session_start DESC);

COMMENT ON TABLE user_sessions IS 'User session tracking for analytics';

-- User events for granular tracking
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

CREATE INDEX idx_events_user_id ON user_events(user_id);
CREATE INDEX idx_events_session_id ON user_events(session_id);
CREATE INDEX idx_events_name ON user_events(event_name);
CREATE INDEX idx_events_category ON user_events(event_category);
CREATE INDEX idx_events_timestamp ON user_events(timestamp DESC);
CREATE INDEX idx_events_screen ON user_events(screen_name);
CREATE INDEX idx_events_user_timestamp ON user_events(user_id, timestamp DESC);

COMMENT ON TABLE user_events IS 'Granular event tracking for behavioral analytics';

-- ============================================
-- STEP 3: Campaign management
-- ============================================

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
  
  CONSTRAINT valid_campaign_dates CHECK (ends_at IS NULL OR ends_at > starts_at)
);

CREATE INDEX idx_campaigns_active ON campaigns(is_active, starts_at, ends_at);
CREATE INDEX idx_campaigns_type ON campaigns(type);
CREATE INDEX idx_campaigns_created_by ON campaigns(created_by);
CREATE INDEX idx_campaigns_starts_at ON campaigns(starts_at DESC);

COMMENT ON TABLE campaigns IS 'Marketing campaigns for user engagement';

-- Campaign interactions
CREATE TABLE IF NOT EXISTS campaign_interactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  
  interaction_type TEXT CHECK (interaction_type IN ('impression', 'click', 'conversion', 'dismiss')) NOT NULL,
  
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_campaign_interactions_campaign ON campaign_interactions(campaign_id);
CREATE INDEX idx_campaign_interactions_user ON campaign_interactions(user_id);
CREATE INDEX idx_campaign_interactions_type ON campaign_interactions(interaction_type);
CREATE INDEX idx_campaign_interactions_created ON campaign_interactions(created_at DESC);

-- ============================================
-- STEP 4: Ad management
-- ============================================

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
  
  CONSTRAINT valid_ad_dates CHECK (ends_at IS NULL OR ends_at > starts_at)
);

CREATE INDEX idx_ads_active ON ads(is_active, starts_at, ends_at);
CREATE INDEX idx_ads_placement ON ads(placement);

-- Ad impressions
CREATE TABLE IF NOT EXISTS ad_impressions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ad_id UUID REFERENCES ads(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  
  clicked BOOLEAN DEFAULT FALSE,
  clicked_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ad_impressions_ad ON ad_impressions(ad_id);
CREATE INDEX idx_ad_impressions_user_date ON ad_impressions(user_id, created_at);

-- ============================================
-- STEP 5: Push notifications
-- ============================================

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

CREATE INDEX idx_push_status ON push_notifications(status, scheduled_for);
CREATE INDEX idx_push_created_by ON push_notifications(created_by);

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

CREATE INDEX idx_push_logs_notification ON push_notification_logs(notification_id);
CREATE INDEX idx_push_logs_user ON push_notification_logs(user_id);
CREATE INDEX idx_push_logs_status ON push_notification_logs(status);

-- ============================================
-- STEP 6: Admin users and audit
-- ============================================

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

CREATE INDEX idx_admin_users_role ON admin_users(role);
CREATE INDEX idx_admin_users_active ON admin_users(is_active);

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

CREATE INDEX idx_admin_logs_admin ON admin_activity_logs(admin_id);
CREATE INDEX idx_admin_logs_created ON admin_activity_logs(created_at DESC);
CREATE INDEX idx_admin_logs_action ON admin_activity_logs(action);
CREATE INDEX idx_admin_logs_resource ON admin_activity_logs(resource_type, resource_id);

-- ============================================
-- STEP 7: User segments
-- ============================================

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

CREATE INDEX idx_user_segments_created_by ON user_segments(created_by);

-- ============================================
-- STEP 8: Triggers for auto-updates
-- ============================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to relevant tables
DROP TRIGGER IF EXISTS update_campaigns_updated_at ON campaigns;
CREATE TRIGGER update_campaigns_updated_at BEFORE UPDATE ON campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_ads_updated_at ON ads;
CREATE TRIGGER update_ads_updated_at BEFORE UPDATE ON ads
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_push_notifications_updated_at ON push_notifications;
CREATE TRIGGER update_push_notifications_updated_at BEFORE UPDATE ON push_notifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_admin_users_updated_at ON admin_users;
CREATE TRIGGER update_admin_users_updated_at BEFORE UPDATE ON admin_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_segments_updated_at ON user_segments;
CREATE TRIGGER update_user_segments_updated_at BEFORE UPDATE ON user_segments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Calculate session duration when session ends
CREATE OR REPLACE FUNCTION calculate_session_duration()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.session_end IS NOT NULL AND (OLD.session_end IS NULL OR OLD.session_end != NEW.session_end) THEN
        NEW.duration_seconds = EXTRACT(EPOCH FROM (NEW.session_end - NEW.session_start))::INTEGER;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_session_duration ON user_sessions;
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

DROP TRIGGER IF EXISTS update_campaign_metrics ON campaign_interactions;
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

DROP TRIGGER IF EXISTS update_ad_impressions_count ON ad_impressions;
CREATE TRIGGER update_ad_impressions_count AFTER INSERT ON ad_impressions
    FOR EACH ROW EXECUTE FUNCTION increment_ad_metrics();

CREATE OR REPLACE FUNCTION increment_ad_clicks()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.clicked = TRUE AND (OLD.clicked IS NULL OR OLD.clicked = FALSE) THEN
        UPDATE ads SET clicks = clicks + 1 WHERE id = NEW.ad_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_ad_clicks_count ON ad_impressions;
CREATE TRIGGER update_ad_clicks_count AFTER UPDATE ON ad_impressions
    FOR EACH ROW EXECUTE FUNCTION increment_ad_clicks();

-- Update push notification metrics
CREATE OR REPLACE FUNCTION update_push_metrics()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'sent' AND (OLD IS NULL OR OLD.status IS NULL OR OLD.status != 'sent') THEN
        UPDATE push_notifications SET total_sent = total_sent + 1 WHERE id = NEW.notification_id;
    ELSIF NEW.status = 'delivered' AND (OLD IS NULL OR OLD.status IS NULL OR OLD.status != 'delivered') THEN
        UPDATE push_notifications SET total_delivered = total_delivered + 1 WHERE id = NEW.notification_id;
    ELSIF NEW.status = 'failed' AND (OLD IS NULL OR OLD.status IS NULL OR OLD.status != 'failed') THEN
        UPDATE push_notifications SET total_failed = total_failed + 1 WHERE id = NEW.notification_id;
    ELSIF NEW.status = 'opened' AND (OLD IS NULL OR OLD.status IS NULL OR OLD.status != 'opened') THEN
        UPDATE push_notifications SET total_opened = total_opened + 1 WHERE id = NEW.notification_id;
    ELSIF NEW.status = 'clicked' AND (OLD IS NULL OR OLD.status IS NULL OR OLD.status != 'clicked') THEN
        UPDATE push_notifications SET total_clicked = total_clicked + 1 WHERE id = NEW.notification_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_push_notification_metrics ON push_notification_logs;
CREATE TRIGGER update_push_notification_metrics AFTER INSERT OR UPDATE ON push_notification_logs
    FOR EACH ROW EXECUTE FUNCTION update_push_metrics();

-- Auto-update last_seen_at on user activity
CREATE OR REPLACE FUNCTION update_user_last_seen()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE users 
    SET last_seen_at = NEW.timestamp 
    WHERE id = NEW.user_id 
      AND (last_seen_at IS NULL OR last_seen_at < NEW.timestamp);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_last_seen_on_event ON user_events;
CREATE TRIGGER update_last_seen_on_event AFTER INSERT ON user_events
    FOR EACH ROW EXECUTE FUNCTION update_user_last_seen();

-- ============================================
-- STEP 9: Enable RLS (Row Level Security)
-- ============================================

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

-- Admin full access policies
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

-- User policies (mobile app users can insert their own events/sessions)
CREATE POLICY users_own_sessions ON user_sessions FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY users_own_events ON user_events FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$ 
BEGIN 
  RAISE NOTICE '✅ Admin Panel Migration Completed Successfully!';
  RAISE NOTICE '📊 New tables created: user_sessions, user_events, campaigns, ads, push_notifications, admin_users, etc.';
  RAISE NOTICE '🔧 Users table enhanced with: is_premium, tracking fields, ban management';
  RAISE NOTICE '🔐 RLS policies enabled for all admin tables';
  RAISE NOTICE '⚡ Triggers configured for auto-updates';
  RAISE NOTICE '';
  RAISE NOTICE '📝 Next steps:';
  RAISE NOTICE '1. Run supabase-admin-panel-functions.sql for analytics functions';
  RAISE NOTICE '2. Create your first admin user in auth.users';
  RAISE NOTICE '3. Insert into admin_users table';
END $$;
