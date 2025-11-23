-- Create pool_messages table for real-time chat functionality
-- Supports user messages and automated system notifications

-- Drop existing objects if they exist (for idempotency)
DROP TABLE IF EXISTS pool_messages CASCADE;
DROP TYPE IF EXISTS message_type_enum CASCADE;

-- Create message type enum
CREATE TYPE message_type_enum AS ENUM (
  'user_message',
  'system_notification',
  'payment_reminder',
  'winner_announcement',
  'member_joined',
  'pool_status_change'
);

-- Create pool_messages table
CREATE TABLE pool_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  message_type message_type_enum DEFAULT 'user_message' NOT NULL,
  content TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  is_pinned BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE pool_messages ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Pool members can view messages in their pools
CREATE POLICY "Pool members can view messages"
  ON pool_messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM pool_members
      WHERE pool_id = pool_messages.pool_id 
      AND user_id = auth.uid()
    )
  );

-- Pool members can send messages
CREATE POLICY "Pool members can send messages"
  ON pool_messages FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM pool_members
      WHERE pool_id = pool_messages.pool_id 
      AND user_id = auth.uid()
      AND status = 'active'
    )
  );

-- Users can update their own messages (for editing)
CREATE POLICY "Users can update their own messages"
  ON pool_messages FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own messages, creators can delete any
CREATE POLICY "Users can delete their own messages"
  ON pool_messages FOR DELETE
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM pools
      WHERE id = pool_messages.pool_id
      AND creator_id = auth.uid()
    )
  );

-- Create trigger for updated_at
CREATE TRIGGER set_pool_message_updated_at
  BEFORE UPDATE ON pool_messages
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_pool_messages_pool ON pool_messages(pool_id);
CREATE INDEX IF NOT EXISTS idx_pool_messages_created_at ON pool_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pool_messages_user ON pool_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_pool_messages_pinned ON pool_messages(pool_id, is_pinned) WHERE is_pinned = TRUE;

-- Function to create system messages
CREATE OR REPLACE FUNCTION public.create_system_message(
  p_pool_id UUID,
  p_message_type message_type_enum,
  p_content TEXT,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
  v_message_id UUID;
BEGIN
  INSERT INTO pool_messages (
    pool_id,
    user_id,
    message_type,
    content,
    metadata
  ) VALUES (
    p_pool_id,
    NULL, -- System messages have no user_id
    p_message_type,
    p_content,
    p_metadata
  )
  RETURNING id INTO v_message_id;
  
  RETURN v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to pin/unpin messages (admin only)
CREATE OR REPLACE FUNCTION public.toggle_message_pin(
  p_message_id UUID,
  p_is_pinned BOOLEAN
)
RETURNS BOOLEAN AS $$
DECLARE
  v_pool_id UUID;
BEGIN
  -- Get pool_id from message
  SELECT pool_id INTO v_pool_id
  FROM pool_messages
  WHERE id = p_message_id;
  
  -- Check if user is pool creator
  IF NOT EXISTS (
    SELECT 1 FROM pools
    WHERE id = v_pool_id
    AND creator_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Only pool creator can pin messages';
  END IF;
  
  -- Update pin status
  UPDATE pool_messages
  SET is_pinned = p_is_pinned,
      updated_at = NOW()
  WHERE id = p_message_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
