-- Migration: Admin Statistics and Analytics
-- Description: Creates RPC functions for real-time admin dashboard statistics

-- Function to get comprehensive admin statistics
CREATE OR REPLACE FUNCTION get_admin_stats()
RETURNS JSONB AS $$
DECLARE
  v_stats JSONB;
  v_prev_month_users INTEGER;
  v_prev_month_pools INTEGER;
  v_prev_month_volume DECIMAL;
BEGIN
  -- Get previous month stats for growth calculation
  SELECT COUNT(*) INTO v_prev_month_users
  FROM profiles
  WHERE created_at < DATE_TRUNC('month', CURRENT_DATE);
  
  SELECT COUNT(*) INTO v_prev_month_pools
  FROM pools
  WHERE created_at < DATE_TRUNC('month', CURRENT_DATE);
  
  SELECT COALESCE(SUM(amount), 0) INTO v_prev_month_volume
  FROM transactions
  WHERE transaction_type = 'contribution'
    AND created_at < DATE_TRUNC('month', CURRENT_DATE);
  
  -- Build comprehensive stats object
  SELECT jsonb_build_object(
    -- User Statistics
    'total_users', (SELECT COUNT(*) FROM profiles),
    'active_users', (SELECT COUNT(DISTINCT user_id) FROM pool_members WHERE joined_at >= NOW() - INTERVAL '30 days'),
    'suspended_users', (SELECT COUNT(*) FROM profiles WHERE suspended = TRUE),
    'new_users_this_month', (SELECT COUNT(*) FROM profiles WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE)),
    'user_growth_rate', CASE 
      WHEN v_prev_month_users > 0 
      THEN ROUND(((SELECT COUNT(*) FROM profiles WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE))::DECIMAL / v_prev_month_users * 100), 2)
      ELSE 0 
    END,
    
    -- Pool Statistics
    'total_pools', (SELECT COUNT(*) FROM pools),
    'active_pools', (SELECT COUNT(*) FROM pools WHERE status = 'active'),
    'pending_pools', (SELECT COUNT(*) FROM pools WHERE status = 'pending'),
    'completed_pools', (SELECT COUNT(*) FROM pools WHERE status = 'completed'),
    'new_pools_this_month', (SELECT COUNT(*) FROM pools WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE)),
    'pool_growth_rate', CASE 
      WHEN v_prev_month_pools > 0 
      THEN ROUND(((SELECT COUNT(*) FROM pools WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE))::DECIMAL / v_prev_month_pools * 100), 2)
      ELSE 0 
    END,
    
    -- Financial Statistics
    'total_transactions', (SELECT COUNT(*) FROM transactions),
    'total_volume', (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE transaction_type = 'contribution'),
    'total_payouts', (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE transaction_type = 'payout'),
    'volume_this_month', (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE transaction_type = 'contribution' AND created_at >= DATE_TRUNC('month', CURRENT_DATE)),
    'volume_growth_rate', CASE 
      WHEN v_prev_month_volume > 0 
      THEN ROUND(((SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE transaction_type = 'contribution' AND created_at >= DATE_TRUNC('month', CURRENT_DATE))::DECIMAL / v_prev_month_volume * 100), 2)
      ELSE 0 
    END,
    'average_pool_size', (SELECT COALESCE(AVG(contribution_amount * max_members), 0) FROM pools),
    'average_contribution', (SELECT COALESCE(AVG(amount), 0) FROM transactions WHERE transaction_type = 'contribution'),
    
    -- KYC Statistics
    'pending_kyc', (SELECT COUNT(*) FROM profiles WHERE kyc_verified = FALSE),
    'verified_kyc', (SELECT COUNT(*) FROM profiles WHERE kyc_verified = TRUE),
    'kyc_verification_rate', ROUND((SELECT COUNT(*)::DECIMAL FROM profiles WHERE kyc_verified = TRUE) / NULLIF((SELECT COUNT(*) FROM profiles), 0) * 100, 2),
    
    -- Activity Statistics
    'active_draws', (SELECT COUNT(*) FROM draws WHERE status = 'pending'),
    'completed_draws', (SELECT COUNT(*) FROM draws WHERE status = 'completed'),
    'total_pool_members', (SELECT COUNT(*) FROM pool_members),
    'avg_members_per_pool', ROUND((SELECT COUNT(*)::DECIMAL FROM pool_members) / NULLIF((SELECT COUNT(*) FROM pools), 0), 2)
  ) INTO v_stats;
  
  RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get revenue chart data (last 7 days)
CREATE OR REPLACE FUNCTION get_revenue_chart_data()
RETURNS JSONB AS $$
DECLARE
  v_chart_data JSONB;
