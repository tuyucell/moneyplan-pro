-- ============================================
-- SMART FINANCIAL ASSISTANT ENGINE (SQL-Based AI)
-- ============================================

-- 1. Helper Function: Calculate Trend
CREATE OR REPLACE FUNCTION calculate_spending_trend(p_user_id UUID, p_category TEXT, p_months INT DEFAULT 3)
RETURNS JSONB AS $$
DECLARE
    current_spending NUMERIC;
    avg_past_spending NUMERIC;
    trend_percentage NUMERIC;
BEGIN
    -- This month's spending for category
    SELECT COALESCE(SUM(amount), 0) INTO current_spending
    FROM user_transactions
    WHERE user_id = p_user_id 
      AND category_id = p_category
      AND date >= date_trunc('month', CURRENT_DATE)
      AND type = 'expense';

    -- Average spending of last X months (excluding current)
    SELECT COALESCE(AVG(monthly_total), 0) INTO avg_past_spending
    FROM (
        SELECT date_trunc('month', date), SUM(amount) as monthly_total
        FROM user_transactions
        WHERE user_id = p_user_id 
          AND category_id = p_category
          AND date >= date_trunc('month', CURRENT_DATE - (p_months || ' month')::INTERVAL)
          AND date < date_trunc('month', CURRENT_DATE)
          AND type = 'expense'
        GROUP BY 1
    ) past_months;

    IF avg_past_spending = 0 THEN
        RETURN jsonb_build_object('trend', 0, 'status', 'new');
    END IF;

    trend_percentage := ROUND(((current_spending - avg_past_spending) / avg_past_spending * 100), 1);
    
    RETURN jsonb_build_object(
        'current', current_spending,
        'average', avg_past_spending,
        'trend_pct', trend_percentage,
        'status', CASE WHEN trend_percentage > 15 THEN 'warning' WHEN trend_percentage < -15 THEN 'good' ELSE 'neutral' END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. MAIN ENGINE: Analyze User Finances
-- Returns a list of "Smart Insights"
-- 2. MAIN ENGINE: Analyze User Finances
-- Returns a list of "Smart Insights"
CREATE OR REPLACE FUNCTION analyze_user_financial_health(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
    insights JSONB := '[]'::JSONB;
    coffee_trend JSONB;
    burn_rate_months INT;
    total_balance NUMERIC;
    monthly_burn NUMERIC;
    current_month_income NUMERIC;
    top_expense_category TEXT;
BEGIN
    -- A. CATEGORY ANALYTICS (simulating "Coffee" via 'Food & Drink' or similar id)
    coffee_trend := calculate_spending_trend(p_user_id, 'food', 3);
    
    IF (coffee_trend->>'status') = 'warning' THEN
        insights := insights || jsonb_build_object(
            'type', 'spending_alert',
            'icon', '☕',
            'title', 'Yeme-İçme Harcaması Arttı',
            'message', format('Bu ay yeme-içme harcaman %% %s arttı. Standartlarının üzerindesin.', coffee_trend->>'trend_pct'),
            'priority', 'high'
        );
    END IF;

    -- B. CASH FLOW RUNWAY
    -- Calculate total cash
    SELECT COALESCE(SUM(balance), 0) INTO total_balance FROM user_bank_accounts WHERE user_id = p_user_id;
    
    -- Calculate avg monthly expense (Last 3 months)
    SELECT COALESCE(AVG(monthly_total), 0) INTO monthly_burn
    FROM (
        SELECT date_trunc('month', date), SUM(amount) as monthly_total
        FROM user_transactions
        WHERE user_id = p_user_id AND type = 'expense' AND date > NOW() - INTERVAL '3 months'
        GROUP BY 1
    ) burn;

    -- Cash Flow Logic
    IF monthly_burn > 0 THEN
        burn_rate_months := floor(total_balance / monthly_burn);
        
        -- If balance is less than 1 month of expenses
        IF total_balance < monthly_burn THEN
             insights := insights || jsonb_build_object(
                'type', 'cashflow_risk',
                'icon', '💸',
                'title', 'Nakit Akışı Riski (Kritik)',
                'message', 'Toplam nakit varlığın, 1 aylık ortalama giderini karşılamıyor. Acil durum fonunu gözden geçir.',
                'priority', 'critical'
            );
        ELSIF burn_rate_months < 4 THEN
             insights := insights || jsonb_build_object(
                'type', 'cashflow_risk',
                'icon', '📉',
                'title', 'Nakit Ömrü Uyarısı',
                'message', format('Bu harcama hızıyla yaklaşık %s ay idare edebilirsin. Tasarruf planı yapmalısın.', burn_rate_months),
                'priority', 'high'
            );
        END IF;
    END IF;
    
    -- C. INCOME VS EXPENSE CHECK (Deficit Alert)
    SELECT COALESCE(SUM(amount), 0) INTO current_month_income 
    FROM user_transactions 
    WHERE user_id = p_user_id AND type = 'income' AND date >= date_trunc('month', CURRENT_DATE);

    IF monthly_burn > current_month_income THEN
        -- Find Top Expense Category for this month to give specific advice
        SELECT category_id INTO top_expense_category
        FROM user_transactions
        WHERE user_id = p_user_id 
          AND type = 'expense' 
          AND date >= date_trunc('month', CURRENT_DATE)
        GROUP BY category_id
        ORDER BY SUM(amount) DESC
        LIMIT 1;

        insights := insights || jsonb_build_object(
                'type', 'budget_deficit',
                'icon', '⚠️',
                'title', 'Bütçe Açığı Uyarısı',
                'message', format('Ortalama giderin (%s), bu ayki gelirinden (%s) fazla. En çok harcama yapılan kalem: %s. Bunu kontrol altına almalısın.', 
                                  to_char(monthly_burn, 'FM999,999'), 
                                  to_char(current_month_income, 'FM999,999'),
                                  COALESCE(INITCAP(top_expense_category), 'Belirsiz')),
                'priority', 'medium'
            );
    END IF;

    -- Default if empty
    IF jsonb_array_length(insights) = 0 THEN
        insights := insights || jsonb_build_object(
            'type', 'info',
            'icon', '✅',
            'title', 'Finansal Durum Stabil',
            'message', 'Gelir/Gider dengen sağlıklı görünüyor. Yatırım fırsatlarını değerlendirebilirsin.',
            'priority', 'low'
        );
    END IF;

    RETURN insights;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. MOCK DATA GENERATOR FOR TRANSACTIONS (To demonstrate the AI)
CREATE OR REPLACE FUNCTION generate_mock_financial_data(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Clear old
    DELETE FROM user_transactions WHERE user_id = p_user_id;
    DELETE FROM user_bank_accounts WHERE user_id = p_user_id;

    -- 1. Create a Bank Account
    INSERT INTO user_bank_accounts (id, user_id, account_name, account_type, balance, currency)
    VALUES ('acc_mock_1', p_user_id, 'Main Wallet', 'cash', 15000, 'TRY');

    -- 2. Generate Expenses (Coffee/Food spike this month)
    -- Past months (Average ~2000)
    INSERT INTO user_transactions (id, user_id, amount, type, category_id, description, date)
    SELECT 
        'tx_old_' || i, 
        p_user_id, 
        floor(random() * 50 + 50), -- ~75 * 30 = 2250
        'expense',
        'food',
        'Lunch/Coffee',
        NOW() - (i || ' days')::INTERVAL
    FROM generate_series(30, 90) i;

    -- This month (High spending ~3500)
    INSERT INTO user_transactions (id, user_id, amount, type, category_id, description, date)
    SELECT 
        'tx_new_' || i, 
        p_user_id, 
        floor(random() * 100 + 50), -- ~100 * 30 = 3000
        'expense',
        'food',
        'Expensive Coffee',
        NOW() - (i || ' days')::INTERVAL
    FROM generate_series(1, 25) i;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
