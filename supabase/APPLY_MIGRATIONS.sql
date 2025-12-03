-- ========================================
-- COIN CIRCLE - APPLY ALL PENDING MIGRATIONS
-- Run this SQL in your Supabase SQL Editor
-- ========================================

-- Migration 1: Add enable_chat and require_kyc columns
ALTER TABLE pools ADD COLUMN IF NOT EXISTS enable_chat BOOLEAN DEFAULT TRUE;
ALTER TABLE pools ADD COLUMN IF NOT EXISTS require_kyc BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN pools.enable_chat IS 'Whether chat is enabled for this pool';
COMMENT ON COLUMN pools.require_kyc IS 'Whether KYC verification is required to join this pool';

-- Create function to check if user can join pool based on KYC requirement
CREATE OR REPLACE FUNCTION check_kyc_requirement(
  p_pool_id UUID,
  p_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_require_kyc BOOLEAN;
  v_user_kyc_verified BOOLEAN;
BEGIN
  SELECT require_kyc INTO v_require_kyc
  FROM pools
  WHERE id = p_pool_id;
  
  IF v_require_kyc = FALSE THEN
    RETURN TRUE;
  END IF;
  
  SELECT kyc_verified INTO v_user_kyc_verified
  FROM profiles
  WHERE id = p_user_id;
  
  RETURN COALESCE(v_user_kyc_verified, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Migration 2: Update select_random_winner function
CREATE OR REPLACE FUNCTION public.select_random_winner(
  p_pool_id UUID,
  p_round_number INTEGER
)
RETURNS UUID AS $$
DECLARE
  v_winner_id UUID;
  v_winning_amount DECIMAL(15, 2);
  v_pool_rules JSONB;
  v_start_draw_month INTEGER := 1;
  v_current_winners_count INTEGER;
  v_total_members INTEGER;
  v_current_members INTEGER;
  v_total_rounds INTEGER;
  v_winners_so_far INTEGER;
  v_remaining_winners INTEGER;
  v_remaining_months INTEGER;
  v_winners_needed_this_round INTEGER;
  v_contribution_amount DECIMAL(15, 2);
BEGIN
  -- Get pool rules and details
  SELECT rules, max_members, current_members, total_rounds, contribution_amount
  INTO v_pool_rules, v_total_members, v_current_members, v_total_rounds, v_contribution_amount
  FROM pools WHERE id = p_pool_id;
  
  -- Use current_members (actual joined members) instead of max_members
  v_total_members := COALESCE(v_current_members, v_total_members);
  
  -- Parse start_draw_month
  IF v_pool_rules IS NOT NULL AND v_pool_rules->>'start_draw_month' IS NOT NULL THEN
    v_start_draw_month := (v_pool_rules->>'start_draw_month')::INTEGER;
  END IF;

  -- Check if round is eligible for draw
  IF p_round_number < v_start_draw_month THEN
    RAISE EXCEPTION 'Draws have not started yet. Starts at month %', v_start_draw_month;
  END IF;

  -- Dynamic Winner Calculation Logic
  SELECT COUNT(*) INTO v_winners_so_far
  FROM winner_history 
  WHERE pool_id = p_pool_id;

  -- Calculate remaining winners needed
  v_remaining_winners := v_total_members - v_winners_so_far;
  
  IF v_remaining_winners <= 0 THEN
    RAISE EXCEPTION 'All members have already won';
  END IF;

  -- Calculate remaining months (including current one)
  v_remaining_months := v_total_rounds - p_round_number + 1;

  -- Calculate winners needed for THIS round
  IF v_remaining_months <= 0 THEN
      v_winners_needed_this_round := v_remaining_winners;
  ELSE
      v_winners_needed_this_round := CEIL(v_remaining_winners::DECIMAL / v_remaining_months::DECIMAL);
  END IF;

  -- Check if max winners for this round reached
  SELECT COUNT(*) INTO v_current_winners_count
  FROM winner_history 
  WHERE pool_id = p_pool_id AND round_number = p_round_number;

  IF v_current_winners_count >= v_winners_needed_this_round THEN
    RAISE EXCEPTION 'All winners (%/%) already selected for this round', v_current_winners_count, v_winners_needed_this_round;
  END IF;

  -- Calculate winning amount
  v_winning_amount := (v_contribution_amount * v_total_members) / v_winners_needed_this_round;

  -- Select a random member who hasn't won yet AND is active
  SELECT user_id INTO v_winner_id
  FROM pool_members
  WHERE pool_id = p_pool_id
    AND (has_won = FALSE OR has_won IS NULL)
    AND status = 'active'
  ORDER BY random()
  LIMIT 1;

  IF v_winner_id IS NULL THEN
    RAISE EXCEPTION 'No eligible members found to win. Total members: %, Winners so far: %, Remaining: %', 
      v_total_members, v_winners_so_far, v_remaining_winners;
  END IF;

  -- Insert into winner_history
  INSERT INTO winner_history (
    pool_id,
    user_id,
    round_number,
    winning_amount,
    selection_method,
    payout_status
  ) VALUES (
    p_pool_id,
    v_winner_id,
    p_round_number,
    v_winning_amount,
    'random',
    'pending'
  );

  -- Mark user as having won
  UPDATE pool_members SET has_won = TRUE WHERE pool_id = p_pool_id AND user_id = v_winner_id;

  RETURN v_winner_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Migration 3: Add Sequential Rotation winner selection
CREATE OR REPLACE FUNCTION public.select_sequential_winner(
  p_pool_id UUID,
  p_round_number INTEGER
)
RETURNS UUID AS $$
DECLARE
  v_winner_id UUID;
  v_winning_amount DECIMAL(15, 2);
  v_contribution_amount DECIMAL(15, 2);
  v_total_members INTEGER;
BEGIN
  SELECT contribution_amount, current_members
  INTO v_contribution_amount, v_total_members
  FROM pools WHERE id = p_pool_id;
  
  v_winning_amount := v_contribution_amount * v_total_members;
  
  SELECT user_id INTO v_winner_id
  FROM pool_members
  WHERE pool_id = p_pool_id
    AND (has_won = FALSE OR has_won IS NULL)
    AND status = 'active'
  ORDER BY joined_at ASC
  LIMIT 1;

  IF v_winner_id IS NULL THEN
    RAISE EXCEPTION 'No eligible members found for sequential selection';
  END IF;

  INSERT INTO winner_history (
    pool_id,
    user_id,
    round_number,
    winning_amount,
    selection_method,
    payout_status
  ) VALUES (
    p_pool_id,
    v_winner_id,
    p_round_number,
    v_winning_amount,
    'sequential',
    'pending'
  );

  UPDATE pool_members SET has_won = TRUE WHERE pool_id = p_pool_id AND user_id = v_winner_id;

  RETURN v_winner_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Migration 4: Add Member Voting winner selection
CREATE OR REPLACE FUNCTION public.select_voted_winner(
  p_pool_id UUID,
  p_round_number INTEGER
)
RETURNS UUID AS $$
DECLARE
  v_winner_id UUID;
  v_winning_amount DECIMAL(15, 2);
  v_contribution_amount DECIMAL(15, 2);
  v_total_members INTEGER;
  v_vote_count INTEGER;
BEGIN
  SELECT contribution_amount, current_members
  INTO v_contribution_amount, v_total_members
  FROM pools WHERE id = p_pool_id;
  
  v_winning_amount := v_contribution_amount * v_total_members;
  
  SELECT v.candidate_id, COUNT(*) as votes INTO v_winner_id, v_vote_count
  FROM votes v
  INNER JOIN pool_members pm ON v.candidate_id = pm.user_id AND v.pool_id = pm.pool_id
  WHERE v.pool_id = p_pool_id
    AND v.round_number = p_round_number
    AND (pm.has_won = FALSE OR pm.has_won IS NULL)
    AND pm.status = 'active'
  GROUP BY v.candidate_id
  ORDER BY COUNT(*) DESC, v.created_at ASC
  LIMIT 1;

  IF v_winner_id IS NULL THEN
    RAISE EXCEPTION 'No votes found for this round. Members must vote first.';
  END IF;

  INSERT INTO winner_history (
    pool_id,
    user_id,
    round_number,
    winning_amount,
    selection_method,
    payout_status,
    vote_count
  ) VALUES (
    p_pool_id,
    v_winner_id,
    p_round_number,
    v_winning_amount,
    'voting',
    'pending',
    v_vote_count
  );

  UPDATE pool_members SET has_won = TRUE WHERE pool_id = p_pool_id AND user_id = v_winner_id;

  RETURN v_winner_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- VERIFICATION QUERIES
-- Run these to verify the migrations worked
-- ========================================

-- Check if columns were added
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'pools' 
AND column_name IN ('enable_chat', 'require_kyc');

-- Check if functions exist
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('check_kyc_requirement', 'select_random_winner', 'select_sequential_winner', 'select_voted_winner');
