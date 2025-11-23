-- Migration: Create Notifications System
-- Description: Creates notifications table with RLS and triggers for real-time notifications

-- Drop existing table if it exists (to ensure clean state)
DROP TABLE IF EXISTS notifications CASCADE;

-- Create notifications table
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('payment_reminder', 'draw_announcement', 'pool_update', 'member_activity', 'system_message', 'winner_announcement', 'contribution_received', 'pool_joined', 'pool_created')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb,
  read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT valid_read_at CHECK (read_at IS NULL OR read = TRUE)
);

-- Create indexes for better performance
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(user_id, read);
CREATE INDEX idx_notifications_type ON notifications(user_id, type);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- Enable Row Level Security
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can only see their own notifications
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  USING (auth.uid() = user_id);

-- Only system/admin can insert notifications
CREATE POLICY "System can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (TRUE); -- Will be restricted by service role key

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- Function to create notification
CREATE OR REPLACE FUNCTION create_notification(
  p_user_id UUID,
  p_type TEXT,
  p_title TEXT,
  p_message TEXT,
  p_data JSONB DEFAULT '{}'::jsonb
) RETURNS UUID AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  INSERT INTO notifications (user_id, type, title, message, data)
  VALUES (p_user_id, p_type, p_title, p_message, p_data)
  RETURNING id INTO v_notification_id;
  
  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to notify all pool members
CREATE OR REPLACE FUNCTION notify_pool_members(
  p_pool_id UUID,
  p_type TEXT,
  p_title TEXT,
  p_message TEXT,
  p_data JSONB DEFAULT '{}'::jsonb
) RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER := 0;
BEGIN
  INSERT INTO notifications (user_id, type, title, message, data)
  SELECT 
    user_id,
    p_type,
    p_title,
    p_message,
    p_data
  FROM pool_members
  WHERE pool_id = p_pool_id;
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Notify when someone joins a pool
CREATE OR REPLACE FUNCTION notify_on_pool_join() RETURNS TRIGGER AS $$
DECLARE
  v_pool_name TEXT;
  v_member_name TEXT;
