-- ============================================================================
-- PUSH NOTIFICATIONS DATABASE SETUP
-- ============================================================================
-- This script adds necessary columns and tables for push notifications
-- Run this in Supabase SQL Editor
-- ============================================================================

-- 1. Add FCM token column to profiles table
-- ============================================================================
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token ON profiles(fcm_token) WHERE fcm_token IS NOT NULL;

-- 2. Create notification_preferences table (if not exists)
-- ============================================================================
CREATE TABLE IF NOT EXISTS notification_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  
  -- Notification type preferences
  payment_reminders BOOLEAN DEFAULT true,
  draw_announcements BOOLEAN DEFAULT true,
  pool_updates BOOLEAN DEFAULT true,
  member_activities BOOLEAN DEFAULT true,
  system_messages BOOLEAN DEFAULT true,
  
  -- Quiet hours (optional)
  quiet_hours_enabled BOOLEAN DEFAULT false,
  quiet_hours_start TIME,
  quiet_hours_end TIME,
  
  -- Push notification settings
  push_enabled BOOLEAN DEFAULT true,
  email_enabled BOOLEAN DEFAULT true,
  sms_enabled BOOLEAN DEFAULT false,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies for notification_preferences
CREATE POLICY "Users can view own notification preferences"
  ON notification_preferences FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notification preferences"
  ON notification_preferences FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notification preferences"
  ON notification_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 3. Ensure notifications table exists with correct structure
-- ============================================================================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  
  type TEXT NOT NULL, -- 'payment', 'pool_update', 'winner', 'system', etc.
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  
  metadata JSONB, -- Additional data (pool_id, transaction_id, etc.)
  
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies for notifications
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_created 
  ON notifications(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread 
  ON notifications(user_id, is_read) WHERE is_read = false;

CREATE INDEX IF NOT EXISTS idx_notifications_type 
  ON notifications(type);

-- 4. Create function to auto-update updated_at timestamp
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for notification_preferences
DROP TRIGGER IF EXISTS update_notification_preferences_updated_at ON notification_preferences;
CREATE TRIGGER update_notification_preferences_updated_at
  BEFORE UPDATE ON notification_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 5. Create function to check if user wants notification type
-- ============================================================================
CREATE OR REPLACE FUNCTION should_send_notification(
  p_user_id UUID,
  p_notification_type TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_prefs RECORD;
  v_enabled BOOLEAN;
BEGIN
  -- Get user preferences
  SELECT * INTO v_prefs
  FROM notification_preferences
  WHERE user_id = p_user_id;
  
  -- If no preferences, default to true
  IF v_prefs IS NULL THEN
    RETURN true;
  END IF;
  
  -- Check if push notifications are enabled
  IF v_prefs.push_enabled = false THEN
    RETURN false;
  END IF;
  
  -- Check specific notification type
  v_enabled := CASE p_notification_type
    WHEN 'payment' THEN v_prefs.payment_reminders
    WHEN 'draw' THEN v_prefs.draw_announcements
    WHEN 'pool_update' THEN v_prefs.pool_updates
    WHEN 'member_activity' THEN v_prefs.member_activities
    WHEN 'system' THEN v_prefs.system_messages
    ELSE true -- Default to enabled for unknown types
  END;
  
  -- Check quiet hours if enabled
  IF v_prefs.quiet_hours_enabled AND v_enabled THEN
    IF CURRENT_TIME BETWEEN v_prefs.quiet_hours_start AND v_prefs.quiet_hours_end THEN
      -- During quiet hours, only send critical notifications
      IF p_notification_type IN ('system', 'security') THEN
        RETURN true;
      ELSE
        RETURN false;
      END IF;
    END IF;
  END IF;
  
  RETURN v_enabled;
END;
$$ LANGUAGE plpgsql;

-- 6. Create function to send push notification (placeholder)
-- ============================================================================
-- This function would be called by a trigger or manually
-- In production, this would call a Supabase Edge Function
CREATE OR REPLACE FUNCTION send_push_notification(
  p_user_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID AS $$
DECLARE
  v_fcm_token TEXT;
  v_notification_type TEXT;
BEGIN
  -- Extract notification type from data
  v_notification_type := p_data->>'type';
  
  -- Check if user wants this notification
  IF NOT should_send_notification(p_user_id, v_notification_type) THEN
    RAISE NOTICE 'User has disabled % notifications', v_notification_type;
    RETURN;
  END IF;
  
  -- Get user's FCM token
  SELECT fcm_token INTO v_fcm_token
  FROM profiles
  WHERE id = p_user_id;
  
  IF v_fcm_token IS NULL THEN
    RAISE NOTICE 'User % has no FCM token', p_user_id;
    RETURN;
  END IF;
  
  -- TODO: Call Supabase Edge Function to send actual push notification
  -- For now, just log it
  RAISE NOTICE 'Would send push notification to %: % - %', v_fcm_token, p_title, p_body;
  
  -- In production, you would do something like:
  -- PERFORM net.http_post(
  --   url := 'https://your-project.supabase.co/functions/v1/send-push',
  --   headers := '{"Content-Type": "application/json"}'::jsonb,
  --   body := jsonb_build_object(
  --     'token', v_fcm_token,
  --     'title', p_title,
  --     'body', p_body,
  --     'data', p_data
  --   )
  -- );
END;
$$ LANGUAGE plpgsql;

-- 7. Create trigger to send push notification when notification is created
-- ============================================================================
-- Uncomment this when you have the Edge Function set up
/*
CREATE OR REPLACE FUNCTION trigger_push_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- Send push notification
  PERFORM send_push_notification(
    NEW.user_id,
    NEW.title,
    NEW.message,
    jsonb_build_object('type', NEW.type) || COALESCE(NEW.metadata, '{}'::jsonb)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_notification_created ON notifications;
CREATE TRIGGER on_notification_created
  AFTER INSERT ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION trigger_push_notification();
*/

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if fcm_token column exists
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name = 'fcm_token';

-- Check notification_preferences table
SELECT COUNT(*) as preference_count FROM notification_preferences;

-- Check notifications table
SELECT COUNT(*) as notification_count FROM notifications;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Push Notifications database setup complete!';
  RAISE NOTICE '📝 Next steps:';
  RAISE NOTICE '   1. Configure Firebase in your Flutter app';
  RAISE NOTICE '   2. Run the app to generate FCM tokens';
  RAISE NOTICE '   3. Set up Supabase Edge Function for sending notifications';
  RAISE NOTICE '   4. Uncomment the trigger at the end of this file';
END $$;
