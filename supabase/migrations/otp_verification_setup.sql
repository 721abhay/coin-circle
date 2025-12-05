-- OTP Verification Setup
-- Run this in Supabase SQL Editor to ensure profile table has necessary columns

-- 1. Add phone_verified column
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT FALSE;

-- 2. Add phone column (if not already present)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone TEXT;

-- 3. Create index for phone lookups
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON profiles(phone);

-- 4. Function to automatically mark phone as verified when auth.users phone is confirmed
-- (Optional, but good for consistency if you use Supabase Auth's native phone verification)
-- Note: Supabase Auth updates auth.users, we need to sync to public.profiles if we want strict sync.
-- For now, our app logic handles the update to public.profiles explicitly.

DO $$
BEGIN
  RAISE NOTICE '✅ OTP verification columns added successfully!';
END $$;
