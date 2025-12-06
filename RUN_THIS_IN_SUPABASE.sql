-- ============================================
-- RUN THIS IN SUPABASE SQL EDITOR
-- Fixes ALL relationship errors + Storage permissions + Missing Columns
-- ============================================

-- 1. FIX MISSING COLUMNS IN PROFILES
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS first_name TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_name TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS location TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS date_of_birth TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS state TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS postal_code TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS pan_number TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS aadhaar_number TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS occupation TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS annual_income TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS emergency_contact_name TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS emergency_contact_phone TEXT;

-- Populate first/last name from full_name if empty
UPDATE profiles 
SET first_name = split_part(full_name, ' ', 1),
    last_name = substring(full_name from position(' ' in full_name) + 1)
WHERE first_name IS NULL;

-- 2. FIX STORAGE PERMISSIONS (Profile Images)
-- First, ensure the bucket exists and is public
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can upload their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can upload an avatar" ON storage.objects;

-- Create permissive policies for avatars
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatars" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars' AND 
    auth.uid() = owner
  );

CREATE POLICY "Users can update their own avatars" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'avatars' AND 
    auth.uid() = owner
  );

-- 3. FIX DISPUTES RELATIONSHIPS
ALTER TABLE disputes DROP CONSTRAINT IF EXISTS disputes_creator_id_fkey;
ALTER TABLE disputes DROP CONSTRAINT IF EXISTS disputes_reported_user_id_fkey;
ALTER TABLE disputes DROP CONSTRAINT IF EXISTS disputes_pool_id_fkey;

ALTER TABLE disputes ADD CONSTRAINT disputes_creator_id_fkey 
  FOREIGN KEY (creator_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE disputes ADD CONSTRAINT disputes_reported_user_id_fkey 
  FOREIGN KEY (reported_user_id) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE disputes ADD CONSTRAINT disputes_pool_id_fkey 
  FOREIGN KEY (pool_id) REFERENCES pools(id) ON DELETE CASCADE;

-- 4. FIX WITHDRAWAL_REQUESTS RELATIONSHIPS
ALTER TABLE withdrawal_requests DROP CONSTRAINT IF EXISTS withdrawal_requests_user_id_fkey;
ALTER TABLE withdrawal_requests ADD CONSTRAINT withdrawal_requests_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

-- 5. FIX POOLS CREATOR RELATIONSHIP
ALTER TABLE pools DROP CONSTRAINT IF EXISTS pools_creator_id_fkey;
ALTER TABLE pools ADD CONSTRAINT pools_creator_id_fkey 
  FOREIGN KEY (creator_id) REFERENCES profiles(id) ON DELETE CASCADE;

-- 6. ADD ADMIN RLS POLICIES
DROP POLICY IF EXISTS "Admins can view all disputes" ON disputes;
CREATE POLICY "Admins can view all disputes" ON disputes
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

DROP POLICY IF EXISTS "Admins can view all withdrawals" ON withdrawal_requests;
CREATE POLICY "Admins can view all withdrawals" ON withdrawal_requests
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

DROP POLICY IF EXISTS "Admins can update withdrawals" ON withdrawal_requests;
CREATE POLICY "Admins can update withdrawals" ON withdrawal_requests
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

-- 8. AUTOMATICALLY CREATE PROFILE ON SIGN UP
-- This function copies metadata (full_name, phone) from auth.users to public.profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, phone, created_at, updated_at)
  VALUES (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'phone',
    now(),
    now()
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger the function every time a user is created
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 9. SET YOUR ACCOUNT AS ADMIN
UPDATE profiles SET is_admin = true 
WHERE email = 'abhayvishwakarma0814@gmail.com';

-- VERIFICATION
SELECT 'Missing Columns Fixed' as check_name, COUNT(*) FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name IN ('bio', 'location', 'date_of_birth', 'first_name', 'phone');
