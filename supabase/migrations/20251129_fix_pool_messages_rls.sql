-- Fix RLS policy for pool_messages to allow creators to send messages

DROP POLICY IF EXISTS "Pool members can send messages" ON pool_messages;

CREATE POLICY "Pool members and creators can send messages"
  ON pool_messages FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND (
      EXISTS (
        SELECT 1 FROM pool_members
        WHERE pool_id = pool_messages.pool_id 
        AND user_id = auth.uid()
        AND status = 'active'
      )
      OR
      EXISTS (
        SELECT 1 FROM pools
        WHERE id = pool_messages.pool_id
        AND creator_id = auth.uid()
      )
    )
  );
