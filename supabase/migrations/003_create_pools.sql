-- Create pools table
-- Stores information about savings pools

CREATE TYPE pool_type_enum AS ENUM ('fixed', 'bidding', 'lottery');
CREATE TYPE pool_status_enum AS ENUM ('pending', 'active', 'completed', 'cancelled');
CREATE TYPE pool_privacy_enum AS ENUM ('public', 'private', 'invite-only');
CREATE TYPE frequency_enum AS ENUM ('daily', 'weekly', 'monthly');

CREATE TABLE IF NOT EXISTS pools (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  pool_type pool_type_enum NOT NULL DEFAULT 'fixed',
  contribution_amount DECIMAL(15, 2) NOT NULL CHECK (contribution_amount > 0),
  total_amount DECIMAL(15, 2) NOT NULL CHECK (total_amount > 0),
  max_members INTEGER NOT NULL CHECK (max_members > 0 AND max_members <= 100),
  current_members INTEGER DEFAULT 0 CHECK (current_members >= 0 AND current_members <= max_members),
  frequency frequency_enum NOT NULL DEFAULT 'monthly',
  start_date DATE NOT NULL,
  end_date DATE,
  status pool_status_enum DEFAULT 'pending',
  current_round INTEGER DEFAULT 0 CHECK (current_round >= 0),
  total_rounds INTEGER NOT NULL CHECK (total_rounds > 0),
  auto_debit BOOLEAN DEFAULT FALSE,
  privacy pool_privacy_enum DEFAULT 'public',
  rules JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT valid_dates CHECK (end_date IS NULL OR end_date > start_date),
  CONSTRAINT valid_total_amount CHECK (total_amount = contribution_amount * max_members)
);

-- Enable Row Level Security
ALTER TABLE pools ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can view public pools"
  ON pools FOR SELECT
  USING (
    privacy = 'public' 
    OR creator_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM pool_members 
      WHERE pool_id = pools.id AND user_id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users can create pools"
  ON pools FOR INSERT
  WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Creators can update their pools"
  ON pools FOR UPDATE
  USING (auth.uid() = creator_id);

CREATE POLICY "Creators can delete their pools"
  ON pools FOR DELETE
  USING (auth.uid() = creator_id AND status = 'pending');

-- Create trigger for updated_at
CREATE TRIGGER set_pool_updated_at
  BEFORE UPDATE ON pools
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_pools_creator ON pools(creator_id);
CREATE INDEX IF NOT EXISTS idx_pools_status ON pools(status);
CREATE INDEX IF NOT EXISTS idx_pools_privacy ON pools(privacy);
CREATE INDEX IF NOT EXISTS idx_pools_start_date ON pools(start_date);
CREATE INDEX IF NOT EXISTS idx_pools_type ON pools(pool_type);
