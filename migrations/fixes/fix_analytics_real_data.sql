-- ============================================
-- Analytics Real Data Fix Script
-- ============================================
-- Bu script, Analytics sayfasındaki son dummy verileri temizler ve
-- fonksiyonları gerçek 'audit_logs' ve 'users' verilerine bağlar.

-- 0. Audit Logs Tablosunun Varlığını Garantiye Al
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    action TEXT,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    ip_address TEXT
);

-- 1. FIX: Retention Cohorts (Gerçek Veri Hesaplaması)
CREATE OR REPLACE FUNCTION get_retention_cohorts()
RETURNS TABLE (
    period_start DATE,
    new_users BIGINT,
    day_1_retention NUMERIC,
    day_7_retention NUMERIC,
    day_14_retention NUMERIC,
    day_30_retention NUMERIC
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    WITH cohorts AS (
        SELECT DATE_TRUNC('week', created_at)::DATE as c_date, id, created_at
        FROM users
        WHERE created_at > NOW() - INTERVAL '6 months' AND deleted_at IS NULL
    )
    SELECT 
        c_date as period_start,
        COUNT(DISTINCT id)::BIGINT as new_users,
        ROUND(COUNT(DISTINCT CASE WHEN EXISTS (SELECT 1 FROM audit_logs a WHERE a.user_id = cohorts.id AND a.created_at >= cohorts.created_at + INTERVAL '1 day') THEN id END)::NUMERIC / NULLIF(COUNT(DISTINCT id), 0) * 100, 1) as day_1_retention,
        ROUND(COUNT(DISTINCT CASE WHEN EXISTS (SELECT 1 FROM audit_logs a WHERE a.user_id = cohorts.id AND a.created_at >= cohorts.created_at + INTERVAL '7 days') THEN id END)::NUMERIC / NULLIF(COUNT(DISTINCT id), 0) * 100, 1) as day_7_retention,
        ROUND(COUNT(DISTINCT CASE WHEN EXISTS (SELECT 1 FROM audit_logs a WHERE a.user_id = cohorts.id AND a.created_at >= cohorts.created_at + INTERVAL '14 days') THEN id END)::NUMERIC / NULLIF(COUNT(DISTINCT id), 0) * 100, 1) as day_14_retention,
        ROUND(COUNT(DISTINCT CASE WHEN EXISTS (SELECT 1 FROM audit_logs a WHERE a.user_id = cohorts.id AND a.created_at >= cohorts.created_at + INTERVAL '30 days') THEN id END)::NUMERIC / NULLIF(COUNT(DISTINCT id), 0) * 100, 1) as day_30_retention
    FROM cohorts
    GROUP BY 1
    ORDER BY 1 DESC;
END;
$$;

-- 2. FIX: At Risk Users V2 (Frontend ile Uyumlu Sütun İsimleri)
CREATE OR REPLACE FUNCTION get_at_risk_users_v2(p_limit_count INT DEFAULT 50)
RETURNS TABLE (
    user_id UUID,
    email_addr TEXT,
    display_name TEXT,
    engagement_score INT,
    days_inactive INT,
    risk_status TEXT,
    recommended_action TEXT,
    is_premium BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id as user_id,
        u.email::TEXT as email_addr,
        u.display_name::TEXT,
        -- Skor Hesaplama: Premium(50) + Son Görülme(40/20)
        (
            (CASE WHEN u.is_premium THEN 50 ELSE 0 END) +
            (CASE WHEN u.last_seen_at > NOW() - INTERVAL '7 days' THEN 40 
                  WHEN u.last_seen_at > NOW() - INTERVAL '30 days' THEN 20 
                  ELSE 0 END)
        )::INT as engagement_score,
        COALESCE(EXTRACT(DAY FROM (NOW() - COALESCE(u.last_seen_at, u.created_at))), 0)::INT as days_inactive,
        CASE 
            WHEN EXTRACT(DAY FROM (NOW() - COALESCE(u.last_seen_at, u.created_at))) > 30 THEN 'HIGH'
            WHEN EXTRACT(DAY FROM (NOW() - COALESCE(u.last_seen_at, u.created_at))) > 14 THEN 'MEDIUM'
            ELSE 'LOW'
        END as risk_status,
        'Monitor activity'::TEXT as recommended_action,
        u.is_premium
    FROM users u
    WHERE u.is_active = true AND u.deleted_at IS NULL
    -- Sadece 7 günden fazla inaktif olanları göster
    AND (u.last_seen_at < NOW() - INTERVAL '7 days' OR u.last_seen_at IS NULL)
    ORDER BY u.last_seen_at ASC NULLS FIRST
    LIMIT p_limit_count;
END;
$$;

DO $$
BEGIN
  RAISE NOTICE '✅ Analytics Functions Updated to use REAL Data!';
END $$;
