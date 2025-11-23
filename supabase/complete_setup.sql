-- ============================================
-- Coin Circle - Complete Database Setup
-- ============================================
-- Run this entire file in Supabase SQL Editor
-- ============================================

-- CRITICAL: Drop existing tables to ensure fresh setup
-- This fixes "column does not exist" errors by recreating tables correctly
DROP TABLE IF EXISTS bids CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS winner_history CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS pool_members CASCADE;
DROP TABLE IF EXISTS pools CASCADE;
DROP TABLE IF EXISTS wallets CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- MIGRATION 001: Create Profiles Table
-- ============================================

CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  phone_number TEXT,
  avatar_url TEXT,
  date_of_birth DATE,
  address JSONB,
  kyc_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);

-- ============================================
-- MIGRATION 002: Create Wallets Table
-- ============================================

CREATE TABLE IF NOT EXISTS wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
  available_balance DECIMAL(15, 2) DEFAULT 0.00 CHECK (available_balance >= 0),
  locked_balance DECIMAL(15, 2) DEFAULT 0.00 CHECK (locked_balance >= 0),
  total_winnings DECIMAL(15, 2) DEFAULT 0.00 CHECK (total_winnings >= 0),
  currency TEXT DEFAULT 'INR' NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own wallet"
  ON wallets FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own wallet"
  ON wallets FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own wallet"
  ON wallets FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.handle_new_profile()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.wallets (user_id, currency)
  VALUES (NEW.id, 'INR');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_profile_created ON profiles;
CREATE TRIGGER on_profile_created
  AFTER INSERT ON profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_profile();

CREATE TRIGGER set_wallet_updated_at
  BEFORE UPDATE ON wallets
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);

-- ============================================
-- MIGRATION 003: Create Pools Table
-- ============================================

DO $$ BEGIN
  CREATE TYPE pool_type_enum AS ENUM ('fixed', 'bidding', 'lottery');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE pool_status_enum AS ENUM ('pending', 'active', 'completed', 'cancelled');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE pool_privacy_enum AS ENUM ('public', 'private', 'invite-only');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE frequency_enum AS ENUM ('daily', 'weekly', 'monthly');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS pools (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  pool_type pool_type_enum NOT NULL DEFAULT 'fixed',
  contribution_amount DECIMAL(15, 2) NOT NULL CHECK (contribution_amount > 0),
  total_amount DECIMAL(15, 2) NOT NULL CHECK (total_amount > 0),
  max_members INTEGER NOT NULL CHECK (max_members > 0 AND max_members <= 100),
  current_members INTEGER DEFAULT 0 CHECK (current_members >= 0 AND current_members <= max_members),
  frequency frequency_enum NOT NULL DEFAULT 'monthly',
  start_date DATE NOT NULL,
  end_date DATE,
  status pool_status_enum DEFAULT 'pending',
  current_round INTEGER DEFAULT 0 CHECK (current_round >= 0),
  total_rounds INTEGER NOT NULL CHECK (total_rounds > 0),
  auto_debit BOOLEAN DEFAULT FALSE,
  privacy pool_privacy_enum DEFAULT 'public',
  rules JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT valid_dates CHECK (end_date IS NULL OR end_date > start_date),
  CONSTRAINT valid_total_amount CHECK (total_amount = contribution_amount * max_members)
);

-- Add privacy column if it doesn't exist (for existing tables)
DO $$ 
BEGIN 
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pools' AND column_name = 'privacy') THEN
    ALTER TABLE pools ADD COLUMN privacy pool_privacy_enum DEFAULT 'public';
  END IF;
END $$;

ALTER TABLE pools ENABLE ROW LEVEL SECURITY;

-- Policy "Anyone can view public pools" moved to after pool_members table creation
-- because it references pool_members table


CREATE POLICY "Authenticated users can create pools"
  ON pools FOR INSERT
  WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Creators can update their pools"
  ON pools FOR UPDATE
  USING (auth.uid() = creator_id);

CREATE POLICY "Creators can delete their pools"
  ON pools FOR DELETE
  USING (auth.uid() = creator_id AND status = 'pending');

CREATE TRIGGER set_pool_updated_at
  BEFORE UPDATE ON pools
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_pools_creator ON pools(creator_id);
CREATE INDEX IF NOT EXISTS idx_pools_status ON pools(status);
CREATE INDEX IF NOT EXISTS idx_pools_privacy ON pools(privacy);
CREATE INDEX IF NOT EXISTS idx_pools_start_date ON pools(start_date);
CREATE INDEX IF NOT EXISTS idx_pools_type ON pools(pool_type);

