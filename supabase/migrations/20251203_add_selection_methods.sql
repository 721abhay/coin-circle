-- Add Sequential Rotation winner selection
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
  -- Get pool details
  SELECT contribution_amount, current_members
  INTO v_contribution_amount, v_total_members
  FROM pools WHERE id = p_pool_id;
  
  -- Calculate winning amount
  v_winning_amount := v_contribution_amount * v_total_members;
  
  -- Select next member in sequence (by join order) who hasn't won
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
    'sequential',
    'pending'
  );

  -- Mark user as having won
  UPDATE pool_members SET has_won = TRUE WHERE pool_id = p_pool_id AND user_id = v_winner_id;

  RETURN v_winner_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add Member Voting winner selection
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
  -- Get pool details
  SELECT contribution_amount, current_members
  INTO v_contribution_amount, v_total_members
  FROM pools WHERE id = p_pool_id;
  
  -- Calculate winning amount
  v_winning_amount := v_contribution_amount * v_total_members;
  
  -- Select member with most votes who hasn't won yet
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

  -- Insert into winner_history
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

  -- Mark user as having won
  UPDATE pool_members SET has_won = TRUE WHERE pool_id = p_pool_id AND user_id = v_winner_id;

  RETURN v_winner_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
