-- ============================================
-- COIN CIRCLE - COMPLETE DATABASE SETUP
-- Run this entire script in Supabase SQL Editor
-- ============================================

-- STEP 1: Create all security tables
-- From: security_tables.sql

-- Security settings table
CREATE TABLE IF NOT EXISTS public.user_security_settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  pin_hash TEXT,
  pin_enabled BOOLEAN DEFAULT false,
  biometric_enabled BOOLEAN DEFAULT false,
  two_factor_enabled BOOLEAN DEFAULT false,
  two_factor_method TEXT,
  daily_transaction_limit NUMERIC DEFAULT 50000,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Security events log
CREATE TABLE IF NOT EXISTS public.security_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  ip_address TEXT,
  device_info TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Transaction velocity tracking
CREATE TABLE IF NOT EXISTS public.transaction_velocity (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  transaction_count INTEGER DEFAULT 0,
  window_start TIMESTAMPTZ DEFAULT NOW(),
  window_end TIMESTAMPTZ DEFAULT NOW() + INTERVAL '5 minutes',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trusted devices
CREATE TABLE IF NOT EXISTS public.trusted_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  device_fingerprint TEXT NOT NULL,
  device_name TEXT,
  last_used TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, device_fingerprint)
);

-- STEP 2: Create advanced security tables
-- From: advanced_security.sql

-- Rate limiting table
CREATE TABLE IF NOT EXISTS public.api_rate_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  endpoint TEXT NOT NULL,
  request_count INTEGER DEFAULT 1,
  window_start TIMESTAMPTZ DEFAULT NOW(),
  window_end TIMESTAMPTZ DEFAULT NOW() + INTERVAL '1 minute',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, endpoint, window_start)
);

-- IP whitelist for admin operations
CREATE TABLE IF NOT EXISTS public.admin_ip_whitelist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ip_address TEXT NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- TDS records for tax compliance
CREATE TABLE IF NOT EXISTS public.tds_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  transaction_id UUID REFERENCES transactions(id),
  winning_amount NUMERIC NOT NULL,
  tds_amount NUMERIC NOT NULL,
  tds_percentage NUMERIC DEFAULT 30.0,
  financial_year TEXT NOT NULL,
  quarter TEXT NOT NULL,
  pan_number TEXT,
  form_16a_issued BOOLEAN DEFAULT false,
  form_16a_url TEXT,
  deduction_date TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Geo-location tracking
CREATE TABLE IF NOT EXISTS public.user_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  latitude NUMERIC,
  longitude NUMERIC,
  city TEXT,
  state TEXT,
  country TEXT DEFAULT 'India',
  ip_address TEXT,
  action_type TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Multiple account detection
CREATE TABLE IF NOT EXISTS public.account_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  linked_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  link_type TEXT NOT NULL,
  confidence_score NUMERIC DEFAULT 0.0,
  metadata JSONB DEFAULT '{}'::jsonb,
  is_flagged BOOLEAN DEFAULT false,
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, linked_user_id, link_type)
);

-- STEP 3: Enable Row Level Security
ALTER TABLE public.user_security_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaction_velocity ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trusted_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_rate_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_ip_whitelist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tds_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_links ENABLE ROW LEVEL SECURITY;

-- STEP 4: Create RLS Policies

-- Security settings policies
DROP POLICY IF EXISTS "Users can view own security settings" ON public.user_security_settings;
CREATE POLICY "Users can view own security settings" ON public.user_security_settings
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own security settings" ON public.user_security_settings;
CREATE POLICY "Users can update own security settings" ON public.user_security_settings
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own security settings" ON public.user_security_settings;
CREATE POLICY "Users can insert own security settings" ON public.user_security_settings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Security events policies
DROP POLICY IF EXISTS "Users can view own security events" ON public.security_events;
CREATE POLICY "Users can view own security events" ON public.security_events
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert security events" ON public.security_events;
CREATE POLICY "System can insert security events" ON public.security_events
  FOR INSERT WITH CHECK (true);

-- Rate limits policies
DROP POLICY IF EXISTS "Users can view own rate limits" ON public.api_rate_limits;
CREATE POLICY "Users can view own rate limits" ON public.api_rate_limits
  FOR SELECT USING (auth.uid() = user_id);

-- TDS records policies
DROP POLICY IF EXISTS "Users can view own TDS records" ON public.tds_records;
CREATE POLICY "Users can view own TDS records" ON public.tds_records
  FOR SELECT USING (auth.uid() = user_id);

-- User locations policies
DROP POLICY IF EXISTS "Users can view own locations" ON public.user_locations;
CREATE POLICY "Users can view own locations" ON public.user_locations
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert locations" ON public.user_locations;
CREATE POLICY "System can insert locations" ON public.user_locations
  FOR INSERT WITH CHECK (true);

-- Trusted devices policies
DROP POLICY IF EXISTS "Users can view own devices" ON public.trusted_devices;
CREATE POLICY "Users can view own devices" ON public.trusted_devices
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own devices" ON public.trusted_devices;
CREATE POLICY "Users can insert own devices" ON public.trusted_devices
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own devices" ON public.trusted_devices;
CREATE POLICY "Users can update own devices" ON public.trusted_devices
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own devices" ON public.trusted_devices;
CREATE POLICY "Users can delete own devices" ON public.trusted_devices
  FOR DELETE USING (auth.uid() = user_id);

-- STEP 5: Create Indexes
CREATE INDEX IF NOT EXISTS idx_security_events_user_id ON public.security_events(user_id);
CREATE INDEX IF NOT EXISTS idx_security_events_created_at ON public.security_events(created_at);
CREATE INDEX IF NOT EXISTS idx_transaction_velocity_user_id ON public.transaction_velocity(user_id);
CREATE INDEX IF NOT EXISTS idx_trusted_devices_user_id ON public.trusted_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_rate_limits_user_endpoint ON public.api_rate_limits(user_id, endpoint, window_start);
CREATE INDEX IF NOT EXISTS idx_tds_records_user_id ON public.tds_records(user_id);
CREATE INDEX IF NOT EXISTS idx_tds_records_financial_year ON public.tds_records(financial_year);
CREATE INDEX IF NOT EXISTS idx_user_locations_user_id ON public.user_locations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_locations_created_at ON public.user_locations(created_at);
CREATE INDEX IF NOT EXISTS idx_account_links_user_id ON public.account_links(user_id);
CREATE INDEX IF NOT EXISTS idx_account_links_flagged ON public.account_links(is_flagged) WHERE is_flagged = true;

-- Performance indexes for existing tables
CREATE INDEX IF NOT EXISTS idx_transactions_user_created ON public.transactions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pool_members_pool_status ON public.pool_members(pool_id, status);
CREATE INDEX IF NOT EXISTS idx_wallets_user ON public.wallets(user_id);

-- ============================================
-- SUCCESS! Tables and indexes created.
-- Next: Run the RPC functions script
-- ============================================
