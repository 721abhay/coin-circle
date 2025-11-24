-- ============================================
-- COIN CIRCLE - RPC FUNCTIONS & TRIGGERS
-- Run this AFTER 01_setup_tables.sql
-- ============================================

-- PART 1: Wallet RPCs
-- ============================================

-- Increment wallet balance
DROP FUNCTION IF EXISTS increment_wallet_balance(UUID, NUMERIC);
CREATE OR REPLACE FUNCTION increment_wallet_balance(p_user_id UUID, p_amount NUMERIC)
RETURNS VOID AS $$
BEGIN
  UPDATE wallets
  SET available_balance = available_balance + p_amount
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Decrement wallet balance
DROP FUNCTION IF EXISTS decrement_wallet_balance(UUID, NUMERIC);
CREATE OR REPLACE FUNCTION decrement_wallet_balance(p_user_id UUID, p_amount NUMERIC)
RETURNS VOID AS $$
BEGIN
  UPDATE wallets
  SET available_balance = available_balance - p_amount
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PART 2: Pool RPCs
-- ============================================

-- Increment pool members count
DROP FUNCTION IF EXISTS increment_pool_members(UUID);
CREATE OR REPLACE FUNCTION increment_pool_members(p_pool_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE pools
  SET current_members = current_members + 1
  WHERE id = p_pool_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get contribution status
DROP FUNCTION IF EXISTS get_contribution_status(UUID, UUID);
CREATE OR REPLACE FUNCTION get_contribution_status(p_pool_id UUID, p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_build_object(
    'is_paid', COALESCE(
      (SELECT status = 'completed' 
       FROM transactions 
       WHERE pool_id = p_pool_id 
         AND user_id = p_user_id 
         AND transaction_type = 'contribution'
       ORDER BY created_at DESC 
       LIMIT 1), 
      false
    ),
    'amount_due', COALESCE((SELECT contribution_amount FROM pools WHERE id = p_pool_id), 0),
    'late_fee', 0.0,
    'total_due', COALESCE((SELECT contribution_amount FROM pools WHERE id = p_pool_id), 0),
    'next_due_date', NOW() + INTERVAL '30 days',
    'status', 'pending'
  ) INTO v_result;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Select random winner
DROP FUNCTION IF EXISTS select_random_winner(UUID);
CREATE OR REPLACE FUNCTION select_random_winner(p_pool_id UUID)
RETURNS UUID AS $$
DECLARE
  v_winner_id UUID;
BEGIN
  SELECT user_id INTO v_winner_id
  FROM pool_members
  WHERE pool_id = p_pool_id 
    AND status = 'active'
  ORDER BY RANDOM()
  LIMIT 1;
  
  RETURN v_winner_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PART 3: Chat RPCs
-- ============================================

-- Create system message
DROP FUNCTION IF EXISTS create_system_message(UUID, TEXT, TEXT);
CREATE OR REPLACE FUNCTION create_system_message(
  p_pool_id UUID,
  p_content TEXT,
  p_message_type TEXT
)
RETURNS UUID AS $$
DECLARE
  v_message_id UUID;
BEGIN
  INSERT INTO pool_messages (pool_id, sender_id, content, message_type, is_system)
  VALUES (p_pool_id, NULL, p_content, p_message_type, true)
  RETURNING id INTO v_message_id;
  
  RETURN v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Toggle message pin
DROP FUNCTION IF EXISTS toggle_message_pin(UUID, BOOLEAN);
CREATE OR REPLACE FUNCTION toggle_message_pin(p_message_id UUID, p_is_pinned BOOLEAN)
RETURNS VOID AS $$
BEGIN
  UPDATE pool_messages
  SET is_pinned = p_is_pinned
  WHERE id = p_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PART 4: Voting RPC
-- ============================================

-- Cast vote
DROP FUNCTION IF EXISTS cast_vote(UUID, UUID, TEXT);
CREATE OR REPLACE FUNCTION cast_vote(
  p_vote_id UUID,
  p_user_id UUID,
  p_vote_option TEXT
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO vote_responses (vote_id, user_id, vote_option)
  VALUES (p_vote_id, p_user_id, p_vote_option)
  ON CONFLICT (vote_id, user_id) 
  DO UPDATE SET vote_option = p_vote_option, updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PART 5: Security RPCs
-- ============================================

-- Rate limiting check
DROP FUNCTION IF EXISTS check_rate_limit(UUID, TEXT, INTEGER);
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_user_id UUID,
  p_endpoint TEXT,
  p_max_requests INTEGER DEFAULT 100
)
RETURNS BOOLEAN AS $$
DECLARE
  v_count INTEGER;
  v_window_start TIMESTAMPTZ;
BEGIN
  v_window_start := DATE_TRUNC('minute', NOW());
  
  SELECT COALESCE(request_count, 0) INTO v_count
  FROM api_rate_limits
  WHERE user_id = p_user_id 
    AND endpoint = p_endpoint
    AND window_start = v_window_start;
  
  IF v_count < p_max_requests THEN
    INSERT INTO api_rate_limits (user_id, endpoint, request_count, window_start, window_end)
    VALUES (p_user_id, p_endpoint, 1, v_window_start, v_window_start + INTERVAL '1 minute')
    ON CONFLICT (user_id, endpoint, window_start) 
    DO UPDATE SET request_count = api_rate_limits.request_count + 1;
    
    RETURN true;
  ELSE
    RETURN false;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- TDS calculation and deduction
DROP FUNCTION IF EXISTS calculate_and_deduct_tds(UUID, NUMERIC, UUID);
CREATE OR REPLACE FUNCTION calculate_and_deduct_tds(
  p_user_id UUID,
  p_winning_amount NUMERIC,
  p_transaction_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_tds_amount NUMERIC;
  v_net_amount NUMERIC;
  v_financial_year TEXT;
  v_quarter TEXT;
  v_pan_number TEXT;
BEGIN
  IF p_winning_amount <= 10000 THEN
    RETURN jsonb_build_object(
      'tds_applicable', false,
      'gross_amount', p_winning_amount,
      'tds_amount', 0,
      'net_amount', p_winning_amount
    );
  END IF;
  
  v_tds_amount := ROUND(p_winning_amount * 0.30, 2);
  v_net_amount := p_winning_amount - v_tds_amount;
  
  v_financial_year := CASE 
    WHEN EXTRACT(MONTH FROM NOW()) >= 4 THEN 
      EXTRACT(YEAR FROM NOW())::TEXT || '-' || (EXTRACT(YEAR FROM NOW()) + 1)::TEXT
    ELSE 
      (EXTRACT(YEAR FROM NOW()) - 1)::TEXT || '-' || EXTRACT(YEAR FROM NOW())::TEXT
  END;
  
  v_quarter := CASE 
    WHEN EXTRACT(MONTH FROM NOW()) BETWEEN 4 AND 6 THEN 'Q1'
    WHEN EXTRACT(MONTH FROM NOW()) BETWEEN 7 AND 9 THEN 'Q2'
    WHEN EXTRACT(MONTH FROM NOW()) BETWEEN 10 AND 12 THEN 'Q3'
    ELSE 'Q4'
  END;
  
  SELECT pan_number INTO v_pan_number
  FROM profiles
  WHERE id = p_user_id;
  
  INSERT INTO tds_records (
    user_id, 
    transaction_id, 
    winning_amount, 
    tds_amount, 
    financial_year, 
    quarter,
    pan_number
  ) VALUES (
    p_user_id, 
    p_transaction_id, 
    p_winning_amount, 
    v_tds_amount, 
    v_financial_year, 
    v_quarter,
    v_pan_number
  );
  
  RETURN jsonb_build_object(
    'tds_applicable', true,
    'gross_amount', p_winning_amount,
    'tds_amount', v_tds_amount,
    'net_amount', v_net_amount,
    'financial_year', v_financial_year,
    'quarter', v_quarter
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Multiple account detection
DROP FUNCTION IF EXISTS detect_multiple_accounts(UUID);
CREATE OR REPLACE FUNCTION detect_multiple_accounts(p_user_id UUID)
RETURNS TABLE(
  linked_user_id UUID,
  link_type TEXT,
  confidence_score NUMERIC,
  details JSONB
) AS $$
BEGIN
  -- Check for same device fingerprint
  INSERT INTO account_links (user_id, linked_user_id, link_type, confidence_score, metadata)
  SELECT 
    p_user_id,
    td2.user_id,
    'device',
    0.9,
    jsonb_build_object('device_fingerprint', td1.device_fingerprint)
  FROM trusted_devices td1
  JOIN trusted_devices td2 ON td1.device_fingerprint = td2.device_fingerprint
  WHERE td1.user_id = p_user_id 
    AND td2.user_id != p_user_id
    AND td1.is_active = true
    AND td2.is_active = true
  ON CONFLICT (user_id, linked_user_id, link_type) DO NOTHING;
  
  -- Check for same IP address
  INSERT INTO account_links (user_id, linked_user_id, link_type, confidence_score, metadata)
  SELECT 
    p_user_id,
    ul2.user_id,
    'ip',
    0.7,
    jsonb_build_object('ip_address', ul1.ip_address)
  FROM user_locations ul1
  JOIN user_locations ul2 ON ul1.ip_address = ul2.ip_address
  WHERE ul1.user_id = p_user_id 
    AND ul2.user_id != p_user_id
    AND ul1.created_at > NOW() - INTERVAL '30 days'
    AND ul2.created_at > NOW() - INTERVAL '30 days'
  ON CONFLICT (user_id, linked_user_id, link_type) DO NOTHING;
  
  RETURN QUERY
  SELECT al.linked_user_id, al.link_type, al.confidence_score, al.metadata
  FROM account_links al
  WHERE al.user_id = p_user_id
  ORDER BY al.confidence_score DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PART 6: Trigger for Auto Wallet Creation
-- ============================================

DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.wallets (user_id, available_balance, locked_balance, total_winnings)
  VALUES (new.id, 0.0, 0.0, 0.0);
  
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url')
  ON CONFLICT (id) DO NOTHING;
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- PART 7: Cleanup Function
-- ============================================

DROP FUNCTION IF EXISTS cleanup_old_rate_limits();
CREATE OR REPLACE FUNCTION cleanup_old_rate_limits()
RETURNS void AS $$
BEGIN
  DELETE FROM api_rate_limits
  WHERE window_end < NOW() - INTERVAL '1 hour';
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- SUCCESS! All RPCs and triggers created.
-- Database setup complete!
-- ============================================
