-- ============================================================================
-- WITHDRAWAL SYSTEM SETUP
-- Run this in Supabase SQL Editor
-- ============================================================================

-- 1. Create withdrawal_requests table
CREATE TABLE IF NOT EXISTS withdrawal_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  amount DECIMAL(15, 2) NOT NULL,
  bank_account_id UUID REFERENCES bank_accounts(id),
  
  -- Status
  status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
  
  -- Admin processing
  processed_by UUID REFERENCES profiles(id),
  processed_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. RLS Policies
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS withdrawal_requests_select_own ON withdrawal_requests;
DROP POLICY IF EXISTS withdrawal_requests_insert_own ON withdrawal_requests;
DROP POLICY IF EXISTS withdrawal_requests_select_all ON withdrawal_requests;
DROP POLICY IF EXISTS withdrawal_requests_update_all ON withdrawal_requests;

-- Users can view their own requests
CREATE POLICY withdrawal_requests_select_own ON withdrawal_requests
  FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own requests
CREATE POLICY withdrawal_requests_insert_own ON withdrawal_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Admins (or authenticated users for now) can view all requests
-- This is needed for the admin dashboard
CREATE POLICY withdrawal_requests_select_all ON withdrawal_requests
  FOR SELECT USING (auth.role() = 'authenticated');

-- Admins (or authenticated users for now) can update status
CREATE POLICY withdrawal_requests_update_all ON withdrawal_requests
  FOR UPDATE USING (auth.role() = 'authenticated');

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_user_id ON withdrawal_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_status ON withdrawal_requests(status);

-- 4. Trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_withdrawal_requests_updated_at ON withdrawal_requests;

CREATE TRIGGER update_withdrawal_requests_updated_at
BEFORE UPDATE ON withdrawal_requests
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 5. Add payout_status to winner_history if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'winner_history' AND column_name = 'payout_status'
  ) THEN
    ALTER TABLE winner_history 
    ADD COLUMN payout_status VARCHAR(20) DEFAULT 'pending'; -- pending, approved
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'winner_history' AND column_name = 'payout_approved_at'
  ) THEN
    ALTER TABLE winner_history 
    ADD COLUMN payout_approved_at TIMESTAMP WITH TIME ZONE;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'winner_history' AND column_name = 'payout_approved_by'
  ) THEN
    ALTER TABLE winner_history 
    ADD COLUMN payout_approved_by UUID REFERENCES profiles(id);
  END IF;
END $$;

-- 6. Verification
SELECT 'Withdrawal system setup complete!' as status;
