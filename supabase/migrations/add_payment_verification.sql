-- Add payment verification columns to transactions table
-- This prevents fake transactions from showing as real money

-- 1. Add verification columns
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS payment_verified BOOLEAN DEFAULT false;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS payment_gateway TEXT; -- 'razorpay', 'paytm', 'upi', etc.
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS payment_gateway_id TEXT; -- Gateway transaction ID
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS payment_gateway_response JSONB; -- Full gateway response
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES auth.users(id);

-- 2. Add payment status enum (if not exists)
DO $$ BEGIN
  CREATE TYPE payment_status AS ENUM ('pending', 'processing', 'verified', 'failed', 'refunded');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- 3. Add payment_status column
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS payment_status payment_status DEFAULT 'pending';

-- 4. Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_transactions_payment_verified ON transactions(payment_verified);
CREATE INDEX IF NOT EXISTS idx_transactions_payment_status ON transactions(payment_status);
CREATE INDEX IF NOT EXISTS idx_transactions_payment_gateway_id ON transactions(payment_gateway_id);

-- 5. Update existing transactions to mark as unverified
UPDATE transactions
SET 
  payment_verified = false,
  payment_status = 'pending'
WHERE payment_verified IS NULL OR payment_verified = true;

-- 6. Create function to verify payment
CREATE OR REPLACE FUNCTION verify_payment(
  p_transaction_id UUID,
  p_gateway_id TEXT,
  p_gateway_response JSONB
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_transaction RECORD;
  v_result jsonb;
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true) THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  -- Get transaction details
  SELECT * INTO v_transaction FROM transactions WHERE id = p_transaction_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction not found';
  END IF;

  -- Update transaction as verified
  UPDATE transactions
  SET 
    payment_verified = true,
    payment_status = 'verified',
    payment_gateway_id = p_gateway_id,
    payment_gateway_response = p_gateway_response,
    verified_at = NOW(),
    verified_by = auth.uid()
  WHERE id = p_transaction_id;

  -- Create notification for user
  INSERT INTO notifications (user_id, title, message, type, created_at)
  VALUES (
    v_transaction.user_id,
    'Payment Verified',
    'Your payment of ₹' || v_transaction.amount || ' has been verified and credited to your account.',
    'system',
    NOW()
  );

  v_result := jsonb_build_object(
    'success', true,
    'message', 'Payment verified successfully',
    'transaction_id', p_transaction_id
  );

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION verify_payment(UUID, TEXT, JSONB) TO authenticated;

-- 7. Create function to mark payment as failed
CREATE OR REPLACE FUNCTION mark_payment_failed(
  p_transaction_id UUID,
  p_reason TEXT
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_transaction RECORD;
  v_result jsonb;
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true) THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  -- Get transaction details
  SELECT * INTO v_transaction FROM transactions WHERE id = p_transaction_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction not found';
  END IF;

  -- Update transaction as failed
  UPDATE transactions
  SET 
    payment_verified = false,
    payment_status = 'failed',
    verified_at = NOW(),
    verified_by = auth.uid()
  WHERE id = p_transaction_id;

  -- Create notification for user
  INSERT INTO notifications (user_id, title, message, type, created_at)
  VALUES (
    v_transaction.user_id,
    'Payment Failed',
    'Your payment of ₹' || v_transaction.amount || ' could not be verified. Reason: ' || p_reason,
    'system',
    NOW()
  );

  v_result := jsonb_build_object(
    'success', true,
    'message', 'Payment marked as failed',
    'transaction_id', p_transaction_id
  );

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION mark_payment_failed(UUID, TEXT) TO authenticated;

-- 8. Create view for verified transactions only
CREATE OR REPLACE VIEW verified_transactions AS
SELECT * FROM transactions
WHERE payment_verified = true AND payment_status = 'verified';

-- 9. Update RLS policies to only show verified transactions to users
DROP POLICY IF EXISTS "Users can view their own transactions" ON transactions;
CREATE POLICY "Users can view their own verified transactions" ON transactions
  FOR SELECT
  USING (
    user_id = auth.uid() 
    AND (payment_verified = true OR payment_status = 'verified')
  );

-- 10. Admins can see all transactions
DROP POLICY IF EXISTS "Admins can view all transactions" ON transactions;
CREATE POLICY "Admins can view all transactions" ON transactions
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );
