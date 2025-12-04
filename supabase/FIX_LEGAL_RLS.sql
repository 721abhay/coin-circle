-- ============================================================================
-- FIX LEGAL RLS FOR SYSTEM ADMINS
-- ============================================================================
-- This script updates the RLS policies for the Legal System to allow
-- System Admins (profiles.is_admin = true) to perform actions, not just Pool Admins.
-- ============================================================================

-- 1. Update "Admins can create notices" policy
DROP POLICY IF EXISTS "Admins can create notices" ON legal_notices;

CREATE POLICY "Admins can create notices" ON legal_notices
  FOR INSERT WITH CHECK (
    -- Allow Pool Admins
    EXISTS (
      SELECT 1 FROM pool_members
      WHERE pool_id = legal_notices.pool_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
    OR
    -- Allow System Admins
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.is_admin = TRUE
    )
  );

-- 2. Allow Admins to view all notices (not just their own)
DROP POLICY IF EXISTS "Admins can view all notices" ON legal_notices;

CREATE POLICY "Admins can view all notices" ON legal_notices
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.is_admin = TRUE
    )
  );

-- 3. Allow Admins to view all agreements
DROP POLICY IF EXISTS "Admins can view all agreements" ON legal_agreements;

CREATE POLICY "Admins can view all agreements" ON legal_agreements
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.is_admin = TRUE
    )
  );

-- 4. Allow Admins to view all legal actions
DROP POLICY IF EXISTS "Admins can view all legal actions" ON legal_actions;

CREATE POLICY "Admins can view all legal actions" ON legal_actions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.is_admin = TRUE
    )
  );

-- 5. Allow Admins to view all escalations
DROP POLICY IF EXISTS "Admins can view all escalations" ON enforcement_escalations;

CREATE POLICY "Admins can view all escalations" ON enforcement_escalations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.is_admin = TRUE
    )
  );

-- Verification
SELECT 'Legal RLS policies updated for System Admins' as status;