-- ============================================
-- MIGRATION 004: Create Pool Members Table
-- ============================================

DO $$ BEGIN
  CREATE TYPE member_role_enum AS ENUM ('admin', 'member');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE member_status_enum AS ENUM ('active', 'inactive', 'removed');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE payment_status_enum AS ENUM ('pending', 'paid', 'overdue');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS pool_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  role member_role_enum DEFAULT 'member' NOT NULL,
  join_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status member_status_enum DEFAULT 'active' NOT NULL,
  total_contributed DECIMAL(15, 2) DEFAULT 0.00 CHECK (total_contributed >= 0),
  total_won DECIMAL(15, 2) DEFAULT 0.00 CHECK (total_won >= 0),
  payment_status payment_status_enum DEFAULT 'pending',
  last_payment_date TIMESTAMP WITH TIME ZONE,
  has_won BOOLEAN DEFAULT FALSE,
  win_round INTEGER CHECK (win_round > 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(pool_id, user_id)
);

ALTER TABLE pool_members ENABLE ROW LEVEL SECURITY;

-- Add the policy for pools that references pool_members here
CREATE POLICY "Anyone can view public pools"
  ON pools FOR SELECT
  USING (
    privacy = 'public' 
    OR creator_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM pool_members 
      WHERE pool_id = pools.id AND user_id = auth.uid()
    )
  );

CREATE POLICY "Pool members can view members of their pools"
  ON pool_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM pools 
      WHERE id = pool_members.pool_id 
      AND (privacy = 'public' OR creator_id = auth.uid())
    )
    OR user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM pool_members pm
      WHERE pm.pool_id = pool_members.pool_id AND pm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can join pools"
  ON pool_members FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM pools 
      WHERE id = pool_id 
      AND status = 'pending'
      AND current_members < max_members
    )
  );

CREATE POLICY "Pool admins can update members"
  ON pool_members FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM pool_members pm
      WHERE pm.pool_id = pool_members.pool_id 
      AND pm.user_id = auth.uid()
      AND pm.role = 'admin'
    )
    OR user_id = auth.uid()
  );

CREATE POLICY "Users can leave pools or admins can remove members"
  ON pool_members FOR DELETE
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM pool_members pm
      WHERE pm.pool_id = pool_members.pool_id 
      AND pm.user_id = auth.uid()
      AND pm.role = 'admin'
    )
  );

CREATE OR REPLACE FUNCTION public.update_pool_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE pools 
    SET current_members = current_members + 1
    WHERE id = NEW.pool_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE pools 
    SET current_members = current_members - 1
    WHERE id = OLD.pool_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_pool_member_added ON pool_members;
CREATE TRIGGER on_pool_member_added
  AFTER INSERT ON pool_members
  FOR EACH ROW EXECUTE FUNCTION public.update_pool_member_count();

DROP TRIGGER IF EXISTS on_pool_member_removed ON pool_members;
CREATE TRIGGER on_pool_member_removed
  AFTER DELETE ON pool_members
  FOR EACH ROW EXECUTE FUNCTION public.update_pool_member_count();

CREATE TRIGGER set_pool_member_updated_at
  BEFORE UPDATE ON pool_members
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_pool_members_pool ON pool_members(pool_id);
CREATE INDEX IF NOT EXISTS idx_pool_members_user ON pool_members(user_id);
CREATE INDEX IF NOT EXISTS idx_pool_members_status ON pool_members(status);
CREATE INDEX IF NOT EXISTS idx_pool_members_payment_status ON pool_members(payment_status);

-- ============================================
-- MIGRATION 005: Create Transactions Table
-- ============================================

DO $$ BEGIN
  CREATE TYPE transaction_type_enum AS ENUM ('deposit', 'withdrawal', 'contribution', 'winning', 'refund');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE transaction_status_enum AS ENUM ('pending', 'completed', 'failed', 'cancelled');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE payment_method_enum AS ENUM ('bank_transfer', 'upi', 'card', 'wallet');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  pool_id UUID REFERENCES pools(id) ON DELETE SET NULL,
  transaction_type transaction_type_enum NOT NULL,
  amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
  currency TEXT DEFAULT 'INR' NOT NULL,
  status transaction_status_enum DEFAULT 'pending' NOT NULL,
  payment_method payment_method_enum,
  payment_reference TEXT,
  description TEXT,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own transactions"
  ON transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "System can update transactions"
  ON transactions FOR UPDATE
  USING (false);

