-- FIX TDS COMPLIANCE FOR SAVINGS POOL (NOT GAMBLING/LOTTERY)
-- This is a CHIT FUND / SAVINGS POOL system where users save their own money
-- TDS is NOT applicable on principal amount (users' own savings)
-- TDS only applies on INTEREST income (if any) at 10% under Section 194A

-- ============================================
-- 1. DROP INCORRECT TDS SYSTEM
-- ============================================

-- Drop the incorrect functions first
DROP FUNCTION IF EXISTS process_winner_payout(UUID, UUID, INTEGER);
DROP FUNCTION IF EXISTS verify_winner_and_calculate_tds(UUID, UUID, INTEGER);

-- ============================================
-- 2. UPDATED TDS RECORDS TABLE
-- ============================================

-- Recreate TDS table for interest income only
DROP TABLE IF EXISTS tds_records CASCADE;

CREATE TABLE tds_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  pool_id UUID REFERENCES pools(id) NOT NULL,
  winner_history_id UUID REFERENCES winner_history(id) NOT NULL,
  
  -- Amount breakdown
  principal_amount BIGINT NOT NULL, -- User's own pooled savings (NO TDS)
  interest_amount BIGINT DEFAULT 0, -- Interest earned (TDS applicable if > ₹10,000)
  gross_amount BIGINT NOT NULL, -- Total = principal + interest
  
  -- TDS only on interest (if applicable)
  tds_rate DECIMAL(5,2) DEFAULT 10.00, -- 10% TDS on interest (Section 194A)
  tds_amount BIGINT DEFAULT 0, -- TDS on interest only
  net_amount BIGINT NOT NULL, -- Amount after TDS
  
  -- PAN details (MANDATORY only if TDS is applicable)
  pan_number TEXT,
  pan_verified BOOLEAN DEFAULT false,
  
  -- TDS certificate (only if TDS was deducted)
  tds_certificate_number TEXT,
  tds_certificate_url TEXT,
  tds_filed_date DATE,
  
  -- Financial year
  financial_year TEXT NOT NULL,
  quarter TEXT NOT NULL,
  
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN (
    'no_tds_required', 'pending', 'deducted', 'filed', 'certificate_issued'
  )),
  
  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tds_records_user_id ON tds_records(user_id);
CREATE INDEX idx_tds_records_pool_id ON tds_records(pool_id);
CREATE INDEX idx_tds_records_financial_year ON tds_records(financial_year);

