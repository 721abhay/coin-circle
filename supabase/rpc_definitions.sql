-- RPC for incrementing wallet balance
DROP FUNCTION IF EXISTS increment_wallet_balance(UUID, NUMERIC);
CREATE OR REPLACE FUNCTION increment_wallet_balance(p_user_id UUID, p_amount NUMERIC)
RETURNS VOID AS $$
BEGIN
  UPDATE wallets
  SET available_balance = available_balance + p_amount,
      updated_at = NOW()
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- RPC for decrementing wallet balance
DROP FUNCTION IF EXISTS decrement_wallet_balance(UUID, NUMERIC);
CREATE OR REPLACE FUNCTION decrement_wallet_balance(p_user_id UUID, p_amount NUMERIC)
RETURNS VOID AS $$
BEGIN
  UPDATE wallets
  SET available_balance = available_balance - p_amount,
      updated_at = NOW()
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- RPC for incrementing pool members count
DROP FUNCTION IF EXISTS increment_pool_members(UUID);
CREATE OR REPLACE FUNCTION increment_pool_members(p_pool_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE pools
  SET current_members = current_members + 1
  WHERE id = p_pool_id;
END;
$$ LANGUAGE plpgsql;

-- RPC for creating a system message
DROP FUNCTION IF EXISTS create_system_message(UUID, TEXT, TEXT, JSONB);
CREATE OR REPLACE FUNCTION create_system_message(
  p_pool_id UUID,
  p_message_type TEXT,
  p_content TEXT,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO pool_messages (pool_id, user_id, message_type, content, metadata)
  VALUES (p_pool_id, auth.uid(), p_message_type, p_content, p_metadata);
END;
$$ LANGUAGE plpgsql;

-- RPC for toggling message pin
DROP FUNCTION IF EXISTS toggle_message_pin(UUID, BOOLEAN);
CREATE OR REPLACE FUNCTION toggle_message_pin(p_message_id UUID, p_is_pinned BOOLEAN)
RETURNS VOID AS $$
BEGIN
  UPDATE pool_messages
  SET is_pinned = p_is_pinned
  WHERE id = p_message_id;
END;
$$ LANGUAGE plpgsql;

-- RPC for getting contribution status
DROP FUNCTION IF EXISTS get_contribution_status(UUID, UUID);
CREATE OR REPLACE FUNCTION get_contribution_status(p_pool_id UUID, p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  -- This is a simplified example. You would typically query a contributions table.
  SELECT jsonb_build_object(
    'is_paid', false,
    'amount_due', (SELECT contribution_amount FROM pools WHERE id = p_pool_id),
    'late_fee', 0.0,
    'total_due', (SELECT contribution_amount FROM pools WHERE id = p_pool_id),
    'next_due_date', (SELECT start_date FROM pools WHERE id = p_pool_id), -- simplified
    'status', 'pending'
  ) INTO v_result;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- RPC for selecting a random winner
DROP FUNCTION IF EXISTS select_random_winner(UUID);
CREATE OR REPLACE FUNCTION select_random_winner(p_pool_id UUID)
RETURNS UUID AS $$
DECLARE
  v_winner_id UUID;
BEGIN
  SELECT user_id INTO v_winner_id
  FROM pool_members
  WHERE pool_id = p_pool_id AND status = 'active'
  ORDER BY RANDOM()
  LIMIT 1;
  
  RETURN v_winner_id;
END;
$$ LANGUAGE plpgsql;

-- RPC for casting a vote
DROP FUNCTION IF EXISTS cast_vote(UUID, TEXT);
CREATE OR REPLACE FUNCTION cast_vote(p_pool_id UUID, p_vote_option TEXT)
RETURNS VOID AS $$
BEGIN
  -- Implement voting logic here, e.g., inserting into a votes table
  -- For now, this is a placeholder
  NULL;
END;
$$ LANGUAGE plpgsql;
