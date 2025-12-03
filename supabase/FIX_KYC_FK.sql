-- ============================================================================
-- FIX KYC FOREIGN KEY CONSTRAINT
-- ============================================================================
-- The kyc_documents table has a foreign key constraint that is failing.
-- This script recreates the constraint to correctly reference auth.users.
-- ============================================================================

DO $$ 
BEGIN
  -- 1. Drop the existing foreign key constraint if it exists
  IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'kyc_documents_user_id_fkey') THEN
    ALTER TABLE kyc_documents DROP CONSTRAINT kyc_documents_user_id_fkey;
  END IF;

  -- 2. Add the correct foreign key constraint referencing auth.users
  -- We use auth.users because it is the source of truth for user IDs.
  ALTER TABLE kyc_documents
    ADD CONSTRAINT kyc_documents_user_id_fkey 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;

END $$;

-- Verification
SELECT 
  tc.constraint_name, 
  ccu.table_name AS foreign_table_name,
  kcu.column_name
FROM 
  information_schema.table_constraints AS tc 
  JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
  JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE constraint_type = 'FOREIGN KEY' AND tc.table_name='kyc_documents';
