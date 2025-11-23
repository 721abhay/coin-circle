-- Migration: Gamification and Special Features
-- Description: Adds tables for gamification, special pool features, support, and user preferences.

-- ==========================================
-- 1. User Preferences & Settings
-- ==========================================

ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS accessibility_settings JSONB DEFAULT '{"text_scale": 1.0, "high_contrast": false, "screen_reader": false, "language": "en"}'::jsonb,
ADD COLUMN IF NOT EXISTS currency_settings JSONB DEFAULT '{"primary_currency": "INR", "auto_convert": true}'::jsonb;

-- ==========================================
-- 2. Gamification System
-- ==========================================

-- Gamification Profile (XP, Level, etc.)
CREATE TABLE IF NOT EXISTS gamification_profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    current_xp INTEGER DEFAULT 0,
    current_level INTEGER DEFAULT 1,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    total_points INTEGER DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Streak Logs (Daily/Weekly tracking)
CREATE TABLE IF NOT EXISTS streak_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    activity_date DATE NOT NULL,
    activity_type TEXT NOT NULL, -- 'payment', 'login', etc.
    points_earned INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, activity_date, activity_type)
);

-- Badges Definition
CREATE TABLE IF NOT EXISTS badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    icon_url TEXT,
    category TEXT, -- 'payment', 'social', 'tenure', etc.
    xp_reward INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Badges (Earned Badges)
CREATE TABLE IF NOT EXISTS user_badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    badge_id UUID REFERENCES badges(id) ON DELETE CASCADE,
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, badge_id)
);

-- Challenges Definition
CREATE TABLE IF NOT EXISTS challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL, -- 'daily', 'weekly', 'monthly', 'one_time'
    category TEXT NOT NULL, -- 'payment', 'referral', 'savings'
    target_value INTEGER NOT NULL, -- e.g., 5 payments
    xp_reward INTEGER DEFAULT 0,
    points_reward INTEGER DEFAULT 0,
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Challenges (Progress Tracking)
CREATE TABLE IF NOT EXISTS user_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE,
    current_progress INTEGER DEFAULT 0,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP WITH TIME ZONE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, challenge_id)
);

-- ==========================================
-- 3. Special Pool Features
-- ==========================================

-- Pool Templates
CREATE TABLE IF NOT EXISTS pool_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT, -- 'savings', 'emergency', 'travel', etc.
    default_config JSONB NOT NULL, -- contribution amount, frequency, etc.
    icon_name TEXT,
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Goal-Based Pool Settings
CREATE TABLE IF NOT EXISTS pool_goals (
    pool_id UUID PRIMARY KEY REFERENCES pools(id) ON DELETE CASCADE,
    target_amount NUMERIC(12, 2) NOT NULL,
    target_date TIMESTAMP WITH TIME ZONE,
    milestones JSONB DEFAULT '[]'::jsonb, -- List of milestone amounts/dates
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Recurring Pool Configuration
CREATE TABLE IF NOT EXISTS recurring_pool_configs (
    pool_id UUID PRIMARY KEY REFERENCES pools(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    frequency TEXT NOT NULL, -- 'monthly', 'quarterly', etc.
    next_renewal_date TIMESTAMP WITH TIME ZONE,
    auto_renew BOOLEAN DEFAULT true,
    renewal_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- 4. Support & Content
-- ==========================================

-- Support Tickets
CREATE TABLE IF NOT EXISTS support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    category TEXT NOT NULL,
    subject TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT DEFAULT 'open', -- 'open', 'in_progress', 'resolved', 'closed'
    priority TEXT DEFAULT 'medium', -- 'low', 'medium', 'high'
    attachments JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- FAQs
CREATE TABLE IF NOT EXISTS faqs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category TEXT NOT NULL,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    display_order INTEGER DEFAULT 0,
    is_published BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tutorials
CREATE TABLE IF NOT EXISTS tutorials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    video_url TEXT,
    thumbnail_url TEXT,
    category TEXT,
    duration_seconds INTEGER,
    display_order INTEGER DEFAULT 0,
    is_published BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- 5. RLS Policies
-- ==========================================

-- Enable RLS
ALTER TABLE gamification_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE streak_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE pool_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE pool_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE recurring_pool_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE faqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE tutorials ENABLE ROW LEVEL SECURITY;

-- Gamification Profiles: Users can view their own profile, public can view basic stats (for leaderboards)
CREATE POLICY "Users can view their own gamification profile" ON gamification_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Public can view basic gamification stats" ON gamification_profiles
    FOR SELECT USING (true); -- Refine this later if needed to hide sensitive data

-- Streak Logs: Users can view their own
CREATE POLICY "Users can view their own streak logs" ON streak_logs
    FOR SELECT USING (auth.uid() = user_id);

-- Badges: Public read
CREATE POLICY "Everyone can view badges" ON badges
    FOR SELECT USING (true);

-- User Badges: Users can view their own, public can view others' earned badges
CREATE POLICY "Everyone can view user badges" ON user_badges
    FOR SELECT USING (true);

-- Challenges: Public read
CREATE POLICY "Everyone can view challenges" ON challenges
    FOR SELECT USING (true);

-- User Challenges: Users can view/manage their own
CREATE POLICY "Users can view their own challenges" ON user_challenges
    FOR SELECT USING (auth.uid() = user_id);
    
CREATE POLICY "Users can join challenges" ON user_challenges
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their challenge progress" ON user_challenges
    FOR UPDATE USING (auth.uid() = user_id);

-- Pool Templates: Public read
CREATE POLICY "Everyone can view pool templates" ON pool_templates
    FOR SELECT USING (true);

-- Pool Goals: Members of the pool can view
CREATE POLICY "Pool members can view goals" ON pool_goals
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM pool_members 
            WHERE pool_members.pool_id = pool_goals.pool_id 
            AND pool_members.user_id = auth.uid()
        )
    );

-- Recurring Configs: Members can view
CREATE POLICY "Pool members can view recurring config" ON recurring_pool_configs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM pool_members 
            WHERE pool_members.pool_id = recurring_pool_configs.pool_id 
            AND pool_members.user_id = auth.uid()
        )
    );

-- Support Tickets: Users can view/create their own
CREATE POLICY "Users can view their own tickets" ON support_tickets
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create tickets" ON support_tickets
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- FAQs & Tutorials: Public read
CREATE POLICY "Everyone can view FAQs" ON faqs
    FOR SELECT USING (is_published = true);

CREATE POLICY "Everyone can view Tutorials" ON tutorials
    FOR SELECT USING (is_published = true);

-- ==========================================
-- 6. Triggers & Functions
-- ==========================================

-- Function to create gamification profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user_gamification()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.gamification_profiles (user_id)
  VALUES (new.id);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user gamification profile
-- Note: This assumes the 'profiles' table creation trigger exists. 
-- We can attach this to the 'profiles' table insert or 'auth.users' insert.
-- Attaching to 'profiles' is safer if we want to ensure profile exists first.
CREATE TRIGGER on_profile_created_gamification
  AFTER INSERT ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user_gamification();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_support_tickets_updated_at
    BEFORE UPDATE ON support_tickets
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
