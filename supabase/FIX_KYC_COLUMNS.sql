-- ============================================================================
-- FIX KYC COLUMNS
-- ============================================================================
-- This script safely adds missing columns to the kyc_documents table.
-- It handles cases where the table exists but columns are missing.
-- ============================================================================

-- 1. Ensure kyc_documents table exists
CREATE TABLE IF NOT EXISTS kyc_documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Add missing columns safely
DO $$ 
BEGIN
  -- Aadhaar
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='aadhaar_number') THEN
    ALTER TABLE kyc_documents ADD COLUMN aadhaar_number VARCHAR(12);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='aadhaar_photo_url') THEN
    ALTER TABLE kyc_documents ADD COLUMN aadhaar_photo_url TEXT;
  END IF;

  -- PAN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='pan_number') THEN
    ALTER TABLE kyc_documents ADD COLUMN pan_number VARCHAR(10);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='pan_photo_url') THEN
    ALTER TABLE kyc_documents ADD COLUMN pan_photo_url TEXT;
  END IF;

  -- Bank Account
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='bank_account_number') THEN
    ALTER TABLE kyc_documents ADD COLUMN bank_account_number VARCHAR(20);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='bank_ifsc_code') THEN
    ALTER TABLE kyc_documents ADD COLUMN bank_ifsc_code VARCHAR(11);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='bank_verified') THEN
    ALTER TABLE kyc_documents ADD COLUMN bank_verified BOOLEAN DEFAULT FALSE;
  END IF;

  -- Other Proofs
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='selfie_with_id_url') THEN
    ALTER TABLE kyc_documents ADD COLUMN selfie_with_id_url TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='address_proof_url') THEN
    ALTER TABLE kyc_documents ADD COLUMN address_proof_url TEXT;
  END IF;

  -- Status & Metadata
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='verification_status') THEN
    ALTER TABLE kyc_documents ADD COLUMN verification_status VARCHAR(20) DEFAULT 'pending';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='verified_by') THEN
    ALTER TABLE kyc_documents ADD COLUMN verified_by UUID REFERENCES auth.users(id);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='verified_at') THEN
    ALTER TABLE kyc_documents ADD COLUMN verified_at TIMESTAMP WITH TIME ZONE;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='rejection_reason') THEN
    ALTER TABLE kyc_documents ADD COLUMN rejection_reason TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='kyc_documents' AND column_name='submitted_at') THEN
    ALTER TABLE kyc_documents ADD COLUMN submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
  END IF;
END $$;

-- 3. Ensure RLS is enabled
ALTER TABLE kyc_documents ENABLE ROW LEVEL SECURITY;

-- 4. Re-create policies to be safe
DROP POLICY IF EXISTS kyc_documents_select_own ON kyc_documents;
DROP POLICY IF EXISTS kyc_documents_insert_own ON kyc_documents;
DROP POLICY IF EXISTS kyc_documents_update_own ON kyc_documents;

CREATE POLICY kyc_documents_select_own ON kyc_documents
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY kyc_documents_insert_own ON kyc_documents
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY kyc_documents_update_own ON kyc_documents
  FOR UPDATE USING (auth.uid() = user_id AND verification_status = 'pending');

-- 5. Verification
SELECT 
  column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'kyc_documents';
