-- Add RLS Policies to allow Admins to view ALL data in User Sync Tables

-- 1. Transactions
DROP POLICY IF EXISTS "Admins can view all transactions" ON user_transactions;
CREATE POLICY "Admins can view all transactions"
ON user_transactions FOR SELECT
USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);

-- 2. Bank Accounts
DROP POLICY IF EXISTS "Admins can view all bank accounts" ON user_bank_accounts;
CREATE POLICY "Admins can view all bank accounts"
ON user_bank_accounts FOR SELECT
USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);

-- 3. Portfolio Assets
DROP POLICY IF EXISTS "Admins can view all portfolio assets" ON user_portfolio_assets;
CREATE POLICY "Admins can view all portfolio assets"
ON user_portfolio_assets FOR SELECT
USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);

-- 4. Watchlists
DROP POLICY IF EXISTS "Admins can view all watchlists" ON user_watchlists;
CREATE POLICY "Admins can view all watchlists"
ON user_watchlists FOR SELECT
USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);

-- 5. Sync Status
DROP POLICY IF EXISTS "Admins can view all sync status" ON user_sync_status;
CREATE POLICY "Admins can view all sync status"
ON user_sync_status FOR SELECT
USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);
