-- ============================================
-- TEST NOTIFICATIONS
-- Run this to test if notifications are working
-- ============================================

-- 1. Get your user ID (replace email with yours)
SELECT id, email, phone FROM profiles WHERE email = 'santoshbs4842795@gmail.com';

-- 2. Create a test notification (replace USER_ID with the ID from step 1)
INSERT INTO notifications (user_id, type, title, message, metadata)
VALUES (
  'YOUR_USER_ID_HERE',  -- Replace with actual user ID
  'test',
  'Test Notification',
  'This is a test notification to verify the system is working.',
  '{"test": true}'::jsonb
);

-- 3. Check if notification was created
SELECT * FROM notifications ORDER BY created_at DESC LIMIT 5;

-- 4. Test KYC approval notification by manually updating a KYC status
-- (Only run this if you have a pending KYC document)
-- UPDATE kyc_documents 
-- SET verification_status = 'approved', 
--     verified_at = NOW()
-- WHERE user_id = 'YOUR_USER_ID_HERE'
-- AND verification_status = 'pending';

-- 5. Verify notification was auto-created
SELECT 
  n.title,
  n.message,
  n.type,
  n.created_at,
  p.email
FROM notifications n
JOIN profiles p ON n.user_id = p.id
ORDER BY n.created_at DESC
LIMIT 10;
