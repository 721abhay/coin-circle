-- WALLET & TRANSACTIONS SETUP (Idempotent)
-- Run this in Supabase SQL Editor

-- 1. Create Wallets Table
CREATE TABLE IF NOT EXISTS wallets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  available_balance NUMERIC DEFAULT 0.00,
  locked_balance NUMERIC DEFAULT 0.00,
  winning_balance NUMERIC DEFAULT 0.00,
  total_winnings NUMERIC DEFAULT 0.00,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create Transactions Table
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  pool_id UUID REFERENCES pools(id) ON DELETE SET NULL,
  transaction_type VARCHAR(50) NOT NULL,
  amount NUMERIC NOT NULL,
  currency VARCHAR(10) DEFAULT 'INR',
  status VARCHAR(20) DEFAULT 'pending',
  payment_method VARCHAR(50),
  payment_reference VARCHAR(100),
  description TEXT,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create Deposit Requests Table
CREATE TABLE IF NOT EXISTS deposit_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  amount NUMERIC NOT NULL,
  transaction_reference VARCHAR(100),
  proof_url TEXT,
  status VARCHAR(20) DEFAULT 'pending',
  admin_notes TEXT,
  processed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create Withdrawal Requests Table
CREATE TABLE IF NOT EXISTS withdrawal_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  amount NUMERIC NOT NULL,
  bank_account_id UUID REFERENCES bank_accounts(id),
  status VARCHAR(20) DEFAULT 'pending',
  rejection_reason TEXT,
  processed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Enable RLS
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE deposit_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies (Drop first to avoid errors)

DO $$ 
BEGIN
  -- Wallets
  DROP POLICY IF EXISTS "Users can view own wallet" ON wallets;
  DROP POLICY IF EXISTS "Users can update own wallet" ON wallets;
  DROP POLICY IF EXISTS "Users can insert own wallet" ON wallets;
  
  -- Transactions
  DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
  DROP POLICY IF EXISTS "Users can insert own transactions" ON transactions;
  
  -- Deposit Requests
  DROP POLICY IF EXISTS "Users can view own deposit requests" ON deposit_requests;
  DROP POLICY IF EXISTS "Users can insert own deposit requests" ON deposit_requests;
  
  -- Withdrawal Requests
  DROP POLICY IF EXISTS "Users can view own withdrawal requests" ON withdrawal_requests;
  DROP POLICY IF EXISTS "Users can insert own withdrawal requests" ON withdrawal_requests;
END $$;

CREATE POLICY "Users can view own wallet" ON wallets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own wallet" ON wallets FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own wallet" ON wallets FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own transactions" ON transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own transactions" ON transactions FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own deposit requests" ON deposit_requests FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own deposit requests" ON deposit_requests FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own withdrawal requests" ON withdrawal_requests FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own withdrawal requests" ON withdrawal_requests FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 7. RPCs

CREATE OR REPLACE FUNCTION increment_wallet_balance(p_user_id UUID, p_amount NUMERIC)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE wallets SET available_balance = available_balance + p_amount, updated_at = NOW() WHERE user_id = p_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION decrement_wallet_balance(p_user_id UUID, p_amount NUMERIC)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_available NUMERIC;
BEGIN
  SELECT available_balance INTO v_available FROM wallets WHERE user_id = p_user_id FOR UPDATE;
  IF v_available < p_amount THEN RAISE EXCEPTION 'Insufficient funds'; END IF;
  UPDATE wallets SET available_balance = available_balance - p_amount, locked_balance = locked_balance + p_amount, updated_at = NOW() WHERE user_id = p_user_id;
END;
$$;
