-- Add Demographic Columns to Users Table
-- Required for Analytics page to show real data instead of 'Unknown'

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS birth_year INTEGER;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS occupation TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS financial_goal TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS risk_tolerance TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS display_name TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_premium BOOLEAN DEFAULT FALSE;

-- Optional: Update RPC function for demographics if it exists
-- This ensures the analytics page query works correctly with new columns
CREATE OR REPLACE FUNCTION public.get_user_demographics()
RETURNS TABLE (
    category TEXT,
    value TEXT,
    count BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    -- Gender
    SELECT 'gender'::TEXT, COALESCE(gender, 'Not Specified'), COUNT(*)::BIGINT 
    FROM public.users GROUP BY gender
    UNION ALL
    -- Risk Tolerance
    SELECT 'risk_tolerance'::TEXT, COALESCE(risk_tolerance, 'Unknown'), COUNT(*)::BIGINT 
    FROM public.users GROUP BY risk_tolerance
    UNION ALL
    -- Financial Goal
    SELECT 'financial_goal'::TEXT, COALESCE(financial_goal, 'Unknown'), COUNT(*)::BIGINT 
    FROM public.users GROUP BY financial_goal;
END;
$$;
