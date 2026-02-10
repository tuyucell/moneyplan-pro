-- Financial Pilot & Forecast Engine Setup
-- ==========================================

-- 1. Scenarios Table: Stores user-defined "What-If" parameters
CREATE TABLE IF NOT EXISTS scenarios (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES auth.users(id) NOT NULL,
    name text NOT NULL, -- e.g., "Enflasyon %20", "Yeni Maaş", "Kredi Ödemesi"
    is_active boolean DEFAULT false,
    parameters jsonb DEFAULT '{}'::jsonb, -- { "expense_multiplier": 1.2, "income_multiplier": 1.1, "one_off_cost": 5000, "one_off_date": "2024-06-01" }
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- RLS Policies for Scenarios
ALTER TABLE scenarios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own scenarios" ON scenarios;
CREATE POLICY "Users can view their own scenarios"
    ON scenarios FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own scenarios" ON scenarios;
CREATE POLICY "Users can insert their own scenarios"
    ON scenarios FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own scenarios" ON scenarios;
CREATE POLICY "Users can update their own scenarios"
    ON scenarios FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own scenarios" ON scenarios;
CREATE POLICY "Users can delete their own scenarios"
    ON scenarios FOR DELETE
    USING (auth.uid() = user_id);


-- 2. Aggregate Helper for multipliers
-- Postgres doesn't have a native PRODUCT aggregate, creating one.
CREATE OR REPLACE FUNCTION mul(numeric, numeric) RETURNS numeric AS $$
    SELECT $1 * $2;
$$ LANGUAGE SQL;

DROP AGGREGATE IF EXISTS product(numeric);
CREATE AGGREGATE product (numeric) (
    sfunc = mul,
    stype = numeric,
    initcond = 1
);


-- 3. Forecast Calculation RPC
-- Returns a daily balance projection for the next X months.

-- Drop previous versions to avoid "is not unique" ambiguity error
DROP FUNCTION IF EXISTS calculate_financial_pilot(uuid, int, numeric, int);
DROP FUNCTION IF EXISTS calculate_financial_pilot(uuid, int, numeric, int, numeric);

CREATE OR REPLACE FUNCTION calculate_financial_pilot(
    p_user_id uuid,
    p_months int DEFAULT 3,
    p_simulate_purchase_amount numeric DEFAULT 0,
    p_simulate_purchase_installments int DEFAULT 1,
    p_current_balance numeric DEFAULT 0 -- New Parameter
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_date date := CURRENT_DATE;
    v_end_date date := CURRENT_DATE + (p_months * 30);
    v_current_balance numeric := 0;
    v_daily_balances jsonb := '[]'::jsonb;
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
BEGIN
    -- 1. Determine Initial Balance
    IF p_current_balance != 0 THEN
        v_current_balance := p_current_balance;
    ELSE
        -- Fallback: Get from DB if parameter is 0 (though likely DB is also 0 or static)
        SELECT COALESCE(SUM(balance), 0)
        INTO v_current_balance
        FROM user_bank_accounts
        WHERE user_id = p_user_id 
          AND account_type NOT IN ('Kredi Kartı', 'Kredi'); -- Exclude debt accounts
    END IF;

    -- 2. Load Active Scenario Parameters (Aggregation)
    -- We assume the 'product' aggregate exists or we use logic to combine them.
    -- If 'product' aggregate is tricky in some environments, we can iterate.
    -- Here we use a simpler approach: multiple rows -> aggregated multipliers.
    
    SELECT 
        COALESCE(EXP(SUM(LN(NULLIF(ABS((parameters->>'expense_multiplier')::numeric), 0)))), 1.0),
        COALESCE(EXP(SUM(LN(NULLIF(ABS((parameters->>'income_multiplier')::numeric), 0)))), 1.0)
    INTO v_expense_multiplier, v_income_multiplier
    FROM scenarios
    WHERE user_id = p_user_id AND is_active = true;
    
    -- Note: Mathematical trick for Product: exp(sum(ln(x))). 
    -- Handled negative numbers? Usually multipliers are positive.
    -- Fallback to 1.0 if null.

    IF v_expense_multiplier IS NULL THEN v_expense_multiplier := 1.0; END IF;
    IF v_income_multiplier IS NULL THEN v_income_multiplier := 1.0; END IF;

    -- 3. Loop through days
    v_day_balance := v_current_balance;
    v_min_projected_balance := v_current_balance;
    
    FOR i IN 0..(p_months * 30) LOOP
        v_date := v_start_date + i;
        
        -- A. Calculate Recurring Income for this day
        SELECT COALESCE(SUM(amount), 0) INTO v_daily_income
        FROM user_transactions
        WHERE user_id = p_user_id
          AND is_recurring = true
          AND type = 'income'
          AND EXTRACT(DAY FROM date) = EXTRACT(DAY FROM v_date); -- Simplistic monthly recurrence check
          
        -- B. Calculate Recurring Expense for this day
        SELECT COALESCE(SUM(amount), 0) INTO v_daily_expense
        FROM user_transactions
        WHERE user_id = p_user_id
          AND is_recurring = true
          AND type = 'expense'
          AND EXTRACT(DAY FROM date) = EXTRACT(DAY FROM v_date);

        -- Apply Scenario Multipliers
        v_daily_income := v_daily_income * v_income_multiplier;
        v_daily_expense := v_daily_expense * v_expense_multiplier;

        -- Apply Purchase Simulation (if today is purchase date - simplistically today)
        IF i = 0 AND p_simulate_purchase_amount > 0 THEN
             IF p_simulate_purchase_installments > 1 THEN
                 -- First installment only? Or logic to spread?
                 -- Simplified: Deduct 1st installment today
                 v_daily_expense := v_daily_expense + (p_simulate_purchase_amount / p_simulate_purchase_installments);
             ELSE
                 v_daily_expense := v_daily_expense + p_simulate_purchase_amount;
             END IF;
        ELSIF i > 0 AND p_simulate_purchase_installments > 1 AND (i % 30 = 0) AND (i / 30 < p_simulate_purchase_installments) THEN
             -- Subsequent installments every 30 days
             v_daily_expense := v_daily_expense + (p_simulate_purchase_amount / p_simulate_purchase_installments);
        END IF;

        -- Update Balance
        v_day_balance := v_day_balance + v_daily_income - v_daily_expense;
        
        -- Track Min Balance
        IF v_day_balance < v_min_projected_balance THEN
            v_min_projected_balance := v_day_balance;
        END IF;

        -- Append to Result Series
        -- Store every day is expensive, maybe weekly? Storing daily for chart smoothness.
        v_daily_balances := v_daily_balances || jsonb_build_object(
            'date', v_date,
            'balance', v_day_balance,
            'income', v_daily_income,
            'expense', v_daily_expense
        );
    END LOOP;

    -- 4. Determine Status
    IF v_min_projected_balance < 0 THEN
        v_safety_status := 'CRITICAL';
    ELSIF v_min_projected_balance < 5000 THEN -- Configurable threshold
        v_safety_status := 'WARNING';
    END IF;

    -- 5. Construct Final JSON
    v_result := jsonb_build_object(
        'chart_data', v_daily_balances,
        'current_balance', v_current_balance,
        'min_projected_balance', v_min_projected_balance,
        'safety_status', v_safety_status,
        'scenario_applied', (v_expense_multiplier != 1.0 OR v_income_multiplier != 1.0)
    );

    RETURN v_result;
END;
$$;

GRANT ALL ON FUNCTION calculate_financial_pilot TO authenticated;
GRANT ALL ON TABLE scenarios TO authenticated;
