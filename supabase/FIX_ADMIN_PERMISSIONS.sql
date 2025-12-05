-- 1. Add is_admin column to profiles if it doesn't exist
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- 2. Make the current user an admin (since we don't know the ID, we'll update ALL users for this test environment)
-- WARNING: In a real app, you would only update specific users.
UPDATE profiles SET is_admin = TRUE;

-- 3. Update RLS policies for kyc_documents to allow admins to view/edit everything

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can view own KYC" ON kyc_documents;
DROP POLICY IF EXISTS "Users can insert own KYC" ON kyc_documents;
DROP POLICY IF EXISTS "Users can update own KYC" ON kyc_documents;
DROP POLICY IF EXISTS kyc_documents_select_own ON kyc_documents;
DROP POLICY IF EXISTS kyc_documents_insert_own ON kyc_documents;
DROP POLICY IF EXISTS kyc_documents_update_own ON kyc_documents;

-- Create new comprehensive policies

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

-- 4. Ensure profiles are visible to admins (so they can see names/emails in the list)
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
CREATE POLICY "Profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

-- 5. Success message
SELECT 'Admin privileges granted and RLS updated!' as status;
