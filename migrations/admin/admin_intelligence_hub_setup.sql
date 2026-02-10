-- ============================================
-- ADMIN INTELLIGENCE HUB BİG SETUP
-- ============================================

-- 1. TABLO: Audit Logs (Gelişmiş)
-- Bu tablo veritabanı seviyesindeki (Trigger) tüm CRUD işlemlerini tutar.
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    admin_id UUID DEFAULT auth.uid(), -- İşlemi yapan admin (varsa)
    action TEXT NOT NULL, -- INSERT, UPDATE, DELETE, LOGIN vb.
    table_name TEXT, 
    record_id TEXT, -- Etkilenen satırın ID'si
    old_data JSONB,
    new_data JSONB,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. TABLO: User Activities (Live Feed için)
-- Bu tablo uygulama içindeki aksiyonları (Sayfa görüntüleme, buton tıklama vb.) tutar.
CREATE TABLE IF NOT EXISTS user_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL, -- page_view, feature_use, click
    activity_name TEXT NOT NULL, -- "Dashboard", "Add Transaction"
    metadata JSONB DEFAULT '{}',
    client_info JSONB DEFAULT '{}', -- OS, App Version vb.
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Realtime yayını aç
ALTER PUBLICATION supabase_realtime ADD TABLE user_activities;
ALTER PUBLICATION supabase_realtime ADD TABLE audit_logs;

-- 3. AUDIT TRIGGER FONKSİYONU
CREATE OR REPLACE FUNCTION process_audit_log()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Eğer context'te user varsa al (genelde auth.uid())
    BEGIN
        v_user_id := auth.uid();
    EXCEPTION WHEN OTHERS THEN
        v_user_id := NULL;
    END;

    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_logs (user_id, action, table_name, record_id, old_data, created_at)
        VALUES (COALESCE(OLD.user_id, v_user_id), 'DELETE', TG_TABLE_NAME, OLD.id::TEXT, to_jsonb(OLD), NOW());
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_logs (user_id, action, table_name, record_id, old_data, new_data, created_at)
        VALUES (COALESCE(NEW.user_id, v_user_id), 'UPDATE', TG_TABLE_NAME, NEW.id::TEXT, to_jsonb(OLD), to_jsonb(NEW), NOW());
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_logs (user_id, action, table_name, record_id, new_data, created_at)
        VALUES (COALESCE(NEW.user_id, v_user_id), 'INSERT', TG_TABLE_NAME, NEW.id::TEXT, to_jsonb(NEW), NOW());
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. TRIGGERLARI BAĞLA
-- Not: Her tabloya eklenmeden önce varlığı kontrol edilmeli.

-- TRANSACTIONS Audit
DROP TRIGGER IF EXISTS trg_audit_transactions ON user_transactions;
CREATE TRIGGER trg_audit_transactions
AFTER INSERT OR UPDATE OR DELETE ON user_transactions
FOR EACH ROW EXECUTE FUNCTION process_audit_log();

-- PORTFOLIO Audit
DROP TRIGGER IF EXISTS trg_audit_portfolio ON user_portfolio_assets;
CREATE TRIGGER trg_audit_portfolio
AFTER INSERT OR UPDATE OR DELETE ON user_portfolio_assets
FOR EACH ROW EXECUTE FUNCTION process_audit_log();

-- WATCHLIST Audit
DROP TRIGGER IF EXISTS trg_audit_watchlist ON user_watchlists;
CREATE TRIGGER trg_audit_watchlist
AFTER INSERT OR UPDATE OR DELETE ON user_watchlists
FOR EACH ROW EXECUTE FUNCTION process_audit_log();

-- USERS Audit
DROP TRIGGER IF EXISTS trg_audit_users ON users;
CREATE TRIGGER trg_audit_users
AFTER UPDATE ON users -- Insert'ü auth tarafı yapıyor, Delete genelde soft-delete
FOR EACH ROW EXECUTE FUNCTION process_audit_log();

-- 5. RPC: Gelişmiş Kullanıcı Arama ve Filtreleme
CREATE OR REPLACE FUNCTION search_users_intelligence(
    p_search TEXT DEFAULT '',
    p_role TEXT DEFAULT NULL,
    p_status TEXT DEFAULT NULL,
    p_limit INT DEFAULT 50,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    email TEXT,
    display_name TEXT,
    is_premium BOOLEAN,
    last_seen_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    total_assets_count BIGINT,
    total_transactions_count BIGINT,
    account_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.email::TEXT,
        u.display_name::TEXT,
        u.is_premium,
        u.last_seen_at,
        u.created_at,
        (SELECT COUNT(*) FROM user_portfolio_assets WHERE user_id = u.id) as total_assets_count,
        (SELECT COUNT(*) FROM user_transactions WHERE user_id = u.id) as total_transactions_count,
        CASE 
            WHEN u.is_banned THEN 'BANNED'
            WHEN u.deleted_at IS NOT NULL THEN 'DELETED'
            WHEN u.last_seen_at > NOW() - INTERVAL '5 minutes' THEN 'ONLINE'
            ELSE 'OFFLINE'
        END as account_status
    FROM users u
    WHERE (u.email ILIKE '%' || p_search || '%' OR u.display_name ILIKE '%' || p_search || '%')
    AND (p_role IS NULL OR (p_role = 'premium' AND u.is_premium = true) OR (p_role = 'free' AND u.is_premium = false))
    ORDER BY u.last_seen_at DESC NULLS LAST
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. RPC: Live Event Feed (Realtime öncesi fallback)
CREATE OR REPLACE FUNCTION get_intelligence_live_feed(p_limit INT DEFAULT 20)
RETURNS TABLE (
    id UUID,
    user_email TEXT,
    activity_type TEXT,
    activity_name TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ua.id,
        u.email::TEXT as user_email,
        ua.activity_type,
        ua.activity_name,
        ua.metadata,
        ua.created_at
    FROM user_activities ua
    JOIN users u ON ua.user_id = u.id
    ORDER BY ua.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
