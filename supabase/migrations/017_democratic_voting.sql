-- Democratic Voting System Migration
-- Adds voting functionality for winner approval

-- 1. Update winner_history to track voting status
ALTER TYPE payout_status_enum ADD VALUE IF NOT EXISTS 'voting_pending';
ALTER TYPE payout_status_enum ADD VALUE IF NOT EXISTS 'voting_rejected';

-- 2. Create pool_votes table
CREATE TABLE IF NOT EXISTS pool_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE NOT NULL,
  round_number INTEGER NOT NULL,
  voter_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  vote BOOLEAN NOT NULL, -- TRUE = Approve, FALSE = Reject
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(pool_id, round_number, voter_id)
);

-- 3. Enable RLS
ALTER TABLE pool_votes ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
-- Members can view votes for their pool
DROP POLICY IF EXISTS "Members can view votes" ON pool_votes;
CREATE POLICY "Members can view votes" ON pool_votes
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM pool_members
      WHERE pool_id = pool_votes.pool_id 
      AND user_id = auth.uid()
    )
  );

-- Members can cast their own vote
DROP POLICY IF EXISTS "Members can cast vote" ON pool_votes;
CREATE POLICY "Members can cast vote" ON pool_votes
  FOR INSERT
  WITH CHECK (
    auth.uid() = voter_id AND
    EXISTS (
      SELECT 1 FROM pool_members
      WHERE pool_id = pool_votes.pool_id 
      AND user_id = auth.uid()
    )
  );

-- 5. Function to cast a vote
CREATE OR REPLACE FUNCTION public.cast_vote(
  p_pool_id UUID,
  p_round INTEGER,
  p_vote BOOLEAN
)
RETURNS BOOLEAN AS $$
DECLARE
  v_total_members INTEGER;
  v_total_votes INTEGER;
  v_reject_votes INTEGER;
  v_winner_id UUID;
BEGIN
  -- Check if voting is active for this round
  SELECT user_id INTO v_winner_id
  FROM winner_history
  WHERE pool_id = p_pool_id 
  AND round_number = p_round 
  AND payout_status = 'voting_pending';

  IF v_winner_id IS NULL THEN
    RAISE EXCEPTION 'Voting is not active for this round';
  END IF;

  -- Insert the vote
  INSERT INTO pool_votes (pool_id, round_number, voter_id, vote)
  VALUES (p_pool_id, p_round, auth.uid(), p_vote);

  -- Check voting results
  SELECT COUNT(*) INTO v_total_members FROM pool_members WHERE pool_id = p_pool_id;
  SELECT COUNT(*) INTO v_total_votes FROM pool_votes WHERE pool_id = p_pool_id AND round_number = p_round;
  SELECT COUNT(*) INTO v_reject_votes FROM pool_votes WHERE pool_id = p_pool_id AND round_number = p_round AND vote = FALSE;

  -- If any rejection, fail immediately
  IF v_reject_votes > 0 THEN
    UPDATE winner_history
    SET payout_status = 'voting_rejected'
    WHERE pool_id = p_pool_id AND round_number = p_round;
    
    -- Notify members of rejection
    INSERT INTO notifications (user_id, notification_type, title, message, related_pool_id)
    SELECT 
      user_id,
      'pool_update',
      'Winner Rejected',
      'The winner selection for round ' || p_round || ' was rejected by a member.',
      p_pool_id
    FROM pool_members
    WHERE pool_id = p_pool_id;
    
    RETURN FALSE;
  END IF;

  -- If all members voted and all approved
  IF v_total_votes = v_total_members THEN
    -- Update status to pending (ready for payout) or completed if we want to automate payout here
    -- For now, let's set to 'pending' which implies approved but not yet paid out
    -- Or we can introduce a new status 'approved' if needed, but 'pending' was the original "ready to pay" state
    -- Let's stick to 'pending' as the "Approved, waiting for transfer" state.
    -- Wait, the original flow was: Selected -> Pending -> Completed.
    -- New flow: Selected -> Voting Pending -> (All Approved) -> Pending -> Completed.
    
    UPDATE winner_history
    SET payout_status = 'pending'
    WHERE pool_id = p_pool_id AND round_number = p_round;

    -- Notify members of approval
    INSERT INTO notifications (user_id, notification_type, title, message, related_pool_id)
    SELECT 
      user_id,
      'pool_update',
      'Winner Approved',
      'The winner for round ' || p_round || ' has been unanimously approved!',
      p_pool_id
    FROM pool_members
    WHERE pool_id = p_pool_id;
    
    RETURN TRUE;
  END IF;

  RETURN NULL; -- Voting continues
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Function to get voting status
CREATE OR REPLACE FUNCTION public.get_voting_status(
  p_pool_id UUID,
  p_round INTEGER
)
RETURNS JSON AS $$
DECLARE
  v_total_members INTEGER;
  v_total_votes INTEGER;
  v_my_vote BOOLEAN;
BEGIN
  SELECT COUNT(*) INTO v_total_members FROM pool_members WHERE pool_id = p_pool_id;
  SELECT COUNT(*) INTO v_total_votes FROM pool_votes WHERE pool_id = p_pool_id AND round_number = p_round;
  
  SELECT vote INTO v_my_vote 
  FROM pool_votes 
  WHERE pool_id = p_pool_id 
  AND round_number = p_round 
  AND voter_id = auth.uid();

  RETURN json_build_object(
    'total_members', v_total_members,
    'total_votes', v_total_votes,
    'has_voted', (v_my_vote IS NOT NULL),
    'my_vote', v_my_vote
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
