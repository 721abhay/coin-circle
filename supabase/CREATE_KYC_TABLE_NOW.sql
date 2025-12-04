-- ============================================
-- MINIMAL KYC TABLE SETUP
-- Copy this entire script and run it in Supabase SQL Editor
-- ============================================

-- Create the table
CREATE TABLE IF NOT EXISTS kyc_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  
  -- Document fields
  aadhaar_number VARCHAR(12),
  aadhaar_photo_url TEXT,
  pan_number VARCHAR(10),
  pan_photo_url TEXT,
  bank_account_number VARCHAR(20),
  bank_ifsc_code VARCHAR(11),
  selfie_with_id_url TEXT,
  address_proof_url TEXT,
  
  -- Status fields
  verification_status VARCHAR(20) DEFAULT 'pending',
  verified_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE kyc_documents ENABLE ROW LEVEL SECURITY;

-- Allow users to view their own KYC
CREATE POLICY "Users can view own KYC" ON kyc_documents
  FOR SELECT USING (auth.uid() = user_id);

-- Allow users to insert their own KYC
CREATE POLICY "Users can insert own KYC" ON kyc_documents
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own KYC
CREATE POLICY "Users can update own KYC" ON kyc_documents
  FOR UPDATE USING (auth.uid() = user_id);

-- Success message
SELECT 'KYC table created successfully!' as message;
