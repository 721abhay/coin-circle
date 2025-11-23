-- 1. Create Enums for Notification Categories and Priority
CREATE TYPE notification_category AS ENUM ('payment', 'draw', 'pool', 'member', 'system');
CREATE TYPE notification_priority AS ENUM ('low', 'normal', 'high');

-- 2. Add columns to existing notifications table
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS category notification_category DEFAULT 'system';
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS priority notification_priority DEFAULT 'normal';

-- 3. Create Notification Preferences Table
CREATE TABLE IF NOT EXISTS notification_preferences (
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE PRIMARY KEY,
    payment_reminders BOOLEAN DEFAULT TRUE,
    draw_announcements BOOLEAN DEFAULT TRUE,
    pool_updates BOOLEAN DEFAULT TRUE,
    member_activities BOOLEAN DEFAULT TRUE,
    system_messages BOOLEAN DEFAULT TRUE,
    quiet_hours_enabled BOOLEAN DEFAULT FALSE,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Enable RLS
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for Notification Preferences
DROP POLICY IF EXISTS "Users can view own preferences" ON notification_preferences;
CREATE POLICY "Users can view own preferences" ON notification_preferences
    FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own preferences" ON notification_preferences;
CREATE POLICY "Users can update own preferences" ON notification_preferences
    FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own preferences" ON notification_preferences;
CREATE POLICY "Users can insert own preferences" ON notification_preferences
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- 6. Function to create default preferences for new users
CREATE OR REPLACE FUNCTION public.create_default_notification_preferences()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.notification_preferences (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Trigger to create default preferences on user creation
DROP TRIGGER IF EXISTS on_user_created_notification_prefs ON profiles;
CREATE TRIGGER on_user_created_notification_prefs
    AFTER INSERT ON profiles
    FOR EACH ROW EXECUTE FUNCTION public.create_default_notification_preferences();

-- 8. Function to check if notification should be sent based on preferences
CREATE OR REPLACE FUNCTION public.should_send_notification(
    p_user_id UUID,
    p_category notification_category
)
RETURNS BOOLEAN AS $$
DECLARE
    v_prefs RECORD;
    v_current_time TIME;
BEGIN
    -- Get user preferences
    SELECT * INTO v_prefs
    FROM notification_preferences
    WHERE user_id = p_user_id;
    
    -- If no preferences found, allow notification (default behavior)
    IF NOT FOUND THEN
        RETURN TRUE;
    END IF;
    
    -- Check category preference
    CASE p_category
        WHEN 'payment' THEN
            IF NOT v_prefs.payment_reminders THEN
                RETURN FALSE;
            END IF;
        WHEN 'draw' THEN
            IF NOT v_prefs.draw_announcements THEN
                RETURN FALSE;
            END IF;
        WHEN 'pool' THEN
            IF NOT v_prefs.pool_updates THEN
                RETURN FALSE;
            END IF;
        WHEN 'member' THEN
            IF NOT v_prefs.member_activities THEN
                RETURN FALSE;
            END IF;
        WHEN 'system' THEN
            IF NOT v_prefs.system_messages THEN
                RETURN FALSE;
            END IF;
    END CASE;
    
    -- Check quiet hours
    IF v_prefs.quiet_hours_enabled THEN
        v_current_time := CURRENT_TIME;
        
        -- Handle quiet hours that span midnight
        IF v_prefs.quiet_hours_start <= v_prefs.quiet_hours_end THEN
            -- Normal case: e.g., 22:00 to 08:00
            IF v_current_time >= v_prefs.quiet_hours_start AND v_current_time < v_prefs.quiet_hours_end THEN
                RETURN FALSE;
            END IF;
        ELSE
            -- Spans midnight: e.g., 22:00 to 08:00
            IF v_current_time >= v_prefs.quiet_hours_start OR v_current_time < v_prefs.quiet_hours_end THEN
                RETURN FALSE;
            END IF;
        END IF;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_notifications_category ON notifications(category);
CREATE INDEX IF NOT EXISTS idx_notifications_priority ON notifications(priority);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
