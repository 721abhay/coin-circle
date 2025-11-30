-- Migration: Updated late fee calculation - ₹50 first day, +₹10 each subsequent day
-- This replaces the previous late fee structure

-- Step 1: Drop ALL existing versions of these functions
DO $$ 
DECLARE
    r RECORD;
BEGIN
    -- Drop all versions of calculate_late_fee
    FOR r IN 
        SELECT oid::regprocedure 
        FROM pg_proc 
        WHERE proname = 'calculate_late_fee'
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.oid::regprocedure || ' CASCADE';
    END LOOP;
    
    -- Drop all versions of get_payment_status_with_late_fee
    FOR r IN 
        SELECT oid::regprocedure 
        FROM pg_proc 
        WHERE proname = 'get_payment_status_with_late_fee'
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.oid::regprocedure || ' CASCADE';
    END LOOP;
    
    -- Drop all versions of get_contribution_status
    FOR r IN 
        SELECT oid::regprocedure 
        FROM pg_proc 
        WHERE proname = 'get_contribution_status'
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.oid::regprocedure || ' CASCADE';
    END LOOP;
END $$;

-- Step 2: Create new function to calculate late fee: ₹50 on first day late, then +₹10 each day
CREATE FUNCTION calculate_late_fee(days_late INTEGER)
RETURNS NUMERIC AS $$
BEGIN
  -- No grace period - late fees start immediately after due date
  -- Late Fee Structure: ₹50 on day 1, then +₹10 each day (50, 60, 70, 80, 90, 100...)
  
  IF days_late <= 0 THEN
    RETURN 0;
  ELSE
    -- ₹50 for first day + ₹10 for each additional day
    RETURN 50 + ((days_late - 1) * 10);
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Step 3: Create function to get payment status with updated late fee calculation
CREATE FUNCTION get_payment_status_with_late_fee(
  p_pool_id UUID,
  p_user_id UUID,
  p_payment_day INTEGER DEFAULT 1
)
RETURNS TABLE (
  is_paid BOOLEAN,
  amount_due NUMERIC,
  late_fee NUMERIC,
  total_due NUMERIC,
  days_late INTEGER,
  next_due_date TIMESTAMP WITH TIME ZONE,
  status TEXT
) AS $$
DECLARE
  v_pool RECORD;
  v_last_payment RECORD;
  v_days_overdue INTEGER;
  v_calculated_late_fee NUMERIC;
  v_current_month_start DATE;
  v_payment_due_date DATE;
BEGIN
  -- Get pool details
  SELECT * INTO v_pool
  FROM pools
  WHERE id = p_pool_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pool not found';
  END IF;
  
  -- Calculate payment due date based on payment day setting
  -- Get the current month's payment date
  v_current_month_start := DATE_TRUNC('month', CURRENT_DATE);
  v_payment_due_date := v_current_month_start + (p_payment_day - 1);
  
  -- If we're past this month's payment day, next payment is next month
  IF CURRENT_DATE > v_payment_due_date THEN
    next_due_date := (v_current_month_start + INTERVAL '1 month' + (p_payment_day - 1))::TIMESTAMP WITH TIME ZONE;
  ELSE
    next_due_date := v_payment_due_date::TIMESTAMP WITH TIME ZONE;
  END IF;
  
  -- Check if user has paid for current period
  SELECT * INTO v_last_payment
  FROM transactions
  WHERE pool_id = p_pool_id
    AND user_id = p_user_id
    AND transaction_type = 'contribution'
    AND status = 'completed'
    AND created_at >= v_current_month_start
    AND created_at < (v_current_month_start + INTERVAL '1 month')
  ORDER BY created_at DESC
  LIMIT 1;
  
  -- Determine payment status
  IF FOUND THEN
    -- User has paid for current period
    is_paid := TRUE;
    amount_due := 0;
    late_fee := 0;
    total_due := 0;
    days_late := 0;
    status := 'paid';
  ELSE
    -- User has not paid
    is_paid := FALSE;
    amount_due := v_pool.contribution_amount;
    
    -- Calculate days overdue (NO grace period)
    IF CURRENT_DATE > v_payment_due_date THEN
      v_days_overdue := EXTRACT(DAY FROM (CURRENT_DATE - v_payment_due_date))::INTEGER;
      days_late := v_days_overdue;
      
      -- Calculate late fee: ₹50 first day + ₹10 each additional day
      v_calculated_late_fee := calculate_late_fee(v_days_overdue);
      late_fee := v_calculated_late_fee;
      status := 'overdue';
    ELSE
      -- Payment not yet due
      days_late := 0;
      late_fee := 0;
      status := 'pending';
    END IF;
    
    total_due := amount_due + late_fee;
  END IF;
  
  RETURN NEXT;
END;
$$ LANGUAGE plpgsql STABLE;

-- Step 4: Create updated get_contribution_status function
CREATE FUNCTION get_contribution_status(
  p_pool_id UUID,
  p_user_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_result RECORD;
  v_pool RECORD;
  v_payment_day INTEGER;
BEGIN
  -- Get pool details including payment day
  SELECT * INTO v_pool
  FROM pools
  WHERE id = p_pool_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pool not found';
  END IF;
  
  -- Get payment day from pool (default to 1 if not set)
  v_payment_day := COALESCE(v_pool.payment_day, 1);
  
  -- Get payment status with updated late fee calculation
  SELECT * INTO v_result
  FROM get_payment_status_with_late_fee(p_pool_id, p_user_id, v_payment_day);
  
  RETURN json_build_object(
    'is_paid', v_result.is_paid,
    'amount_due', v_result.amount_due,
    'late_fee', v_result.late_fee,
    'total_due', v_result.total_due,
    'days_late', v_result.days_late,
    'next_due_date', v_result.next_due_date,
    'status', v_result.status,
    'payment_day', v_payment_day,
    'grace_period_days', 0
  );
END;
$$ LANGUAGE plpgsql STABLE;

-- Step 5: Add payment_day and joining_fee columns to pools table if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pools' AND column_name = 'payment_day') THEN
    ALTER TABLE pools ADD COLUMN payment_day INTEGER DEFAULT 1 CHECK (payment_day >= 1 AND payment_day <= 28);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pools' AND column_name = 'joining_fee') THEN
    ALTER TABLE pools ADD COLUMN joining_fee NUMERIC(10, 2) DEFAULT 50.00;
  END IF;
END $$;

-- Step 6: Add helpful comments
COMMENT ON FUNCTION calculate_late_fee IS 'Calculates late fees: ₹50 on first day late, then +₹10 each subsequent day (50, 60, 70, 80...). No grace period.';
COMMENT ON COLUMN pools.payment_day IS 'Day of month (1-28) when members must pay their contribution';
COMMENT ON COLUMN pools.joining_fee IS 'One-time fee charged when a member joins the pool (platform profit)';
