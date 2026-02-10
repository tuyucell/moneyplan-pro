-- Add missing fields for Watchlist and Portfolio Sync

-- 1. Update user_watchlists table
ALTER TABLE IF EXISTS user_watchlists 
ADD COLUMN IF NOT EXISTS asset_name TEXT;

-- 2. Rename columns or ensure mapping (we stick to user_data_sync.sql names but ensure Flutter matches)
-- Current user_portfolio_assets has 'quantity', Flutter has 'units'.
-- We will keep 'quantity' in DB as it is standard, but map it in Flutter.

-- 3. Ensure RLS policies are robust
DROP POLICY IF EXISTS "Users can manage their own watchlist" ON user_watchlists;
CREATE POLICY "Users can manage their own watchlist" 
ON user_watchlists FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage their own portfolio" ON user_portfolio_assets;
CREATE POLICY "Users can manage their own portfolio" 
ON user_portfolio_assets FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
