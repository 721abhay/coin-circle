-- ============================================
-- COMPREHENSIVE FIX FOR ADMIN DASHBOARD ERRORS
-- Run this script to fix all relationship issues
-- ============================================

-- 1. FIX DISPUTES TABLE RELATIONSHIPS
-- ============================================

-- Drop existing foreign key constraints
ALTER TABLE disputes DROP CONSTRAINT IF EXISTS disputes_creator_id_fkey;
ALTER TABLE disputes DROP CONSTRAINT IF EXISTS disputes_reported_user_id_fkey;
ALTER TABLE disputes DROP CONSTRAINT IF EXISTS disputes_pool_id_fkey;

-- Add correct foreign keys to profiles table (not auth.users)
ALTER TABLE disputes 
  ADD CONSTRAINT disputes_creator_id_fkey 
  FOREIGN KEY (creator_id) 
  REFERENCES profiles(id) 
  ON DELETE CASCADE;

ALTER TABLE disputes 
  ADD CONSTRAINT disputes_reported_user_id_fkey 
  FOREIGN KEY (reported_user_id) 
  REFERENCES profiles(id) 
  ON DELETE SET NULL;

ALTER TABLE disputes 
  ADD CONSTRAINT disputes_pool_id_fkey 
  FOREIGN KEY (pool_id) 
  REFERENCES pools(id) 
  ON DELETE CASCADE;

-- Fix dispute_evidence foreign keys
ALTER TABLE dispute_evidence DROP CONSTRAINT IF EXISTS dispute_evidence_uploader_id_fkey;
ALTER TABLE dispute_evidence 
  ADD CONSTRAINT dispute_evidence_uploader_id_fkey 
  FOREIGN KEY (uploader_id) 
  REFERENCES profiles(id) 
  ON DELETE CASCADE;

-- 2. VERIFY WITHDRAWAL_REQUESTS RELATIONSHIP
-- ============================================
-- This should already be correct, but we'll ensure it

ALTER TABLE withdrawal_requests DROP CONSTRAINT IF EXISTS withdrawal_requests_user_id_fkey;
ALTER TABLE withdrawal_requests 
  ADD CONSTRAINT withdrawal_requests_user_id_fkey 
  FOREIGN KEY (user_id) 
  REFERENCES profiles(id) 
  ON DELETE CASCADE;

-- 3. VERIFY POOLS CREATOR RELATIONSHIP
-- ============================================

ALTER TABLE pools DROP CONSTRAINT IF EXISTS pools_creator_id_fkey;
ALTER TABLE pools 
  ADD CONSTRAINT pools_creator_id_fkey 
  FOREIGN KEY (creator_id) 
  REFERENCES profiles(id) 
  ON DELETE CASCADE;

-- 4. UPDATE RLS POLICIES
-- ============================================

-- Disputes policies (use is_admin instead of role)
DROP POLICY IF EXISTS "Admins can view all disputes" ON disputes;
CREATE POLICY "Admins can view all disputes" ON disputes
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

DROP POLICY IF EXISTS "Admins can update disputes" ON disputes;
CREATE POLICY "Admins can update disputes" ON disputes
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

-- Dispute evidence policies
DROP POLICY IF EXISTS "Admins can view all evidence" ON dispute_evidence;
CREATE POLICY "Admins can view all evidence" ON dispute_evidence
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

-- Withdrawal requests admin policies
DROP POLICY IF EXISTS "Admins can view all withdrawal requests" ON withdrawal_requests;
CREATE POLICY "Admins can view all withdrawal requests" ON withdrawal_requests
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

DROP POLICY IF EXISTS "Admins can update withdrawal requests" ON withdrawal_requests;
CREATE POLICY "Admins can update withdrawal requests" ON withdrawal_requests
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

-- 5. CREATE INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_disputes_creator ON disputes(creator_id);
CREATE INDEX IF NOT EXISTS idx_disputes_pool ON disputes(pool_id);
CREATE INDEX IF NOT EXISTS idx_disputes_status ON disputes(status);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_user ON withdrawal_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_status ON withdrawal_requests(status);

-- 6. VERIFY DATA INTEGRITY
-- ============================================

-- Check for orphaned records in disputes
DO $$
DECLARE
  orphan_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO orphan_count
  FROM disputes d
  WHERE NOT EXISTS (SELECT 1 FROM profiles p WHERE p.id = d.creator_id);
  
  IF orphan_count > 0 THEN
    RAISE NOTICE 'WARNING: Found % orphaned dispute records with invalid creator_id', orphan_count;
  END IF;
END $$;

-- Check for orphaned records in withdrawal_requests
DO $$
DECLARE
  orphan_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO orphan_count
  FROM withdrawal_requests wr
  WHERE NOT EXISTS (SELECT 1 FROM profiles p WHERE p.id = wr.user_id);
  
  IF orphan_count > 0 THEN
    RAISE NOTICE 'WARNING: Found % orphaned withdrawal_request records with invalid user_id', orphan_count;
  END IF;
END $$;

-- ============================================
-- COMPLETION MESSAGE
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '✅ All relationship fixes applied successfully!';
  RAISE NOTICE '✅ Admin Dashboard should now load without errors';
  RAISE NOTICE '✅ Please restart your Flutter app to see changes';
END $$;
