-- Migration: Late Fee System
-- Description: Add late fee configuration to pools and enforcement logic

-- Add late fee columns to pools table
ALTER TABLE pools 
ADD COLUMN IF NOT EXISTS late_fee_amount DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS late_fee_type TEXT DEFAULT 'fixed', -- 'fixed' or 'percentage'
ADD COLUMN IF NOT EXISTS grace_period_days INTEGER DEFAULT 0;

-- Function to calculate late fee for a contribution
CREATE OR REPLACE FUNCTION calculate_late_fee(
  p_pool_id UUID,
  p_payment_date TIMESTAMPTZ,
  p_contribution_amount DECIMAL
)
RETURNS DECIMAL AS $$
DECLARE
  v_pool RECORD;
  v_due_date TIMESTAMPTZ;
  v_days_late INTEGER;
  v_late_fee DECIMAL := 0;
BEGIN
  -- Get pool settings
  SELECT 
    late_fee_amount,
    late_fee_type,
    grace_period_days,
    contribution_frequency
  INTO v_pool
  FROM pools
  WHERE id = p_pool_id;

  -- Calculate due date (simplified - assumes monthly for now)
  -- In production, this would be more complex based on contribution_frequency
  v_due_date := DATE_TRUNC('month', p_payment_date) + INTERVAL '1 month';
  
  -- Calculate days late
  v_days_late := EXTRACT(DAY FROM (p_payment_date - v_due_date))::INTEGER;
  
  -- Only charge late fee if past grace period
  IF v_days_late > v_pool.grace_period_days THEN
    IF v_pool.late_fee_type = 'fixed' THEN
      v_late_fee := v_pool.late_fee_amount;
    ELSIF v_pool.late_fee_type = 'percentage' THEN
      v_late_fee := (p_contribution_amount * v_pool.late_fee_amount / 100);
    END IF;
  END IF;

  RETURN COALESCE(v_late_fee, 0);
END;
$$ LANGUAGE plpgsql;

-- Add late_fee column to transactions if not exists
ALTER TABLE transactions
ADD COLUMN IF NOT EXISTS late_fee DECIMAL(10,2) DEFAULT 0;

-- Function to get contribution status with late fee
CREATE OR REPLACE FUNCTION get_contribution_status(
  p_pool_id UUID,
  p_user_id UUID
)
RETURNS TABLE (
  is_paid BOOLEAN,
  amount_due DECIMAL,
  late_fee DECIMAL,
  total_due DECIMAL,
  due_date TIMESTAMPTZ,
  days_until_due INTEGER
) AS $$
DECLARE
  v_pool RECORD;
  v_last_payment TIMESTAMPTZ;
  v_calculated_due_date TIMESTAMPTZ;
  v_contribution_amount DECIMAL;
  v_late_fee_amount DECIMAL := 0;
  v_is_paid BOOLEAN := FALSE;
BEGIN
  -- Get pool details
  SELECT 
    contribution_amount,
    contribution_frequency,
    late_fee_amount,
    late_fee_type,
    grace_period_days,
    created_at
  INTO v_pool
  FROM pools
  WHERE id = p_pool_id;

  v_contribution_amount := v_pool.contribution_amount;

  -- Get last payment date
  SELECT MAX(created_at)
  INTO v_last_payment
  FROM transactions
  WHERE pool_id = p_pool_id
    AND user_id = p_user_id
    AND type = 'contribution';

  -- Calculate next due date based on frequency
  IF v_last_payment IS NULL THEN
    -- First payment due immediately
    v_calculated_due_date := v_pool.created_at;
  ELSE
    -- Calculate based on frequency
    CASE v_pool.contribution_frequency
      WHEN 'weekly' THEN
        v_calculated_due_date := v_last_payment + INTERVAL '1 week';
      WHEN 'biweekly' THEN
        v_calculated_due_date := v_last_payment + INTERVAL '2 weeks';
      WHEN 'monthly' THEN
        v_calculated_due_date := v_last_payment + INTERVAL '1 month';
      ELSE
        v_calculated_due_date := v_last_payment + INTERVAL '1 month';
    END CASE;
  END IF;

  -- Check if current cycle is paid
  SELECT EXISTS(
    SELECT 1 FROM transactions
    WHERE pool_id = p_pool_id
      AND user_id = p_user_id
      AND type = 'contribution'
      AND created_at >= v_calculated_due_date
  ) INTO v_is_paid;

  -- Calculate late fee if overdue and not paid
  IF NOT v_is_paid AND NOW() > (v_calculated_due_date + (v_pool.grace_period_days || ' days')::INTERVAL) THEN
    IF v_pool.late_fee_type = 'fixed' THEN
      v_late_fee_amount := v_pool.late_fee_amount;
    ELSIF v_pool.late_fee_type = 'percentage' THEN
      v_late_fee_amount := (v_contribution_amount * v_pool.late_fee_amount / 100);
    END IF;
  END IF;

  RETURN QUERY SELECT
    v_is_paid,
    v_contribution_amount,
    v_late_fee_amount,
    v_contribution_amount + v_late_fee_amount,
    v_calculated_due_date,
    EXTRACT(DAY FROM (v_calculated_due_date - NOW()))::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- Comment on new columns
COMMENT ON COLUMN pools.late_fee_amount IS 'Late fee amount (fixed amount or percentage based on late_fee_type)';
COMMENT ON COLUMN pools.late_fee_type IS 'Type of late fee: fixed (dollar amount) or percentage';
COMMENT ON COLUMN pools.grace_period_days IS 'Number of days after due date before late fee is charged';
COMMENT ON COLUMN transactions.late_fee IS 'Late fee charged for this transaction';
