-- Watchlist Migration Fix: Add missing columns for persistence and price tracking

-- 1. Add asset_id, asset_name and handle mapping
DO $$ 
BEGIN 
    -- Add asset_id if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_watchlists' AND column_name='asset_id') THEN
        ALTER TABLE user_watchlists ADD COLUMN asset_id TEXT;
        -- For existing rows, try to migrate symbol to asset_id as a fallback
        UPDATE user_watchlists SET asset_id = symbol WHERE asset_id IS NULL;
    END IF;

    -- Add asset_name if not exists (redundancy check)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_watchlists' AND column_name='asset_name') THEN
        ALTER TABLE user_watchlists ADD COLUMN asset_name TEXT;
    END IF;

    -- Ensure asset_type exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_watchlists' AND column_name='asset_type') THEN
        ALTER TABLE user_watchlists ADD COLUMN asset_type TEXT;
    END IF;
END $$;

-- 2. Clean up any broken constraints and recreate unique index to include asset_id maybe? 
-- Actually, unique(user_id, symbol) is fine, but asset_id is the primary key for lookups.

-- 3. Ensure RLS is still solid
ALTER TABLE user_watchlists ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own watchlist" ON user_watchlists;
CREATE POLICY "Users can manage their own watchlist" 
ON user_watchlists FOR ALL 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
