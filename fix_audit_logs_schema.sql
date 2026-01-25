-- ============================================
-- AUDIT LOGS REPAIR SCRIPT
-- ============================================

-- Tablonun varlığını ve kolonlarını garanti altına alalım
DO $$ 
BEGIN 
    -- table_name kolonu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_logs' AND column_name='table_name') THEN
        ALTER TABLE audit_logs ADD COLUMN table_name TEXT;
    END IF;

    -- record_id kolonu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_logs' AND column_name='record_id') THEN
        ALTER TABLE audit_logs ADD COLUMN record_id TEXT;
    END IF;

    -- old_data kolonu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_logs' AND column_name='old_data') THEN
        ALTER TABLE audit_logs ADD COLUMN old_data JSONB;
    END IF;

    -- new_data kolonu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_logs' AND column_name='new_data') THEN
        ALTER TABLE audit_logs ADD COLUMN new_data JSONB;
    END IF;

    -- admin_id kolonu yoksa ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_logs' AND column_name='admin_id') THEN
        ALTER TABLE audit_logs ADD COLUMN admin_id UUID DEFAULT auth.uid();
    END IF;
END $$;

-- Trigger fonksiyonunu yeniden oluştur (Garanti için)
CREATE OR REPLACE FUNCTION process_audit_log()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    BEGIN
        v_user_id := auth.uid();
    EXCEPTION WHEN OTHERS THEN
        v_user_id := NULL;
    END;

    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_logs (user_id, action, table_name, record_id, old_data, created_at)
        VALUES (
            COALESCE((to_jsonb(OLD) ->> 'user_id')::UUID, v_user_id), 
            'DELETE', 
            TG_TABLE_NAME, 
            OLD.id::TEXT, 
            to_jsonb(OLD), 
            NOW()
        );
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_logs (user_id, action, table_name, record_id, old_data, new_data, created_at)
        VALUES (
            COALESCE((to_jsonb(NEW) ->> 'user_id')::UUID, v_user_id), 
            'UPDATE', 
            TG_TABLE_NAME, 
            NEW.id::TEXT, 
            to_jsonb(OLD), 
            to_jsonb(NEW), 
            NOW()
        );
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_logs (user_id, action, table_name, record_id, new_data, created_at)
        VALUES (
            COALESCE((to_jsonb(NEW) ->> 'user_id')::UUID, v_user_id), 
            'INSERT', 
            TG_TABLE_NAME, 
            NEW.id::TEXT, 
            to_jsonb(NEW), 
            NOW()
        );
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
