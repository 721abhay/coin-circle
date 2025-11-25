-- Add 'pending' status to member_status_enum
-- This allows members to be in pending state before approval

-- First, add the new enum value
ALTER TYPE member_status_enum ADD VALUE IF NOT EXISTS 'pending';

-- Function to find a pool by invite code, bypassing RLS
CREATE OR REPLACE FUNCTION public.get_pool_by_invite_code(p_invite_code TEXT)
RETURNS SETOF pools
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM pools
  WHERE invite_code = p_invite_code
  LIMIT 1;
END;
$$;

-- Function to join a pool securely, bypassing RLS for checks
-- Also sends notifications to creator and user
CREATE OR REPLACE FUNCTION public.join_pool_secure(p_pool_id UUID, p_invite_code TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_pool pools%ROWTYPE;
  v_user_id UUID;
  v_user_name TEXT;
BEGIN
  v_user_id := auth.uid();
  
  -- Get pool details (bypassing RLS)
  SELECT * INTO v_pool
  FROM pools
  WHERE id = p_pool_id;
  
  IF v_pool IS NULL THEN
    RAISE EXCEPTION 'Pool not found';
  END IF;
  
  -- Verify invite code
  IF v_pool.invite_code != p_invite_code THEN
    RAISE EXCEPTION 'Invalid invite code';
  END IF;
  
  -- Check capacity
  IF v_pool.current_members >= v_pool.max_members THEN
    RAISE EXCEPTION 'Pool is full';
  END IF;
  
  -- Check if already member
  IF EXISTS (SELECT 1 FROM pool_members WHERE pool_id = p_pool_id AND user_id = v_user_id) THEN
    RAISE EXCEPTION 'Already a member or request pending';
  END IF;
  
  -- Insert member with pending status
  INSERT INTO pool_members (pool_id, user_id, role, status, join_date)
  VALUES (p_pool_id, v_user_id, 'member', 'pending', NOW());
  
  -- Get user name for notification
  SELECT full_name INTO v_user_name FROM profiles WHERE id = v_user_id;
  IF v_user_name IS NULL THEN v_user_name := 'A user'; END IF;

  -- Notify Creator
  INSERT INTO notifications (user_id, title, message, type, category, metadata)
  VALUES (
    v_pool.creator_id, 
    'New Join Request', 
    v_user_name || ' has requested to join ' || v_pool.name, 
    'pool_update', 
    'info',
    jsonb_build_object('pool_id', p_pool_id, 'user_id', v_user_id)
  );

  -- Notify User
  INSERT INTO notifications (user_id, title, message, type, category, metadata)
  VALUES (
    v_user_id, 
    'Join Request Sent', 
    'You have requested to join ' || v_pool.name, 
    'pool_joined', 
    'success',
    jsonb_build_object('pool_id', p_pool_id)
  );
  
END;
$$;
