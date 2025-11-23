-- Fix infinite recursion by using SECURITY DEFINER functions

-- 1. Create a function to check pool membership without triggering RLS
CREATE OR REPLACE FUNCTION public.is_pool_member(_pool_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM pool_members
    WHERE pool_id = _pool_id
    AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Update pools policy to use the function
DROP POLICY IF EXISTS "Anyone can view public pools" ON pools;
CREATE POLICY "Anyone can view public pools"
  ON pools FOR SELECT
  USING (
    privacy = 'public' 
    OR creator_id = auth.uid()
    OR is_pool_member(id)
  );

-- 3. Create a function to check pool privacy/creator without triggering RLS
CREATE OR REPLACE FUNCTION public.can_view_pool_members(_pool_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM pools 
    WHERE id = _pool_id 
    AND (privacy = 'public' OR creator_id = auth.uid())
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Update pool_members policy
DROP POLICY IF EXISTS "Pool members can view members of their pools" ON pool_members;
CREATE POLICY "Pool members can view members of their pools"
  ON pool_members FOR SELECT
  USING (
    can_view_pool_members(pool_id)
    OR user_id = auth.uid()
    OR is_pool_member(pool_id)
  );
