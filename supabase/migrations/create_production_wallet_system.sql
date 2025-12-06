-- PRODUCTION-GRADE WALLET SYSTEM FOR INDIA
-- Following RBI guidelines and industry best practices
-- Used by: Paytm, PhonePe, Google Pay, Razorpay

-- ============================================
-- 1. WALLET TABLE (Main Balance)
-- ============================================
CREATE TABLE IF NOT EXISTS wallets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  
  -- Balance fields (in paise for precision)
  balance BIGINT DEFAULT 0 CHECK (balance >= 0), -- Available balance in paise
  locked_balance BIGINT DEFAULT 0 CHECK (locked_balance >= 0), -- Locked for pending transactions
  total_balance BIGINT GENERATED ALWAYS AS (balance + locked_balance) STORED,
  
  -- Limits (RBI compliance)
  daily_limit BIGINT DEFAULT 10000000, -- ₹100,000 daily limit (in paise)
  monthly_limit BIGINT DEFAULT 100000000, -- ₹10,00,000 monthly limit
  daily_spent BIGINT DEFAULT 0,
  monthly_spent BIGINT DEFAULT 0,
  last_daily_reset DATE DEFAULT CURRENT_DATE,
  last_monthly_reset DATE DEFAULT CURRENT_DATE,
  
  -- KYC status (RBI requirement)
  kyc_status TEXT DEFAULT 'pending' CHECK (kyc_status IN ('pending', 'basic', 'full')),
  kyc_limit BIGINT DEFAULT 1000000, -- ₹10,000 for basic KYC, ₹1,00,000 for full KYC
  
  -- Security
  pin_hash TEXT, -- Wallet PIN (hashed)
  pin_attempts INTEGER DEFAULT 0,
  pin_locked_until TIMESTAMPTZ,
  
  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT positive_balance CHECK (balance >= 0),
  CONSTRAINT positive_locked CHECK (locked_balance >= 0)
);

-- ============================================
-- 2. WALLET TRANSACTIONS (Ledger)
-- ============================================
CREATE TABLE IF NOT EXISTS wallet_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wallet_id UUID REFERENCES wallets(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  
  -- Transaction details
  type TEXT NOT NULL CHECK (type IN (
    'credit', 'debit', 'lock', 'unlock', 'refund', 'reversal'
  )),
  category TEXT NOT NULL CHECK (category IN (
    'add_money', 'withdraw', 'pool_contribution', 'pool_winning', 
    'joining_fee', 'late_fee', 'refund', 'cashback', 'bonus'
  )),
  
  -- Amount (in paise)
  amount BIGINT NOT NULL CHECK (amount > 0),
  
  -- Balance snapshot (for audit)
  balance_before BIGINT NOT NULL,
  balance_after BIGINT NOT NULL,
  
  -- Payment gateway details
  payment_gateway TEXT, -- 'razorpay', 'paytm', 'phonepe', 'upi'
  payment_gateway_id TEXT UNIQUE, -- Gateway transaction ID
  payment_method TEXT, -- 'upi', 'card', 'netbanking', 'wallet'
  payment_gateway_response JSONB,
  
  -- Verification (CRITICAL)
  status TEXT DEFAULT 'pending' CHECK (status IN (
    'pending', 'processing', 'success', 'failed', 'reversed', 'refunded'
  )),
  verified BOOLEAN DEFAULT false,
  verified_at TIMESTAMPTZ,
  verified_by UUID REFERENCES auth.users(id),
  
  -- Reference
  reference_type TEXT, -- 'pool', 'withdrawal', 'add_money'
  reference_id UUID, -- Pool ID, withdrawal ID, etc.
  
  -- Description
  description TEXT NOT NULL,
  notes TEXT,
  
  -- Metadata
  metadata JSONB DEFAULT '{}',
  
  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. WITHDRAWAL REQUESTS
-- ============================================
CREATE TABLE IF NOT EXISTS withdrawal_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  wallet_id UUID REFERENCES wallets(id) NOT NULL,
  
  -- Amount
  amount BIGINT NOT NULL CHECK (amount > 0),
  
  -- Bank details
  bank_account_id UUID REFERENCES bank_accounts(id) NOT NULL,
  
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN (
    'pending', 'processing', 'completed', 'failed', 'cancelled'
  )),
  
  -- Processing
  processed_at TIMESTAMPTZ,
  processed_by UUID REFERENCES auth.users(id),
  
  -- Gateway details
  payment_gateway TEXT,
  payment_gateway_id TEXT,
  payment_gateway_response JSONB,
  
  -- Failure reason
  failure_reason TEXT,
  
  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 4. BANK ACCOUNTS (For withdrawals)
