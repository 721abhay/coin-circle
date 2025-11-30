-- Fix disputes table foreign key relationships
-- The issue: disputes references auth.users instead of profiles

-- Step 1: Drop existing foreign key constraints
ALTER TABLE disputes DROP CONSTRAINT IF EXISTS disputes_creator_id_fkey;
ALTER TABLE disputes DROP CONSTRAINT IF EXISTS disputes_reported_user_id_fkey;

-- Step 2: Add correct foreign keys to profiles table
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

-- Step 3: Ensure pool_id foreign key exists
ALTER TABLE disputes DROP CONSTRAINT IF EXISTS disputes_pool_id_fkey;
ALTER TABLE disputes 
  ADD CONSTRAINT disputes_pool_id_fkey 
  FOREIGN KEY (pool_id) 
  REFERENCES pools(id) 
  ON DELETE CASCADE;

-- Step 4: Fix dispute_evidence foreign keys
ALTER TABLE dispute_evidence DROP CONSTRAINT IF EXISTS dispute_evidence_uploader_id_fkey;
ALTER TABLE dispute_evidence 
  ADD CONSTRAINT dispute_evidence_uploader_id_fkey 
  FOREIGN KEY (uploader_id) 
  REFERENCES profiles(id) 
  ON DELETE CASCADE;

-- Step 5: Update RLS policies to use profiles.is_admin instead of profiles.role
DROP POLICY IF EXISTS "Admins can view all disputes" ON disputes;
CREATE POLICY "Admins can view all disputes" ON disputes
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

DROP POLICY IF EXISTS "Admins can view all evidence" ON dispute_evidence;
CREATE POLICY "Admins can view all evidence" ON dispute_evidence
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

-- Step 6: Add admin update/delete policies
DROP POLICY IF EXISTS "Admins can update disputes" ON disputes;
CREATE POLICY "Admins can update disputes" ON disputes
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );
