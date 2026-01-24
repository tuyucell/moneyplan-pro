-- 1. DROP Existing Tables (To recreate with TEXT IDs)
DROP TABLE IF EXISTS user_transactions CASCADE;
DROP TABLE IF EXISTS user_bank_accounts CASCADE;
DROP TABLE IF EXISTS user_portfolio_assets CASCADE;
DROP TABLE IF EXISTS user_watchlists CASCADE;
DROP TABLE IF EXISTS user_sync_status CASCADE;

-- 2. Bank Accounts (ID type changed to TEXT to match local string IDs like 'isbank')
CREATE TABLE user_bank_accounts (
    id TEXT PRIMARY KEY, 
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    account_name TEXT NOT NULL,
    account_type TEXT NOT NULL,
    balance NUMERIC DEFAULT 0,
    currency TEXT DEFAULT 'TRY',
    iban TEXT,
    bank_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for Bank Accounts
ALTER TABLE user_bank_accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own bank accounts" ON user_bank_accounts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own bank accounts" ON user_bank_accounts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own bank accounts" ON user_bank_accounts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own bank accounts" ON user_bank_accounts FOR DELETE USING (auth.uid() = user_id);


-- 3. Transactions (ID type TEXT)
CREATE TABLE user_transactions (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    amount NUMERIC NOT NULL,
    type TEXT NOT NULL,
    category_id TEXT,
    description TEXT,
    date TIMESTAMPTZ NOT NULL,
    currency TEXT DEFAULT 'TRY',
    account_id TEXT REFERENCES user_bank_accounts(id) ON DELETE SET NULL, -- References TEXT ID
    is_recurring BOOLEAN DEFAULT false,
    recurrence_type TEXT,
    recurrence_end_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for Transactions
ALTER TABLE user_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own transactions" ON user_transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own transactions" ON user_transactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own transactions" ON user_transactions FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own transactions" ON user_transactions FOR DELETE USING (auth.uid() = user_id);


-- 4. Portfolio Assets (ID type TEXT)
CREATE TABLE user_portfolio_assets (
    id TEXT DEFAULT gen_random_uuid()::text PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    symbol TEXT NOT NULL,
    name TEXT,
    type TEXT,
    quantity NUMERIC NOT NULL DEFAULT 0,
    average_cost NUMERIC DEFAULT 0,
    currency TEXT DEFAULT 'USD',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, symbol)
);

-- RLS for Portfolio
ALTER TABLE user_portfolio_assets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own portfolio" ON user_portfolio_assets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own portfolio" ON user_portfolio_assets FOR ALL USING (auth.uid() = user_id);


-- 5. Watchlist (ID UUID is fine here, as we sync by symbol+user_id)
CREATE TABLE user_watchlists (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    symbol TEXT NOT NULL,
    asset_type TEXT,
    added_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, symbol)
);

-- RLS for Watchlist
ALTER TABLE user_watchlists ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own watchlist" ON user_watchlists FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own watchlist" ON user_watchlists FOR ALL USING (auth.uid() = user_id);


-- 6. Sync Status
CREATE TABLE user_sync_status (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE PRIMARY KEY,
    last_synced_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT
);
ALTER TABLE user_sync_status ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own sync status" ON user_sync_status FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own sync status" ON user_sync_status FOR ALL USING (auth.uid() = user_id);
