-- 1. Create a Secure Helper Function to check Admin status
-- SECURITY DEFINER allows this function to bypass RLS to check the user's role without recursion
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.users
    WHERE id = auth.uid()
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 2. Fix 'users' table RLS Policy (Use function to avoid infinite recursion)
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;

CREATE POLICY "Admins can view all users"
ON public.users FOR SELECT
USING (
    public.is_admin() -- Uses the secure function
    OR
    auth.uid() = id   -- Or users can see themselves
);


-- 3. Fix other tables RLS Policies (Optional but recommended)
-- Transactions
DROP POLICY IF EXISTS "Admins can view all transactions" ON user_transactions;
CREATE POLICY "Admins can view all transactions"
ON user_transactions FOR SELECT
USING (public.is_admin());

-- Bank Accounts
DROP POLICY IF EXISTS "Admins can view all bank accounts" ON user_bank_accounts;
CREATE POLICY "Admins can view all bank accounts"
ON user_bank_accounts FOR SELECT
USING (public.is_admin());

-- Portfolio
DROP POLICY IF EXISTS "Admins can view all portfolio assets" ON user_portfolio_assets;
CREATE POLICY "Admins can view all portfolio assets"
ON user_portfolio_assets FOR SELECT
USING (public.is_admin());

-- Watchlists
DROP POLICY IF EXISTS "Admins can view all watchlists" ON user_watchlists;
CREATE POLICY "Admins can view all watchlists"
ON user_watchlists FOR SELECT
USING (public.is_admin());
