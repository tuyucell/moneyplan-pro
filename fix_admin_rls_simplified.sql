-- ============================================
-- RLS RE-RE-FIX FOR ADMINS
-- ============================================

-- 1. Ensure user 'admin' check is case-friendly and direct
-- We need to make sure the policy is applied to SELECT operations.

DO $$
BEGIN
    -- Force allow everything if current user's role in DB is 'admin'
    
    -- Transaction Table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_transactions') THEN
        DROP POLICY IF EXISTS "Admins can view all transactions" ON user_transactions;
        CREATE POLICY "Admins can view all transactions" ON user_transactions 
        FOR SELECT TO authenticated
        USING (
            (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
            OR auth.uid() = user_id
        );
    END IF;

    -- Portfolio Table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_portfolio_assets') THEN
        DROP POLICY IF EXISTS "Admins can view all portfolio assets" ON user_portfolio_assets;
        CREATE POLICY "Admins can view all portfolio assets" ON user_portfolio_assets 
        FOR SELECT TO authenticated
        USING (
            (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
            OR auth.uid() = user_id
        );
    END IF;

    -- Watchlist Table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_watchlists') THEN
        DROP POLICY IF EXISTS "Admins can view all watchlists" ON user_watchlists;
        CREATE POLICY "Admins can view all watchlists" ON user_watchlists 
        FOR SELECT TO authenticated
        USING (
            (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
            OR auth.uid() = user_id
        );
    END IF;

    -- Audit Logs (Admins only)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'audit_logs') THEN
        DROP POLICY IF EXISTS "Admins can view all logs" ON audit_logs;
        CREATE POLICY "Admins can view all logs" ON audit_logs 
        FOR SELECT TO authenticated
        USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');
    END IF;

    -- User Activities (Admins only)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_activities') THEN
        DROP POLICY IF EXISTS "Admins can view all activities" ON user_activities;
        CREATE POLICY "Admins can view all activities" ON user_activities 
        FOR SELECT TO authenticated
        USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');
    END IF;

END $$;

-- 2. Grant PERMISSIONS
-- Make sure the authenticated role has access to these tables
GRANT SELECT ON public.user_transactions TO authenticated;
GRANT SELECT ON public.user_portfolio_assets TO authenticated;
GRANT SELECT ON public.user_watchlists TO authenticated;
GRANT SELECT ON public.audit_logs TO authenticated;
GRANT SELECT ON public.user_activities TO authenticated;

-- 3. Verify Role column exists and is populated
-- If 'admin' doesn't exist, we might need to set it for the current user manually.
-- This script assumes the user is already an admin in public.users.
