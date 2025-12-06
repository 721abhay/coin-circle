# 🔔 Notification System Setup

To make the notification system work completely (sending and receiving), you need to set up the database tables in Supabase.

## 1. Run the SQL Script
Copy the following SQL code and run it in your **Supabase SQL Editor**:

```sql
-- ============================================================================
-- NOTIFICATIONS SETUP
-- ============================================================================

-- 1. Create notifications table
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
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS policies for notifications
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
CREATE POLICY "Users can view their own preferences" 
ON notification_preferences FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own preferences" 
ON notification_preferences FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own preferences" 
ON notification_preferences FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- 6. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- 7. Enable Realtime for notifications
alter publication supabase_realtime add table notifications;
```

## 2. What this does
- Creates a `notifications` table to store messages.
- Creates a `notification_preferences` table for user settings.
- Enables **Realtime** so notifications appear instantly in the app.
- Sets up **Security Policies** so users can only see their own notifications, but can send notifications to others (e.g., when joining a pool).

## 3. Verify in App
1.  Go to **Profile > Notifications**.
2.  It should show "No notifications yet" (instead of a loading spinner or error).
3.  Try joining a pool or performing an action that triggers a notification.