BEGIN
  SELECT jsonb_agg(
    jsonb_build_object(
      'date', day::DATE,
      'revenue', COALESCE(daily_revenue, 0)
    ) ORDER BY day
  ) INTO v_chart_data
  FROM (
    SELECT 
      generate_series(
        CURRENT_DATE - INTERVAL '6 days',
        CURRENT_DATE,
        INTERVAL '1 day'
      )::DATE AS day
  ) dates
  LEFT JOIN (
    SELECT 
      DATE(created_at) AS transaction_date,
      SUM(amount) AS daily_revenue
    FROM transactions
    WHERE transaction_type = 'contribution'
      AND created_at >= CURRENT_DATE - INTERVAL '6 days'
    GROUP BY DATE(created_at)
  ) revenue ON dates.day = revenue.transaction_date;
  
  RETURN v_chart_data;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get recent admin activity log
CREATE OR REPLACE FUNCTION get_admin_activity_log(p_limit INTEGER DEFAULT 10)
RETURNS TABLE (
  id UUID,
  action TEXT,
  description TEXT,
  performed_by UUID,
  performed_by_name TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.id,
    t.transaction_type AS action,
    CASE 
      WHEN t.transaction_type = 'contribution' THEN 'User contributed ₹' || t.amount
      WHEN t.transaction_type = 'payout' THEN 'Payout of ₹' || t.amount
      ELSE t.transaction_type
    END AS description,
    t.user_id AS performed_by,
    p.full_name AS performed_by_name,
    t.created_at
  FROM transactions t
  JOIN profiles p ON t.user_id = p.id
  ORDER BY t.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user growth data (last 30 days)
CREATE OR REPLACE FUNCTION get_user_growth_data()
RETURNS JSONB AS $$
DECLARE
  v_growth_data JSONB;
BEGIN
  SELECT jsonb_agg(
    jsonb_build_object(
      'date', day::DATE,
      'new_users', COALESCE(daily_users, 0),
      'total_users', COALESCE(cumulative_users, 0)
    ) ORDER BY day
  ) INTO v_growth_data
  FROM (
    SELECT 
      day,
      daily_users,
      SUM(daily_users) OVER (ORDER BY day) AS cumulative_users
    FROM (
      SELECT 
        generate_series(
          CURRENT_DATE - INTERVAL '29 days',
          CURRENT_DATE,
          INTERVAL '1 day'
        )::DATE AS day
    ) dates
    LEFT JOIN (
      SELECT 
        DATE(created_at) AS signup_date,
        COUNT(*) AS daily_users
      FROM profiles
      WHERE created_at >= CURRENT_DATE - INTERVAL '29 days'
      GROUP BY DATE(created_at)
    ) signups ON dates.day = signups.signup_date
  ) growth_data;
  
  RETURN v_growth_data;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get pool statistics by status
CREATE OR REPLACE FUNCTION get_pool_stats_by_status()
RETURNS JSONB AS $$
BEGIN
  RETURN (
    SELECT jsonb_object_agg(status, pool_count)
    FROM (
      SELECT 
        status,
        COUNT(*) AS pool_count
      FROM pools
      GROUP BY status
    ) pool_stats
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get top performing pools
CREATE OR REPLACE FUNCTION get_top_pools(p_limit INTEGER DEFAULT 5)
RETURNS TABLE (
  pool_id UUID,
  pool_name TEXT,
  total_contributions DECIMAL,
  member_count INTEGER,
  completion_rate DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id AS pool_id,
    p.name AS pool_name,
    COALESCE(SUM(t.amount), 0) AS total_contributions,
    COUNT(DISTINCT pm.user_id)::INTEGER AS member_count,
    ROUND((p.current_round::DECIMAL / p.total_rounds * 100), 2) AS completion_rate
  FROM pools p
  LEFT JOIN transactions t ON p.id = t.pool_id AND t.transaction_type = 'contribution'
  LEFT JOIN pool_members pm ON p.id = pm.pool_id
  GROUP BY p.id, p.name, p.current_round, p.total_rounds
  ORDER BY total_contributions DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_admin_stats TO authenticated;
GRANT EXECUTE ON FUNCTION get_revenue_chart_data TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_activity_log TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_growth_data TO authenticated;
GRANT EXECUTE ON FUNCTION get_pool_stats_by_status TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_pools TO authenticated;

-- Comments
COMMENT ON FUNCTION get_admin_stats IS 'Returns comprehensive admin dashboard statistics';
COMMENT ON FUNCTION get_revenue_chart_data IS 'Returns revenue data for the last 7 days for charting';
COMMENT ON FUNCTION get_admin_activity_log IS 'Returns recent admin activity log entries';
COMMENT ON FUNCTION get_user_growth_data IS 'Returns user growth data for the last 30 days';
COMMENT ON FUNCTION get_pool_stats_by_status IS 'Returns pool count grouped by status';
COMMENT ON FUNCTION get_top_pools IS 'Returns top performing pools by contribution amount';
