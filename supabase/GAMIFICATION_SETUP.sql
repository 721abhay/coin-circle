-- GAMIFICATION & REVIEWS SETUP
-- Run this in Supabase SQL Editor

-- 1. Create Badges Table
CREATE TABLE IF NOT EXISTS badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  icon_url TEXT,
  xp_reward INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create User Badges Table
CREATE TABLE IF NOT EXISTS user_badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  badge_id UUID REFERENCES badges(id) ON DELETE CASCADE,
  earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, badge_id)
);

-- 3. Create Challenges Table
CREATE TABLE IF NOT EXISTS challenges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  type VARCHAR(50) NOT NULL, -- 'daily', 'weekly', 'monthly'
  target_value INTEGER NOT NULL,
  points_reward INTEGER DEFAULT 0,
  start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create User Challenges Table
CREATE TABLE IF NOT EXISTS user_challenges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE,
  current_progress INTEGER DEFAULT 0,
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMP WITH TIME ZONE,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, challenge_id)
);

-- 5. Create Reviews Table
CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reviewer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  reviewee_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  pool_id UUID, -- Optional, if review is linked to a specific pool
  rating NUMERIC(2, 1) NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Create Gamification Profiles Table (if not exists)
CREATE TABLE IF NOT EXISTS gamification_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  current_xp INTEGER DEFAULT 0,
  current_level INTEGER DEFAULT 1,
  current_streak INTEGER DEFAULT 0,
  last_activity_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Enable RLS
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE gamification_profiles ENABLE ROW LEVEL SECURITY;

-- 8. Create Policies (Simplified for demo)
-- Badges: Public read
CREATE POLICY "Badges are viewable by everyone" ON badges FOR SELECT USING (true);

-- User Badges: View own, insert own (system usually does this, but for demo allow insert)
CREATE POLICY "Users can view own badges" ON user_badges FOR SELECT USING (auth.uid() = user_id);

-- Challenges: Public read
CREATE POLICY "Challenges are viewable by everyone" ON challenges FOR SELECT USING (true);

-- User Challenges: View own, update own
CREATE POLICY "Users can view own challenges" ON user_challenges FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own challenges" ON user_challenges FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can join challenges" ON user_challenges FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Reviews: Public read, insert own
CREATE POLICY "Reviews are viewable by everyone" ON reviews FOR SELECT USING (true);
CREATE POLICY "Users can write reviews" ON reviews FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

-- Gamification Profiles: Public read (for leaderboards), update own
CREATE POLICY "Profiles are viewable by everyone" ON gamification_profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON gamification_profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own profile" ON gamification_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);


-- 9. SEED DATA (So the app isn't empty!)

-- Insert Badges
INSERT INTO badges (name, description, icon_url, xp_reward) VALUES
('Early Adopter', 'Joined in the first month', '🚀', 100),
('First Pool', 'Joined your first pool', '🏊', 50),
('Reliable', 'Paid on time for 3 cycles', '⭐', 200),
('Winner', 'Won a pool pot', '🏆', 500),
('Socialite', 'Referred 5 friends', '🤝', 150),
('Big Saver', 'Contributed over ₹50,000', '💰', 300)
ON CONFLICT DO NOTHING;

-- Insert Challenges
INSERT INTO challenges (title, description, type, target_value, points_reward, end_date) VALUES
('Savings Sprint', 'Save ₹5000 this week', 'weekly', 5000, 100, NOW() + INTERVAL '7 days'),
('Daily Login', 'Check the app daily', 'daily', 1, 10, NOW() + INTERVAL '1 day'),
('Pool Master', 'Join 3 active pools', 'monthly', 3, 300, NOW() + INTERVAL '30 days')
ON CONFLICT DO NOTHING;

-- Insert Mock Reviews (Linked to a random user if possible, or just generic)
-- Note: We can't easily link to real users in SQL seed without knowing IDs.
-- This part is best done via the app or a script that knows user IDs.
-- However, we can create a function to seed reviews for a specific user if needed.

