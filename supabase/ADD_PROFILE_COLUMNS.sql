-- ============================================================================
-- SIMPLE SETUP - Add columns one by one (safer approach)
-- ============================================================================
-- Run this in Supabase SQL Editor
-- This adds columns individually to avoid any conflicts
-- ============================================================================

-- Add phone column
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone TEXT;

-- Add verification columns
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false;

-- Add address columns
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS city VARCHAR(100);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS state VARCHAR(100);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS postal_code VARCHAR(10);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS country VARCHAR(100) DEFAULT 'India';

-- Add personal details
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS date_of_birth DATE;

-- Add identity documents
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS pan_number VARCHAR(10);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS aadhaar_number VARCHAR(12);

-- Add financial information
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS occupation VARCHAR(100);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS annual_income VARCHAR(50);

-- Add emergency contact
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS emergency_contact_name VARCHAR(255);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS emergency_contact_phone VARCHAR(15);

-- Add privacy settings
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS privacy_settings JSONB DEFAULT '{}'::jsonb;

-- Verify columns were added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
  AND column_name IN (
    'phone', 'phone_verified', 'email_verified', 
    'address', 'city', 'state', 'postal_code',
    'date_of_birth', 'pan_number', 'aadhaar_number',
    'occupation', 'annual_income',
    'emergency_contact_name', 'emergency_contact_phone'
  )
ORDER BY column_name;

-- Success message
SELECT '✅ Profile columns added successfully!' as status;
