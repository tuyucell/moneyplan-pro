BEGIN;

-- Step 0: Ensure any old constraints with different names are also gone
ALTER TABLE user_transactions DROP CONSTRAINT IF EXISTS user_transactions_account_id_fkey;
ALTER TABLE user_transactions DROP CONSTRAINT IF EXISTS user_transactions_account_fkey;
ALTER TABLE user_bank_accounts DROP CONSTRAINT IF EXISTS user_bank_accounts_pkey;

-- Step 1: Ensure columns are TEXT (to support 'isbank' style IDs from Mobile App)
-- If they are currently UUID, this converts them safely.
ALTER TABLE user_bank_accounts ALTER COLUMN id TYPE TEXT;
ALTER TABLE user_transactions ALTER COLUMN account_id TYPE TEXT;

-- Step 2: Change Primary Key to Composite (user_id, id)
ALTER TABLE user_bank_accounts ADD PRIMARY KEY (user_id, id);

-- Step 3: Cleanup orphaned transactions
-- Now both are TEXT, so no "invalid input syntax for uuid" errors.
UPDATE user_transactions ut
SET account_id = NULL
WHERE account_id IS NOT NULL 
  AND NOT EXISTS (
    SELECT 1 FROM user_bank_accounts uba 
    WHERE uba.user_id = ut.user_id AND uba.id = ut.account_id
);

-- Step 4: Add Composite Foreign Key
ALTER TABLE user_transactions 
ADD CONSTRAINT user_transactions_account_fkey 
FOREIGN KEY (user_id, account_id) 
REFERENCES user_bank_accounts (user_id, id)
ON DELETE SET NULL;

-- Step 5: Fix user_transactions PK too (Optional but recommended for consistency)
ALTER TABLE user_transactions DROP CONSTRAINT IF EXISTS user_transactions_pkey;
ALTER TABLE user_transactions ALTER COLUMN id TYPE TEXT;
ALTER TABLE user_transactions ADD PRIMARY KEY (user_id, id);

-- Step 6: RLS Policies (Ensure clean state)
DROP POLICY IF EXISTS "Users can view their own accounts" ON user_bank_accounts;
DROP POLICY IF EXISTS "Users can insert their own accounts" ON user_bank_accounts;
DROP POLICY IF EXISTS "Users can update their own accounts" ON user_bank_accounts;
DROP POLICY IF EXISTS "Users can delete their own accounts" ON user_bank_accounts;

CREATE POLICY "Users can view their own accounts" ON user_bank_accounts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own accounts" ON user_bank_accounts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own accounts" ON user_bank_accounts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own accounts" ON user_bank_accounts FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE user_bank_accounts ENABLE ROW LEVEL SECURITY;

GRANT ALL ON user_bank_accounts TO authenticated;
GRANT ALL ON user_bank_accounts TO service_role;

COMMIT;


-- Verification queries (run these separately to check):
-- SELECT * FROM user_bank_accounts WHERE user_id = auth.uid();
-- SELECT constraint_name, constraint_type FROM information_schema.table_constraints WHERE table_name = 'user_bank_accounts';
