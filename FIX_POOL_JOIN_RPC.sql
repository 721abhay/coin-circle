-- Run this in Supabase SQL Editor to fix the "Loading" issue when joining pools

CREATE OR REPLACE FUNCTION request_join_pool(
  p_pool_id UUID,
  p_invite_code TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_pool_code TEXT;
  v_user_id UUID;
  v_exists BOOLEAN;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not logged in';
  END IF;

  -- Check if pool exists and get code
  SELECT invite_code INTO v_pool_code
  FROM pools
  WHERE id = p_pool_id;

  IF v_pool_code IS NULL THEN
    RAISE EXCEPTION 'Pool not found';
  END IF;

  -- Verify invite code
  IF v_pool_code != p_invite_code THEN
    RAISE EXCEPTION 'Invalid invite code';
  END IF;

  -- Check if already a member
  SELECT EXISTS (
    SELECT 1 FROM pool_members
    WHERE pool_id = p_pool_id AND user_id = v_user_id
  ) INTO v_exists;

  IF v_exists THEN
    RAISE EXCEPTION 'You have already requested to join or are a member of this pool';
  END IF;

  -- Insert pending request
  INSERT INTO pool_members (pool_id, user_id, role, status, join_date)
  VALUES (p_pool_id, v_user_id, 'member', 'pending', NOW());

END;
$$;

-- Secure RPC to complete payment and activate membership
CREATE OR REPLACE FUNCTION complete_join_payment(
  p_pool_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_joining_fee NUMERIC;
  v_contribution_amount NUMERIC;
  v_total_required NUMERIC;
  v_available_balance NUMERIC;
  v_pool_name TEXT;
BEGIN
  -- Get user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not logged in';
  END IF;

  -- Get pool details
  SELECT joining_fee, contribution_amount, name 
  INTO v_joining_fee, v_contribution_amount, v_pool_name
  FROM pools WHERE id = p_pool_id;
  
  IF v_pool_name IS NULL THEN
    RAISE EXCEPTION 'Pool not found';
  END IF;

  v_total_required := COALESCE(v_joining_fee, 0) + COALESCE(v_contribution_amount, 0);

  -- Check balance (FOR UPDATE to lock the row)
  SELECT available_balance INTO v_available_balance
  FROM wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF v_available_balance < v_total_required THEN
    RAISE EXCEPTION 'Insufficient balance';
  END IF;

  -- Deduct from wallet
  UPDATE wallets
  SET available_balance = available_balance - v_total_required,
      locked_balance = locked_balance + COALESCE(v_contribution_amount, 0)
  WHERE user_id = v_user_id;

  -- Record Joining Fee Transaction
  INSERT INTO transactions (user_id, pool_id, transaction_type, amount, status, description, created_at)
  VALUES (v_user_id, p_pool_id, 'joining_fee', v_joining_fee, 'completed', 'Joining fee for ' || v_pool_name, NOW());

  -- Record Contribution Transaction
  INSERT INTO transactions (user_id, pool_id, transaction_type, amount, status, description, created_at)
  VALUES (v_user_id, p_pool_id, 'contribution', v_contribution_amount, 'completed', 'First contribution for ' || v_pool_name, NOW());

  -- Update Member Status
  UPDATE pool_members
  SET status = 'active'
  WHERE pool_id = p_pool_id AND user_id = v_user_id;

END;
$$;
