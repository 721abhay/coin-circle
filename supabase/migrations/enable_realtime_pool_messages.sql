-- Enable Realtime for pool_messages table to ensure chat updates appear immediately
-- This is required for the stream() method to receive updates

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND tablename = 'pool_messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE pool_messages;
  END IF;
END
$$;
