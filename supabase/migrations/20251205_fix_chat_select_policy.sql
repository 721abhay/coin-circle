-- Fix RLS policy for pool_messages to ensure creators and members can view messages

DROP POLICY IF EXISTS "Pool members can view messages" ON pool_messages;

CREATE POLICY "Pool members and creators can view messages"
  ON pool_messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM pool_members
      WHERE pool_id = pool_messages.pool_id 
      AND user_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM pools
      WHERE id = pool_messages.pool_id
      AND creator_id = auth.uid()
    )
  );
