-- Create winner_history table
-- Tracks winners for each pool round

CREATE TYPE selection_method_enum AS ENUM ('random', 'bid', 'lottery');
CREATE TYPE payout_status_enum AS ENUM ('pending', 'completed', 'failed');

CREATE TABLE IF NOT EXISTS winner_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  round_number INTEGER NOT NULL CHECK (round_number > 0),
  winning_amount DECIMAL(15, 2) NOT NULL CHECK (winning_amount > 0),
  selection_method selection_method_enum NOT NULL,
  bid_amount DECIMAL(15, 2) CHECK (bid_amount >= 0),
  selected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  payout_status payout_status_enum DEFAULT 'pending',
  payout_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(pool_id, round_number),
  CONSTRAINT valid_bid_amount CHECK (
    (selection_method = 'bid' AND bid_amount IS NOT NULL) OR
    (selection_method != 'bid' AND bid_amount IS NULL)
  )
);

-- Enable Row Level Security
ALTER TABLE winner_history ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Pool members can view winner history"
  ON winner_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM pool_members
      WHERE pool_id = winner_history.pool_id 
      AND user_id = auth.uid()
    )
    OR user_id = auth.uid()
  );

-- Only system can insert/update winner history (via Edge Functions)
CREATE POLICY "System can insert winner history"
  ON winner_history FOR INSERT
  WITH CHECK (false); -- Will be handled by Edge Functions

CREATE POLICY "System can update winner history"
  ON winner_history FOR UPDATE
  USING (false); -- Will be handled by Edge Functions

-- Create function to update pool member on winner selection
CREATE OR REPLACE FUNCTION public.handle_winner_selection()
RETURNS TRIGGER AS $$
BEGIN
  -- Update pool member
  UPDATE pool_members
  SET has_won = TRUE,
      win_round = NEW.round_number
  WHERE pool_id = NEW.pool_id AND user_id = NEW.user_id;
  
  -- Update pool current round
  UPDATE pools
  SET current_round = NEW.round_number
  WHERE id = NEW.pool_id;
  
  -- Create winning transaction
  INSERT INTO transactions (
    user_id,
    pool_id,
    transaction_type,
    amount,
    status,
    description
  ) VALUES (
    NEW.user_id,
    NEW.pool_id,
    'winning',
    NEW.winning_amount,
    'pending',
    'Pool round ' || NEW.round_number || ' winning'
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for winner selection
DROP TRIGGER IF EXISTS on_winner_selected ON winner_history;
CREATE TRIGGER on_winner_selected
  AFTER INSERT ON winner_history
  FOR EACH ROW EXECUTE FUNCTION public.handle_winner_selection();

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_winner_history_pool ON winner_history(pool_id);
CREATE INDEX IF NOT EXISTS idx_winner_history_user ON winner_history(user_id);
CREATE INDEX IF NOT EXISTS idx_winner_history_round ON winner_history(pool_id, round_number);
CREATE INDEX IF NOT EXISTS idx_winner_history_payout_status ON winner_history(payout_status);
