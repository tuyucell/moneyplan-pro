-- RLS Policy Fix for user_bank_accounts table

-- 1. Enable RLS on the table (if not already enabled)
ALTER TABLE user_bank_accounts ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own accounts" ON user_bank_accounts;
DROP POLICY IF EXISTS "Users can insert their own accounts" ON user_bank_accounts;
DROP POLICY IF EXISTS "Users can update their own accounts" ON user_bank_accounts;
DROP POLICY IF EXISTS "Users can delete their own accounts" ON user_bank_accounts;

-- 3. Re-create correct policies
-- Allow SELECT for own rows
CREATE POLICY "Users can view their own accounts"
ON user_bank_accounts
FOR SELECT
USING (auth.uid() = user_id);

-- Allow INSERT if user_id matches auth.uid()
CREATE POLICY "Users can insert their own accounts"
ON user_bank_accounts
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Allow UPDATE if user_id matches auth.uid()
CREATE POLICY "Users can update their own accounts"
ON user_bank_accounts
FOR UPDATE
USING (auth.uid() = user_id);

-- Allow DELETE if user_id matches auth.uid()
CREATE POLICY "Users can delete their own accounts"
ON user_bank_accounts
FOR DELETE
USING (auth.uid() = user_id);

-- 4. Grant access to authenticated users
GRANT ALL ON user_bank_accounts TO authenticated;