-- ============================================
-- 3. CORRECTED WINNER VERIFICATION FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION verify_winner_and_calculate_payout(
  p_pool_id UUID,
  p_winner_id UUID,
  p_round_number INTEGER
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_pool RECORD;
  v_winner RECORD;
  v_winner_history RECORD;
  v_member_count INTEGER;
  v_principal_amount BIGINT;
  v_interest_amount BIGINT := 0; -- No interest in basic pools
  v_gross_amount BIGINT;
  v_tds_amount BIGINT := 0;
  v_net_amount BIGINT;
  v_tds_applicable BOOLEAN := false;
  v_result jsonb;
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true) THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  -- Get pool details
  SELECT * INTO v_pool FROM pools WHERE id = p_pool_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pool not found';
  END IF;

  -- Get winner details
  SELECT * INTO v_winner FROM profiles WHERE id = p_winner_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Winner not found';
  END IF;

  -- Verify winner is actually in the pool
  IF NOT EXISTS (
    SELECT 1 FROM pool_members 
    WHERE pool_id = p_pool_id 
    AND user_id = p_winner_id 
    AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'User is not an active member of this pool';
  END IF;

  -- Get winner history record
  SELECT * INTO v_winner_history 
  FROM winner_history 
  WHERE pool_id = p_pool_id 
  AND user_id = p_winner_id 
  AND round_number = p_round_number;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Winner history record not found';
  END IF;

  -- Get member count
  SELECT COUNT(*) INTO v_member_count
  FROM pool_members
  WHERE pool_id = p_pool_id AND status = 'active';

  -- Calculate principal amount (users' own pooled savings)
  -- This is just their collective contributions - NO TDS on this
  v_principal_amount := v_pool.contribution_amount * v_member_count;
  
  -- Interest calculation (if pool has interest feature - currently 0)
  -- In future, if you add interest: v_interest_amount := calculate_interest(...)
  v_interest_amount := 0;
  
  -- Total amount
  v_gross_amount := v_principal_amount + v_interest_amount;

  -- TDS is ONLY applicable on INTEREST if it exceeds ₹10,000
  -- NOT on principal (users' own savings)
  IF v_interest_amount > 1000000 THEN -- ₹10,000 in paise
    v_tds_applicable := true;
    
    -- Check if PAN is available
    IF v_winner.pan_number IS NULL OR v_winner.pan_number = '' THEN
      RAISE EXCEPTION 'PAN card is mandatory for interest income above ₹10,000. Please update PAN in profile.';
    END IF;

    IF v_winner.pan_verified = false THEN
      RAISE EXCEPTION 'PAN card not verified. Please verify PAN before processing payout.';
    END IF;

    -- Calculate TDS on INTEREST ONLY (10% under Section 194A)
    v_tds_amount := (v_interest_amount * 10) / 100;
    v_net_amount := v_gross_amount - v_tds_amount;

    -- Create TDS record
    INSERT INTO tds_records (
      user_id, pool_id, winner_history_id,
      principal_amount, interest_amount, gross_amount,
      tds_rate, tds_amount, net_amount,
      pan_number, pan_verified,
      financial_year, quarter, status
    ) VALUES (
      p_winner_id, p_pool_id, v_winner_history.id,
      v_principal_amount, v_interest_amount, v_gross_amount,
      10.00, v_tds_amount, v_net_amount,
      v_winner.pan_number, v_winner.pan_verified,
      get_financial_year(NOW()), get_quarter(NOW()), 'deducted'
    );

  ELSE
    -- NO TDS - User gets full amount (their own savings)
    v_tds_amount := 0;
    v_net_amount := v_gross_amount;
    
    -- Create record showing no TDS required
    INSERT INTO tds_records (
      user_id, pool_id, winner_history_id,
      principal_amount, interest_amount, gross_amount,
      tds_rate, tds_amount, net_amount,
      financial_year, quarter, status
    ) VALUES (
      p_winner_id, p_pool_id, v_winner_history.id,
      v_principal_amount, v_interest_amount, v_gross_amount,
      0.00, 0, v_gross_amount,
      get_financial_year(NOW()), get_quarter(NOW()), 'no_tds_required'
    );
  END IF;

  -- Update winner_history with payout details
  UPDATE winner_history
  SET 
    payout_amount = v_net_amount,
    tds_amount = v_tds_amount,
    payout_status = 'approved',
    updated_at = NOW()
  WHERE id = v_winner_history.id;

  -- Build result
  v_result := jsonb_build_object(
    'success', true,
    'winner_id', p_winner_id,
    'winner_name', v_winner.full_name,
    'pan_number', v_winner.pan_number,
    'member_count', v_member_count,
    'principal_amount', v_principal_amount,
    'interest_amount', v_interest_amount,
    'gross_amount', v_gross_amount,
    'tds_applicable', v_tds_applicable,
    'tds_amount', v_tds_amount,
    'net_amount', v_net_amount,
    'tds_rate', CASE WHEN v_tds_applicable THEN 10.00 ELSE 0.00 END,
    'message', CASE 
      WHEN v_tds_applicable THEN 
        'TDS of 10% on interest (₹' || (v_tds_amount::DECIMAL / 100) || ') will be deducted. Net payout: ₹' || (v_net_amount::DECIMAL / 100)
      ELSE 
        'No TDS applicable. This is your own pooled savings. Full amount: ₹' || (v_gross_amount::DECIMAL / 100)
    END,
    'note', 'This is a savings pool. You are receiving your own pooled money, not lottery/gambling winnings.'
  );

  RETURN v_result;
END;
$$;

-- ============================================
-- 4. CORRECTED PAYOUT FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION process_winner_payout(
  p_pool_id UUID,
  p_winner_id UUID,
  p_round_number INTEGER
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_verification jsonb;
  v_net_amount BIGINT;
  v_tds_amount BIGINT;
  v_tds_applicable BOOLEAN;
  v_result jsonb;
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true) THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  -- Step 1: Verify winner and calculate payout
  v_verification := verify_winner_and_calculate_payout(p_pool_id, p_winner_id, p_round_number);
  
  v_net_amount := (v_verification->>'net_amount')::BIGINT;
  v_tds_amount := (v_verification->>'tds_amount')::BIGINT;
  v_tds_applicable := (v_verification->>'tds_applicable')::BOOLEAN;

  -- Step 2: Credit net amount to winner's wallet
  PERFORM add_money_to_wallet(
    p_winner_id,
    v_net_amount,
    'pool_winning',
    'pool_' || p_pool_id,
    jsonb_build_object(
      'pool_id', p_pool_id,
      'round_number', p_round_number,
      'principal_amount', v_verification->>'principal_amount',
      'interest_amount', v_verification->>'interest_amount',
      'gross_amount', v_verification->>'gross_amount',
      'tds_amount', v_tds_amount,
      'net_amount', v_net_amount,
      'note', 'Savings pool payout - your own pooled money'
    )
  );

  -- Step 3: Update winner_history
  UPDATE winner_history
  SET 
    payout_status = 'paid',
    payout_date = NOW(),
    updated_at = NOW()
  WHERE pool_id = p_pool_id 
  AND user_id = p_winner_id 
  AND round_number = p_round_number;

  -- Step 4: Send notification to winner
  INSERT INTO notifications (user_id, title, message, type, created_at)
  VALUES (
    p_winner_id,
    'Pool Payout Credited',
    'Congratulations! ₹' || (v_net_amount::DECIMAL / 100) || ' has been credited to your wallet.' ||
    CASE WHEN v_tds_applicable THEN 
      ' (TDS of ₹' || (v_tds_amount::DECIMAL / 100) || ' deducted on interest income as per Income Tax Act)'
    ELSE 
      ' This is your own pooled savings - no TDS deducted.'
    END,
    'system',
    NOW()
  );

  v_result := jsonb_build_object(
    'success', true,
    'message', 'Payout processed successfully',
    'verification', v_verification
  );

  RETURN v_result;
END;
$$;

-- ============================================
-- 5. GRANT PERMISSIONS
-- ============================================

GRANT EXECUTE ON FUNCTION verify_winner_and_calculate_payout(UUID, UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION process_winner_payout(UUID, UUID, INTEGER) TO authenticated;

-- ============================================
-- 6. COMMENTS
-- ============================================

COMMENT ON TABLE tds_records IS 'TDS records for INTEREST income only (if > ₹10,000). Principal amount (users own savings) is NOT subject to TDS.';
COMMENT ON COLUMN tds_records.principal_amount IS 'Users own pooled savings - NO TDS on this amount';
COMMENT ON COLUMN tds_records.interest_amount IS 'Interest earned - TDS applicable if > ₹10,000 at 10% (Section 194A)';
COMMENT ON COLUMN tds_records.tds_rate IS 'TDS rate 10% on interest (Section 194A), NOT 30% (this is savings, not gambling)';
COMMENT ON FUNCTION verify_winner_and_calculate_payout IS 'Verifies winner and calculates payout. TDS only on interest if > ₹10,000, NOT on principal (users own savings)';
COMMENT ON FUNCTION process_winner_payout IS 'Processes winner payout. Users receive their own pooled savings without TDS (unless interest exceeds ₹10,000)';
