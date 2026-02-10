-- ============================================
-- STRATEGIC DECISION & ANALYTICS RPCS
-- ============================================

-- 1. COHORT RETENTION ANALYSIS
-- Kullanıcıların kayıt olduktan sonraki tutunma oranlarını (haftalık) hesaplar.
CREATE OR REPLACE FUNCTION get_cohort_retention()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    WITH user_cohorts AS (
        SELECT 
            id as user_id,
            date_trunc('week', created_at) as cohort_week
        FROM users
        WHERE created_at > NOW() - INTERVAL '12 weeks'
    ),
    activity_weeks AS (
        SELECT 
            user_id,
            date_trunc('week', created_at) as activity_week
        FROM user_activities
        UNION
        SELECT 
            user_id,
            date_trunc('week', created_at) as activity_week
        FROM audit_logs
    ),
    retention_counts AS (
        SELECT 
            c.cohort_week,
            (EXTRACT(DAY FROM (a.activity_week - c.cohort_week)) / 7)::INT as week_number,
            COUNT(DISTINCT c.user_id) as active_users
        FROM user_cohorts c
        LEFT JOIN activity_weeks a ON c.user_id = a.user_id AND a.activity_week >= c.cohort_week
        GROUP BY 1, 2
    ),
    cohort_sizes AS (
        SELECT cohort_week, COUNT(user_id) as cohort_size
        FROM user_cohorts
        GROUP BY 1
    )
    SELECT json_agg(row_to_json(data)) INTO result
    FROM (
        SELECT 
            r.cohort_week::TEXT,
            r.week_number,
            r.active_users,
            s.cohort_size,
            ROUND((r.active_users::FLOAT / s.cohort_size::FLOAT) * 100) as retention_rate
        FROM retention_counts r
        JOIN cohort_sizes s ON r.cohort_week = s.cohort_week
        ORDER BY r.cohort_week DESC, r.week_number ASC
    ) data;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. FEATURE USAGE HEATMAP / DISTRIBUTION
-- Kullanıcıların işlem tiplerine göre (Insert/Update yerine) anlamlı özellik kullanımını döner
CREATE OR REPLACE FUNCTION get_feature_usage_distribution()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT json_agg(row_to_json(data)) INTO result
    FROM (
        SELECT 
            CASE 
                -- Portföy İşlemleri
                WHEN table_name = 'user_portfolio_assets' AND action = 'INSERT' THEN 'Added Asset to Portfolio'
                WHEN table_name = 'user_portfolio_assets' AND action = 'UPDATE' THEN 'Updated Asset'
                WHEN table_name = 'user_portfolio_assets' AND action = 'DELETE' THEN 'Removed Asset'
                -- İzleme Listesi
                WHEN table_name = 'user_watchlists' AND action = 'INSERT' THEN 'Added to Watchlist'
                WHEN table_name = 'user_watchlists' AND action = 'DELETE' THEN 'Removed from Watchlist'
                -- Kullanıcı İşlemleri
                WHEN action = 'LOGIN' THEN 'User Login'
                WHEN table_name = 'users' AND action = 'UPDATE' THEN 'Profile Update'
                -- Diğer
                ELSE CONCAT(INITCAP(action), ' ', INITCAP(table_name))
            END as activity_name,
            'Interaction' as activity_type,
            COUNT(*) as usage_count,
            COUNT(DISTINCT user_id) as unique_users,
            ROUND(COUNT(*)::FLOAT / NULLIF((SELECT COUNT(*) FROM audit_logs), 0)::FLOAT * 100) as percentage
        FROM audit_logs
        WHERE created_at > NOW() - INTERVAL '30 days'
        GROUP BY 1
        ORDER BY usage_count DESC
        LIMIT 10
    ) data;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2.1 PAGE VISITS ANALYTICS (Duration & Clicks)
-- Bu tablo frontend tarafından doldurulmalıdır, şimdilik mock veri ile çalışacak
CREATE TABLE IF NOT EXISTS page_visits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    page_path TEXT NOT NULL,
    duration_seconds INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Frontend'den çağrılacak analiz fonksiyonu: Kategori Bazlı Isı Haritası (Heatmap) için
DROP FUNCTION IF EXISTS get_page_engagement_stats(integer);

