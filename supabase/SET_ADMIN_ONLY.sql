-- ============================================
-- FIX ADMIN ACCESS - ONLY FOR SPECIFIC EMAIL
-- ============================================

-- 1. First, remove admin access from ALL users
UPDATE profiles SET is_admin = FALSE;

-- 2. Grant admin access ONLY to your specific email
-- Replace 'your-admin-email@example.com' with your actual admin email
UPDATE profiles 
SET is_admin = TRUE 
WHERE email = 'santoshbs4842795@gmail.com';  -- CHANGE THIS TO YOUR ADMIN EMAIL

-- 3. Verify the change
SELECT email, is_admin, kyc_verified 
FROM profiles 
ORDER BY is_admin DESC, email;

-- You should see:
-- - Only your email has is_admin = true
-- - All other users have is_admin = false
