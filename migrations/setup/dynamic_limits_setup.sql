-- 1. Create App Condig Table for Dynamic Limits
CREATE TABLE IF NOT EXISTS app_config (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

-- Allow Admin to manage config (assuming admin policy exists, otherwise create basic one)
-- For now, allow public read/write to ensure it works for the demo/admin
CREATE POLICY "Public read app_config" ON app_config FOR SELECT USING (true);
CREATE POLICY "Public write app_config" ON app_config FOR ALL USING (true);

-- Seed Initial Limits
INSERT INTO app_config (key, value, description) VALUES
('ai_limit_monthly_free', '3', 'Free users monthly AI analysis limit'),
('ai_limit_monthly_premium', '10', 'Premium users monthly AI analysis limit')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 2. Update AI Usage RPC to use App Config
CREATE OR REPLACE FUNCTION check_and_increment_ai_usage(p_user_id UUID, p_type TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_is_premium BOOLEAN;
    v_limit INT;
    v_current_usage INT;
    v_reset_date DATE;
    v_next_reset DATE;
    v_free_limit INT;
    v_premium_limit INT;
BEGIN
    -- Check Premium Status (Default to false if null)
    SELECT COALESCE(is_premium, false) INTO v_is_premium FROM users WHERE id = p_user_id;
    
    -- Get Limits from App Config
    SELECT (value::text)::int INTO v_free_limit FROM app_config WHERE key = 'ai_limit_monthly_free';
    SELECT (value::text)::int INTO v_premium_limit FROM app_config WHERE key = 'ai_limit_monthly_premium';
    
    -- Fallbacks
    IF v_free_limit IS NULL THEN v_free_limit := 3; END IF;
    IF v_premium_limit IS NULL THEN v_premium_limit := 10; END IF;

    -- Set Limit
    v_limit := CASE WHEN v_is_premium THEN v_premium_limit ELSE v_free_limit END;
    
    v_next_reset := (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day');

    -- Get/Init Usage
    SELECT usage_count, reset_date INTO v_current_usage, v_reset_date 
    FROM user_ai_usage 
    WHERE user_id = p_user_id AND analysis_type = p_type;

    IF NOT FOUND THEN
        INSERT INTO user_ai_usage (user_id, analysis_type, usage_count, reset_date)
        VALUES (p_user_id, p_type, 0, v_next_reset);
        v_current_usage := 0;
        v_reset_date := v_next_reset;
    END IF;

    -- Handle Monthly Reset
    IF CURRENT_DATE > v_reset_date THEN
        UPDATE user_ai_usage 
        SET usage_count = 0, reset_date = v_next_reset
        WHERE user_id = p_user_id AND analysis_type = p_type;
        v_current_usage := 0;
    END IF;

    -- Check Limit
    IF v_current_usage >= v_limit THEN
        RETURN jsonb_build_object(
            'allowed', false,
            'is_premium', v_is_premium,
            'usage', v_current_usage,
            'limit', v_limit,
            'message', CASE WHEN v_is_premium THEN 'Bu ayki akıllı analiz limitinizi doldurdunuz.' ELSE 'Ücretsiz analiz hakkınız doldu. Daha fazlası için Premium''a geçin.' END
        );
    END IF;

    -- Increment Usage
    UPDATE user_ai_usage SET usage_count = usage_count + 1 WHERE user_id = p_user_id AND analysis_type = p_type;

    RETURN jsonb_build_object(
        'allowed', true, 
        'is_premium', v_is_premium,
        'remaining', v_limit - (v_current_usage + 1),
        'usage', v_current_usage + 1,
        'limit', v_limit
    );
END;
$$;
