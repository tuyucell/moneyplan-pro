-- 1. AI Usage Tracking (Fair Usage Policy)
-- Tracks how many times a user uses the AI tools per month
CREATE TABLE IF NOT EXISTS user_ai_usage (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    analysis_type TEXT NOT NULL, -- 'health_check', 'purchase_advice'
    usage_count INT DEFAULT 0,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    reset_date DATE DEFAULT (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day'),
    PRIMARY KEY (user_id, analysis_type)
);

ALTER TABLE user_ai_usage ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can only see their own usage" ON user_ai_usage;
CREATE POLICY "Users can only see their own usage" 
ON user_ai_usage FOR SELECT 
USING (auth.uid() = user_id);

-- 2. Market Interest Rates (For Smart Purchase Decisions)
-- Stores current financial market indicators updated by Admin or Cron
CREATE TABLE IF NOT EXISTS market_interest_rates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    type TEXT UNIQUE NOT NULL, -- 'deposit_monthly', 'loan_monthly', 'inflation_monthly'
    rate NUMERIC NOT NULL, -- Percentage (e.g., 3.5 for 3.5%)
    description TEXT,
    last_updated TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE market_interest_rates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read access for market rates" ON market_interest_rates;
CREATE POLICY "Public read access for market rates" ON market_interest_rates FOR SELECT USING (true);

-- Seed Initial Market Data (Turkey Context - Example Rates)
INSERT INTO market_interest_rates (type, rate, description) VALUES
('deposit_monthly', 3.5, 'Ortalama Aylık Mevduat Faizi (32 Gün)'),
('credit_card_monthly', 4.25, 'Kredi Kartı Akdi/Gecikme Faizi'),
('inflation_monthly', 3.0, 'Tahmini Aylık Enflasyon')
ON CONFLICT (type) DO UPDATE 
SET rate = EXCLUDED.rate, last_updated = NOW();

-- 3. Check & Increment Usage (RPC)
-- Handles limit checking and auto-resetting monthly counters
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
BEGIN
    -- Check Premium Status
    SELECT COALESCE(is_premium, false) INTO v_is_premium FROM users WHERE id = p_user_id;
    
    -- Set Limit (Configurable)
    v_limit := CASE WHEN v_is_premium THEN 10 ELSE 3 END; -- 3/Month Free, 10/Month Pro
    
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

-- 4. Purchase Decision RPC (NPV Calculation)
-- Calculates whether it's better to pay cash or use installments based on opportunity cost
-- Now supports Optional Custom Rate (e.g. user's own bank offer)

-- DROP OLD SIGNATURES TO PREVENT AMBIGUITY (PGRST203)
DROP FUNCTION IF EXISTS analyze_purchase_decision(numeric, int, numeric);
DROP FUNCTION IF EXISTS analyze_purchase_decision(numeric, int, numeric, numeric);

CREATE OR REPLACE FUNCTION analyze_purchase_decision(
    p_amount NUMERIC, 
    p_installments INT, 
    p_installment_amount NUMERIC,
    p_custom_rate NUMERIC DEFAULT NULL -- Optional: User provided monthly interest rate
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_deposit_rate NUMERIC;
    v_total_installment_cost NUMERIC;
    v_npv_cost NUMERIC := 0;
    v_recommendation TEXT;
    i INT;
    v_opportunity_gain NUMERIC;
BEGIN
    -- 1. Determine Interest Rate
    IF p_custom_rate IS NOT NULL AND p_custom_rate > 0 THEN
        v_deposit_rate := p_custom_rate;
    ELSE
        -- Get default market rate
        SELECT rate INTO v_deposit_rate FROM market_interest_rates WHERE type = 'deposit_monthly';
        -- Fallback
        IF v_deposit_rate IS NULL THEN v_deposit_rate := 3.5; END IF;
    END IF;

    -- Calculate Totals
    v_total_installment_cost := p_installments * p_installment_amount;
    
    -- NPV Calculation
    FOR i IN 1..p_installments LOOP
        v_npv_cost := v_npv_cost + (p_installment_amount / power((1 + v_deposit_rate/100.0), i));
    END LOOP;

    -- Decision Logic
    IF v_npv_cost < p_amount THEN
        v_recommendation := 'INSTALLMENT';
        v_opportunity_gain := p_amount - v_npv_cost;
    ELSE
        v_recommendation := 'CASH';
        v_opportunity_gain := v_npv_cost - p_amount; 
    END IF;

    RETURN jsonb_build_object(
        'recommendation', v_recommendation,
        'market_rate', v_deposit_rate,
        'is_custom_rate', (p_custom_rate IS NOT NULL AND p_custom_rate > 0),
        'cash_price', p_amount,
        'total_installment_price', v_total_installment_cost,
        'npv_cost', round(v_npv_cost, 2),
        'opportunity_gain', round(v_opportunity_gain, 2),
        'message', CASE 
            WHEN v_recommendation = 'INSTALLMENT' THEN 
                format('Taksitli alım daha avantajlı! Nakit paranı aylık %s oranla mevduatta değerlendirirsen, vade farkına rağmen %s TL değer kazanırsın.', v_deposit_rate, round(v_opportunity_gain, 2))
            ELSE 
                format('Nakit alım daha avantajlı. Taksitli seçenekteki toplam ödeme çok yüksek, mevduat getirisini (%s TL) aşıyor.', round(v_opportunity_gain, 2))
            END
    );
END;
$$;
