-- Create suspend_user_admin function for admin to suspend/unsuspend users
CREATE OR REPLACE FUNCTION suspend_user_admin(
  p_reason TEXT,
  p_user_id UUID
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user RECORD;
  v_is_suspended BOOLEAN;
  v_result jsonb;
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true) THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  -- Get user details
  SELECT * INTO v_user FROM profiles WHERE id = p_user_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  -- Toggle suspension status
  v_is_suspended := NOT COALESCE(v_user.is_suspended, false);

  -- Update user suspension status
  UPDATE profiles 
  SET 
    is_suspended = v_is_suspended,
    updated_at = NOW()
  WHERE id = p_user_id;

  -- Create notification for the user
  INSERT INTO notifications (user_id, title, message, type, created_at)
  VALUES (
    p_user_id,
    CASE WHEN v_is_suspended THEN 'Account Suspended' ELSE 'Account Unsuspended' END,
    CASE 
      WHEN v_is_suspended THEN 'Your account has been suspended. Reason: ' || p_reason
      ELSE 'Your account has been unsuspended. You can now access all features.'
    END,
    'system',
    NOW()
  );

  v_result := jsonb_build_object(
    'success', true,
    'message', CASE WHEN v_is_suspended THEN 'User suspended' ELSE 'User unsuspended' END,
    'user_id', p_user_id,
    'is_suspended', v_is_suspended,
    'reason', p_reason
  );

  RETURN v_result;
END;
$$;

-- Grant execute permission to authenticated users (RLS will check admin status)
GRANT EXECUTE ON FUNCTION suspend_user_admin(TEXT, UUID) TO authenticated;
