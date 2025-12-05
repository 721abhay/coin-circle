-- Quick Push Notifications Database Setup
-- Run this in Supabase SQL Editor

-- Add FCM token column to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token 
ON profiles(fcm_token) 
WHERE fcm_token IS NOT NULL;

-- Verify the column was added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name = 'fcm_token';

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ FCM token column added successfully!';
  RAISE NOTICE '📝 You can now run: flutter run';
END $$;
