-- Reset all users to NOT be admins
UPDATE profiles SET is_admin = FALSE;

-- OPTIONAL: Set a specific user as admin (Uncomment and replace email)
-- UPDATE profiles SET is_admin = TRUE WHERE email = 'admin@example.com';

-- Verify the change
SELECT email, is_admin FROM profiles;
