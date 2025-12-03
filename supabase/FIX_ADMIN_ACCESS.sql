-- ============================================================================
-- FIX ADMIN ACCESS FOR KYC
-- ============================================================================
-- This script enables Admin access to view all KYC documents.
-- 1. Adds 'is_admin' column to profiles.
-- 2. Adds RLS policy for admins to view all KYC documents.
-- 3. Makes the currently logged-in user an Admin.
-- ============================================================================

-- 1. Add is_admin column to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- 2. Create RLS policy for Admins
-- Note: Policies are additive (OR logic), so this works alongside the existing "view own" policy.
DROP POLICY IF EXISTS "Admins can view all KYC documents" ON kyc_documents;

CREATE POLICY "Admins can view all KYC documents" ON kyc_documents
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.is_admin = TRUE
    )
  );

-- Also allow Admins to update KYC status
DROP POLICY IF EXISTS "Admins can update KYC documents" ON kyc_documents;

CREATE POLICY "Admins can update KYC documents" ON kyc_documents
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.is_admin = TRUE
    )
  );

-- 3. Make the current user an Admin
-- IMPORTANT: This will make the user running this script an Admin.
UPDATE profiles SET is_admin = TRUE WHERE id = auth.uid();

-- Verification
SELECT id, email, is_admin FROM profiles WHERE id = auth.uid();
