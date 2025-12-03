-- ========================================
-- KYC VERIFICATION & LEGAL ENFORCEMENT SYSTEM - SAFE VERSION
-- Run this AFTER APPLY_MIGRATIONS.sql
-- ========================================

-- 1. User Defaulter Status (Add to profiles first)
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='defaulter_status') THEN
    ALTER TABLE profiles ADD COLUMN defaulter_status VARCHAR(20) DEFAULT 'good';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='defaulter_badge') THEN
    ALTER TABLE profiles ADD COLUMN defaulter_badge BOOLEAN  DEFAULT FALSE;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='account_suspended') THEN
    ALTER TABLE profiles ADD COLUMN account_suspended BOOLEAN DEFAULT FALSE;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='suspension_reason') THEN
    ALTER TABLE profiles ADD COLUMN suspension_reason TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='total_defaults') THEN
    ALTER TABLE profiles ADD COLUMN total_defaults INTEGER DEFAULT 0;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='total_default_amount') THEN
    ALTER TABLE profiles ADD COLUMN total_default_amount DECIMAL(15, 2) DEFAULT 0;
  END IF;
END $$;

-- 2. KYC Documents Table
CREATE TABLE IF NOT EXISTS kyc_documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Document Types
  aadhaar_number VARCHAR(12),
  aadhaar_photo_url TEXT,
  pan_number VARCHAR(10),
  pan_photo_url TEXT,
  bank_account_number VARCHAR(20),
  bank_ifsc_code VARCHAR(11),
  bank_verified BOOLEAN DEFAULT FALSE,
  selfie_with_id_url TEXT,
  address_proof_url TEXT,
  
  -- Verification Status
  verification_status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
  verified_by UUID REFERENCES profiles(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  
  -- Metadata
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(user_id)
);

-- 3. Function: Check if user can create/join pools
CREATE OR REPLACE FUNCTION can_participate_in_pools(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_kyc_verified BOOLEAN;
  v_account_suspended BOOLEAN;
  v_defaulter_status VARCHAR(20);
BEGIN
  SELECT kyc_verified, account_suspended, defaulter_status
  INTO v_kyc_verified, v_account_suspended, v_defaulter_status
  FROM profiles
  WHERE id = p_user_id;
  
  -- Must be KYC verified
  IF v_kyc_verified IS NULL OR v_kyc_verified = FALSE THEN
    RETURN FALSE;
  END IF;
  
  -- Must not be suspended
  IF v_account_suspended = TRUE THEN
    RETURN FALSE;
  END IF;
  
  -- Must not be banned
  IF v_defaulter_status = 'banned' THEN
    RETURN FALSE;
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. RLS Policies for KYC
ALTER TABLE kyc_documents ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS kyc_documents_select_own ON kyc_documents;
DROP POLICY IF EXISTS kyc_documents_insert_own ON kyc_documents;
DROP POLICY IF EXISTS kyc_documents_update_own ON kyc_documents;

-- Users can view their own KYC
CREATE POLICY kyc_documents_select_own ON kyc_documents
  FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own KYC
CREATE POLICY kyc_documents_insert_own ON kyc_documents
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own KYC (only if pending)
CREATE POLICY kyc_documents_update_own ON kyc_documents
  FOR UPDATE USING (auth.uid() = user_id AND verification_status = 'pending');

-- 5. Create storage bucket for KYC documents
INSERT INTO storage.buckets (id, name, public)
VALUES ('kyc-documents', 'kyc-documents', false)
ON CONFLICT (id) DO NOTHING;

-- 6. Storage policies for KYC documents
DROP POLICY IF EXISTS "Users can upload their own KYC documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own KYC documents" ON storage.objects;

CREATE POLICY "Users can upload their own KYC documents"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'kyc-documents' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view their own KYC documents"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'kyc-documents' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- 7. Indexes
CREATE INDEX IF NOT EXISTS idx_kyc_documents_user_id ON kyc_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_kyc_documents_status ON kyc_documents(verification_status);
CREATE INDEX IF NOT EXISTS idx_profiles_defaulter_status ON profiles(defaulter_status);
CREATE INDEX IF NOT EXISTS idx_profiles_kyc_verified ON profiles(kyc_verified);

-- ========================================
-- VERIFICATION
-- ========================================
SELECT 'Setup complete!' as status;

SELECT 'KYC table created:' as info;
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_name = 'kyc_documents'
) as kyc_table_exists;

SELECT 'Function created:' as info;
SELECT EXISTS (
  SELECT FROM information_schema.routines
  WHERE routine_name = 'can_participate_in_pools'
) as function_exists;

SELECT 'Profile columns added:' as info;
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND column_name IN ('defaulter_status', 'account_suspended', 'kyc_verified');