CREATE TRIGGER set_transaction_updated_at
  BEFORE UPDATE ON transactions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_transactions_user ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_pool ON transactions(pool_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC);

CREATE OR REPLACE FUNCTION public.handle_transaction_completion()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    CASE NEW.transaction_type
      WHEN 'deposit' THEN
        UPDATE wallets 
        SET available_balance = available_balance + NEW.amount
        WHERE user_id = NEW.user_id;
        
      WHEN 'withdrawal' THEN
        UPDATE wallets 
        SET available_balance = available_balance - NEW.amount
        WHERE user_id = NEW.user_id;
        
      WHEN 'contribution' THEN
        UPDATE wallets 
        SET available_balance = available_balance - NEW.amount,
            locked_balance = locked_balance + NEW.amount
        WHERE user_id = NEW.user_id;
        
        UPDATE pool_members
        SET total_contributed = total_contributed + NEW.amount,
            payment_status = 'paid',
            last_payment_date = NOW()
        WHERE pool_id = NEW.pool_id AND user_id = NEW.user_id;
        
      WHEN 'winning' THEN
        UPDATE wallets 
        SET locked_balance = locked_balance - NEW.amount,
            available_balance = available_balance + NEW.amount,
            total_winnings = total_winnings + NEW.amount
        WHERE user_id = NEW.user_id;
        
        UPDATE pool_members
        SET total_won = total_won + NEW.amount
        WHERE pool_id = NEW.pool_id AND user_id = NEW.user_id;
        
      WHEN 'refund' THEN
        UPDATE wallets 
        SET available_balance = available_balance + NEW.amount
        WHERE user_id = NEW.user_id;
    END CASE;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_transaction_completed ON transactions;
CREATE TRIGGER on_transaction_completed
  AFTER UPDATE ON transactions
  FOR EACH ROW 
  WHEN (NEW.status = 'completed' AND OLD.status != 'completed')
  EXECUTE FUNCTION public.handle_transaction_completion();

-- ============================================
-- MIGRATION 006: Create Winner History Table
-- ============================================

DO $$ BEGIN
  CREATE TYPE selection_method_enum AS ENUM ('random', 'bid', 'lottery');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE payout_status_enum AS ENUM ('pending', 'completed', 'failed');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS winner_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  round_number INTEGER NOT NULL CHECK (round_number > 0),
  winning_amount DECIMAL(15, 2) NOT NULL CHECK (winning_amount > 0),
  selection_method selection_method_enum NOT NULL,
  bid_amount DECIMAL(15, 2) CHECK (bid_amount >= 0),
  selected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  payout_status payout_status_enum DEFAULT 'pending',
  payout_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(pool_id, round_number),
  CONSTRAINT valid_bid_amount CHECK (
    (selection_method = 'bid' AND bid_amount IS NOT NULL) OR
    (selection_method != 'bid' AND bid_amount IS NULL)
  )
);

ALTER TABLE winner_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pool members can view winner history"
  ON winner_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM pool_members
      WHERE pool_id = winner_history.pool_id 
      AND user_id = auth.uid()
    )
    OR user_id = auth.uid()
  );

CREATE POLICY "System can insert winner history"
  ON winner_history FOR INSERT
  WITH CHECK (false);

CREATE POLICY "System can update winner history"
  ON winner_history FOR UPDATE
  USING (false);