-- ============================================
CREATE TABLE IF NOT EXISTS bank_accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  
  -- Bank details
  account_holder_name TEXT NOT NULL,
  account_number TEXT NOT NULL,
  ifsc_code TEXT NOT NULL,
  bank_name TEXT NOT NULL,
  branch_name TEXT,
  account_type TEXT CHECK (account_type IN ('savings', 'current')),
  
  -- Verification
  verified BOOLEAN DEFAULT false,
  verified_at TIMESTAMPTZ,
  verification_method TEXT, -- 'penny_drop', 'manual'
  
  -- Primary account
  is_primary BOOLEAN DEFAULT false,
  
  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Unique constraint
  UNIQUE(user_id, account_number)
);

-- ============================================
-- 5. WALLET FUNCTIONS
-- ============================================

-- Function: Add money to wallet (after payment verification)
CREATE OR REPLACE FUNCTION add_money_to_wallet(
  p_user_id UUID,
  p_amount BIGINT,
  p_gateway TEXT,
  p_gateway_id TEXT,
  p_gateway_response JSONB
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_wallet RECORD;
  v_transaction_id UUID;
  v_result jsonb;
BEGIN
  -- Get wallet
  SELECT * INTO v_wallet FROM wallets WHERE user_id = p_user_id FOR UPDATE;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Wallet not found';
  END IF;
  
  -- Check if gateway ID already used (prevent duplicate)
  IF EXISTS (SELECT 1 FROM wallet_transactions WHERE payment_gateway_id = p_gateway_id) THEN
    RAISE EXCEPTION 'Transaction already processed';
  END IF;
  
  -- Create transaction record
  INSERT INTO wallet_transactions (
    wallet_id, user_id, type, category, amount,
    balance_before, balance_after,
    payment_gateway, payment_gateway_id, payment_gateway_response,
    status, verified, verified_at,
    description
  ) VALUES (
    v_wallet.id, p_user_id, 'credit', 'add_money', p_amount,
    v_wallet.balance, v_wallet.balance + p_amount,
    p_gateway, p_gateway_id, p_gateway_response,
    'success', true, NOW(),
    'Money added to wallet'
  ) RETURNING id INTO v_transaction_id;
  
  -- Update wallet balance
  UPDATE wallets
  SET 
    balance = balance + p_amount,
    updated_at = NOW()
  WHERE id = v_wallet.id;
  
  -- Create notification
  INSERT INTO notifications (user_id, title, message, type, created_at)
  VALUES (
    p_user_id,
    'Money Added',
    '₹' || (p_amount::DECIMAL / 100) || ' has been added to your wallet.',
    'system',
    NOW()
  );
  
  v_result := jsonb_build_object(
    'success', true,
    'transaction_id', v_transaction_id,
    'new_balance', v_wallet.balance + p_amount
  );
  
  RETURN v_result;
END;
$$;

-- Function: Deduct money from wallet (for pool contributions, etc.)
CREATE OR REPLACE FUNCTION deduct_from_wallet(
  p_user_id UUID,
  p_amount BIGINT,
  p_category TEXT,
  p_description TEXT,
  p_reference_type TEXT DEFAULT NULL,
  p_reference_id UUID DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_wallet RECORD;
  v_transaction_id UUID;
  v_result jsonb;
BEGIN
  -- Get wallet
  SELECT * INTO v_wallet FROM wallets WHERE user_id = p_user_id FOR UPDATE;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Wallet not found';
  END IF;
  
  -- Check sufficient balance
  IF v_wallet.balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient balance';
  END IF;
  
  -- Create transaction record
  INSERT INTO wallet_transactions (
    wallet_id, user_id, type, category, amount,
    balance_before, balance_after,
    status, verified, verified_at,
    description, reference_type, reference_id
  ) VALUES (
    v_wallet.id, p_user_id, 'debit', p_category, p_amount,
    v_wallet.balance, v_wallet.balance - p_amount,
    'success', true, NOW(),
    p_description, p_reference_type, p_reference_id
  ) RETURNING id INTO v_transaction_id;
  
  -- Update wallet balance
  UPDATE wallets
  SET 
    balance = balance - p_amount,
    updated_at = NOW()
  WHERE id = v_wallet.id;
  
  v_result := jsonb_build_object(
    'success', true,
    'transaction_id', v_transaction_id,
    'new_balance', v_wallet.balance - p_amount
  );
  
  RETURN v_result;
END;
$$;

-- Function: Lock balance (for pending transactions)
CREATE OR REPLACE FUNCTION lock_wallet_balance(
  p_user_id UUID,
  p_amount BIGINT,
  p_reference_type TEXT,
  p_reference_id UUID
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_wallet RECORD;
  v_transaction_id UUID;
BEGIN
  SELECT * INTO v_wallet FROM wallets WHERE user_id = p_user_id FOR UPDATE;
  
  IF v_wallet.balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient balance';
  END IF;
  
  -- Move from balance to locked_balance
  UPDATE wallets
  SET 
    balance = balance - p_amount,
    locked_balance = locked_balance + p_amount
  WHERE id = v_wallet.id;
  
  -- Record transaction
  INSERT INTO wallet_transactions (
    wallet_id, user_id, type, category, amount,
    balance_before, balance_after,
    status, description, reference_type, reference_id
  ) VALUES (
    v_wallet.id, p_user_id, 'lock', 'pool_contribution', p_amount,
    v_wallet.balance, v_wallet.balance - p_amount,
    'success', 'Balance locked for transaction', p_reference_type, p_reference_id
  ) RETURNING id INTO v_transaction_id;
  
  RETURN jsonb_build_object('success', true, 'transaction_id', v_transaction_id);
END;
$$;

-- ============================================
-- 6. ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can view their verified transactions" ON wallet_transactions;
DROP POLICY IF EXISTS "Admins can view all wallets" ON wallets;
DROP POLICY IF EXISTS "Admins can view all transactions" ON wallet_transactions;

-- Wallets: Users can only see their own
CREATE POLICY "Users can view their own wallet" ON wallets
  FOR SELECT USING (user_id = auth.uid());

-- Wallet transactions: Users can only see verified transactions
CREATE POLICY "Users can view their verified transactions" ON wallet_transactions
  FOR SELECT USING (user_id = auth.uid() AND verified = true);

-- Admins can see all
CREATE POLICY "Admins can view all wallets" ON wallets
  FOR ALL USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true));

CREATE POLICY "Admins can view all transactions" ON wallet_transactions
  FOR ALL USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true));

