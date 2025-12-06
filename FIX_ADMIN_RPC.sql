-- Admin Stats RPC
CREATE OR REPLACE FUNCTION get_admin_stats()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_users INT;
  v_active_pools INT;
  v_total_volume NUMERIC;
  v_pending_kyc INT;
BEGIN
  SELECT COUNT(*) INTO v_total_users FROM profiles;
  SELECT COUNT(*) INTO v_active_pools FROM pools WHERE status = 'active';
  SELECT COALESCE(SUM(amount), 0) INTO v_total_volume FROM transactions WHERE status = 'completed';
  SELECT COUNT(*) INTO v_pending_kyc FROM profiles WHERE pan_number IS NOT NULL AND (phone_verified = false OR email_verified = false);

  RETURN jsonb_build_object(
    'total_users', v_total_users,
    'active_pools', v_active_pools,
    'total_volume', v_total_volume,
    'pending_kyc', v_pending_kyc,
    'user_growth_rate', 5, 
    'pool_growth_rate', 10, 
    'volume_growth_rate', 15
  );
END;
$$;

-- Revenue Chart Data RPC
CREATE OR REPLACE FUNCTION get_revenue_chart_data()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Return last 7 days revenue (sum of joining fees)
  RETURN (
    SELECT jsonb_agg(jsonb_build_object('date', day, 'amount', COALESCE(daily_sum, 0)))
    FROM (
      SELECT 
        date_trunc('day', created_at) as day, 
        SUM(amount) as daily_sum
      FROM transactions
      WHERE transaction_type = 'joining_fee' AND created_at > NOW() - INTERVAL '7 days'
      GROUP BY 1
      ORDER BY 1
    ) t
  );
END;
$$;

-- Process Withdrawal RPC
CREATE OR REPLACE FUNCTION process_withdrawal(
  p_withdrawal_id UUID,
  p_status TEXT,
  p_rejection_reason TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_amount NUMERIC;
BEGIN
  -- Get withdrawal details
  SELECT user_id, amount INTO v_user_id, v_amount
  FROM withdrawal_requests
  WHERE id = p_withdrawal_id;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Withdrawal request not found';
  END IF;

  -- Update request status
  UPDATE withdrawal_requests
  SET status = p_status,
      rejection_reason = p_rejection_reason,
      processed_at = NOW()
  WHERE id = p_withdrawal_id;

  -- If rejected, refund the locked amount to available balance
  IF p_status = 'rejected' THEN
    UPDATE wallets
    SET locked_balance = locked_balance - v_amount,
        available_balance = available_balance + v_amount
    WHERE user_id = v_user_id;
    
  ELSIF p_status = 'completed' THEN
    -- Deduct from locked balance (it was moved there on request)
    UPDATE wallets
    SET locked_balance = locked_balance - v_amount
    WHERE user_id = v_user_id;
  END IF;
END;
$$;

-- Approve Deposit Request RPC (Atomic)
CREATE OR REPLACE FUNCTION approve_deposit_request(
  p_request_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_amount NUMERIC;
  v_status TEXT;
BEGIN
  SELECT user_id, amount, status INTO v_user_id, v_amount, v_status
  FROM deposit_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF v_status != 'pending' THEN
    RAISE EXCEPTION 'Request already processed';
  END IF;

  -- Update request
  UPDATE deposit_requests
  SET status = 'approved',
      processed_at = NOW()
  WHERE id = p_request_id;

  -- Credit wallet
  UPDATE wallets
  SET available_balance = available_balance + v_amount
  WHERE user_id = v_user_id;

  -- Record transaction
  INSERT INTO transactions (user_id, transaction_type, amount, status, description, metadata)
  VALUES (v_user_id, 'deposit', v_amount, 'completed', 'Manual Deposit Approved', jsonb_build_object('request_id', p_request_id));

END;
$$;
