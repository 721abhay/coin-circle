-- Admin System Migration
-- Adds admin functionality including admin flag, admin-only functions, and security policies

-- Add admin columns to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS admin_notes TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS suspended BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS suspension_reason TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS suspended_at TIMESTAMP WITH TIME ZONE;

-- Create index for admin queries
CREATE INDEX IF NOT EXISTS idx_profiles_admin ON profiles(is_admin) WHERE is_admin = TRUE;
CREATE INDEX IF NOT EXISTS idx_profiles_suspended ON profiles(suspended) WHERE suspended = TRUE;

-- Function to check if current user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND is_admin = TRUE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all users (admin only)
CREATE OR REPLACE FUNCTION public.get_all_users(
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0,
  p_search TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  full_name TEXT,
  email TEXT,
  phone_number TEXT,
  suspended BOOLEAN,
  suspension_reason TEXT,
  is_admin BOOLEAN,
  pools_joined BIGINT,
  pools_created BIGINT,
  wallet_balance DECIMAL,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin only';
  END IF;

  RETURN QUERY
  SELECT 
    p.id,
    p.full_name,
    p.email,
    p.phone_number,
    p.suspended,
    p.suspension_reason,
    p.is_admin,
    COUNT(DISTINCT pm.pool_id) AS pools_joined,
    COUNT(DISTINCT po.id) AS pools_created,
    COALESCE(w.available_balance, 0) AS wallet_balance,
    p.created_at
  FROM profiles p
  LEFT JOIN pool_members pm ON p.id = pm.user_id
  LEFT JOIN pools po ON p.id = po.creator_id
  LEFT JOIN wallets w ON p.id = w.user_id
  WHERE 
    (p_search IS NULL OR 
     p.full_name ILIKE '%' || p_search || '%' OR 
     p.email ILIKE '%' || p_search || '%')
  GROUP BY p.id, w.available_balance
  ORDER BY p.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user details (admin only)
CREATE OR REPLACE FUNCTION public.get_user_details_admin(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin only';
  END IF;

  SELECT json_build_object(
    'profile', row_to_json(p.*),
    'wallet', row_to_json(w.*),
    'pools_joined', (SELECT COUNT(*) FROM pool_members WHERE user_id = p_user_id),
    'pools_created', (SELECT COUNT(*) FROM pools WHERE creator_id = p_user_id),
    'total_transactions', (SELECT COUNT(*) FROM transactions WHERE user_id = p_user_id),
    'total_contributed', (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE user_id = p_user_id AND transaction_type = 'contribution'),
    'total_won', (SELECT COALESCE(SUM(winning_amount), 0) FROM winner_history WHERE user_id = p_user_id)
  ) INTO v_result
  FROM profiles p
  LEFT JOIN wallets w ON p.id = w.user_id
  WHERE p.id = p_user_id;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to suspend user (admin only)
CREATE OR REPLACE FUNCTION public.suspend_user(
  p_user_id UUID,
  p_reason TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin only';
  END IF;

  -- Cannot suspend another admin
  IF EXISTS (SELECT 1 FROM profiles WHERE id = p_user_id AND is_admin = TRUE) THEN
    RAISE EXCEPTION 'Cannot suspend admin users';
  END IF;

  UPDATE profiles
  SET 
    suspended = TRUE,
    suspension_reason = p_reason,
    suspended_at = NOW()
  WHERE id = p_user_id;

  -- Log the action
  INSERT INTO audit_logs (table_name, record_id, action, old_data, new_data, user_id)
  VALUES ('profiles', p_user_id, 'suspend_user', NULL, json_build_object('reason', p_reason), auth.uid());

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to unsuspend user (admin only)
CREATE OR REPLACE FUNCTION public.unsuspend_user(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin only';
  END IF;

  UPDATE profiles
  SET 
    suspended = FALSE,
    suspension_reason = NULL,
    suspended_at = NULL
  WHERE id = p_user_id;

  -- Log the action
  INSERT INTO audit_logs (table_name, record_id, action, old_data, new_data, user_id)
  VALUES ('profiles', p_user_id, 'unsuspend_user', NULL, NULL, auth.uid());

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all pools (admin view)
CREATE OR REPLACE FUNCTION public.get_all_pools_admin(
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0,
  p_status pool_status_enum DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  creator_name TEXT,
  pool_type pool_type_enum,
  status pool_status_enum,
  current_members INTEGER,
  max_members INTEGER,
  contribution_amount DECIMAL,
  total_amount DECIMAL,
  created_at TIMESTAMP WITH TIME ZONE,
  start_date DATE
) AS $$
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin only';
  END IF;

  RETURN QUERY
  SELECT 
    p.id,
    p.name,
    pr.full_name AS creator_name,
    p.pool_type,
    p.status,
    p.current_members,
    p.max_members,
    p.contribution_amount,
    p.total_amount,
    p.created_at,
    p.start_date
  FROM pools p
  LEFT JOIN profiles pr ON p.creator_id = pr.id
  WHERE (p_status IS NULL OR p.status = p_status)
  ORDER BY p.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to force close pool (admin only)
CREATE OR REPLACE FUNCTION public.force_close_pool(
  p_pool_id UUID,
  p_reason TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin only';
  END IF;

  UPDATE pools
  SET 
    status = 'cancelled',
    updated_at = NOW()
  WHERE id = p_pool_id;

  -- Log the action
  INSERT INTO audit_logs (table_name, record_id, action, old_data, new_data, user_id)
  VALUES ('pools', p_pool_id, 'force_close', NULL, json_build_object('reason', p_reason), auth.uid());

  -- Send notification to pool members
  INSERT INTO notifications (user_id, notification_type, title, message, related_pool_id)
  SELECT 
    pm.user_id,
    'pool_update',
    'Pool Closed',
    'The pool "' || po.name || '" has been closed by administration. Reason: ' || p_reason,
    p_pool_id
  FROM pool_members pm
  JOIN pools po ON pm.pool_id = po.id
  WHERE pm.pool_id = p_pool_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get platform statistics (admin only)
CREATE OR REPLACE FUNCTION public.get_platform_stats()
RETURNS JSON AS $$
DECLARE
  v_stats JSON;
BEGIN
  -- Check if user is admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied: Admin only';
  END IF;

  SELECT json_build_object(
    'total_users', (SELECT COUNT(*) FROM profiles),
    'active_users', (SELECT COUNT(DISTINCT user_id) FROM transactions WHERE created_at > NOW() - INTERVAL '30 days'),
    'suspended_users', (SELECT COUNT(*) FROM profiles WHERE suspended = TRUE),
    'total_pools', (SELECT COUNT(*) FROM pools),
    'active_pools', (SELECT COUNT(*) FROM pools WHERE status = 'active'),
    'pending_pools', (SELECT COUNT(*) FROM pools WHERE status = 'pending'),
    'completed_pools', (SELECT COUNT(*) FROM pools WHERE status = 'completed'),
    'total_transactions', (SELECT COUNT(*) FROM transactions),
    'total_transaction_volume', (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE status = 'completed'),
    'total_payouts', (SELECT COALESCE(SUM(winning_amount), 0) FROM winner_history),
    'average_pool_size', (SELECT COALESCE(AVG(max_members), 0) FROM pools),
    'average_contribution', (SELECT COALESCE(AVG(contribution_amount), 0) FROM pools)
  ) INTO v_stats;

  RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add RLS policy to prevent suspended users from accessing the app
DROP POLICY IF EXISTS "Suspended users cannot access" ON profiles;
CREATE POLICY "Suspended users cannot access" ON profiles
  FOR SELECT
  USING (
    id = auth.uid() AND (suspended = FALSE OR suspended IS NULL)
  );
