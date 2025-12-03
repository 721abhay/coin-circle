-- ============================================
-- REPUTATION & SOCIAL PRESSURE SYSTEM
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Add reputation fields to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS reputation_score INT DEFAULT 50;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS on_time_payment_percentage DECIMAL(5,2) DEFAULT 100.00;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS total_payments_made INT DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS on_time_payments INT DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS late_payments INT DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS missed_payments INT DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS pools_completed INT DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS pools_defaulted INT DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_defaulter BOOLEAN DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS defaulted_at TIMESTAMPTZ;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_reputation_update TIMESTAMPTZ DEFAULT NOW();

-- 2. Create/Update badges table
-- Drop existing if needed and recreate with correct schema
DROP TABLE IF EXISTS user_badges CASCADE;
DROP TABLE IF EXISTS badges CASCADE;

CREATE TABLE badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  icon VARCHAR(50), -- emoji or icon name
  color VARCHAR(20), -- hex color
  requirement_type VARCHAR(50), -- 'reputation', 'payments', 'pools_completed', etc.
  requirement_value INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create user_badges table (many-to-many)
CREATE TABLE user_badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  badge_id UUID REFERENCES badges(id) ON DELETE CASCADE,
  earned_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, badge_id)
);

-- 4. Create reputation_history table
CREATE TABLE IF NOT EXISTS reputation_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  change_amount INT NOT NULL,
  reason VARCHAR(100) NOT NULL,
  previous_score INT NOT NULL,
  new_score INT NOT NULL,
  pool_id UUID REFERENCES pools(id) ON DELETE SET NULL,
  transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Create reviews table
CREATE TABLE IF NOT EXISTS user_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reviewer_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  reviewee_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE,
  rating INT CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  is_verified BOOLEAN DEFAULT false, -- Only from same pool members
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(reviewer_id, reviewee_id, pool_id),
  CHECK (reviewer_id != reviewee_id)
);

-- 6. Create blacklist table
CREATE TABLE IF NOT EXISTS blacklist (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  phone_number VARCHAR(20),
  email VARCHAR(255),
  aadhaar_hash VARCHAR(255), -- Hashed for privacy
  device_id VARCHAR(255),
  reason TEXT NOT NULL,
  blacklisted_by UUID REFERENCES auth.users(id),
  blacklisted_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ, -- NULL = permanent
  is_active BOOLEAN DEFAULT true
);

-- 7. Create default_events table (track defaulting incidents)
CREATE TABLE IF NOT EXISTS default_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE,
  round_number INT,
  amount_owed DECIMAL(10,2),
  reason VARCHAR(255),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Enable RLS
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE reputation_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE blacklist ENABLE ROW LEVEL SECURITY;
ALTER TABLE default_events ENABLE ROW LEVEL SECURITY;

-- 9. RLS Policies for badges
DROP POLICY IF EXISTS "Anyone can view badges" ON badges;
CREATE POLICY "Anyone can view badges" ON badges FOR SELECT USING (true);

-- 10. RLS Policies for user_badges
DROP POLICY IF EXISTS "Anyone can view user badges" ON user_badges;
CREATE POLICY "Anyone can view user badges" ON user_badges FOR SELECT USING (true);

-- 11. RLS Policies for reputation_history
DROP POLICY IF EXISTS "Users can view their own reputation history" ON reputation_history;
CREATE POLICY "Users can view their own reputation history" ON reputation_history
  FOR SELECT USING (auth.uid() = user_id);

-- 12. RLS Policies for user_reviews
DROP POLICY IF EXISTS "Anyone can view reviews" ON user_reviews;
CREATE POLICY "Anyone can view reviews" ON user_reviews FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can create reviews for pool members" ON user_reviews;
CREATE POLICY "Users can create reviews for pool members" ON user_reviews
  FOR INSERT WITH CHECK (
    auth.uid() = reviewer_id
    AND EXISTS (
      SELECT 1 FROM pool_members pm1
      JOIN pool_members pm2 ON pm1.pool_id = pm2.pool_id
      WHERE pm1.user_id = auth.uid()
      AND pm2.user_id = reviewee_id
      AND pm1.pool_id = user_reviews.pool_id
    )
  );

DROP POLICY IF EXISTS "Users can update their own reviews" ON user_reviews;
CREATE POLICY "Users can update their own reviews" ON user_reviews
  FOR UPDATE USING (auth.uid() = reviewer_id);

-- 13. RLS Policies for blacklist (admin only)
DROP POLICY IF EXISTS "Admins can view blacklist" ON blacklist;
CREATE POLICY "Admins can view blacklist" ON blacklist
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND email LIKE '%@admin.com' -- Replace with your admin check
    )
  );

-- 14. RLS Policies for default_events
DROP POLICY IF EXISTS "Pool members can view default events" ON default_events;
CREATE POLICY "Pool members can view default events" ON default_events
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM pool_members
      WHERE pool_id = default_events.pool_id
      AND user_id = auth.uid()
    )
  );

