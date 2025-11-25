-- Add profile_visibility column to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS profile_visibility TEXT DEFAULT 'Private';

-- Update existing profiles
UPDATE public.profiles 
SET profile_visibility = 'Private' 
WHERE profile_visibility IS NULL;
