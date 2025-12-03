-- Update select_random_winner to use dynamic winner calculation
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
  -- 1. Count total winners selected so far (all previous rounds)
  SELECT COUNT(*) INTO v_winners_so_far
  FROM winner_history 
  WHERE pool_id = p_pool_id;

  -- 2. Calculate remaining winners needed
  v_remaining_winners := v_total_members - v_winners_so_far;
  
  -- If no one left to win, raise error
  IF v_remaining_winners <= 0 THEN
    RAISE EXCEPTION 'All members have already won';
  END IF;

  -- 3. Calculate remaining months (including current one)
  v_remaining_months := v_total_rounds - p_round_number + 1;

  -- 4. Calculate winners needed for THIS round
  -- Formula: Ceil(RemainingWinners / RemainingMonths)
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

  -- Calculate winning amount (total contribution for the round / winners per draw)
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