-- 15. Insert default badges
INSERT INTO badges (name, description, icon, color, requirement_type, requirement_value) VALUES
  ('New Member', 'Welcome to Coin Circle!', '🆕', '#3B82F6', 'reputation', 0),
  ('Trusted Member', 'Reputation score 70+', '✅', '#10B981', 'reputation', 70),
  ('Elite Member', 'Reputation score 90+', '⭐', '#F59E0B', 'reputation', 90),
  ('Perfect Payer', '100% on-time payments', '💯', '#8B5CF6', 'on_time_percentage', 100),
  ('Reliable', '95%+ on-time payments', '🎯', '#06B6D4', 'on_time_percentage', 95),
  ('Pool Completer', 'Completed 1 pool', '🏆', '#EC4899', 'pools_completed', 1),
  ('Veteran', 'Completed 5 pools', '🎖️', '#EF4444', 'pools_completed', 5),
  ('Legend', 'Completed 10 pools', '👑', '#FBBF24', 'pools_completed', 10),
  ('Defaulter', 'Has defaulted on a pool', '🚫', '#DC2626', 'is_defaulter', 1),
  ('Banned', 'Permanently banned', '⛔', '#991B1B', 'is_banned', 1)
ON CONFLICT (name) DO NOTHING;

-- 16. Function to calculate reputation score
CREATE OR REPLACE FUNCTION calculate_reputation_score(p_user_id UUID)
RETURNS INT AS $$
DECLARE
  v_score INT;
  v_on_time INT;
  v_late INT;
  v_missed INT;
  v_completed INT;
  v_defaulted INT;
BEGIN
  SELECT 
    on_time_payments,
    late_payments,
    missed_payments,
    pools_completed,
    pools_defaulted
  INTO v_on_time, v_late, v_missed, v_completed, v_defaulted
  FROM profiles
  WHERE id = p_user_id;

  -- Base score: 50
  v_score := 50;

  -- Add points for on-time payments (+5 each)
  v_score := v_score + (v_on_time * 5);

  -- Subtract points for late payments (-10 each)
  v_score := v_score - (v_late * 10);

  -- Subtract points for missed payments (-20 each)
  v_score := v_score - (v_missed * 20);

  -- Add points for completed pools (+50 each)
  v_score := v_score + (v_completed * 50);

  -- Massive penalty for defaulting (-100 each)
  v_score := v_score - (v_defaulted * 100);

  -- Cap between 0 and 100
  IF v_score < 0 THEN v_score := 0; END IF;
  IF v_score > 100 THEN v_score := 100; END IF;

  RETURN v_score;
END;
$$ LANGUAGE plpgsql;

