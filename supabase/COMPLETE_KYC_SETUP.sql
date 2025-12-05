-- ============================================
-- COMPLETE KYC SYSTEM SETUP
-- Run this script in Supabase SQL Editor
-- ============================================

-- 1. Ensure kyc_verified column exists in profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS kyc_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone TEXT;

-- 2. Sync phone numbers from auth.users to profiles
UPDATE public.profiles p
SET phone = u.phone
FROM auth.users u
WHERE p.id = u.id
AND p.phone IS NULL
AND u.phone IS NOT NULL;

-- 3. Make current users admins (for testing - adjust as needed)
-- IMPORTANT: In production, only set specific users as admin
UPDATE profiles SET is_admin = TRUE;

-- 4. Ensure kyc_documents table exists with correct structure
CREATE TABLE IF NOT EXISTS kyc_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Document fields
  aadhaar_number VARCHAR(12),
  aadhaar_photo_url TEXT,
  pan_number VARCHAR(10),
  pan_photo_url TEXT,
  bank_account_number VARCHAR(20),
  bank_ifsc_code VARCHAR(11),
  bank_verified BOOLEAN DEFAULT FALSE,
  selfie_with_id_url TEXT,
  address_proof_url TEXT,
  
  -- Status fields
  verification_status VARCHAR(20) DEFAULT 'pending',
  verified_by UUID REFERENCES profiles(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(user_id)
);

-- 5. Enable RLS on kyc_documents
ALTER TABLE kyc_documents ENABLE ROW LEVEL SECURITY;

-- 6. Drop old policies
DROP POLICY IF EXISTS "Users can view own KYC" ON kyc_documents;
DROP POLICY IF EXISTS "Users can insert own KYC" ON kyc_documents;
DROP POLICY IF EXISTS "Users can update own KYC" ON kyc_documents;
DROP POLICY IF EXISTS kyc_documents_select_own ON kyc_documents;
DROP POLICY IF EXISTS kyc_documents_insert_own ON kyc_documents;
DROP POLICY IF EXISTS kyc_documents_update_own ON kyc_documents;
DROP POLICY IF EXISTS "KYC Visibility" ON kyc_documents;
DROP POLICY IF EXISTS "KYC Submission" ON kyc_documents;
DROP POLICY IF EXISTS "KYC Updates" ON kyc_documents;

-- 7. Create comprehensive RLS policies for KYC

-- SELECT: Users see their own, Admins see ALL
CREATE POLICY "KYC Visibility" ON kyc_documents
  FOR SELECT USING (
    auth.uid() = user_id OR 
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE)
  );

-- INSERT: Users can insert their own
CREATE POLICY "KYC Submission" ON kyc_documents
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
  );

-- UPDATE: Users can update their own if pending, Admins can update ANY (for approval)
CREATE POLICY "KYC Updates" ON kyc_documents
  FOR UPDATE USING (
    (auth.uid() = user_id AND verification_status = 'pending') OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE)
  );

-- 8. Ensure profiles are visible to admins
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
CREATE POLICY "Profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

-- 9. Create/update storage bucket for KYC documents
INSERT INTO storage.buckets (id, name, public)
VALUES ('kyc-documents', 'kyc-documents', true)
ON CONFLICT (id) DO UPDATE
SET public = true;

-- 10. Drop old storage policies
DROP POLICY IF EXISTS "Users can view their own KYC documents" ON storage.objects;
DROP POLICY IF EXISTS "Public can view KYC documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own KYC documents" ON storage.objects;

-- 11. Create storage policies

-- Allow public viewing of KYC documents (Required for Image.network with getPublicUrl)
CREATE POLICY "Public can view KYC documents"
ON storage.objects FOR SELECT
USING ( bucket_id = 'kyc-documents' );

-- Allow authenticated users to upload
CREATE POLICY "Users can upload their own KYC documents"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'kyc-documents' AND
  auth.role() = 'authenticated'
);

-- 12. Create or replace the can_participate_in_pools function
CREATE OR REPLACE FUNCTION can_participate_in_pools(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_kyc_verified BOOLEAN;
  v_account_suspended BOOLEAN;
BEGIN
  SELECT kyc_verified, account_suspended
  INTO v_kyc_verified, v_account_suspended
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
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_kyc_documents_user_id ON kyc_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_kyc_documents_status ON kyc_documents(verification_status);
CREATE INDEX IF NOT EXISTS idx_profiles_kyc_verified ON profiles(kyc_verified);
CREATE INDEX IF NOT EXISTS idx_profiles_is_admin ON profiles(is_admin);

-- 14. Success message
SELECT 'KYC System Setup Complete!' as status;
SELECT 'Total Users: ' || COUNT(*) as info FROM profiles;
SELECT 'Admin Users: ' || COUNT(*) as info FROM profiles WHERE is_admin = TRUE;
SELECT 'KYC Verified Users: ' || COUNT(*) as info FROM profiles WHERE kyc_verified = TRUE;
SELECT 'Pending KYC Requests: ' || COUNT(*) as info FROM kyc_documents WHERE verification_status = 'pending';
