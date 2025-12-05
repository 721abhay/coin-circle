-- 1. Ensure phone column exists in profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone TEXT;

-- 2. Sync phone numbers from auth.users to public.profiles
-- This updates existing users who have a phone number in auth but not in profiles
UPDATE public.profiles p
SET phone = u.phone
FROM auth.users u
WHERE p.id = u.id
AND p.phone IS NULL
AND u.phone IS NOT NULL;

-- 3. Create a trigger to automatically sync phone number on user update/insert
CREATE OR REPLACE FUNCTION public.handle_user_phone_update() 
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.profiles
  SET phone = NEW.phone
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists to avoid duplication
DROP TRIGGER IF EXISTS on_auth_user_phone_update ON auth.users;

-- Create the trigger
CREATE TRIGGER on_auth_user_phone_update
AFTER UPDATE OF phone ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_user_phone_update();

-- 4. Success message
SELECT 'Phone numbers synced and trigger created!' as status;
