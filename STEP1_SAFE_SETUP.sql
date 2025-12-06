-- ============================================================================
-- SAFE SETUP - Profile & Bank Accounts Schema
-- ============================================================================
-- This script safely adds columns to profiles and creates bank_accounts table
-- Run this in Supabase SQL Editor
-- Safe to run multiple times - won't error if tables/columns already exist
-- ============================================================================

-- 1. Add personal details columns to profiles table
-- ============================================================================
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS city VARCHAR(100),
ADD COLUMN IF NOT EXISTS state VARCHAR(100),
ADD COLUMN IF NOT EXISTS postal_code VARCHAR(10),
ADD COLUMN IF NOT EXISTS country VARCHAR(100) DEFAULT 'India',
ADD COLUMN IF NOT EXISTS date_of_birth DATE,
ADD COLUMN IF NOT EXISTS pan_number VARCHAR(10),
ADD COLUMN IF NOT EXISTS aadhaar_number VARCHAR(12),
ADD COLUMN IF NOT EXISTS annual_income VARCHAR(50),
ADD COLUMN IF NOT EXISTS occupation VARCHAR(100),
ADD COLUMN IF NOT EXISTS emergency_contact_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS emergency_contact_phone VARCHAR(15),
ADD COLUMN IF NOT EXISTS privacy_settings JSONB DEFAULT '{
  "show_profile_picture": true,
  "show_full_name": true,
  "show_phone": false,
  "show_email": false,
  "show_location": false
}'::jsonb;

-- 2. Create bank_accounts table
-- ============================================================================
CREATE TABLE IF NOT EXISTS bank_accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  account_holder_name VARCHAR(255) NOT NULL,
  account_number VARCHAR(20) NOT NULL,
  ifsc_code VARCHAR(11) NOT NULL,
  bank_name VARCHAR(255) NOT NULL,
  branch_name VARCHAR(255),
  account_type VARCHAR(20) DEFAULT 'savings' CHECK (account_type IN ('savings', 'current', 'salary')),
  is_primary BOOLEAN DEFAULT false,
  is_verified BOOLEAN DEFAULT false,
  verification_method VARCHAR(50),
  verification_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Add unique constraint for user_id + account_number
-- ============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'bank_accounts_user_account_unique'
  ) THEN
    ALTER TABLE bank_accounts 
    ADD CONSTRAINT bank_accounts_user_account_unique 
    UNIQUE(user_id, account_number);
  END IF;
END $$;

-- 4. Add check constraint for only one primary account per user
-- ============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'bank_accounts_one_primary_per_user'
  ) THEN
    CREATE UNIQUE INDEX bank_accounts_one_primary_per_user 
    ON bank_accounts(user_id) 
    WHERE is_primary = true;
  END IF;
END $$;

-- 5. Enable Row Level Security
-- ============================================================================
ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;

-- 6. Drop existing policies if they exist
-- ============================================================================
DROP POLICY IF EXISTS "Users can view their own bank accounts" ON bank_accounts;
DROP POLICY IF EXISTS "Users can insert their own bank accounts" ON bank_accounts;
DROP POLICY IF EXISTS "Users can update their own bank accounts" ON bank_accounts;
DROP POLICY IF EXISTS "Users can delete their own bank accounts" ON bank_accounts;

-- 7. Create RLS policies for bank_accounts
-- ============================================================================
CREATE POLICY "Users can view their own bank accounts" 
ON bank_accounts FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own bank accounts" 
ON bank_accounts FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own bank accounts" 
ON bank_accounts FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own bank accounts" 
ON bank_accounts FOR DELETE 
USING (auth.uid() = user_id);

-- 8. Create indexes for performance
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_bank_accounts_user_id ON bank_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_bank_accounts_is_primary ON bank_accounts(user_id, is_primary) WHERE is_primary = true;

-- 9. Create function to set primary bank account
-- ============================================================================
CREATE OR REPLACE FUNCTION set_primary_bank_account(
  account_id UUID, 
  user_id_param UUID
)
RETURNS VOID AS $$
BEGIN
  -- First, unset all primary flags for this user
  UPDATE bank_accounts 
  SET is_primary = false 
  WHERE user_id = user_id_param;
  
  -- Then set the specified account as primary
  UPDATE bank_accounts 
  SET is_primary = true 
  WHERE id = account_id 
    AND user_id = user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Create trigger to update updated_at timestamp
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_bank_accounts_updated_at ON bank_accounts;

CREATE TRIGGER update_bank_accounts_updated_at
BEFORE UPDATE ON bank_accounts
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 11. Create function to validate IFSC code format
-- ============================================================================
CREATE OR REPLACE FUNCTION validate_ifsc_code()
RETURNS TRIGGER AS $$
BEGIN
  -- IFSC code should be 11 characters: 4 letters, 0, then 6 alphanumeric
  IF NEW.ifsc_code !~ '^[A-Z]{4}0[A-Z0-9]{6}$' THEN
    RAISE EXCEPTION 'Invalid IFSC code format. Expected format: ABCD0123456';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS validate_ifsc_before_insert ON bank_accounts;
DROP TRIGGER IF EXISTS validate_ifsc_before_update ON bank_accounts;

CREATE TRIGGER validate_ifsc_before_insert
BEFORE INSERT ON bank_accounts
FOR EACH ROW
EXECUTE FUNCTION validate_ifsc_code();

CREATE TRIGGER validate_ifsc_before_update
BEFORE UPDATE ON bank_accounts
FOR EACH ROW
WHEN (OLD.ifsc_code IS DISTINCT FROM NEW.ifsc_code)
EXECUTE FUNCTION validate_ifsc_code();

-- ============================================================================
-- VERIFICATION QUERY
-- ============================================================================
SELECT 
  '✅ SUCCESS! Profile & Bank Accounts schema is ready!' as status,
  (SELECT COUNT(*) FROM bank_accounts) as total_bank_accounts,
  (SELECT COUNT(*) FROM profiles WHERE pan_number IS NOT NULL) as profiles_with_pan,
  (SELECT COUNT(*) FROM profiles WHERE address IS NOT NULL) as profiles_with_address;
