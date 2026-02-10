-- Create tables for syncing user data (Wallet, Portfolio, Watchlist)
-- Enable RLS on all tables

-- 1. User Wallets (Bank Accounts)
CREATE TABLE IF NOT EXISTS user_bank_accounts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    account_name TEXT NOT NULL,
    account_type TEXT NOT NULL, -- 'Bank', 'Cash', 'Investment'
    balance NUMERIC DEFAULT 0,
    currency TEXT DEFAULT 'TRY',
    iban TEXT,
    bank_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for bank accounts
ALTER TABLE user_bank_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own bank accounts" 
ON user_bank_accounts FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own bank accounts" 
ON user_bank_accounts FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own bank accounts" 
ON user_bank_accounts FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own bank accounts" 
ON user_bank_accounts FOR DELETE 
USING (auth.uid() = user_id);


-- 2. Wallet Transactions (Income/Expense)
CREATE TABLE IF NOT EXISTS user_transactions (
    id TEXT PRIMARY KEY, -- Using TEXT to match Hive UUIDs/Strings or Generating UUIDs if migrating
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    amount NUMERIC NOT NULL,
    type TEXT NOT NULL, -- 'income', 'expense'
    category_id TEXT,
    description TEXT,
    date TIMESTAMPTZ NOT NULL,
    currency TEXT DEFAULT 'TRY',
    account_id UUID REFERENCES user_bank_accounts(id) ON DELETE SET NULL, -- Link to bank account
    is_recurring BOOLEAN DEFAULT false,
    recurrence_type TEXT, -- 'daily', 'weekly', 'monthly', 'yearly'
    recurrence_end_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for transactions
ALTER TABLE user_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own transactions" 
ON user_transactions FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own transactions" 
ON user_transactions FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own transactions" 
ON user_transactions FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own transactions" 
ON user_transactions FOR DELETE 
USING (auth.uid() = user_id);


-- 3. Portfolio Assets
CREATE TABLE IF NOT EXISTS user_portfolio_assets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    symbol TEXT NOT NULL, -- 'AAPL', 'BTC-USD', 'GARAN'
    name TEXT,
    type TEXT, -- 'stock', 'crypto', 'gold', 'forex'
    quantity NUMERIC NOT NULL DEFAULT 0,
    average_cost NUMERIC DEFAULT 0,
    currency TEXT DEFAULT 'USD',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, symbol) -- Prevent duplicates of same asset for same user
);

-- RLS for portfolio
ALTER TABLE user_portfolio_assets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own portfolio" 
ON user_portfolio_assets FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own portfolio" 
ON user_portfolio_assets FOR ALL 
USING (auth.uid() = user_id);


-- 4. Watchlist
CREATE TABLE IF NOT EXISTS user_watchlists (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    symbol TEXT NOT NULL,
    asset_type TEXT,
    added_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, symbol)
);

-- RLS for watchlist
ALTER TABLE user_watchlists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own watchlist" 
ON user_watchlists FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own watchlist" 
ON user_watchlists FOR ALL 
USING (auth.uid() = user_id);


-- 5. Sync Logs (Optional, to track last sync time)
CREATE TABLE IF NOT EXISTS user_sync_status (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE PRIMARY KEY,
    last_synced_at TIMESTAMPTZ DEFAULT NOW(),
    device_id TEXT
);

ALTER TABLE user_sync_status ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own sync status" ON user_sync_status FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own sync status" ON user_sync_status FOR ALL USING (auth.uid() = user_id);
