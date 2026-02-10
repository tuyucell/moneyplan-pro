-- INVESTGUIDE FINAL MASTER FIX (Schema & Recursion)
-- Run this in Supabase SQL Editor to resolve all current issues.

BEGIN;

-- ============================================
-- 1. SECURITY HELPER (To break recursion)
-- ============================================

-- Create a security definer function to check admin status.
-- SECURITY DEFINER makes the function run with the privileges of the creator (usually owner/superuser),
-- which bypasses RLS on the tables it queries. This is the standard fix for RLS recursion.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  -- We use public.admin_users explicitly to avoid any schema search path issues
  RETURN EXISTS (
    SELECT 1 FROM public.admin_users 
    WHERE id = auth.uid() 
    AND is_active = TRUE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================
-- 2. PRICE ALERTS RECONSTRUCTION
-- ============================================

-- If the schema cache is stuck, sometimes dropping and recreating is the only way.
-- WARNING: This will clear existing alerts, but since creation is currently failing, 
-- this is the safest way to ensure the table matches the code perfectly.
DROP TABLE IF EXISTS public.price_alerts CASCADE;

CREATE TABLE public.price_alerts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    asset_id TEXT NOT NULL,
    asset_name TEXT NOT NULL,
    symbol TEXT NOT NULL,
    target_price DECIMAL NOT NULL,
    is_above BOOLEAN DEFAULT true, -- must match 'is_above' in Dart code
    is_active BOOLEAN DEFAULT true,
    last_triggered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indices for performance
CREATE INDEX IF NOT EXISTS idx_price_alerts_user_id ON public.price_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_price_alerts_is_active ON public.price_alerts(is_active);

-- Enable RLS
ALTER TABLE public.price_alerts ENABLE ROW LEVEL SECURITY;

-- Simple non-recursive policies
CREATE POLICY "Users can view their own alerts" ON public.price_alerts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own alerts" ON public.price_alerts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own alerts" ON public.price_alerts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own alerts" ON public.price_alerts FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 3. FIX ADMIN RECURSION (The 42P17 error)
-- ============================================

-- Drop all policies that might be recursive
DROP POLICY IF EXISTS admin_all_admin_users ON public.admin_users;
DROP POLICY IF EXISTS admin_all_sessions ON public.user_sessions;
DROP POLICY IF EXISTS admin_all_events ON public.user_events;
DROP POLICY IF EXISTS admin_all_campaigns ON public.campaigns;
DROP POLICY IF EXISTS admin_all_ads ON public.ads;
DROP POLICY IF EXISTS admin_all_push ON public.push_notifications;
DROP POLICY IF EXISTS admin_all_segments ON public.user_segments;

-- Re-apply using the is_admin() helper
CREATE POLICY admin_all_admin_users ON public.admin_users FOR ALL TO authenticated USING (is_admin());
CREATE POLICY admin_all_sessions ON public.user_sessions FOR ALL TO authenticated USING (is_admin());
CREATE POLICY admin_all_events ON public.user_events FOR ALL TO authenticated USING (is_admin());
CREATE POLICY admin_all_campaigns ON public.campaigns FOR ALL TO authenticated USING (is_admin());
CREATE POLICY admin_all_ads ON public.ads FOR ALL TO authenticated USING (is_admin());
CREATE POLICY admin_all_push ON public.push_notifications FOR ALL TO authenticated USING (is_admin());
CREATE POLICY admin_all_segments ON public.user_segments FOR ALL TO authenticated USING (is_admin());

-- ============================================
-- 4. SCHEMA CACHE REFRESH
-- ============================================
-- Doing dummy DDL on the public schema helps PostgREST refresh its cache
COMMENT ON TABLE public.price_alerts IS 'User price alerts - Schema Refreshed';

COMMIT;

-- Verification query (run this afterwards)
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'price_alerts';
