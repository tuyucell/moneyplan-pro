-- InvestGuide Security Hardening Script
-- This script fixes the 15 security errors reported by Supabase Security Advisor.

-- 1. ENABLE RLS ON PUBLIC TABLES
-- These tables had policies created but RLS was not actually enabled, or were public without RLS.

ALTER TABLE IF EXISTS public.asset_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.asset_exchanges ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.exchange_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.exchange_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.exchanges ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.exchange_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.popular_searches ENABLE ROW LEVEL SECURITY;

-- 2. ENSURE PUBLIC READ ACCESS (Fallback policies if they didn't exist)
-- The advisor mentioned "Policies include {...}" which implies they exist, 
-- but we run these anyway with "IF NOT EXISTS" logic (using DO blocks for safety)

DO $$ 
BEGIN
    -- Assets
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'assets' AND policyname = 'Public can read assets') THEN
        CREATE POLICY "Public can read assets" ON public.assets FOR SELECT USING (true);
    END IF;
    
    -- Asset Categories
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'asset_categories' AND policyname = 'Public can read categories') THEN
        CREATE POLICY "Public can read categories" ON public.asset_categories FOR SELECT USING (true);
    END IF;
    
    -- Asset Exchanges
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'asset_exchanges' AND policyname = 'Public can read asset_exchanges') THEN
        CREATE POLICY "Public can read asset_exchanges" ON public.asset_exchanges FOR SELECT USING (true);
    END IF;

    -- Exchanges
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exchanges' AND policyname = 'Public can read exchanges') THEN
        CREATE POLICY "Public can read exchanges" ON public.exchanges FOR SELECT USING (true);
    END IF;

    -- Exchange Details
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exchange_details' AND policyname = 'Public can read exchange_details') THEN
        CREATE POLICY "Public can read exchange_details" ON public.exchange_details FOR SELECT USING (true);
    END IF;

    -- Exchange Reviews
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'exchange_reviews' AND policyname = 'Public can read approved reviews') THEN
        CREATE POLICY "Public can read approved reviews" ON public.exchange_reviews FOR SELECT USING (is_approved = true);
    END IF;
    
    -- Popular Searches
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'popular_searches' AND policyname = 'Public can read popular searches') THEN
        CREATE POLICY "Public can read popular searches" ON public.popular_searches FOR SELECT USING (true);
    END IF;
END $$;

-- 3. FIX SECURITY DEFINER VIEWS
-- Converting views to SECURITY INVOKER for better security.
-- Note: Requires Postgres 15+. If it fails, the views may need manual recreation.

ALTER VIEW IF EXISTS public.v_exchange_summary SET (security_invoker = on);
ALTER VIEW IF EXISTS public.v_asset_search SET (security_invoker = on);

-- 4. ADDITIONAL SECURITY: ENSURE AUTHENTICATED USERS CAN ONLY SEE THEIR OWN SESSIONS/EVENTS
-- (If not already handled in previous migrations)
ALTER TABLE IF EXISTS public.user_sessions ENABLE ROW LEVEL SECURITY;
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_sessions' AND policyname = 'Users can view own sessions') THEN
        CREATE POLICY "Users can view own sessions" ON public.user_sessions FOR SELECT USING (auth.uid() = user_id);
    END IF;
END $$;

ALTER TABLE IF EXISTS public.user_events ENABLE ROW LEVEL SECURITY;
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_events' AND policyname = 'Users can view own events') THEN
        CREATE POLICY "Users can view own events" ON public.user_events FOR SELECT USING (auth.uid() = user_id);
    END IF;
END $$;
