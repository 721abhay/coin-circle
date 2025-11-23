-- Migration: Create Draws Table
-- Description: Creates draws table for pool winner selection and payout tracking

-- Create draws table
CREATE TABLE IF NOT EXISTS draws (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pool_id UUID NOT NULL REFERENCES pools(id) ON DELETE CASCADE,
  round_number INTEGER NOT NULL,
  winner_id UUID REFERENCES profiles(id),
  payout_amount DECIMAL NOT NULL,
  draw_date TIMESTAMPTZ NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
  draw_method TEXT DEFAULT 'random' CHECK (draw_method IN ('random', 'voting')),
  votes_required INTEGER DEFAULT 0,
  votes_received INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  cancellation_reason TEXT,
  CONSTRAINT unique_pool_round UNIQUE (pool_id, round_number)
);

-- Create indexes
CREATE INDEX idx_draws_pool_id ON draws(pool_id);
CREATE INDEX idx_draws_winner_id ON draws(winner_id);
CREATE INDEX idx_draws_status ON draws(status);
CREATE INDEX idx_draws_draw_date ON draws(draw_date);

-- Enable Row Level Security
ALTER TABLE draws ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view draws for pools they're members of
CREATE POLICY "Users can view draws for their pools"
  ON draws FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM pool_members pm
      WHERE pm.pool_id = draws.pool_id
        AND pm.user_id = auth.uid()
    )
  );

-- Only system can insert/update draws
CREATE POLICY "System can manage draws"
  ON draws FOR ALL
  USING (TRUE)
  WITH CHECK (TRUE);

-- Function to create a draw
CREATE OR REPLACE FUNCTION create_draw(
  p_pool_id UUID,
  p_round_number INTEGER,
  p_payout_amount DECIMAL,
  p_draw_date TIMESTAMPTZ,
  p_draw_method TEXT DEFAULT 'random'
) RETURNS UUID AS $$
DECLARE
  v_draw_id UUID;
BEGIN
  INSERT INTO draws (
    pool_id,
    round_number,
    payout_amount,
    draw_date,
    draw_method,
    status
  ) VALUES (
    p_pool_id,
    p_round_number,
    p_payout_amount,
    p_draw_date,
    p_draw_method,
    'pending'
  ) RETURNING id INTO v_draw_id;
  
  RETURN v_draw_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to complete a draw
CREATE OR REPLACE FUNCTION complete_draw(
  p_draw_id UUID,
  p_winner_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
  UPDATE draws
  SET 
    winner_id = p_winner_id,
    status = 'completed',
    completed_at = NOW()
  WHERE id = p_draw_id
    AND status = 'pending';
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get upcoming draws
CREATE OR REPLACE FUNCTION get_upcoming_draws(p_user_id UUID DEFAULT NULL)
RETURNS TABLE (
  draw_id UUID,
  pool_id UUID,
  pool_name TEXT,
  round_number INTEGER,
  payout_amount DECIMAL,
  draw_date TIMESTAMPTZ,
  days_until_draw INTEGER,
  member_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    d.id AS draw_id,
    d.pool_id,
    p.name AS pool_name,
    d.round_number,
    d.payout_amount,
    d.draw_date,
    EXTRACT(DAY FROM (d.draw_date - NOW()))::INTEGER AS days_until_draw,
    (SELECT COUNT(*)::INTEGER FROM pool_members WHERE pool_id = d.pool_id) AS member_count
  FROM draws d
  JOIN pools p ON d.pool_id = p.id
  WHERE d.status = 'pending'
    AND d.draw_date >= NOW()
    AND (
      p_user_id IS NULL 
      OR EXISTS (
        SELECT 1 FROM pool_members pm 
        WHERE pm.pool_id = d.pool_id 
          AND pm.user_id = p_user_id
      )
    )
  ORDER BY d.draw_date ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get draw history for a pool
CREATE OR REPLACE FUNCTION get_pool_draw_history(p_pool_id UUID)
RETURNS TABLE (
  draw_id UUID,
  round_number INTEGER,
  winner_id UUID,
  winner_name TEXT,
  payout_amount DECIMAL,
  draw_date TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    d.id AS draw_id,
    d.round_number,
    d.winner_id,
    pr.full_name AS winner_name,
    d.payout_amount,
    d.draw_date,
    d.completed_at,
    d.status
  FROM draws d
  LEFT JOIN profiles pr ON d.winner_id = pr.id
  WHERE d.pool_id = p_pool_id
  ORDER BY d.round_number DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update pool current_round after draw completion
CREATE OR REPLACE FUNCTION update_pool_round_on_draw() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    UPDATE pools
    SET current_round = current_round + 1
    WHERE id = NEW.pool_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_pool_round ON draws;
CREATE TRIGGER trigger_update_pool_round
  AFTER UPDATE ON draws
  FOR EACH ROW
  EXECUTE FUNCTION update_pool_round_on_draw();

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_draw TO authenticated;
GRANT EXECUTE ON FUNCTION complete_draw TO authenticated;
GRANT EXECUTE ON FUNCTION get_upcoming_draws TO authenticated;
GRANT EXECUTE ON FUNCTION get_pool_draw_history TO authenticated;

-- Comments
COMMENT ON TABLE draws IS 'Stores pool draw information and winner selection';
COMMENT ON FUNCTION create_draw IS 'Creates a new draw for a pool round';
COMMENT ON FUNCTION complete_draw IS 'Marks a draw as completed with a winner';
COMMENT ON FUNCTION get_upcoming_draws IS 'Returns upcoming draws for a user or all draws';
COMMENT ON FUNCTION get_pool_draw_history IS 'Returns draw history for a specific pool';
