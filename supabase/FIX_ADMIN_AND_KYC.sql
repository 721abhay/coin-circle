-- ============================================
-- COMPLETE FIX: Admin Access + KYC Verification
-- Run this in Supabase SQL Editor
-- ============================================

-- STEP 1: Remove admin from ALL users first
UPDATE profiles SET is_admin = FALSE;

-- STEP 2: Set admin ONLY for your email (UPDATE THIS EMAIL!)
-- Check your profile screen to see your email, then update below:
UPDATE profiles 
SET is_admin = TRUE 
WHERE email IN (
  'santoshbs4842795@gmail.com',  -- Add your admin email here
  'admin@coincircle.com'          -- Or any other admin emails
);

-- STEP 3: Ensure kyc_verified column exists and has correct values
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS kyc_verified BOOLEAN DEFAULT FALSE;

-- STEP 4: Check if the approved KYC users have kyc_verified set to true
-- This updates profiles based on approved KYC documents
UPDATE profiles p
SET kyc_verified = TRUE
WHERE EXISTS (
  SELECT 1 FROM kyc_documents k
  WHERE k.user_id = p.id
  AND k.verification_status = 'approved'
);

-- STEP 5: Verify the results
SELECT 
  email,
  is_admin,
  kyc_verified,
  created_at
FROM profiles
ORDER BY is_admin DESC, created_at DESC;

-- STEP 6: Check KYC documents status
SELECT 
  p.email,
  k.verification_status,
  k.verified_at,
  p.kyc_verified as profile_kyc_verified
FROM kyc_documents k
JOIN profiles p ON k.user_id = p.id
ORDER BY k.submitted_at DESC;

-- Expected Results:
-- 1. Only your admin email should have is_admin = true
-- 2. Users with approved KYC should have kyc_verified = true
-- 3. Users with pending/rejected KYC should have kyc_verified = false
