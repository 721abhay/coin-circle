-- ============================================
-- SIMPLE FIX - Run in Supabase SQL Editor
-- ============================================

-- STEP 1: Add role column if it doesn't exist
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user';

-- STEP 2: Set your account as admin
-- REPLACE 'YOUR_EMAIL@gmail.com' with your actual email
UPDATE profiles 
SET role = 'admin' 
WHERE email = 'YOUR_EMAIL@gmail.com';

-- Verify it worked
SELECT id, email, role FROM profiles WHERE role = 'admin';


-- STEP 3: Fix users with null names
UPDATE profiles 
SET full_name = 'User ' || SUBSTRING(id::text, 1, 8)
WHERE full_name IS NULL OR full_name = '' OR full_name = 'null null';


-- STEP 4: Create missing wallets
INSERT INTO wallets (user_id, available_balance, locked_balance, created_at)
SELECT id, 0, 0, NOW() 
FROM profiles 
WHERE id NOT IN (SELECT user_id FROM wallets)
ON CONFLICT (user_id) DO NOTHING;


-- STEP 5: Create profiles for users without them
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


-- STEP 6: Verify everything
SELECT 
  COUNT(*) as total_users,
  COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_count,
  COUNT(CASE WHEN full_name IS NULL OR full_name = '' THEN 1 END) as null_names
FROM profiles;

SELECT 
  COUNT(DISTINCT p.id) as users_with_profiles,
  COUNT(DISTINCT w.user_id) as users_with_wallets
FROM profiles p
LEFT JOIN wallets w ON w.user_id = p.id;


-- ============================================
-- DONE! 
-- You should see:
-- - Your email with role = 'admin'
-- - No null names
-- - Same number of profiles and wallets
-- ============================================
