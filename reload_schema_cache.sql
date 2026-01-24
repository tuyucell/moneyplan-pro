-- 1. Reload PostgREST API Schema Cache
-- This is often required after SQL changes so the API knows about new types/functions.
NOTIFY pgrst, 'reload config';

-- 2. Explicitly Fix Audit Logs Foreign Key Relationship
-- Sometimes auto-detected keys fail. We make it explicit.
DO $$
BEGIN
    -- Check if constraint exists, drop it to be safe
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'audit_logs_user_id_fkey') THEN
        ALTER TABLE audit_logs DROP CONSTRAINT audit_logs_user_id_fkey;
    END IF;

    -- Add constraint again
    ALTER TABLE audit_logs 
    ADD CONSTRAINT audit_logs_user_id_fkey 
    FOREIGN KEY (user_id) 
    REFERENCES public.users(id) 
    ON DELETE SET NULL;
END $$;