CREATE OR REPLACE FUNCTION public.handle_winner_selection()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE pool_members
  SET has_won = TRUE,
      win_round = NEW.round_number
  WHERE pool_id = NEW.pool_id AND user_id = NEW.user_id;
  
  UPDATE pools
  SET current_round = NEW.round_number
  WHERE id = NEW.pool_id;
  
  INSERT INTO transactions (
    user_id,
    pool_id,
    transaction_type,
    amount,
    status,
    description
  ) VALUES (
    NEW.user_id,
    NEW.pool_id,
    'winning',
    NEW.winning_amount,
    'pending',
    'Pool round ' || NEW.round_number || ' winning'
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_winner_selected ON winner_history;
CREATE TRIGGER on_winner_selected
  AFTER INSERT ON winner_history
  FOR EACH ROW EXECUTE FUNCTION public.handle_winner_selection();

CREATE INDEX IF NOT EXISTS idx_winner_history_pool ON winner_history(pool_id);
CREATE INDEX IF NOT EXISTS idx_winner_history_user ON winner_history(user_id);
CREATE INDEX IF NOT EXISTS idx_winner_history_round ON winner_history(pool_id, round_number);
CREATE INDEX IF NOT EXISTS idx_winner_history_payout_status ON winner_history(payout_status);

-- ============================================
-- MIGRATION 007: Create Notifications Table
-- ============================================

DO $$ BEGIN
  CREATE TYPE notification_type_enum AS ENUM (
    'payment_reminder',
    'draw_announcement',
    'pool_update',
    'member_activity',
    'system'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE notification_category_enum AS ENUM ('info', 'warning', 'success', 'error');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type notification_type_enum NOT NULL,
  category notification_category_enum DEFAULT 'info',
  is_read BOOLEAN DEFAULT FALSE,
  action_url TEXT,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notifications"
  ON notifications FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (true);

CREATE OR REPLACE FUNCTION public.handle_notification_read()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_read = TRUE AND OLD.is_read = FALSE THEN
    NEW.read_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_notification_read ON notifications;
CREATE TRIGGER on_notification_read
  BEFORE UPDATE ON notifications
  FOR EACH ROW 
  WHEN (NEW.is_read = TRUE AND OLD.is_read = FALSE)
  EXECUTE FUNCTION public.handle_notification_read();

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

CREATE OR REPLACE FUNCTION public.send_notification(
  p_user_id UUID,
  p_title TEXT,
  p_message TEXT,
  p_type notification_type_enum,
  p_category notification_category_enum DEFAULT 'info',
  p_action_url TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  notification_id UUID;
BEGIN
  INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    category,
    action_url,
    metadata
  ) VALUES (
    p_user_id,
    p_title,
    p_message,
    p_type,
    p_category,
    p_action_url,
    p_metadata
  ) RETURNING id INTO notification_id;
  
  RETURN notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- MIGRATION 008: Create Bids Table
-- ============================================

DO $$ BEGIN
  CREATE TYPE bid_status_enum AS ENUM ('active', 'won', 'lost', 'cancelled');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS bids (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  round_number INTEGER NOT NULL CHECK (round_number > 0),
  bid_amount DECIMAL(15, 2) NOT NULL CHECK (bid_amount > 0),
  status bid_status_enum DEFAULT 'active' NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(pool_id, user_id, round_number)
);

ALTER TABLE bids ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pool members can view bids in their pools"
  ON bids FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM pool_members
      WHERE pool_id = bids.pool_id 
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Pool members can create bids"
  ON bids FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM pool_members
      WHERE pool_id = bids.pool_id 
      AND user_id = auth.uid()
      AND status = 'active'
      AND has_won = FALSE
    )
  );

CREATE POLICY "Users can update their own bids"
  ON bids FOR UPDATE
  USING (
    auth.uid() = user_id 
    AND status = 'active'
  );

CREATE POLICY "Users can cancel their own bids"
  ON bids FOR DELETE
  USING (
    auth.uid() = user_id 
    AND status = 'active'
  );

CREATE TRIGGER set_bid_updated_at
  BEFORE UPDATE ON bids
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_bids_pool ON bids(pool_id);
CREATE INDEX IF NOT EXISTS idx_bids_user ON bids(user_id);
CREATE INDEX IF NOT EXISTS idx_bids_round ON bids(pool_id, round_number);
CREATE INDEX IF NOT EXISTS idx_bids_status ON bids(status);
CREATE INDEX IF NOT EXISTS idx_bids_amount ON bids(pool_id, round_number, bid_amount DESC);

CREATE OR REPLACE FUNCTION public.get_highest_bid(
  p_pool_id UUID,
  p_round_number INTEGER
)
RETURNS TABLE (
  bid_id UUID,
  user_id UUID,
  bid_amount DECIMAL(15, 2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    id,
    bids.user_id,
    bids.bid_amount
  FROM bids
  WHERE pool_id = p_pool_id
    AND round_number = p_round_number
    AND status = 'active'
  ORDER BY bid_amount DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.mark_losing_bids(
  p_pool_id UUID,
  p_round_number INTEGER,
  p_winning_bid_id UUID
)
RETURNS void AS $$
BEGIN
  UPDATE bids
  SET status = 'lost'
  WHERE pool_id = p_pool_id
    AND round_number = p_round_number
    AND id != p_winning_bid_id
    AND status = 'active';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Setup Complete!
-- ============================================
-- All tables, policies, triggers, and functions have been created.
-- You can now use the Coin Circle app with Supabase backend!
-- ============================================
