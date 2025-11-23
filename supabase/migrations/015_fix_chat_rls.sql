-- Fix RLS policies for pool_messages
-- This migration updates the INSERT policy to allow both user messages and system messages

-- Drop existing INSERT policy
DROP POLICY IF EXISTS "Pool members can send messages" ON pool_messages;

-- Create new INSERT policy that handles both user and system messages
CREATE POLICY "Pool members can send messages"
  ON pool_messages FOR INSERT
  WITH CHECK (
    -- Allow user messages from active pool members
    (
      user_id IS NOT NULL
      AND auth.uid() = user_id
      AND EXISTS (
        SELECT 1 FROM pool_members
        WHERE pool_id = pool_messages.pool_id 
        AND user_id = auth.uid()
        AND status = 'active'
      )
    )
    -- OR allow system messages (user_id IS NULL) - these are created via SECURITY DEFINER function
    OR (user_id IS NULL)
  );
