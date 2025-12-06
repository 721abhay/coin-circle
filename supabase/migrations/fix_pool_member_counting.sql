-- Fix pool member counting to only count active members
-- This prevents pending requests from blocking the pool

-- 1. Drop existing triggers and function with CASCADE
DROP TRIGGER IF EXISTS update_pool_member_count ON pool_members CASCADE;
DROP TRIGGER IF EXISTS on_pool_member_added ON pool_members CASCADE;
DROP TRIGGER IF EXISTS on_pool_member_removed ON pool_members CASCADE;
DROP FUNCTION IF EXISTS update_pool_member_count() CASCADE;

-- 2. Create function to update pool member count (ONLY active members)
CREATE OR REPLACE FUNCTION update_pool_member_count()
RETURNS TRIGGER AS $$
BEGIN
  -- When a member is added or status changes
  IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    -- Update current_members to count only ACTIVE members
    UPDATE pools
    SET current_members = (
      SELECT COUNT(*)
      FROM pool_members
      WHERE pool_id = NEW.pool_id
      AND status = 'active'
    )
    WHERE id = NEW.pool_id;
    
    RETURN NEW;
  END IF;

  -- When a member is deleted
  IF (TG_OP = 'DELETE') THEN
    -- Update current_members to count only ACTIVE members
    UPDATE pools
    SET current_members = (
      SELECT COUNT(*)
      FROM pool_members
      WHERE pool_id = OLD.pool_id
      AND status = 'active'
    )
    WHERE id = OLD.pool_id;
    
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 3. Create trigger
CREATE TRIGGER update_pool_member_count
AFTER INSERT OR UPDATE OR DELETE ON pool_members
FOR EACH ROW
EXECUTE FUNCTION update_pool_member_count();

-- 4. Fix existing pools - recalculate current_members for all pools
UPDATE pools
SET current_members = (
  SELECT COUNT(*)
  FROM pool_members
  WHERE pool_members.pool_id = pools.id
  AND pool_members.status = 'active'
);

-- 5. Add index for better performance
CREATE INDEX IF NOT EXISTS idx_pool_members_status_pool ON pool_members(pool_id, status);
