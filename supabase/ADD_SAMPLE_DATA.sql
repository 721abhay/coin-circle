-- ============================================================================
-- ADD SAMPLE PERSONAL DETAILS DATA
-- ============================================================================
-- This script adds sample data to your profile for testing
-- Run this in Supabase SQL Editor AFTER running SAFE_SETUP.sql
-- Replace the sample data with your actual information
-- ============================================================================

-- Update your profile with personal details
-- This will update the currently logged-in user's profile
UPDATE profiles SET
  -- Contact Information
  phone = '+91 9876543210',
  phone_verified = true,
  email_verified = true,
  
  -- Address
  address = '123 Main Street, Apartment 4B',
  city = 'Mumbai',
  state = 'Maharashtra',
  postal_code = '400001',
  country = 'India',
  
  -- Personal Details
  date_of_birth = '1990-08-15',  -- Format: YYYY-MM-DD
  
  -- Identity Documents
  pan_number = 'ABCDE1234F',
  aadhaar_number = '123456789012',
  
  -- Financial Information
  occupation = 'Software Engineer',
  annual_income = '₹10,00,000 - ₹15,00,000',
  
  -- Emergency Contact
  emergency_contact_name = 'John Doe',
  emergency_contact_phone = '+91 9876543211',
  
  -- Privacy Settings (optional)
  privacy_settings = '{
    "show_profile_picture": true,
    "show_full_name": true,
    "show_phone": false,
    "show_email": false,
    "show_location": false
  }'::jsonb

WHERE id = auth.uid();  -- This updates only YOUR profile

-- Verify the update
SELECT 
  full_name,
  phone,
  email,
  city,
  state,
  date_of_birth,
  pan_number,
  occupation,
  '✅ Profile updated successfully!' as status
FROM profiles 
WHERE id = auth.uid();

-- ============================================================================
-- CUSTOMIZE YOUR DATA
-- ============================================================================
-- To customize, simply change the values above:
--
-- 1. Phone: Your actual phone number (with country code)
-- 2. Address: Your street address
-- 3. City: Your city name
-- 4. State: Your state/province
-- 5. Postal Code: Your PIN/ZIP code
-- 6. Date of Birth: Format YYYY-MM-DD (e.g., '1990-08-15')
-- 7. PAN Number: Your PAN card number (10 characters)
-- 8. Aadhaar Number: Your Aadhaar number (12 digits, no spaces)
-- 9. Occupation: Your job title
-- 10. Annual Income: Your income range
-- 11. Emergency Contact: Name and phone of emergency contact
--
-- Then run this script again!
-- ============================================================================
