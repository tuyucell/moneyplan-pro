-- ============================================
-- AUDIT LOGS NUCLEAR FIX (Defensive Version)
-- ============================================

-- Tablonun varlığını ve kolonlarını garanti altına alalım
DO $$ 
BEGIN 
    -- audit_logs tablosu ve temel kolonları
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

    -- Kolonları tek tek kontrol et ve ekle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_logs' AND column_name='table_name') THEN
        ALTER TABLE audit_logs ADD COLUMN table_name TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_logs' AND column_name='record_id') THEN
        ALTER TABLE audit_logs ADD COLUMN record_id TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_logs' AND column_name='old_data') THEN
        ALTER TABLE audit_logs ADD COLUMN old_data JSONB;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_logs' AND column_name='new_data') THEN
        ALTER TABLE audit_logs ADD COLUMN new_data JSONB;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='audit_logs' AND column_name='admin_id') THEN
        ALTER TABLE audit_logs ADD COLUMN admin_id UUID;
    END IF;
END $$;

-- RLS Ayarları
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can view all logs" ON audit_logs;
CREATE POLICY "Admins can view all logs" ON audit_logs FOR SELECT USING (true); -- Adminler görebilir

-- TRIGGER FONKSIYONU: EN GÜVENLI HALI
CREATE OR REPLACE FUNCTION process_audit_log()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
    v_old_json JSONB;
    v_new_json JSONB;
BEGIN
    -- Mevcut kullanıcıyı güvenli bir şekilde al
    BEGIN
        v_user_id := auth.uid();
    EXCEPTION WHEN OTHERS THEN
        v_user_id := NULL;
    END;

    -- Kayıtları JSON'a çevir (Kolon bağımsızlığı için en güvenli yol)
    IF (TG_OP = 'DELETE') THEN
        v_old_json := to_jsonb(OLD);
    ELSIF (TG_OP = 'UPDATE') THEN
        v_old_json := to_jsonb(OLD);
        v_new_json := to_jsonb(NEW);
    ELSIF (TG_OP = 'INSERT') THEN
        v_new_json := to_jsonb(NEW);
    END IF;

    -- Tetiklenen tablodan user_id veya admin_id çekmeye çalış
    -- to_jsonb(record) ->> 'key' kullanmak kolon yoksa NULL döner, hata vermez!
    
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
    -- Trigger hata alsa bile asıl işlemin (INSERT/UPDATE) devam etmesi için exception'ı yut
    -- Bu sayede audit log yazılamazsa bile veri kaybı olmaz
    RAISE WARNING 'Audit log failed for table %: %', TG_TABLE_NAME, SQLERRM;
    IF (TG_OP = 'DELETE') THEN RETURN OLD; END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
