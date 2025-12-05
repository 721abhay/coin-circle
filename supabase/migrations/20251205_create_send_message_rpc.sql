CREATE OR REPLACE FUNCTION send_pool_message(
  p_pool_id UUID,
  p_content TEXT,
  p_message_type message_type_enum DEFAULT 'user_message',
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_is_allowed BOOLEAN;
BEGIN
  v_user_id := auth.uid();
  
  -- Check if user is creator
  IF EXISTS (SELECT 1 FROM pools WHERE id = p_pool_id AND creator_id = v_user_id) THEN
    v_is_allowed := TRUE;
  ELSE
    -- Check if user is active or approved member
    IF EXISTS (
      SELECT 1 FROM pool_members 
      WHERE pool_id = p_pool_id 
      AND user_id = v_user_id 
      AND (status::text = 'active' OR status::text = 'approved')
    ) THEN
      v_is_allowed := TRUE;
    ELSE
      v_is_allowed := FALSE;
    END IF;
  END IF;

  IF NOT v_is_allowed THEN
    RAISE EXCEPTION 'Permission denied. You must be a member to chat.';
  END IF;

  INSERT INTO pool_messages (pool_id, user_id, content, message_type, metadata)
  VALUES (p_pool_id, v_user_id, p_content, p_message_type, p_metadata);
END;
$$;
