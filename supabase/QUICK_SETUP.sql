-- MINIMAL SETUP - Just Bank Accounts and Personal Details
-- Run this in Supabase SQL Editor

-- 1. Add personal details columns to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS date_of_birth DATE,
ADD COLUMN IF NOT EXISTS pan_number VARCHAR(10),
ADD COLUMN IF NOT EXISTS aadhaar_number VARCHAR(12),
ADD COLUMN IF NOT EXISTS annual_income VARCHAR(50),
ADD COLUMN IF NOT EXISTS occupation VARCHAR(100),
ADD COLUMN IF NOT EXISTS privacy_settings JSONB DEFAULT '{}'::jsonb;

-- 2. Create bank_accounts  
CREATE TABLE IF NOT EXISTS bank_accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  account_holder_name VARCHAR(255) NOT NULL,
  account_number VARCHAR(20) NOT NULL,
  ifsc_code VARCHAR(11) NOT NULL,
  bank_name VARCHAR(255) NOT NULL,
  branch_name VARCHAR(255),
  account_type VARCHAR(20) DEFAULT 'savings',
  is_primary BOOLEAN DEFAULT false,
  is_verified BOOLEAN DEFAULT false,
  verification_method VARCHAR(50),
  verification_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, account_number)
);

-- 3. Enable RLS on bank_accounts
ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;

-- 4. Create policies for bank_accounts
CREATE POLICY "Users can view their own bank accounts" ON bank_accounts 
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own bank accounts" ON bank_accounts 
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own bank accounts" ON bank_accounts 
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own bank accounts" ON bank_accounts 
  FOR DELETE USING (auth.uid() = user_id);

-- 5. Create index for performance
CREATE INDEX IF NOT EXISTS idx_bank_accounts_user_id ON bank_accounts(user_id);

-- 6. Create function to set primary bank account
CREATE OR REPLACE FUNCTION set_primary_bank_account(account_id UUID, user_id_param UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE bank_accounts SET is_primary = false WHERE user_id = user_id_param;
    UPDATE bank_accounts SET is_primary = true WHERE id = account_id AND user_id = user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Done! Your tables are ready.
SELECT 'SUCCESS: Bank Accounts and Personal Details tables created!' as message;