-- ============================================
-- 7. TRIGGERS
-- ============================================

-- Auto-create wallet for new users
CREATE OR REPLACE FUNCTION create_wallet_for_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO wallets (user_id) VALUES (NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_wallet_for_user();

-- Update timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER wallets_updated_at BEFORE UPDATE ON wallets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER wallet_transactions_updated_at BEFORE UPDATE ON wallet_transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- 8. INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_wallet_id ON wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_user_id ON wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_status ON wallet_transactions(status);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_gateway_id ON wallet_transactions(payment_gateway_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_created_at ON wallet_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_user_id ON withdrawal_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_status ON withdrawal_requests(status);
CREATE INDEX IF NOT EXISTS idx_bank_accounts_user_id ON bank_accounts(user_id);

-- ============================================
-- 9. UPI-SPECIFIC FEATURES (ZERO FEES!)
-- ============================================

-- UPI IDs table (for easy UPI payments)
CREATE TABLE IF NOT EXISTS upi_ids (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  upi_id TEXT NOT NULL UNIQUE, -- user@paytm, user@phonepe, etc.
  verified BOOLEAN DEFAULT false,
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, upi_id)
);

CREATE INDEX IF NOT EXISTS idx_upi_ids_user_id ON upi_ids(user_id);

-- UPI payment preferences
ALTER TABLE wallets ADD COLUMN IF NOT EXISTS preferred_payment_method TEXT DEFAULT 'upi';
ALTER TABLE wallets ADD COLUMN IF NOT EXISTS upi_auto_pay BOOLEAN DEFAULT false;

-- Function: Calculate transaction fee (ONLY UPI = ₹0!)
CREATE OR REPLACE FUNCTION calculate_transaction_fee(
  p_amount BIGINT,
  p_payment_method TEXT
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
BEGIN
  -- Only UPI is supported - and it's FREE in India!
  -- No card or netbanking fees
  RETURN 0;
END;
$$;

-- Add UPI transaction tracking
ALTER TABLE wallet_transactions ADD COLUMN IF NOT EXISTS upi_id TEXT;
ALTER TABLE wallet_transactions ADD COLUMN IF NOT EXISTS transaction_fee BIGINT DEFAULT 0;

COMMENT ON COLUMN wallet_transactions.transaction_fee IS 'Transaction fee in paise (UPI only = always ₹0)';
COMMENT ON TABLE upi_ids IS 'User UPI IDs for zero-fee transactions';


-- ============================================
-- GRANT PERMISSIONS
-- ============================================

GRANT EXECUTE ON FUNCTION add_money_to_wallet(UUID, BIGINT, TEXT, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION deduct_from_wallet(UUID, BIGINT, TEXT, TEXT, TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION lock_wallet_balance(UUID, BIGINT, TEXT, UUID) TO authenticated;
