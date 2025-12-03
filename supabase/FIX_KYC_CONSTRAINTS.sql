-- ============================================================================
-- FIX ALL KYC CONSTRAINTS
-- ============================================================================
-- The kyc_documents table has legacy columns with NOT NULL constraints
-- that are causing errors because the current app version uses specific columns
-- (like aadhaar_photo_url) instead of generic ones (like file_path).
-- This script makes all legacy columns nullable.
-- ============================================================================

DO $$ 
BEGIN
  -- 1. Make 'file_path' nullable
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='file_path') THEN
    ALTER TABLE kyc_documents ALTER COLUMN file_path DROP NOT NULL;
  END IF;

  -- 2. Make 'document_number' nullable (just in case)
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='document_number') THEN
    ALTER TABLE kyc_documents ALTER COLUMN document_number DROP NOT NULL;
  END IF;

  -- 3. Make 'document_type' nullable (re-applying to be sure)
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='document_type') THEN
    ALTER TABLE kyc_documents ALTER COLUMN document_type DROP NOT NULL;
  END IF;

  -- 4. Make 'document_url' nullable (another potential legacy name)
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='document_url') THEN
    ALTER TABLE kyc_documents ALTER COLUMN document_url DROP NOT NULL;
  END IF;

END $$;

-- Verification
SELECT 
  column_name, 
  is_nullable 
FROM information_schema.columns 
WHERE table_name = 'kyc_documents' 
AND column_name IN ('file_path', 'document_number', 'document_type', 'document_url');