-- 17. Function to update reputation
CREATE OR REPLACE FUNCTION update_reputation(
  p_user_id UUID,
  p_change_amount INT,
  p_reason VARCHAR(100),
  p_pool_id UUID DEFAULT NULL,
  p_transaction_id UUID DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  v_old_score INT;
  v_new_score INT;
BEGIN
  -- Get current score
  SELECT reputation_score INTO v_old_score
  FROM profiles
  WHERE id = p_user_id;

  -- Calculate new score
  v_new_score := calculate_reputation_score(p_user_id);

  -- Update profile
  UPDATE profiles
  SET reputation_score = v_new_score,
      last_reputation_update = NOW()
  WHERE id = p_user_id;

  -- Log history
  INSERT INTO reputation_history (
    user_id,
    change_amount,
    reason,
    previous_score,
    new_score,
    pool_id,
    transaction_id
  ) VALUES (
    p_user_id,
    p_change_amount,
    p_reason,
    v_old_score,
    v_new_score,
    p_pool_id,
    p_transaction_id
  );

  -- Auto-assign badges based on new score
  PERFORM assign_badges(p_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 18. Function to assign badges automatically
CREATE OR REPLACE FUNCTION assign_badges(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  v_badge RECORD;
  v_user_value INT;
  v_user_percentage DECIMAL;
  v_is_defaulter BOOLEAN;
  v_is_banned BOOLEAN;
BEGIN
  SELECT 
    reputation_score,
    on_time_payment_percentage,
    pools_completed,
    is_defaulter,
    is_banned
  INTO 
    v_user_value,
    v_user_percentage,
    v_user_value,
    v_is_defaulter,
    v_is_banned
  FROM profiles
  WHERE id = p_user_id;

  FOR v_badge IN SELECT * FROM badges LOOP
    CASE v_badge.requirement_type
      WHEN 'reputation' THEN
        IF v_user_value >= v_badge.requirement_value THEN
          INSERT INTO user_badges (user_id, badge_id)
          VALUES (p_user_id, v_badge.id)
          ON CONFLICT DO NOTHING;
        END IF;
      
      WHEN 'on_time_percentage' THEN
        IF v_user_percentage >= v_badge.requirement_value THEN
          INSERT INTO user_badges (user_id, badge_id)
          VALUES (p_user_id, v_badge.id)
          ON CONFLICT DO NOTHING;
        END IF;
      
      WHEN 'pools_completed' THEN
        SELECT pools_completed INTO v_user_value FROM profiles WHERE id = p_user_id;
        IF v_user_value >= v_badge.requirement_value THEN
          INSERT INTO user_badges (user_id, badge_id)
          VALUES (p_user_id, v_badge.id)
          ON CONFLICT DO NOTHING;
        END IF;
      
      WHEN 'is_defaulter' THEN
        IF v_is_defaulter THEN
          INSERT INTO user_badges (user_id, badge_id)
          VALUES (p_user_id, v_badge.id)
          ON CONFLICT DO NOTHING;
        END IF;
      
      WHEN 'is_banned' THEN
        IF v_is_banned THEN
          INSERT INTO user_badges (user_id, badge_id)
          VALUES (p_user_id, v_badge.id)
          ON CONFLICT DO NOTHING;
        END IF;
    END CASE;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 19. Function to mark user as defaulter
CREATE OR REPLACE FUNCTION mark_as_defaulter(
  p_user_id UUID,
  p_pool_id UUID,
  p_round_number INT,
  p_amount_owed DECIMAL(10,2),
  p_reason VARCHAR(255)
)
RETURNS VOID AS $$
BEGIN
  -- Update profile
  UPDATE profiles
  SET is_defaulter = true,
      defaulted_at = NOW(),
      pools_defaulted = pools_defaulted + 1,
      reputation_score = 0
  WHERE id = p_user_id;

  -- Log default event
  INSERT INTO default_events (user_id, pool_id, round_number, amount_owed, reason)
  VALUES (p_user_id, p_pool_id, p_round_number, p_amount_owed, p_reason);

  -- Update reputation
  PERFORM update_reputation(
    p_user_id,
    -100,
    'Defaulted on pool',
    p_pool_id,
    NULL
  );

  -- Notify all pool members
  INSERT INTO notifications (user_id, type, title, message, data)
  SELECT 
    pm.user_id,
    'default_alert',
    'Member Defaulted',
    (SELECT full_name FROM profiles WHERE id = p_user_id) || ' has defaulted on the pool',
    json_build_object('pool_id', p_pool_id, 'defaulter_id', p_user_id)
  FROM pool_members pm
  WHERE pm.pool_id = p_pool_id
  AND pm.user_id != p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 20. Function to add to blacklist
CREATE OR REPLACE FUNCTION add_to_blacklist(
  p_user_id UUID,
  p_reason TEXT,
  p_permanent BOOLEAN DEFAULT true
)
RETURNS VOID AS $$
DECLARE
  v_phone VARCHAR(20);
  v_email VARCHAR(255);
BEGIN
  -- Get user details
  SELECT phone, email INTO v_phone, v_email
  FROM profiles
  WHERE id = p_user_id;

  -- Ban user
  UPDATE profiles
  SET is_banned = true
  WHERE id = p_user_id;

  -- Add to blacklist
  INSERT INTO blacklist (
    user_id,
    phone_number,
    email,
    reason,
    blacklisted_by,
    expires_at
  ) VALUES (
    p_user_id,
    v_phone,
    v_email,
    p_reason,
    auth.uid(),
    CASE WHEN p_permanent THEN NULL ELSE NOW() + INTERVAL '1 year' END
  );

  -- Update reputation
  PERFORM update_reputation(
    p_user_id,
    -100,
    'Banned from platform',
    NULL,
    NULL
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 21. Function to check if user is blacklisted
CREATE OR REPLACE FUNCTION is_blacklisted(
  p_phone VARCHAR(20) DEFAULT NULL,
  p_email VARCHAR(255) DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM blacklist
    WHERE is_active = true
    AND (expires_at IS NULL OR expires_at > NOW())
    AND (
      (p_phone IS NOT NULL AND phone_number = p_phone)
      OR (p_email IS NOT NULL AND email = p_email)
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 22. Trigger to update on-time payment percentage
CREATE OR REPLACE FUNCTION update_payment_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND NEW.transaction_type = 'contribution' THEN
    UPDATE profiles
    SET total_payments_made = total_payments_made + 1,
        on_time_payments = on_time_payments + 1,
        on_time_payment_percentage = (
          CASE 
            WHEN total_payments_made + 1 = 0 THEN 100
            ELSE ((on_time_payments + 1)::DECIMAL / (total_payments_made + 1)) * 100
          END
        )
    WHERE id = NEW.user_id;

    -- Update reputation
    PERFORM update_reputation(
      NEW.user_id,
      5,
      'On-time payment',
      NEW.pool_id,
      NEW.id
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_payment_stats_trigger ON transactions;
CREATE TRIGGER update_payment_stats_trigger
AFTER INSERT OR UPDATE ON transactions
FOR EACH ROW
EXECUTE FUNCTION update_payment_stats();

-- 23. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_profiles_reputation ON profiles(reputation_score DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_defaulter ON profiles(is_defaulter);
CREATE INDEX IF NOT EXISTS idx_user_badges_user ON user_badges(user_id);
CREATE INDEX IF NOT EXISTS idx_reputation_history_user ON reputation_history(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewee ON user_reviews(reviewee_id);
CREATE INDEX IF NOT EXISTS idx_blacklist_active ON blacklist(is_active, phone_number, email);

-- Success message
SELECT 'Reputation & Social Pressure System created successfully!' as status;
