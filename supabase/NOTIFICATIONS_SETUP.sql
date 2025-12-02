-- ============================================================================
-- NOTIFICATIONS SETUP
-- ============================================================================

-- 1. Create notifications table
-- ============================================================================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  type VARCHAR(50) NOT NULL, -- 'payment', 'draw', 'system', 'pool', 'member'
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create notification_preferences table
-- ============================================================================
CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  payment_reminders BOOLEAN DEFAULT true,
  draw_announcements BOOLEAN DEFAULT true,
  pool_updates BOOLEAN DEFAULT true,
  member_activities BOOLEAN DEFAULT true,
  system_messages BOOLEAN DEFAULT true,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Enable Row Level Security
-- ============================================================================
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS policies for notifications
-- ============================================================================
-- Users can view their own notifications
CREATE POLICY "Users can view their own notifications" 
ON notifications FOR SELECT 
USING (auth.uid() = user_id);

-- Users can update their own notifications (e.g., mark as read)
CREATE POLICY "Users can update their own notifications" 
ON notifications FOR UPDATE 
USING (auth.uid() = user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete their own notifications" 
ON notifications FOR DELETE 
USING (auth.uid() = user_id);

-- Allow any authenticated user to insert notifications (so they can notify others)
CREATE POLICY "Any authenticated user can insert notifications" 
ON notifications FOR INSERT 
WITH CHECK (auth.role() = 'authenticated');

-- 5. Create RLS policies for notification_preferences
-- ============================================================================
-- Users can view their own preferences
CREATE POLICY "Users can view their own preferences" 
ON notification_preferences FOR SELECT 
USING (auth.uid() = user_id);

-- Users can update their own preferences
CREATE POLICY "Users can update their own preferences" 
ON notification_preferences FOR UPDATE 
USING (auth.uid() = user_id);

-- Users can insert their own preferences
CREATE POLICY "Users can insert their own preferences" 
ON notification_preferences FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- 6. Create indexes for performance
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- 7. Function to automatically create preferences for new users
-- ============================================================================
CREATE OR REPLACE FUNCTION handle_new_user_preferences()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.notification_preferences (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users (requires superuser privileges usually, or just run manually)
-- Note: In Supabase dashboard, you might need to create this trigger manually on auth.users
-- DROP TRIGGER IF EXISTS on_auth_user_created_preferences ON auth.users;
-- CREATE TRIGGER on_auth_user_created_preferences
--   AFTER INSERT ON auth.users
--   FOR EACH ROW EXECUTE FUNCTION handle_new_user_preferences();

-- 8. Enable Realtime for notifications
-- ============================================================================
-- This allows the Flutter app to listen for changes
alter publication supabase_realtime add table notifications;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
SELECT 
  '✅ SUCCESS! Notifications schema is ready!' as status,
  (SELECT COUNT(*) FROM notifications) as total_notifications,
  (SELECT COUNT(*) FROM notification_preferences) as total_preferences;