BEGIN
  -- Get pool name
  SELECT name INTO v_pool_name FROM pools WHERE id = NEW.pool_id;
  
  -- Get member name
  SELECT full_name INTO v_member_name FROM profiles WHERE id = NEW.user_id;
  
  -- Notify all existing members (except the new member)
  INSERT INTO notifications (user_id, type, title, message, data)
  SELECT 
    pm.user_id,
    'member_activity',
    'New Member Joined',
    v_member_name || ' joined ' || v_pool_name,
    jsonb_build_object(
      'pool_id', NEW.pool_id,
      'pool_name', v_pool_name,
      'member_id', NEW.user_id,
      'member_name', v_member_name
    )
  FROM pool_members pm
  WHERE pm.pool_id = NEW.pool_id 
    AND pm.user_id != NEW.user_id;
  
  -- Notify the new member
  INSERT INTO notifications (user_id, type, title, message, data)
  VALUES (
    NEW.user_id,
    'pool_joined',
    'Welcome to ' || v_pool_name,
    'You have successfully joined the pool',
    jsonb_build_object('pool_id', NEW.pool_id, 'pool_name', v_pool_name)
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_notify_pool_join ON pool_members;
CREATE TRIGGER trigger_notify_pool_join
  AFTER INSERT ON pool_members
  FOR EACH ROW
  EXECUTE FUNCTION notify_on_pool_join();

-- Trigger: Notify when a contribution is made
CREATE OR REPLACE FUNCTION notify_on_contribution() RETURNS TRIGGER AS $$
DECLARE
  v_pool_name TEXT;
  v_contributor_name TEXT;
BEGIN
  IF NEW.transaction_type = 'contribution' THEN
    -- Get pool name
    SELECT name INTO v_pool_name FROM pools WHERE id = NEW.pool_id;
    
    -- Get contributor name
    SELECT full_name INTO v_contributor_name FROM profiles WHERE id = NEW.user_id;
    
    -- Notify all pool members except contributor
    INSERT INTO notifications (user_id, type, title, message, data)
    SELECT 
      pm.user_id,
      'contribution_received',
      'Contribution Received',
      v_contributor_name || ' contributed ₹' || NEW.amount || ' to ' || v_pool_name,
      jsonb_build_object(
        'pool_id', NEW.pool_id,
        'pool_name', v_pool_name,
        'amount', NEW.amount,
        'contributor_id', NEW.user_id,
        'contributor_name', v_contributor_name
      )
    FROM pool_members pm
    WHERE pm.pool_id = NEW.pool_id 
      AND pm.user_id != NEW.user_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_notify_contribution ON transactions;
CREATE TRIGGER trigger_notify_contribution
  AFTER INSERT ON transactions
  FOR EACH ROW
  EXECUTE FUNCTION notify_on_contribution();

-- Trigger: Notify when a draw is completed
-- NOTE: This trigger is commented out because the 'draws' table doesn't exist yet
-- Uncomment this section after creating the draws table

/*
CREATE OR REPLACE FUNCTION notify_on_draw_complete() RETURNS TRIGGER AS $$
DECLARE
  v_pool_name TEXT;
  v_winner_name TEXT;
BEGIN
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    -- Get pool name
    SELECT name INTO v_pool_name FROM pools WHERE id = NEW.pool_id;
    
    -- Get winner name
    SELECT full_name INTO v_winner_name FROM profiles WHERE id = NEW.winner_id;
    
    -- Notify all pool members
    INSERT INTO notifications (user_id, type, title, message, data)
    SELECT 
      pm.user_id,
      'winner_announcement',
      'Draw Results - ' || v_pool_name,
      CASE 
        WHEN pm.user_id = NEW.winner_id THEN 'Congratulations! You won the draw!'
        ELSE v_winner_name || ' won the draw'
      END,
      jsonb_build_object(
        'pool_id', NEW.pool_id,
        'pool_name', v_pool_name,
        'draw_id', NEW.id,
        'winner_id', NEW.winner_id,
        'winner_name', v_winner_name,
        'amount', NEW.payout_amount
      )
    FROM pool_members pm
    WHERE pm.pool_id = NEW.pool_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_notify_draw_complete ON draws;
CREATE TRIGGER trigger_notify_draw_complete
  AFTER UPDATE ON draws
  FOR EACH ROW
  EXECUTE FUNCTION notify_on_draw_complete();
*/

-- Trigger: Notify on payment reminders (scheduled)
CREATE OR REPLACE FUNCTION send_payment_reminders() RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER := 0;
BEGIN
  -- Find pools with upcoming payment deadlines (3 days before)
  -- Note: Simplified version - checks if user has contributed this month
  INSERT INTO notifications (user_id, type, title, message, data)
  SELECT 
    pm.user_id,
    'payment_reminder',
    'Payment Reminder',
    'Your contribution for ' || p.name || ' is due in 3 days',
    jsonb_build_object(
      'pool_id', p.id,
      'pool_name', p.name,
      'amount', p.contribution_amount,
      'due_date', p.next_draw_date
    )
  FROM pool_members pm
  JOIN pools p ON pm.pool_id = p.id
  WHERE p.status = 'active'
    AND p.next_draw_date = CURRENT_DATE + INTERVAL '3 days'
    AND NOT EXISTS (
      SELECT 1 FROM transactions t
      WHERE t.pool_id = p.id
        AND t.user_id = pm.user_id
        AND t.transaction_type = 'contribution'
        AND t.created_at >= DATE_TRUNC('month', CURRENT_DATE)
    );
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_notification TO authenticated;
GRANT EXECUTE ON FUNCTION notify_pool_members TO authenticated;
GRANT EXECUTE ON FUNCTION send_payment_reminders TO service_role;

-- Comments
COMMENT ON TABLE notifications IS 'Stores user notifications with real-time updates';
COMMENT ON FUNCTION create_notification IS 'Creates a notification for a specific user';
COMMENT ON FUNCTION notify_pool_members IS 'Sends notification to all members of a pool';
COMMENT ON FUNCTION send_payment_reminders IS 'Scheduled function to send payment reminders';
