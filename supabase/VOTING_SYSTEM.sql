-- ============================================
-- VOTING SYSTEM FOR WINNER SELECTION
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Create votes table
CREATE TABLE IF NOT EXISTS votes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE,
  round_number INT NOT NULL,
  voter_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  candidate_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(pool_id, round_number, voter_id),
  CHECK (voter_id != candidate_id) -- Can't vote for yourself
);

-- 2. Create voting_periods table to track when voting is open
CREATE TABLE IF NOT EXISTS voting_periods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE,
  round_number INT NOT NULL,
  status VARCHAR(20) DEFAULT 'open', -- 'open', 'closed', 'completed'
  started_at TIMESTAMPTZ DEFAULT NOW(),
  ends_at TIMESTAMPTZ,
  closed_at TIMESTAMPTZ,
  created_by UUID REFERENCES auth.users(id),
  UNIQUE(pool_id, round_number)
);

-- 3. Enable RLS
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE voting_periods ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies for votes
DROP POLICY IF EXISTS "Users can view votes for their pools" ON votes;
CREATE POLICY "Users can view votes for their pools" ON votes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM pool_members 
      WHERE pool_members.pool_id = votes.pool_id 
      AND pool_members.user_id = auth.uid()
      AND pool_members.status = 'active'
    )
  );

DROP POLICY IF EXISTS "Users can cast their own vote" ON votes;
CREATE POLICY "Users can cast their own vote" ON votes
  FOR INSERT WITH CHECK (
    auth.uid() = voter_id
    AND EXISTS (
      SELECT 1 FROM pool_members 
      WHERE pool_members.pool_id = votes.pool_id 
      AND pool_members.user_id = auth.uid()
      AND pool_members.status = 'active'
    )
  );

DROP POLICY IF EXISTS "Users can update their own vote" ON votes;
CREATE POLICY "Users can update their own vote" ON votes
  FOR UPDATE USING (auth.uid() = voter_id);

-- 5. RLS Policies for voting_periods
DROP POLICY IF EXISTS "Anyone can view voting periods" ON voting_periods;
CREATE POLICY "Anyone can view voting periods" ON voting_periods
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM pool_members 
      WHERE pool_members.pool_id = voting_periods.pool_id 
      AND pool_members.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Admins can manage voting periods" ON voting_periods;
CREATE POLICY "Admins can manage voting periods" ON voting_periods
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM pool_members 
      WHERE pool_members.pool_id = voting_periods.pool_id 
      AND pool_members.user_id = auth.uid()
      AND pool_members.role = 'admin'
    )
  );

-- 6. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_votes_pool_round ON votes(pool_id, round_number);
CREATE INDEX IF NOT EXISTS idx_votes_voter ON votes(voter_id);
CREATE INDEX IF NOT EXISTS idx_votes_candidate ON votes(candidate_id);
CREATE INDEX IF NOT EXISTS idx_voting_periods_pool_round ON voting_periods(pool_id, round_number);
CREATE INDEX IF NOT EXISTS idx_voting_periods_status ON voting_periods(status);

-- 7. Function to start voting period
CREATE OR REPLACE FUNCTION start_voting_period(
  p_pool_id UUID,
  p_round_number INT,
  p_duration_hours INT DEFAULT 48
)
RETURNS UUID AS $$
DECLARE
  v_period_id UUID;
BEGIN
  -- Check if voting period already exists
  IF EXISTS (
    SELECT 1 FROM voting_periods 
    WHERE pool_id = p_pool_id 
    AND round_number = p_round_number
  ) THEN
    RAISE EXCEPTION 'Voting period already exists for this round';
  END IF;

  -- Create voting period
  INSERT INTO voting_periods (
    pool_id,
    round_number,
    status,
    ends_at,
    created_by
  ) VALUES (
    p_pool_id,
    p_round_number,
    'open',
    NOW() + (p_duration_hours || ' hours')::INTERVAL,
    auth.uid()
  ) RETURNING id INTO v_period_id;

  RETURN v_period_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Function to close voting period
CREATE OR REPLACE FUNCTION close_voting_period(
  p_pool_id UUID,
  p_round_number INT
)
RETURNS VOID AS $$
BEGIN
  UPDATE voting_periods
  SET status = 'closed',
      closed_at = NOW()
  WHERE pool_id = p_pool_id
  AND round_number = p_round_number
  AND status = 'open';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Function to cast/update vote
CREATE OR REPLACE FUNCTION cast_vote(
  p_pool_id UUID,
  p_round_number INT,
  p_candidate_id UUID
)
RETURNS VOID AS $$
DECLARE
  v_voter_id UUID;
BEGIN
  v_voter_id := auth.uid();

  -- Check if voting period is open
  IF NOT EXISTS (
    SELECT 1 FROM voting_periods
    WHERE pool_id = p_pool_id
    AND round_number = p_round_number
    AND status = 'open'
    AND (ends_at IS NULL OR ends_at > NOW())
  ) THEN
    RAISE EXCEPTION 'Voting period is not open';
  END IF;

  -- Check if candidate is eligible
  IF NOT EXISTS (
    SELECT 1 FROM pool_members
    WHERE pool_id = p_pool_id
    AND user_id = p_candidate_id
    AND status = 'active'
    AND has_won = false
  ) THEN
    RAISE EXCEPTION 'Candidate is not eligible';
  END IF;

  -- Insert or update vote
  INSERT INTO votes (pool_id, round_number, voter_id, candidate_id)
  VALUES (p_pool_id, p_round_number, v_voter_id, p_candidate_id)
  ON CONFLICT (pool_id, round_number, voter_id)
  DO UPDATE SET 
    candidate_id = p_candidate_id,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Function to get vote counts
CREATE OR REPLACE FUNCTION get_vote_counts(
  p_pool_id UUID,
  p_round_number INT
)
RETURNS TABLE (
  candidate_id UUID,
  candidate_name TEXT,
  vote_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    v.candidate_id,
    p.full_name as candidate_name,
    COUNT(*) as vote_count
  FROM votes v
  JOIN profiles p ON p.id = v.candidate_id
  WHERE v.pool_id = p_pool_id
  AND v.round_number = p_round_number
  GROUP BY v.candidate_id, p.full_name
  ORDER BY vote_count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Success message
SELECT 'Voting system created successfully!' as status;
