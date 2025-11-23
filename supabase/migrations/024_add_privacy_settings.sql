-- Migration: Add privacy settings to profiles
-- Description: Adds a JSONB column for flexible privacy settings

ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS privacy_settings JSONB DEFAULT '{"show_profile": true, "show_activity": true, "email_notifications": true}'::jsonb;

-- Update existing rows to have default settings if null
UPDATE profiles 
SET privacy_settings = '{"show_profile": true, "show_activity": true, "email_notifications": true}'::jsonb 
WHERE privacy_settings IS NULL;
