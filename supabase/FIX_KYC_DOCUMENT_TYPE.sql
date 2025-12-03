-- ============================================================================
-- FIX KYC DOCUMENT TYPE CONSTRAINT
-- ============================================================================
-- The kyc_documents table has a 'document_type' column with a NOT NULL constraint
-- that is causing errors because the current app version doesn't use it.
-- This script makes the column nullable.
-- ============================================================================

DO $$ 
BEGIN
  -- Check if column exists
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='document_type') THEN
    -- Make it nullable
    ALTER TABLE kyc_documents ALTER COLUMN document_type DROP NOT NULL;
    
    -- Optional: Set a default value for existing nulls if needed, though DROP NOT NULL handles future inserts
    -- UPDATE kyc_documents SET document_type = 'comprehensive' WHERE document_type IS NULL;
  END IF;
END $$;

-- Verification
SELECT 
  column_name, 
  is_nullable 
FROM information_schema.columns 
WHERE table_name = 'kyc_documents' 
AND column_name = 'document_type';
