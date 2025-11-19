-- Create bids table
-- For bidding-type pools

CREATE TYPE bid_status_enum AS ENUM ('active', 'won', 'lost', 'cancelled');

CREATE TABLE IF NOT EXISTS bids (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  round_number INTEGER NOT NULL CHECK (round_number > 0),
  bid_amount DECIMAL(15, 2) NOT NULL CHECK (bid_amount > 0),
  status bid_status_enum DEFAULT 'active' NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(pool_id, user_id, round_number),
  CONSTRAINT valid_bid_for_pool_type CHECK (
    EXISTS (
      SELECT 1 FROM pools 
      WHERE id = pool_id AND pool_type = 'bidding'
    )
  )
);

-- Enable Row Level Security
ALTER TABLE bids ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Pool members can view bids in their pools"
  ON bids FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM pool_members
      WHERE pool_id = bids.pool_id 
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Pool members can create bids"
  ON bids FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM pool_members
      WHERE pool_id = bids.pool_id 
      AND user_id = auth.uid()
      AND status = 'active'
      AND has_won = FALSE
    )
  );

CREATE POLICY "Users can update their own bids"
  ON bids FOR UPDATE
  USING (
    auth.uid() = user_id 
    AND status = 'active'
  );

CREATE POLICY "Users can cancel their own bids"
  ON bids FOR DELETE
  USING (
    auth.uid() = user_id 
    AND status = 'active'
  );

-- Create trigger for updated_at
CREATE TRIGGER set_bid_updated_at
  BEFORE UPDATE ON bids
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_bids_pool ON bids(pool_id);
CREATE INDEX IF NOT EXISTS idx_bids_user ON bids(user_id);
CREATE INDEX IF NOT EXISTS idx_bids_round ON bids(pool_id, round_number);
CREATE INDEX IF NOT EXISTS idx_bids_status ON bids(status);
CREATE INDEX IF NOT EXISTS idx_bids_amount ON bids(pool_id, round_number, bid_amount DESC);

-- Create function to get highest bid for a round
CREATE OR REPLACE FUNCTION public.get_highest_bid(
  p_pool_id UUID,
  p_round_number INTEGER
)
RETURNS TABLE (
  bid_id UUID,
  user_id UUID,
  bid_amount DECIMAL(15, 2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    id,
    bids.user_id,
    bids.bid_amount
  FROM bids
  WHERE pool_id = p_pool_id
    AND round_number = p_round_number
    AND status = 'active'
  ORDER BY bid_amount DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to mark losing bids
CREATE OR REPLACE FUNCTION public.mark_losing_bids(
  p_pool_id UUID,
  p_round_number INTEGER,
  p_winning_bid_id UUID
)
RETURNS void AS $$
BEGIN
  UPDATE bids
  SET status = 'lost'
  WHERE pool_id = p_pool_id
    AND round_number = p_round_number
    AND id != p_winning_bid_id
    AND status = 'active';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
