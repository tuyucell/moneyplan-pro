-- Financial Pilot 2.0 (Financial GPS) - Forecast Engine Upgrade
-- =============================================================

BEGIN;

-- 1. Drop old functions to avoid conflicts
DROP FUNCTION IF EXISTS calculate_financial_pilot(uuid, int, numeric, int, numeric);

-- 2. New & Improved Forecast Function
CREATE OR REPLACE FUNCTION calculate_financial_pilot(
    p_user_id uuid,
    p_months int DEFAULT 3,
    p_simulate_purchase_amount numeric DEFAULT 0,
    p_simulate_purchase_installments int DEFAULT 1,
    p_current_balance numeric DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_date date := CURRENT_DATE;
    v_end_date date := CURRENT_DATE + (p_months * 30);
    v_current_balance numeric := p_current_balance;
    v_daily_balances jsonb := '[]'::jsonb;
    v_insights jsonb := '[]'::jsonb;
    v_date date;
    v_day_balance numeric;
    
    -- Transaction sums
    v_daily_income numeric;
    v_daily_expense numeric;
    
    -- Scenario Parameters
    v_expense_multiplier numeric := 1.0;
    v_income_multiplier numeric := 1.0;
    
    -- Result
    v_result jsonb;
    v_safety_status text := 'SAFE';
    v_min_projected_balance numeric;
    v_max_projected_balance numeric;
    
    -- Insight Helpers
    v_consecutive_negative_days int := 0;
    v_first_negative_date date := NULL;
    v_large_expense_date date := NULL;
    v_large_expense_amount numeric := 0;

BEGIN
    -- 1. Determine Initial Balance (Fallback to DB only if parameter is 0)
    IF v_current_balance = 0 THEN
        SELECT COALESCE(SUM(balance), 0) INTO v_current_balance
        FROM user_bank_accounts
        WHERE user_id = p_user_id 
          AND account_type NOT IN ('Kredi Kartı', 'Kredi'); -- Focus on liquid cash
    END IF;

    -- 2. Load Active Scenario Multipliers
    SELECT 
        COALESCE(EXP(SUM(LN(NULLIF(ABS((parameters->>'expense_multiplier')::numeric), 0)))), 1.0),
        COALESCE(EXP(SUM(LN(NULLIF(ABS((parameters->>'income_multiplier')::numeric), 0)))), 1.0)
    INTO v_expense_multiplier, v_income_multiplier
    FROM scenarios
    WHERE user_id = p_user_id AND is_active = true;

    v_expense_multiplier := COALESCE(v_expense_multiplier, 1.0);
    v_income_multiplier := COALESCE(v_income_multiplier, 1.0);

    -- 3. Loop through days
    v_day_balance := v_current_balance;
    v_min_projected_balance := v_current_balance;
    v_max_projected_balance := v_current_balance;
    
    FOR i IN 0..(p_months * 30) LOOP
        v_date := v_start_date + i;
        
        -- A. Recurring Transactions (Respecting start date and end date)
        -- Logic: If monthly, match day of month. If yearly, match day and month.
        SELECT 
            COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0),
            COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0)
        INTO v_daily_income, v_daily_expense
        FROM user_transactions
        WHERE user_id = p_user_id
          AND is_recurring = true
          AND (recurrence_end_date IS NULL OR recurrence_end_date >= v_date)
          AND date <= v_date -- Must have started
          AND (
            (recurrence_type = 'monthly' AND EXTRACT(DAY FROM date) = EXTRACT(DAY FROM v_date)) OR
            (recurrence_type = 'yearly' AND EXTRACT(DAY FROM date) = EXTRACT(DAY FROM v_date) AND EXTRACT(MONTH FROM date) = EXTRACT(MONTH FROM v_date))
          );

        -- B. Future Manual Transactions (Non-recurring, already entered for the future)
        SELECT 
            v_daily_income + COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0),
            v_daily_expense + COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0)
        INTO v_daily_income, v_daily_expense
        FROM user_transactions
        WHERE user_id = p_user_id
          AND is_recurring = false
          AND date::date = v_date;

        -- Apply Scenario Multipliers
        v_daily_income := v_daily_income * v_income_multiplier;
        v_daily_expense := v_daily_expense * v_expense_multiplier;

        -- C. Apply Purchase Simulation (if today is purchase date - simplistically today)
        IF i = 0 AND p_simulate_purchase_amount > 0 THEN
             IF p_simulate_purchase_installments > 1 THEN
                 v_daily_expense := v_daily_expense + (p_simulate_purchase_amount / p_simulate_purchase_installments);
             ELSE
                 v_daily_expense := v_daily_expense + p_simulate_purchase_amount;
             END IF;
        ELSIF i > 0 AND p_simulate_purchase_installments > 1 AND (i % 30 = 0) AND (i / 30 < p_simulate_purchase_installments) THEN
             v_daily_expense := v_daily_expense + (p_simulate_purchase_amount / p_simulate_purchase_installments);
        END IF;

        -- Update Balance
        v_day_balance := v_day_balance + v_daily_income - v_daily_expense;
        
        -- Track Extremes
        IF v_day_balance < v_min_projected_balance THEN v_min_projected_balance := v_day_balance; END IF;
        IF v_day_balance > v_max_projected_balance THEN v_max_projected_balance := v_day_balance; END IF;

        -- Insight Logic: Collect Critical Data
        IF v_day_balance < 0 THEN
            v_consecutive_negative_days := v_consecutive_negative_days + 1;
            IF v_first_negative_date IS NULL THEN v_first_negative_date := v_date; END IF;
        END IF;

        IF v_daily_expense > v_large_expense_amount AND v_daily_expense > 1000 THEN
            v_large_expense_amount := v_daily_expense;
            v_large_expense_date := v_date;
        END IF;

        -- Store Daily Point
        v_daily_balances := v_daily_balances || jsonb_build_object(
            'date', v_date,
            'balance', ROUND(v_day_balance, 2),
            'income', ROUND(v_daily_income, 2),
            'expense', ROUND(v_daily_expense, 2)
        );
    END LOOP;

    -- 4. Generate Strategic Insights
    -- Insight 1: Low Balance / Critical
    IF v_first_negative_date IS NOT NULL THEN
        v_insights := v_insights || jsonb_build_object(
            'type', 'CRITICAL',
            'title', 'Nakit Eksikliği Riski',
            'message', 'Tahminlerimize göre ' || v_first_negative_date || ' tarihinde bakiyeniz eksiye düşebilir. Önlem almanız önerilir.',
            'date', v_first_negative_date
        );
        v_safety_status := 'CRITICAL';
    END IF;

    -- Insight 2: High Liquidity Opportunity
    IF v_max_projected_balance > (v_current_balance + 20000) AND v_min_projected_balance > 5000 THEN
        v_insights := v_insights || jsonb_build_object(
            'type', 'OPPORTUNITY',
            'title', 'Yatırım Fırsatı',
            'message', 'Önümüzdeki dönemde nakit fazlası görünüyor. Boşta duran parayı yatırım fonlarında değerlendirmeyi düşünebilirsiniz.',
            'amount', (v_max_projected_balance - 5000)
        );
    END IF;

    -- Insight 3: Upcoming Large Expense
    IF v_large_expense_date IS NOT NULL AND v_large_expense_date > CURRENT_DATE THEN
        v_insights := v_insights || jsonb_build_object(
            'type', 'ALERT',
            'title', 'Yüklü Ödeme Hatırlatıcı',
            'message', v_large_expense_date || ' tarihinde yaklaşık ' || ROUND(v_large_expense_amount, 0) || ' TL tutarında bir harcama/ödemeniz var.',
            'date', v_large_expense_date
        );
    END IF;

    -- 5. Construct Final JSON
    v_result := jsonb_build_object(
        'chart_data', v_daily_balances,
        'insights', v_insights,
        'current_balance', ROUND(v_current_balance, 2),
        'min_projected_balance', ROUND(v_min_projected_balance, 2),
        'safety_status', v_safety_status,
        'scenario_applied', (v_expense_multiplier != 1.0 OR v_income_multiplier != 1.0)
    );

    RETURN v_result;
END;
$$;

COMMIT;
