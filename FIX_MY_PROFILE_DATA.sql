-- ========================================
-- QUICK FIX: Populate Your Profile Data
-- ========================================
-- Run this in Supabase SQL Editor to fix your profile display

-- Step 1: Check what data you currently have
SELECT id, email, full_name, phone, avatar_url, bio 
FROM profiles 
WHERE email = 'abhayvishwakarma0814@gmail.com';

-- Step 2: Update your profile with your actual data
-- REPLACE THE VALUES BELOW WITH YOUR REAL DATA!
UPDATE profiles 
SET 
  full_name = 'Abhay Vishwakarma',  -- ← Change this to your real name
  phone = '+91 9876543210',          -- ← Change this to your real phone
  first_name = 'Abhay',              -- ← Your first name
  last_name = 'Vishwakarma',         -- ← Your last name
  bio = 'Your bio here',             -- ← Optional: Add a bio
  location = 'Your city'             -- ← Optional: Add your location
WHERE email = 'abhayvishwakarma0814@gmail.com';

-- Step 3: Verify the update worked
SELECT id, email, full_name, phone, avatar_url, bio 
FROM profiles 
WHERE email = 'abhayvishwakarma0814@gmail.com';

-- ========================================
-- After running this:
-- 1. Hot Restart your app (Press R)
-- 2. Go to Profile screen
-- 3. You should see your name and phone!
-- ========================================
