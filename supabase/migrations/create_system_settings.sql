-- Create system_settings table for admin controls
CREATE TABLE IF NOT EXISTS system_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key TEXT UNIQUE NOT NULL,
  setting_value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users(id)
);

-- Insert default settings
INSERT INTO system_settings (setting_key, setting_value) VALUES
  ('maintenance_mode', '{"enabled": false, "message": "System under maintenance"}'::jsonb),
  ('allow_registrations', '{"enabled": true}'::jsonb),
  ('allow_withdrawals', '{"enabled": true}'::jsonb),
  ('app_version', '{"current": "1.0.0", "minimum_required": "1.0.0"}'::jsonb)
ON CONFLICT (setting_key) DO NOTHING;

-- Create announcements table
CREATE TABLE IF NOT EXISTS system_announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message TEXT NOT NULL,
  priority TEXT NOT NULL DEFAULT 'Info', -- Info, Warning, Critical, Success
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  is_active BOOLEAN DEFAULT true
);

-- RPC to update system setting
CREATE OR REPLACE FUNCTION update_system_setting(
  p_setting_key TEXT,
  p_setting_value JSONB,
  p_user_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if user is admin
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = p_user_id AND is_admin = true) THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  -- Update or insert setting
  INSERT INTO system_settings (setting_key, setting_value, updated_by)
  VALUES (p_setting_key, p_setting_value, p_user_id)
  ON CONFLICT (setting_key) 
  DO UPDATE SET 
    setting_value = p_setting_value,
    updated_at = NOW(),
    updated_by = p_user_id;
END;
$$;

-- RPC to get system setting
CREATE OR REPLACE FUNCTION get_system_setting(p_setting_key TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_value JSONB;
BEGIN
  SELECT setting_value INTO v_value
  FROM system_settings
  WHERE setting_key = p_setting_key;
  
  RETURN COALESCE(v_value, '{}'::jsonb);
END;
$$;

-- RPC to create announcement
CREATE OR REPLACE FUNCTION create_announcement(
  p_message TEXT,
  p_priority TEXT,
  p_user_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_announcement_id UUID;
BEGIN
  -- Check if user is admin
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = p_user_id AND is_admin = true) THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  INSERT INTO system_announcements (message, priority, created_by)
  VALUES (p_message, p_priority, p_user_id)
  RETURNING id INTO v_announcement_id;
  
  RETURN v_announcement_id;
END;
$$;

-- Enable RLS
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_announcements ENABLE ROW LEVEL SECURITY;

-- Policies for system_settings (admin only)
CREATE POLICY "Admins can view settings" ON system_settings
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

CREATE POLICY "Admins can update settings" ON system_settings
  FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

-- Policies for announcements
CREATE POLICY "Everyone can view active announcements" ON system_announcements
  FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admins can manage announcements" ON system_announcements
  FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );
