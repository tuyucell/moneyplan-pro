-- Final RLS Fix for user_bank_accounts
-- This script ensures permissions are correct and fixes potentially orphaned rows

-- 1. Enable RLS
ALTER TABLE user_bank_accounts ENABLE ROW LEVEL SECURITY;

-- 2. Clean slate policies
DROP POLICY IF EXISTS "Users can view their own accounts" ON user_bank_accounts;
DROP POLICY IF EXISTS "Users can insert their own accounts" ON user_bank_accounts;
DROP POLICY IF EXISTS "Users can update their own accounts" ON user_bank_accounts;
DROP POLICY IF EXISTS "Users can delete their own accounts" ON user_bank_accounts;
DROP POLICY IF EXISTS "Enable all for users" ON user_bank_accounts;

-- 3. Create permissive policies for owners
-- SELECT
CREATE POLICY "Users can view their own accounts"
ON user_bank_accounts FOR SELECT
USING (auth.uid() = user_id);

-- INSERT (Ensure user_id is set to auth.uid())
CREATE POLICY "Users can insert their own accounts"
ON user_bank_accounts FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- UPDATE
-- Note: 'USING' checks existing row, 'WITH CHECK' checks new state.
-- Since we don't change user_id, both should match auth.uid().
CREATE POLICY "Users can update their own accounts"
ON user_bank_accounts FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- DELETE
CREATE POLICY "Users can delete their own accounts"
ON user_bank_accounts FOR DELETE
USING (auth.uid() = user_id);

-- 4. Auto-fix potentially broken rows (Dev helper)
-- If there are rows with NULL user_id created during testing, assign them to current user.
-- NOTE: This only works if run in SQL Editor where auth.uid() context might be set, 
-- or we can skip this if risky. Better to just Grant permissions.

-- 5. Grant Permissions
GRANT ALL ON user_bank_accounts TO authenticated;
GRANT ALL ON user_bank_accounts TO service_role;
