-- Function to select a random winner for a pool round
CREATE OR REPLACE FUNCTION public.select_random_winner(
  p_pool_id UUID,
  p_round_number INTEGER
)
RETURNS UUID AS $$
DECLARE
  v_winner_id UUID;
  v_winning_amount DECIMAL(15, 2);
BEGIN
  -- Check if winner already exists for this round
  IF EXISTS (
    SELECT 1 FROM winner_history 
    WHERE pool_id = p_pool_id AND round_number = p_round_number
  ) THEN
    RAISE EXCEPTION 'Winner already selected for this round';
  END IF;

  -- Calculate winning amount (total contribution for the round)
  -- For fixed pools: contribution_amount * number of members
  -- For now, we'll calculate based on actual contributions or pool settings
  SELECT (contribution_amount * (SELECT COUNT(*) FROM pool_members WHERE pool_id = p_pool_id))
  INTO v_winning_amount
  FROM pools
  WHERE id = p_pool_id;

  -- Select a random member who hasn't won yet
  SELECT user_id INTO v_winner_id
  FROM pool_members
  WHERE pool_id = p_pool_id
    AND has_won = FALSE
    AND status = 'active'
  ORDER BY random()
  LIMIT 1;

  IF v_winner_id IS NULL THEN
    RAISE EXCEPTION 'No eligible members found to win';
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

  RETURN v_winner_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to select a winner based on bids
CREATE OR REPLACE FUNCTION public.select_bid_winner(
  p_pool_id UUID,
  p_round_number INTEGER
)
RETURNS UUID AS $$
DECLARE
  v_winner_id UUID;
  v_bid_amount DECIMAL(15, 2);
  v_winning_amount DECIMAL(15, 2);
  v_bid_id UUID;
BEGIN
  -- Check if winner already exists
  IF EXISTS (
    SELECT 1 FROM winner_history 
    WHERE pool_id = p_pool_id AND round_number = p_round_number
  ) THEN
    RAISE EXCEPTION 'Winner already selected for this round';
  END IF;

  -- Get the highest bid
  SELECT user_id, bid_amount, id INTO v_winner_id, v_bid_amount, v_bid_id
  FROM bids
  WHERE pool_id = p_pool_id
    AND round_number = p_round_number
    AND status = 'active'
  ORDER BY bid_amount DESC
  LIMIT 1;

  IF v_winner_id IS NULL THEN
    RAISE EXCEPTION 'No active bids found for this round';
  END IF;

  -- Calculate winning amount (Total pool value - Bid amount)
  -- Usually in ROSCA, the bid amount is distributed as interest or deducted from the pot
  -- For simplicity here: Winning Amount = (Monthly Contribution * Members) - Bid Amount
  SELECT ((contribution_amount * (SELECT COUNT(*) FROM pool_members WHERE pool_id = p_pool_id)) - v_bid_amount)
  INTO v_winning_amount
  FROM pools
  WHERE id = p_pool_id;

  -- Insert into winner_history
  INSERT INTO winner_history (
    pool_id,
    user_id,
    round_number,
    winning_amount,
    selection_method,
    bid_amount,
    payout_status
  ) VALUES (
    p_pool_id,
    v_winner_id,
    p_round_number,
    v_winning_amount,
    'bid',
    v_bid_amount,
    'pending'
  );

  -- Mark losing bids
  PERFORM public.mark_losing_bids(p_pool_id, p_round_number, v_bid_id);

  -- Update winning bid status
  UPDATE bids SET status = 'won' WHERE id = v_bid_id;

  RETURN v_winner_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
