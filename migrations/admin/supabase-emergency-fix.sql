-- InvestGuide Emergency Fix Script
-- 1. Fix Price Alerts Schema Cache issue
-- 2. Fix Admin Users Infinite Recursion in RLS

-- ============================================
-- 1. PRICE ALERTS SCHEMA FIX
-- ============================================

-- Ensure the price_alerts table has the correct columns
-- This handles cases where the table was created using an older schema
ALTER TABLE IF EXISTS public.price_alerts 
    ADD COLUMN IF NOT EXISTS is_above BOOLEAN DEFAULT true,
    ADD COLUMN IF NOT EXISTS last_triggered_at TIMESTAMPTZ;

-- Refresh PostgREST schema cache (PostgREST does this automatically on DDL, 
-- but sometimes an explicit schema change helps)
COMMENT ON TABLE public.price_alerts IS 'Active price alerts for users';

-- ============================================
-- 2. ADMIN USERS RLS FIX (Recursion Error)
-- ============================================

-- The previous policy:
-- CREATE POLICY admin_all_admin_users ON admin_users FOR ALL TO authenticated
--   USING (EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND is_active = TRUE));
-- This causes recursion because querying admin_users triggers the check on admin_users.

-- First, drop the recursive policies
DROP POLICY IF EXISTS admin_all_admin_users ON admin_users;
DROP POLICY IF EXISTS admin_all_sessions ON user_sessions;
DROP POLICY IF EXISTS admin_all_events ON user_events;
DROP POLICY IF EXISTS admin_all_campaigns ON campaigns;
DROP POLICY IF EXISTS admin_all_campaign_interactions ON campaign_interactions;
DROP POLICY IF EXISTS admin_all_ads ON ads;
DROP POLICY IF EXISTS admin_all_ad_impressions ON ad_impressions;
DROP POLICY IF EXISTS admin_all_push ON push_notifications;
DROP POLICY IF EXISTS admin_all_push_logs ON push_notification_logs;
DROP POLICY IF EXISTS admin_all_admin_logs ON admin_activity_logs;
DROP POLICY IF EXISTS admin_all_segments ON user_segments;

-- Create a security definer function to check admin status without recursion
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM admin_users 
    WHERE id = auth.uid() 
    AND is_active = TRUE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-apply policies using the function
CREATE POLICY admin_all_admin_users ON admin_users FOR ALL TO authenticated
  USING (public.is_admin());

CREATE POLICY admin_all_sessions ON user_sessions FOR ALL TO authenticated
  USING (public.is_admin());

CREATE POLICY admin_all_events ON user_events FOR ALL TO authenticated
  USING (public.is_admin());

CREATE POLICY admin_all_campaigns ON campaigns FOR ALL TO authenticated
  USING (public.is_admin());

CREATE POLICY admin_all_campaign_interactions ON campaign_interactions FOR ALL TO authenticated
  USING (public.is_admin());

CREATE POLICY admin_all_ads ON ads FOR ALL TO authenticated
  USING (public.is_admin());

CREATE POLICY admin_all_ad_impressions ON ad_impressions FOR ALL TO authenticated
  USING (public.is_admin());

CREATE POLICY admin_all_push ON push_notifications FOR ALL TO authenticated
  USING (public.is_admin());

CREATE POLICY admin_all_push_logs ON push_notification_logs FOR ALL TO authenticated
  USING (public.is_admin());

CREATE POLICY admin_all_admin_logs ON admin_activity_logs FOR ALL TO authenticated
  USING (public.is_admin());

CREATE POLICY admin_all_segments ON user_segments FOR ALL TO authenticated
  USING (public.is_admin());

-- Also ensure the users can insert their own events (needed for app)
DROP POLICY IF EXISTS users_own_sessions ON user_sessions;
CREATE POLICY users_own_sessions ON user_sessions FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS users_own_events ON user_events;
CREATE POLICY users_own_events ON user_events FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Success check
DO $$ 
BEGIN 
  RAISE NOTICE '✅ Schema fixes applied.';
  RAISE NOTICE '🚀 Price alerts is_above column ensured.';
  RAISE NOTICE '🔐 Admin recursion fixed using is_admin() function.';
END $$;
