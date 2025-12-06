-- Create force_close_pool_admin function for admin to force close pools
CREATE OR REPLACE FUNCTION force_close_pool_admin(
  p_pool_id UUID,
  p_reason TEXT
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_pool RECORD;
  v_result jsonb;
BEGIN
  -- Check if user is admin
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true) THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  -- Get pool details
  SELECT * INTO v_pool FROM pools WHERE id = p_pool_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pool not found';
  END IF;

  -- Update pool status to completed
  UPDATE pools 
  SET 
    status = 'completed',
    updated_at = NOW()
  WHERE id = p_pool_id;

  -- Log the admin action (optional - create admin_actions table if needed)
  -- INSERT INTO admin_actions (admin_id, action_type, target_id, reason)
  -- VALUES (auth.uid(), 'force_close_pool', p_pool_id, p_reason);

  v_result := jsonb_build_object(
    'success', true,
    'message', 'Pool force closed successfully',
    'pool_id', p_pool_id,
    'reason', p_reason
  );

  RETURN v_result;
END;
$$;

-- Grant execute permission to authenticated users (RLS will check admin status)
GRANT EXECUTE ON FUNCTION force_close_pool_admin(UUID, TEXT) TO authenticated;
