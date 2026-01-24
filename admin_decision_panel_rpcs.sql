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
-- Uygulama içindeki özelliklerin kullanım yoğunluğunu ve popülerliğini döner.
CREATE OR REPLACE FUNCTION get_feature_usage_distribution()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT json_agg(row_to_json(data)) INTO result
    FROM (
        SELECT 
            activity_name,
            activity_type,
            COUNT(*) as usage_count,
            COUNT(DISTINCT user_id) as unique_users,
            ROUND(COUNT(*)::FLOAT / (SELECT COUNT(*) FROM user_activities)::FLOAT * 100) as percentage
        FROM user_activities
        WHERE created_at > NOW() - INTERVAL '30 days'
        GROUP BY activity_name, activity_type
        ORDER BY usage_count DESC
    ) data;
    
    RETURN result;
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
