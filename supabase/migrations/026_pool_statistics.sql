-- Function to get pool statistics
CREATE OR REPLACE FUNCTION get_pool_statistics(p_pool_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_rounds INTEGER;
  v_current_round INTEGER;
  v_total_collected DECIMAL;
  v_on_time_payments INTEGER;
  v_late_payments INTEGER;
  v_total_payments INTEGER;
  v_completion_percentage DECIMAL;
  v_on_time_rate DECIMAL;
BEGIN
  -- Get pool details
  SELECT 
    duration_months, 
    current_round 
  INTO 
    v_total_rounds, 
    v_current_round 
  FROM pools 
  WHERE id = p_pool_id;

  -- Calculate completion percentage
  IF v_total_rounds > 0 THEN
    v_completion_percentage := (v_current_round::DECIMAL / v_total_rounds::DECIMAL) * 100;
  ELSE
    v_completion_percentage := 0;
  END IF;

  -- Get payment stats
  SELECT 
    COUNT(*) FILTER (WHERE status = 'completed' AND created_at <= due_date),
    COUNT(*) FILTER (WHERE status = 'completed' AND created_at > due_date),
    COUNT(*),
    COALESCE(SUM(amount), 0)
  INTO 
    v_on_time_payments,
    v_late_payments,
    v_total_payments,
    v_total_collected
  FROM transactions
  WHERE pool_id = p_pool_id AND type = 'contribution';

  -- Calculate on-time rate
  IF v_total_payments > 0 THEN
    v_on_time_rate := (v_on_time_payments::DECIMAL / v_total_payments::DECIMAL) * 100;
  ELSE
    v_on_time_rate := 100; -- Default to 100% if no payments yet
  END IF;

  RETURN jsonb_build_object(
    'completion_percentage', ROUND(v_completion_percentage, 1),
    'on_time_rate', ROUND(v_on_time_rate, 1),
    'total_collected', v_total_collected,
    'on_time_payments', v_on_time_payments,
    'late_payments', v_late_payments,
    'total_payments', v_total_payments
  );
END;
$$;
