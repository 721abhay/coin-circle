-- ============================================
-- STEP-BY-STEP FIX SCRIPT
-- Run each section ONE AT A TIME in Supabase SQL Editor
-- ============================================

-- ============================================
-- STEP 1: Set Your Account as Admin
-- IMPORTANT: Replace YOUR_EMAIL@gmail.com with your actual email
-- ============================================
UPDATE profiles 
SET role = 'admin' 
WHERE email = 'YOUR_EMAIL@gmail.com';

-- Verify it worked (should show 1 row)
SELECT id, email, role FROM profiles WHERE role = 'admin';


-- ============================================
-- STEP 2: Fix Users with Null Names
-- ============================================
UPDATE profiles 
SET full_name = 'User ' || SUBSTRING(id::text, 1, 8)
WHERE full_name IS NULL OR full_name = '' OR full_name = 'null null';

-- Verify it worked
SELECT id, full_name FROM profiles WHERE full_name LIKE 'User %';


-- ============================================
-- STEP 3: Create Missing Wallets
-- ============================================
INSERT INTO wallets (user_id, available_balance, locked_balance, created_at)
SELECT id, 0, 0, NOW() 
FROM profiles 
WHERE id NOT IN (SELECT user_id FROM wallets)
ON CONFLICT (user_id) DO NOTHING;

-- Verify it worked
SELECT COUNT(*) as wallets_created FROM wallets;


-- ============================================
-- STEP 4: Find Orphaned Users (users without profiles)
-- ============================================
SELECT 
  u.id, 
  u.email,
  u.created_at
FROM auth.users u 
LEFT JOIN profiles p ON p.id = u.id 
WHERE p.id IS NULL;


-- ============================================
-- STEP 5: Create Profiles for Orphaned Users
-- (Only run if STEP 4 found any users)
-- ============================================
INSERT INTO profiles (id, email, full_name, created_at)
SELECT 
  u.id,
  u.email,
  'User ' || SUBSTRING(u.id::text, 1, 8),
  u.created_at
FROM auth.users u
LEFT JOIN profiles p ON p.id = u.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;


-- ============================================
-- STEP 6: Drop Old Admin Policies (if they exist)
-- ============================================
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can delete profiles" ON profiles;


-- ============================================
-- STEP 7: Create New Admin Policies
-- ============================================
CREATE POLICY "Admins can view all profiles"
ON profiles FOR SELECT
TO authenticated
USING (
  auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  )
);

CREATE POLICY "Admins can update all profiles"
ON profiles FOR UPDATE
TO authenticated
USING (
  auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  )
);

CREATE POLICY "Admins can delete profiles"
ON profiles FOR DELETE
TO authenticated
USING (
  auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  )
);


-- ============================================
-- STEP 8: Verify Everything Worked
-- ============================================

-- Check total users
SELECT 
  COUNT(*) as total_users,
  COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_count,
  COUNT(CASE WHEN full_name IS NULL OR full_name = '' THEN 1 END) as null_names
FROM profiles;

-- Check wallets
SELECT 
  COUNT(DISTINCT p.id) as users_with_profiles,
  COUNT(DISTINCT w.user_id) as users_with_wallets
FROM profiles p
LEFT JOIN wallets w ON w.user_id = p.id;

-- Check policies
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename = 'profiles' AND policyname LIKE 'Admins%';


-- ============================================
-- DONE! 
-- You should see:
-- - Your email as admin
-- - All users have names (no null)
-- - All users have wallets
-- - 3 admin policies created
-- ============================================