CREATE OR REPLACE FUNCTION get_page_engagement_stats(p_days_back INT DEFAULT 30)
RETURNS TABLE (
    category TEXT,
    page_path TEXT,
    avg_duration_seconds NUMERIC,
    total_views BIGINT,
    unique_visitors BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE 
            WHEN pv.page_path LIKE '/market%' THEN 'Markets'
            WHEN pv.page_path LIKE '/portfolio%' THEN 'Wallet (Portfolio)'
            WHEN pv.page_path LIKE '/watchlist%' THEN 'Wallet (Watchlist)'
            WHEN pv.page_path LIKE '/analysis%' THEN 'Tools & Analysis'
            WHEN pv.page_path LIKE '/settings%' THEN 'Settings'
            WHEN pv.page_path = '/dashboard' THEN 'Dashboard'
            ELSE 'Other'
        END as category,
        pv.page_path,
        ROUND(AVG(pv.duration_seconds)::NUMERIC, 1) as avg_duration,
        COUNT(*)::BIGINT as views,
        COUNT(DISTINCT pv.user_id)::BIGINT as visitors
    FROM page_visits pv
    WHERE pv.created_at > NOW() - INTERVAL '1 day' * p_days_back
    GROUP BY 1, 2
    ORDER BY views DESC
    LIMIT 50;
END;
$$;

-- 2.2 GENERATE MOCK DATA (Hierarchical)
CREATE OR REPLACE FUNCTION generate_mock_page_visits()
RETURNS VOID AS $$
DECLARE
    r RECORD;
    -- Paths for heatmap simulation
    v_paths TEXT[] := ARRAY[
        -- Markets
        '/market/BTC', '/market/ETH', '/market/SOL', '/market/AVAX', '/market/XAU', '/market/USD',
        -- Wallet
        '/portfolio/main', '/portfolio/details/1', '/watchlist/main', '/watchlist/crypto',
        -- Tools
        '/analysis/gold', '/analysis/risk-calculator', '/analysis/sentiment',
        -- General
        '/dashboard', '/settings/profile', '/settings/notifications'
    ];
    v_path TEXT;
    v_duration INT;
BEGIN
    -- Clear old mock data just in case
    DELETE FROM page_visits WHERE duration_seconds > 0; 
    
    FOR r IN SELECT id FROM users LIMIT 30 LOOP
        -- Generate 20 visits per user
        FOR i IN 1..20 LOOP
            v_path := v_paths[floor(random() * array_length(v_paths, 1) + 1)::INT];
            v_duration := floor(random() * 600 + 10)::INT; -- 10s to 600s
            
            INSERT INTO page_visits (user_id, page_path, duration_seconds, created_at)
            VALUES (r.id, v_path, v_duration, NOW() - (random() * interval '30 days'));
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 3. USER SEGMENTATION (Power vs Casual)
-- Kullanıcıları son 30 günlük eylem sıklığına göre segmente eder.
CREATE OR REPLACE FUNCTION get_user_segmentation()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    WITH user_stats AS (
        SELECT 
            u.id,
            u.email,
            u.is_premium,
            COUNT(ua.id) as activity_count,
            MAX(ua.created_at) as last_activity
        FROM users u
        LEFT JOIN user_activities ua ON u.id = ua.user_id AND ua.created_at > NOW() - INTERVAL '30 days'
        GROUP BY u.id, u.email, u.is_premium
    )
    SELECT json_agg(row_to_json(data)) INTO result
    FROM (
        SELECT 
            CASE 
                WHEN activity_count > 50 THEN 'Power User'
                WHEN activity_count BETWEEN 10 AND 50 THEN 'Active User'
                WHEN activity_count BETWEEN 1 AND 9 THEN 'Casual User'
                ELSE 'At-Risk / Inactive'
            END as segment,
            COUNT(*) as user_count,
            SUM(CASE WHEN is_premium THEN 1 ELSE 0 END) as premium_count
        FROM user_stats
        GROUP BY 1
    ) data;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. ANOMALY & FRAUD DETECTION
-- Şüpheli IP değişiklikleri veya saniyeler içinde aşırı işlem yapanları döner.
CREATE OR REPLACE FUNCTION get_anomaly_detection()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT json_agg(row_to_json(data)) INTO result
    FROM (
        -- IP Değişikliği Analizi
        SELECT 
            'Multi-IP Usage' as anomaly_type,
            u.email as user_email,
            COUNT(DISTINCT al.ip_address) as ip_count,
            jsonb_agg(DISTINCT al.ip_address) as ips,
            MAX(al.created_at) as latest_event,
            'High' as severity
        FROM audit_logs al
        JOIN users u ON al.user_id = u.id
        WHERE al.created_at > NOW() - INTERVAL '7 days'
        GROUP BY u.email
        HAVING COUNT(DISTINCT al.ip_address) > 3
        
        UNION ALL
        
        -- Aşırı Hızlı İşlem Analizi (Bot şüphesi)
        SELECT 
            'Bot-like Activity' as anomaly_type,
            u.email as user_email,
            COUNT(*) as action_count,
            jsonb_build_object('actions_per_min', COUNT(*) / 10) as metadata,
            MAX(al.created_at) as latest_event,
            'Critical' as severity
        FROM audit_logs al
        JOIN users u ON al.user_id = u.id
        WHERE al.created_at > NOW() - INTERVAL '10 minutes'
        GROUP BY u.email
        HAVING COUNT(*) > 100
    ) data;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. FUNNEL ANALYSIS (Drop-off Points)
-- Kullanıcı yaşam döngüsü hunisi: Kayıt -> Giriş -> İzleme Listesi -> Portföy
CREATE OR REPLACE FUNCTION get_funnel_analysis()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    WITH funnel_steps AS (
        SELECT 1 as step, 'Registration' as stage, COUNT(*) as count FROM users
        UNION ALL
        SELECT 2 as step, 'Active Session' as stage, COUNT(DISTINCT user_id) as count FROM audit_logs WHERE action = 'LOGIN'
        UNION ALL
        SELECT 3 as step, 'Created Watchlist' as stage, COUNT(DISTINCT user_id) as count FROM user_watchlists
        UNION ALL
        SELECT 4 as step, 'Created Portfolio' as stage, COUNT(DISTINCT user_id) as count FROM user_portfolio_assets
    )
    SELECT json_agg(row_to_json(data)) INTO result
    FROM (
        SELECT *, 
            LAG(count) OVER (ORDER BY step) as prev_count,
            ROUND((count::FLOAT / NULLIF(LAG(count) OVER (ORDER BY step), 0)::FLOAT) * 100) as conversion_rate
        FROM funnel_steps
        ORDER BY step
    ) data;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
