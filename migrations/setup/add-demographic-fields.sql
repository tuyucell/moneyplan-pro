-- SQL to add demographic fields to the users table
-- Run this if your users table already exists

ALTER TABLE users ADD COLUMN IF NOT EXISTS birth_year INTEGER;
ALTER TABLE users ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS occupation TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS financial_goal TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS risk_tolerance TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_profile_completed BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN users.birth_year IS 'User birth year for demographics';
COMMENT ON COLUMN users.gender IS 'User gender (male, female, other)';
COMMENT ON COLUMN users.occupation IS 'User occupation/profession';
COMMENT ON COLUMN users.financial_goal IS 'Primary financial goal (savings, investment, retirement, debt)';
COMMENT ON COLUMN users.risk_tolerance IS 'Investment risk tolerance (low, medium, high)';
COMMENT ON COLUMN users.is_profile_completed IS 'Whether the user has completed their onboarding profile';
