-- LEGAL COMPLIANCE FOR INDIA: TDS, PAN, ITR
-- Following Income Tax Act 1961 and RBI guidelines

-- ============================================
-- 1. TDS (TAX DEDUCTED AT SOURCE) TABLE
-- ============================================

-- TDS is MANDATORY for winnings > ₹10,000 in India
CREATE TABLE IF NOT EXISTS tds_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  pool_id UUID REFERENCES pools(id) NOT NULL,
  winner_history_id UUID REFERENCES winner_history(id) NOT NULL,
  
  -- Winning details
  gross_amount BIGINT NOT NULL, -- Total winning in paise
  tds_rate DECIMAL(5,2) DEFAULT 30.00, -- 30% TDS rate
  tds_amount BIGINT NOT NULL, -- TDS deducted in paise
  net_amount BIGINT NOT NULL, -- Amount after TDS in paise
  
  -- PAN details (MANDATORY for TDS)
  pan_number TEXT NOT NULL,
  pan_verified BOOLEAN DEFAULT false,
  
  -- TDS certificate
  tds_certificate_number TEXT, -- Form 16A number
  tds_certificate_url TEXT, -- PDF download link
  tds_filed_date DATE, -- When TDS was filed with govt
  
  -- Financial year
  financial_year TEXT NOT NULL, -- '2024-25'
  quarter TEXT NOT NULL, -- 'Q1', 'Q2', 'Q3', 'Q4'
  
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN (
    'pending', 'deducted', 'filed', 'certificate_issued'
  )),
  
  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tds_records_user_id ON tds_records(user_id);
CREATE INDEX IF NOT EXISTS idx_tds_records_pool_id ON tds_records(pool_id);
CREATE INDEX IF NOT EXISTS idx_tds_records_financial_year ON tds_records(financial_year);

-- ============================================
-- 2. PAN CARD VERIFICATION
-- ============================================

-- PAN is MANDATORY for winnings > ₹10,000
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS pan_number TEXT UNIQUE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS pan_verified BOOLEAN DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS pan_name TEXT; -- Name as per PAN
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS pan_dob DATE; -- DOB as per PAN

-- ============================================
-- 3. WINNER VERIFICATION & PAYOUT
-- ============================================

-- Function: Verify winner and calculate TDS
CREATE OR REPLACE FUNCTION verify_winner_and_calculate_tds(
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
  v_gross_amount BIGINT;
  v_tds_amount BIGINT;
  v_net_amount BIGINT;
  v_member_count INTEGER;
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

  -- Calculate gross amount (contribution_amount * member_count)
  v_gross_amount := v_pool.contribution_amount * v_member_count;

  -- Check if TDS is applicable (> ₹10,000)
  IF v_gross_amount > 1000000 THEN -- ₹10,000 in paise
    -- Check if PAN is available
    IF v_winner.pan_number IS NULL OR v_winner.pan_number = '' THEN
      RAISE EXCEPTION 'PAN card is mandatory for winnings above ₹10,000. Please update PAN in profile.';
    END IF;

    IF v_winner.pan_verified = false THEN
      RAISE EXCEPTION 'PAN card not verified. Please verify PAN before processing payout.';
    END IF;

    -- Calculate TDS (30% for winnings)
    v_tds_amount := (v_gross_amount * 30) / 100;
    v_net_amount := v_gross_amount - v_tds_amount;

    -- Create TDS record
    INSERT INTO tds_records (
      user_id, pool_id, winner_history_id,
      gross_amount, tds_rate, tds_amount, net_amount,
      pan_number, pan_verified,
      financial_year, quarter, status
    ) VALUES (
      p_winner_id, p_pool_id, v_winner_history.id,
      v_gross_amount, 30.00, v_tds_amount, v_net_amount,
      v_winner.pan_number, v_winner.pan_verified,
      get_financial_year(NOW()), get_quarter(NOW()), 'deducted'
    );

  ELSE
    -- No TDS for winnings <= ₹10,000
    v_tds_amount := 0;
    v_net_amount := v_gross_amount;
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
    'gross_amount', v_gross_amount,
    'tds_applicable', v_gross_amount > 1000000,
    'tds_amount', v_tds_amount,
    'net_amount', v_net_amount,
    'tds_rate', CASE WHEN v_gross_amount > 1000000 THEN 30.00 ELSE 0.00 END,
    'message', CASE 
      WHEN v_gross_amount > 1000000 THEN 
        'TDS of 30% (₹' || (v_tds_amount::DECIMAL / 100) || ') will be deducted. Net payout: ₹' || (v_net_amount::DECIMAL / 100)
      ELSE 
        'No TDS applicable. Full amount: ₹' || (v_gross_amount::DECIMAL / 100)
    END
  );

  RETURN v_result;
