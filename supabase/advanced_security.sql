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
  action_type TEXT, -- 'login', 'transaction', 'withdrawal'
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Multiple account detection
CREATE TABLE IF NOT EXISTS public.account_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  linked_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  link_type TEXT NOT NULL, -- 'device', 'ip', 'phone', 'email', 'bank_account'
  confidence_score NUMERIC DEFAULT 0.0, -- 0.0 to 1.0
  metadata JSONB DEFAULT '{}'::jsonb,
  is_flagged BOOLEAN DEFAULT false,
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, linked_user_id, link_type)
);

-- RLS Policies
ALTER TABLE public.api_rate_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_ip_whitelist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tds_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_links ENABLE ROW LEVEL SECURITY;

-- Rate limits: Users can view their own
CREATE POLICY "Users can view own rate limits" ON public.api_rate_limits
  FOR SELECT USING (auth.uid() = user_id);

-- Admin IP whitelist: Only admins can view/modify
CREATE POLICY "Admins can manage IP whitelist" ON public.admin_ip_whitelist
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- TDS records: Users can view their own, admins can view all
CREATE POLICY "Users can view own TDS records" ON public.tds_records
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage TDS records" ON public.tds_records
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- User locations: Users can view their own
CREATE POLICY "Users can view own locations" ON public.user_locations
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert locations" ON public.user_locations
  FOR INSERT WITH CHECK (true);

-- Account links: Only admins can view
CREATE POLICY "Admins can view account links" ON public.account_links
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_rate_limits_user_endpoint ON public.api_rate_limits(user_id, endpoint, window_start);
CREATE INDEX IF NOT EXISTS idx_tds_records_user_id ON public.tds_records(user_id);
CREATE INDEX IF NOT EXISTS idx_tds_records_financial_year ON public.tds_records(financial_year);
CREATE INDEX IF NOT EXISTS idx_user_locations_user_id ON public.user_locations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_locations_created_at ON public.user_locations(created_at);
CREATE INDEX IF NOT EXISTS idx_account_links_user_id ON public.account_links(user_id);
CREATE INDEX IF NOT EXISTS idx_account_links_flagged ON public.account_links(is_flagged) WHERE is_flagged = true;

-- RPC for rate limiting check
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
  
  -- Get current count for this minute
  SELECT COALESCE(request_count, 0) INTO v_count
  FROM api_rate_limits
  WHERE user_id = p_user_id 
    AND endpoint = p_endpoint
    AND window_start = v_window_start;
  
  -- If under limit, increment or create
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

-- RPC for TDS calculation and deduction
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
  -- Only deduct TDS if winning > ₹10,000
  IF p_winning_amount <= 10000 THEN
    RETURN jsonb_build_object(
      'tds_applicable', false,
      'gross_amount', p_winning_amount,
      'tds_amount', 0,
      'net_amount', p_winning_amount
    );
  END IF;
  
  -- Calculate TDS (30% for winnings)
  v_tds_amount := ROUND(p_winning_amount * 0.30, 2);
  v_net_amount := p_winning_amount - v_tds_amount;
  
  -- Determine financial year and quarter
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
  
  -- Get PAN number from profile
  SELECT pan_number INTO v_pan_number
  FROM profiles
  WHERE id = p_user_id;
  
  -- Insert TDS record
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

-- RPC for detecting multiple accounts
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
  
  -- Check for same IP address (recent)
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
  
  -- Return all detected links
  RETURN QUERY
  SELECT al.linked_user_id, al.link_type, al.confidence_score, al.metadata
  FROM account_links al
  WHERE al.user_id = p_user_id
  ORDER BY al.confidence_score DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Cleanup old rate limit records (run periodically)
CREATE OR REPLACE FUNCTION cleanup_old_rate_limits()
RETURNS void AS $$
BEGIN
  DELETE FROM api_rate_limits
  WHERE window_end < NOW() - INTERVAL '1 hour';
END;
$$ LANGUAGE plpgsql;
