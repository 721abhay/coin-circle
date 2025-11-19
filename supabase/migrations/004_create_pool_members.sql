-- Create pool_members table
-- Tracks members of each pool and their participation

CREATE TYPE member_role_enum AS ENUM ('admin', 'member');
CREATE TYPE member_status_enum AS ENUM ('active', 'inactive', 'removed');
CREATE TYPE payment_status_enum AS ENUM ('pending', 'paid', 'overdue');

CREATE TABLE IF NOT EXISTS pool_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  role member_role_enum DEFAULT 'member' NOT NULL,
  join_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status member_status_enum DEFAULT 'active' NOT NULL,
  total_contributed DECIMAL(15, 2) DEFAULT 0.00 CHECK (total_contributed >= 0),
  total_won DECIMAL(15, 2) DEFAULT 0.00 CHECK (total_won >= 0),
  payment_status payment_status_enum DEFAULT 'pending',
  last_payment_date TIMESTAMP WITH TIME ZONE,
  has_won BOOLEAN DEFAULT FALSE,
  win_round INTEGER CHECK (win_round > 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(pool_id, user_id)
);

-- Enable Row Level Security
ALTER TABLE pool_members ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Pool members can view members of their pools"
  ON pool_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM pools 
      WHERE id = pool_members.pool_id 
      AND (privacy = 'public' OR creator_id = auth.uid())
    )
    OR user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM pool_members pm
      WHERE pm.pool_id = pool_members.pool_id AND pm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can join pools"
  ON pool_members FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM pools 
      WHERE id = pool_id 
      AND status = 'pending'
      AND current_members < max_members
    )
  );

CREATE POLICY "Pool admins can update members"
  ON pool_members FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM pool_members pm
      WHERE pm.pool_id = pool_members.pool_id 
      AND pm.user_id = auth.uid()
      AND pm.role = 'admin'
    )
    OR user_id = auth.uid()
  );

CREATE POLICY "Users can leave pools or admins can remove members"
  ON pool_members FOR DELETE
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM pool_members pm
      WHERE pm.pool_id = pool_members.pool_id 
      AND pm.user_id = auth.uid()
      AND pm.role = 'admin'
    )
  );

-- Create function to update pool member count
CREATE OR REPLACE FUNCTION public.update_pool_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE pools 
    SET current_members = current_members + 1
    WHERE id = NEW.pool_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE pools 
    SET current_members = current_members - 1
    WHERE id = OLD.pool_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers for member count
DROP TRIGGER IF EXISTS on_pool_member_added ON pool_members;
CREATE TRIGGER on_pool_member_added
  AFTER INSERT ON pool_members
  FOR EACH ROW EXECUTE FUNCTION public.update_pool_member_count();

DROP TRIGGER IF EXISTS on_pool_member_removed ON pool_members;
CREATE TRIGGER on_pool_member_removed
  AFTER DELETE ON pool_members
  FOR EACH ROW EXECUTE FUNCTION public.update_pool_member_count();

-- Create trigger for updated_at
CREATE TRIGGER set_pool_member_updated_at
  BEFORE UPDATE ON pool_members
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_pool_members_pool ON pool_members(pool_id);
CREATE INDEX IF NOT EXISTS idx_pool_members_user ON pool_members(user_id);
CREATE INDEX IF NOT EXISTS idx_pool_members_status ON pool_members(status);
CREATE INDEX IF NOT EXISTS idx_pool_members_payment_status ON pool_members(payment_status);