END;
$$;

-- ============================================
-- 4. HELPER FUNCTIONS
-- ============================================

-- Get financial year (Apr-Mar in India)
CREATE OR REPLACE FUNCTION get_financial_year(p_date DATE)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  v_year INTEGER;
  v_month INTEGER;
BEGIN
  v_year := EXTRACT(YEAR FROM p_date);
  v_month := EXTRACT(MONTH FROM p_date);
  
  -- Financial year starts in April
  IF v_month >= 4 THEN
    RETURN v_year || '-' || (v_year + 1);
  ELSE
    RETURN (v_year - 1) || '-' || v_year;
  END IF;
END;
$$;

-- Get quarter (Q1: Apr-Jun, Q2: Jul-Sep, Q3: Oct-Dec, Q4: Jan-Mar)
CREATE OR REPLACE FUNCTION get_quarter(p_date DATE)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  v_month INTEGER;
BEGIN
  v_month := EXTRACT(MONTH FROM p_date);
  
  IF v_month >= 4 AND v_month <= 6 THEN
    RETURN 'Q1';
  ELSIF v_month >= 7 AND v_month <= 9 THEN
    RETURN 'Q2';
  ELSIF v_month >= 10 AND v_month <= 12 THEN
    RETURN 'Q3';
  ELSE
    RETURN 'Q4';
  END IF;
END;
$$;

-- ============================================
-- 5. PAYOUT FUNCTION WITH TDS
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
  v_result jsonb;
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true) THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  -- Step 1: Verify winner and calculate TDS
  v_verification := verify_winner_and_calculate_tds(p_pool_id, p_winner_id, p_round_number);
  
  v_net_amount := (v_verification->>'net_amount')::BIGINT;
  v_tds_amount := (v_verification->>'tds_amount')::BIGINT;

  -- Step 2: Credit net amount to winner's wallet
  PERFORM add_money_to_wallet(
    p_winner_id,
    v_net_amount,
    'pool_winning',
    'pool_' || p_pool_id,
    jsonb_build_object(
      'pool_id', p_pool_id,
      'round_number', p_round_number,
      'gross_amount', v_verification->>'gross_amount',
      'tds_amount', v_tds_amount,
      'net_amount', v_net_amount
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
    'Winning Amount Credited',
    'Congratulations! ₹' || (v_net_amount::DECIMAL / 100) || ' has been credited to your wallet.' ||
    CASE WHEN v_tds_amount > 0 THEN 
      ' (TDS of ₹' || (v_tds_amount::DECIMAL / 100) || ' deducted as per Income Tax Act)'
    ELSE '' END,
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
-- 6. UPDATE WINNER_HISTORY TABLE
-- ============================================

ALTER TABLE winner_history ADD COLUMN IF NOT EXISTS tds_amount BIGINT DEFAULT 0;
ALTER TABLE winner_history ADD COLUMN IF NOT EXISTS payout_date TIMESTAMPTZ;

-- ============================================
-- 7. GRANT PERMISSIONS
-- ============================================

GRANT EXECUTE ON FUNCTION verify_winner_and_calculate_tds(UUID, UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION process_winner_payout(UUID, UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_financial_year(DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_quarter(DATE) TO authenticated;

-- ============================================
-- 8. COMMENTS
-- ============================================

COMMENT ON TABLE tds_records IS 'TDS records for winnings > ₹10,000 as per Income Tax Act 1961';
COMMENT ON COLUMN tds_records.tds_rate IS 'TDS rate for winnings is 30% (Section 194B)';
COMMENT ON COLUMN tds_records.pan_number IS 'PAN is mandatory for TDS deduction';
COMMENT ON FUNCTION verify_winner_and_calculate_tds IS 'Verifies winner, checks PAN, calculates TDS (30% for winnings > ₹10,000)';
COMMENT ON FUNCTION process_winner_payout IS 'Processes winner payout with TDS deduction and wallet credit';
