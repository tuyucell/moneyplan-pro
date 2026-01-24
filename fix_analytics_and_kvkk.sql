/**
 * INVESTGUIDE ANALYTICS TEMİZLİĞİ VE KVKK ALTYAPISI
 * -----------------------------------------------
 * Bu script iki ana iş yapar:
 * 1. Analytics grafiklerini kirleten test verilerini (Demographics) sıfırlar.
 * 2. Kullanıcıların hesap silme talebi göndermesi için gerekli tabloyu oluşturur.
 */

-- ============================================
-- 1. ANALYTICS TEMİZLİĞİ (Demographics Reset)
-- ============================================
UPDATE users 
SET 
    gender = NULL,
    birth_year = NULL,
    occupation = NULL,
    financial_goal = NULL,
    risk_tolerance = NULL,
    is_profile_completed = FALSE;

-- ============================================
-- 2. KVKK SİLME TALEPLERİ TABLOSU
-- ============================================
CREATE TABLE IF NOT EXISTS account_deletion_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    reason TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    processed_by UUID REFERENCES users(id)
);

-- Index'ler
CREATE INDEX IF NOT EXISTS idx_deletion_status ON account_deletion_requests(status);

-- ============================================
-- 3. FONKSYİON: TALEP OLUŞTURMA (User Tarafı)
-- ============================================
CREATE OR REPLACE FUNCTION request_account_deletion(p_reason TEXT)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    -- Eğer zaten bekleyen bir talep varsa tekrar oluşturma
    IF EXISTS (SELECT 1 FROM account_deletion_requests WHERE user_id = v_user_id AND status = 'pending') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Active request already exists');
    END IF;

    INSERT INTO account_deletion_requests (user_id, reason)
    VALUES (v_user_id, p_reason);

    RETURN jsonb_build_object('success', true);
END;
$$;

-- ============================================
-- 4. FONKSYİON: TALEBİ ONAYLA (Admin Tarafı)
-- ============================================
CREATE OR REPLACE FUNCTION approve_deletion_request(p_request_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_target_user_id UUID;
    v_admin_id UUID;
BEGIN
    v_admin_id := auth.uid(); -- Admin yetkisi kontrolü frontend'de de yapılmalı
    
    SELECT user_id INTO v_target_user_id 
    FROM account_deletion_requests 
    WHERE id = p_request_id AND status = 'pending';

    IF v_target_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Request not found or already processed');
    END IF;

    -- 1. Kullanıcıyı soft-delete yap
    UPDATE users 
    SET 
        deleted_at = NOW(),
        is_active = FALSE 
    WHERE id = v_target_user_id;

    -- 2. Talebi güncelle
    UPDATE account_deletion_requests 
    SET 
        status = 'approved', 
        processed_at = NOW(),
        processed_by = v_admin_id
    WHERE id = p_request_id;

    RETURN jsonb_build_object('success', true);
END;
$$;

GRANT EXECUTE ON FUNCTION request_account_deletion(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION approve_deletion_request(UUID) TO authenticated;

DO $$
BEGIN
  RAISE NOTICE '✅ Analytics Cleared & KVKK Infrastructure Ready!';
END $$;
