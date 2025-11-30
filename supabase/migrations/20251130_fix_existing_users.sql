-- CRITICAL FIXES - Run these in Supabase SQL Editor NOW

-- 1. Set your account as admin (REPLACE WITH YOUR EMAIL)
UPDATE profiles 
SET role = 'admin' 
WHERE email = 'YOUR_EMAIL@gmail.com';

-- 2. Fix existing users with null/empty names
UPDATE profiles 
SET full_name = 'User ' || SUBSTRING(id::text, 1, 8)
WHERE full_name IS NULL OR full_name = '' OR full_name = 'null null';

-- 3. Create missing wallets for existing users
INSERT INTO wallets (user_id, available_balance, locked_balance, created_at)
SELECT id, 0, 0, NOW() 
FROM profiles 
WHERE id NOT IN (SELECT user_id FROM wallets)
ON CONFLICT (user_id) DO NOTHING;

-- 4. Check for users without profiles (orphaned auth users)
SELECT 
  u.id, 
  u.email,
  u.created_at
FROM auth.users u 
LEFT JOIN profiles p ON p.id = u.id 
WHERE p.id IS NULL;

-- 5. Create profiles for orphaned users (if any found above)
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

-- 6. Add RLS policies for admin access
CREATE POLICY IF NOT EXISTS "Admins can view all profiles"
ON profiles FOR SELECT
TO authenticated
USING (
  auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  )
);

CREATE POLICY IF NOT EXISTS "Admins can update all profiles"
ON profiles FOR UPDATE
TO authenticated
USING (
  auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  )
);

CREATE POLICY IF NOT EXISTS "Admins can delete profiles"
ON profiles FOR DELETE
TO authenticated
USING (
  auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  )
);

-- 7. Verify the fixes
SELECT 
  COUNT(*) as total_users,
  COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_count,
  COUNT(CASE WHEN full_name IS NULL OR full_name = '' THEN 1 END) as null_names
FROM profiles;

-- 8. Check wallet creation
SELECT 
  COUNT(DISTINCT p.id) as users_with_profiles,
  COUNT(DISTINCT w.user_id) as users_with_wallets
FROM profiles p
LEFT JOIN wallets w ON w.user_id = p.id;
