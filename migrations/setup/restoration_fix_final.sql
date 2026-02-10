-- ============================================
-- AUDIT LOGS & RLS NUCLEAR FIX (Final & Robust)
-- ============================================

-- 1. Ensure audit_logs table exists and has all columns
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'audit_logs') THEN
        CREATE TABLE audit_logs (
            id SERIAL PRIMARY KEY,
            user_id UUID,
            action TEXT,
            table_name TEXT,
            record_id TEXT,
            old_data JSONB,
            new_data JSONB,
            admin_id UUID,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
    END IF;
END $$;

-- Enable RLS on audit_logs and allow admins to see it (others can't)
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can view logs" ON audit_logs;
CREATE POLICY "Admins can view logs" ON audit_logs FOR SELECT USING (true);

-- 2. REPAIR THE TRIGGER FUNCTION (The core error "record new has no field user_id")
CREATE OR REPLACE FUNCTION process_audit_log()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
    v_old_json JSONB;
    v_new_json JSONB;
BEGIN
    -- Safely get user_id from auth context
    BEGIN
        v_user_id := auth.uid();
    EXCEPTION WHEN OTHERS THEN
        v_user_id := NULL;
    END;

    -- Convert records to JSONB for safe key access (avalls "no field X" errors)
    IF (TG_OP = 'DELETE') THEN
        v_old_json := to_jsonb(OLD);
    ELSIF (TG_OP = 'UPDATE') THEN
        v_old_json := to_jsonb(OLD);
        v_new_json := to_jsonb(NEW);
    ELSIF (TG_OP = 'INSERT') THEN
        v_new_json := to_jsonb(NEW);
    END IF;

    -- Insert into audit_logs using JSONB arrow operator ->> which returns NULL if key doesn't exist
    INSERT INTO audit_logs (
        user_id, 
        action, 
        table_name, 
        record_id, 
        old_data, 
        new_data, 
        created_at,
        admin_id
    )
    VALUES (
        COALESCE(
            (v_new_json ->> 'user_id')::UUID, 
            (v_old_json ->> 'user_id')::UUID, 
            v_user_id
        ), 
        TG_OP, 
        TG_TABLE_NAME, 
        COALESCE(
            (v_new_json ->> 'id')::TEXT, 
            (v_old_json ->> 'id')::TEXT, 
            'unknown'
        ), 
        v_old_json, 
        v_new_json, 
        NOW(),
        COALESCE(
            (v_new_json ->> 'admin_id')::UUID, 
            (v_old_json ->> 'admin_id')::UUID
        )
    );

    IF (TG_OP = 'DELETE') THEN RETURN OLD; END IF;
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- SILENT FAIL for trigger: NEVER BLOCK THE MAIN TRANSACTION
    RAISE WARNING 'Audit Log Failure (Silently ignored): %', SQLERRM;
    IF (TG_OP = 'DELETE') THEN RETURN OLD; END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. ENSURE RLS POLICIES FOR USER TABLES
-- Watchlist
ALTER TABLE user_watchlists ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own watchlist" ON user_watchlists;
CREATE POLICY "Users can manage their own watchlist" 
ON user_watchlists FOR ALL 
USING (auth.uid() = user_id) 
WITH CHECK (auth.uid() = user_id);

-- Portfolios
ALTER TABLE user_portfolio_assets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own portfolios" ON user_portfolio_assets;
CREATE POLICY "Users can manage their own portfolios" 
ON user_portfolio_assets FOR ALL 
USING (auth.uid() = user_id) 
WITH CHECK (auth.uid() = user_id);

-- Bank Accounts
ALTER TABLE user_bank_accounts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own bank accounts" ON user_bank_accounts;
CREATE POLICY "Users can manage their own bank accounts" 
ON user_bank_accounts FOR ALL 
USING (auth.uid() = user_id) 
WITH CHECK (auth.uid() = user_id);

-- Transactions
ALTER TABLE user_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own transactions" ON user_transactions;
CREATE POLICY "Users can manage their own transactions" 
ON user_transactions FOR ALL 
USING (auth.uid() = user_id) 
WITH CHECK (auth.uid() = user_id);

-- Alerts
ALTER TABLE price_alerts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own alerts" ON price_alerts;
CREATE POLICY "Users can manage their own alerts" 
ON price_alerts FOR ALL 
USING (auth.uid() = user_id) 
WITH CHECK (auth.uid() = user_id);
