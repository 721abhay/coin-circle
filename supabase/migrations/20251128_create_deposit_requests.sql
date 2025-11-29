-- Create deposit_requests table for manual payments
CREATE TABLE IF NOT EXISTS deposit_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
  transaction_reference TEXT NOT NULL, -- UPI Ref ID or Bank Ref
  proof_url TEXT, -- URL to screenshot (optional for now)
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  admin_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE deposit_requests ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Users can view own deposits" ON deposit_requests;
CREATE POLICY "Users can view own deposits" 
  ON deposit_requests FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create deposits" ON deposit_requests;
CREATE POLICY "Users can create deposits" 
  ON deposit_requests FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Trigger for updated_at
DROP TRIGGER IF EXISTS set_deposit_requests_updated_at ON deposit_requests;
CREATE TRIGGER set_deposit_requests_updated_at
  BEFORE UPDATE ON deposit_requests
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Index
CREATE INDEX IF NOT EXISTS idx_deposit_requests_user ON deposit_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_deposit_requests_status ON deposit_requests(status);
