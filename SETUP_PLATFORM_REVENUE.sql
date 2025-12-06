-- ========================================
-- PLATFORM REVENUE SYSTEM - DATABASE SETUP
-- ========================================
-- Run this in Supabase SQL Editor

-- 1. Create platform_revenue table
CREATE TABLE IF NOT EXISTS platform_revenue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE,
  type TEXT CHECK (type IN ('late_fee', 'joining_fee')) NOT NULL,
  amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 2. Add joining_fee column to pools table
ALTER TABLE pools ADD COLUMN IF NOT EXISTS joining_fee DECIMAL(10,2) DEFAULT 20.00;

-- 3. Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_platform_revenue_type ON platform_revenue(type);
CREATE INDEX IF NOT EXISTS idx_platform_revenue_created ON platform_revenue(created_at);
CREATE INDEX IF NOT EXISTS idx_platform_revenue_user ON platform_revenue(user_id);
CREATE INDEX IF NOT EXISTS idx_platform_revenue_pool ON platform_revenue(pool_id);

-- 4. Enable RLS on platform_revenue
ALTER TABLE platform_revenue ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for platform_revenue

-- Admins can see all revenue
CREATE POLICY "Admins can view all platform revenue"
  ON platform_revenue FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

-- Users can see their own fees
CREATE POLICY "Users can view their own fees"
  ON platform_revenue FOR SELECT
  USING (user_id = auth.uid());

-- Only system can insert revenue records (via service role)
-- No policy needed - will be inserted by backend

-- 6. Create function to calculate late fee
CREATE OR REPLACE FUNCTION calculate_late_fee(days_late INTEGER)
RETURNS DECIMAL(10,2) AS $$
BEGIN
  -- Grace period: 0-1 days = no fee
  IF days_late <= 1 THEN
    RETURN 0;
  END IF;
  
  -- Calculate fee: ₹30 base + ₹20 for every 2 days
  -- 2-3 days = ₹50
  -- 4-5 days = ₹70
  -- 6-7 days = ₹90
  -- etc.
  DECLARE
    periods INTEGER;
  BEGIN
    periods := CEIL((days_late - 1.0) / 2.0);
    RETURN 30 + (periods * 20);
  END;
END;
$$ LANGUAGE plpgsql;

-- 7. Test the late fee calculation
SELECT 
  days_late,
  calculate_late_fee(days_late) as late_fee
FROM generate_series(0, 10) as days_late;

-- Expected output:
-- 0 days = ₹0
-- 1 day = ₹0
-- 2 days = ₹50
-- 3 days = ₹50
-- 4 days = ₹70
-- 5 days = ₹70
-- 6 days = ₹90
-- etc.

-- 8. Verify setup
SELECT 'Platform Revenue System Setup Complete!' as status;
