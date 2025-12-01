-- Create a secure RPC for requesting to join a pool
CREATE OR REPLACE FUNCTION request_join_pool(
  p_pool_id UUID,
  p_invite_code TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_pool_code TEXT;
  v_user_id UUID;
  v_exists BOOLEAN;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not logged in';
  END IF;

  -- Check if pool exists and get code
  SELECT invite_code INTO v_pool_code
  FROM pools
  WHERE id = p_pool_id;

  IF v_pool_code IS NULL THEN
    RAISE EXCEPTION 'Pool not found';
  END IF;

  -- Verify invite code
  IF v_pool_code != p_invite_code THEN
    RAISE EXCEPTION 'Invalid invite code';
  END IF;

  -- Check if already a member
  SELECT EXISTS (
    SELECT 1 FROM pool_members
    WHERE pool_id = p_pool_id AND user_id = v_user_id
  ) INTO v_exists;

  IF v_exists THEN
    RAISE EXCEPTION 'You have already requested to join or are a member of this pool';
  END IF;

  -- Insert pending request
  INSERT INTO pool_members (pool_id, user_id, role, status, join_date)
  VALUES (p_pool_id, v_user_id, 'member', 'pending', NOW());

END;
$$;
