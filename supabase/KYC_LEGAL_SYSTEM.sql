-- ========================================
-- KYC VERIFICATION & LEGAL ENFORCEMENT SYSTEM
-- Run this AFTER APPLY_MIGRATIONS.sql
-- ========================================

-- 1. KYC Documents Table
CREATE TABLE IF NOT EXISTS kyc_documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Document Types
  aadhaar_number VARCHAR(12),
  aadhaar_photo_url TEXT,
  pan_number VARCHAR(10),
  pan_photo_url TEXT,
  bank_account_number VARCHAR(20),
  bank_ifsc_code VARCHAR(11),
  bank_verified BOOLEAN DEFAULT FALSE,
  selfie_with_id_url TEXT,
  address_proof_url TEXT,
  
  -- Verification Status
  status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
  verified_by UUID REFERENCES profiles(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  
  -- Metadata
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(user_id)
);

-- 2. Legal Agreements Table
CREATE TABLE IF NOT EXISTS legal_agreements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE,
  
  -- Agreement Details
  agreement_text TEXT NOT NULL,
  version VARCHAR(10) DEFAULT '1.0',
  
  -- Digital Signature
  signed_at TIMESTAMP WITH TIME ZONE,
  ip_address INET,
  device_info JSONB,
  digital_signature TEXT, -- Hash of agreement + timestamp
  
  -- Status
  status VARCHAR(20) DEFAULT 'unsigned', -- unsigned, signed, terminated
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(user_id, pool_id)
);

-- 3. Payment Tracking & Late Fees
CREATE TABLE IF NOT EXISTS payment_tracking (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Payment Details
  round_number INTEGER NOT NULL,
  due_date DATE NOT NULL,
  expected_amount DECIMAL(15, 2) NOT NULL,
  paid_amount DECIMAL(15, 2) DEFAULT 0,
  
  -- Status
  status VARCHAR(20) DEFAULT 'pending', -- pending, paid, overdue, defaulted
  payment_date TIMESTAMP WITH TIME ZONE,
  
  -- Late Fees
  late_fee_amount DECIMAL(15, 2) DEFAULT 0,
  late_fee_per_day DECIMAL(10, 2) DEFAULT 50.00,
  days_overdue INTEGER DEFAULT 0,
  
  -- Recovery Process Stage
  recovery_stage INTEGER DEFAULT 0, -- 0=none, 1-6=steps
  recovery_stage_date TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(pool_id, user_id, round_number)
);

-- 4. Default Consequences Tracking
CREATE TABLE IF NOT EXISTS default_actions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  payment_tracking_id UUID REFERENCES payment_tracking(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Action Details
  action_type VARCHAR(50) NOT NULL, -- reminder, late_fee, account_suspend, etc.
  action_description TEXT,
  action_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Recovery Stage
  recovery_stage INTEGER,
  
  -- Metadata
  metadata JSONB, -- Extra data like email sent, SMS sent, etc.
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Credit Bureau Reports
CREATE TABLE IF NOT EXISTS credit_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Report Details
  report_type VARCHAR(30) DEFAULT 'default', -- default, recovery, cleared
  total_defaulted_amount DECIMAL(15, 2),
  pools_defaulted INTEGER DEFAULT 0,
  
  -- Bureau Information
  reported_to VARCHAR(50), -- CIBIL, Experian, etc.
  report_date DATE,
  report_reference TEXT,
  
  -- Status
  status VARCHAR(20) DEFAULT 'pending', -- pending, reported, cleared
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. User Defaulter Status
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS defaulter_status VARCHAR(20) DEFAULT 'good'; -- good, warning, defaulter, banned
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS defaulter_badge BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS account_suspended BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS suspension_reason TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS total_defaults INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS total_default_amount DECIMAL(15, 2) DEFAULT 0;

-- 7. Update existing kyc_verified to be more restrictive
COMMENT ON COLUMN profiles.kyc_verified IS 'User has completed KYC and been approved by admin';

-- 8. Function: Check if user can create/join pools
CREATE OR REPLACE FUNCTION can_participate_in_pools(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_kyc_verified BOOLEAN;
  v_account_suspended BOOLEAN;
  v_defaulter_status VARCHAR(20);
BEGIN
  SELECT kyc_verified, account_suspended, defaulter_status
  INTO v_kyc_verified, v_account_suspended, v_defaulter_status
  FROM profiles
  WHERE id = p_user_id;
  
  -- Must be KYC verified
  IF v_kyc_verified IS NULL OR v_kyc_verified = FALSE THEN
    RETURN FALSE;
  END IF;
  
  -- Must not be suspended
  IF v_account_suspended = TRUE THEN
    RETURN FALSE;
  END IF;
  
  -- Must not be banned
  IF v_defaulter_status = 'banned' THEN
    RETURN FALSE;
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Function: Calculate late fees
CREATE OR REPLACE FUNCTION calculate_late_fees(p_payment_tracking_id UUID)
RETURNS DECIMAL(15, 2) AS $$
DECLARE
  v_due_date DATE;
  v_days_overdue INTEGER;
  v_late_fee_per_day DECIMAL(10, 2);
  v_total_late_fee DECIMAL(15, 2);
BEGIN
  SELECT 
    due_date,
    late_fee_per_day,
    GREATEST(0, EXTRACT(DAY FROM NOW() - due_date)::INTEGER)
  INTO v_due_date, v_late_fee_per_day, v_days_overdue
  FROM payment_tracking
  WHERE id = p_payment_tracking_id;
  
  v_total_late_fee := v_days_overdue * v_late_fee_per_day;
  
  -- Update payment tracking
  UPDATE payment_tracking
  SET 
    days_overdue = v_days_overdue,
    late_fee_amount = v_total_late_fee,
    updated_at = NOW()
  WHERE id = p_payment_tracking_id;
  
  RETURN v_total_late_fee;
END;
$$ LANGUAGE plpgsql;

-- 10. Function: Process recovery actions
CREATE OR REPLACE FUNCTION process_recovery_stage(p_payment_tracking_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_days_overdue INTEGER;
  v_current_stage INTEGER;
  v_new_stage INTEGER;
  v_user_id UUID;
  v_pool_id UUID;
BEGIN
  SELECT days_overdue, recovery_stage, user_id, pool_id
  INTO v_days_overdue, v_current_stage, v_user_id, v_pool_id
  FROM payment_tracking
  WHERE id = p_payment_tracking_id;
  
  -- Determine recovery stage based on days overdue
  v_new_stage := CASE
    WHEN v_days_overdue = 0 THEN 0
    WHEN v_days_overdue BETWEEN 1 AND 3 THEN 1
    WHEN v_days_overdue = 7 THEN 2
    WHEN v_days_overdue = 14 THEN 3
    WHEN v_days_overdue = 30 THEN 4
    WHEN v_days_overdue >= 60 THEN 5
    ELSE v_current_stage
  END;
  
  -- If stage changed, take action
  IF v_new_stage > v_current_stage THEN
    UPDATE payment_tracking
    SET 
      recovery_stage = v_new_stage,
      recovery_stage_date = NOW(),
      status = CASE 
        WHEN v_new_stage >= 3 THEN 'defaulted'
        WHEN v_new_stage >= 1 THEN 'overdue'
        ELSE status
      END
    WHERE id = p_payment_tracking_id;
    
    -- Log action
    INSERT INTO default_actions (payment_tracking_id, user_id, action_type, recovery_stage, metadata)
    VALUES (
      p_payment_tracking_id,
      v_user_id,
      CASE v_new_stage
        WHEN 1 THEN 'daily_reminders'
        WHEN 2 THEN 'legal_notice'
        WHEN 3 THEN 'credit_bureau_report'
        WHEN 4 THEN 'legal_action'
        WHEN 5 THEN 'collection_agency'
      END,
      v_new_stage,
      jsonb_build_object('pool_id', v_pool_id, 'days_overdue', v_days_overdue)
    );
    
    -- Apply consequences
    IF v_new_stage >= 2 THEN
      -- Suspend account
      UPDATE profiles
      SET 
        account_suspended = TRUE,
        suspension_reason = 'Payment overdue for ' || v_days_overdue || ' days'
      WHERE id = v_user_id;
    END IF;
    
    IF v_new_stage >= 3 THEN
      -- Mark as defaulter
      UPDATE profiles
      SET 
        defaulter_status = 'defaulter',
        defaulter_badge = TRUE,
        total_defaults = total_defaults + 1
      WHERE id = v_user_id;
      
      -- Create credit report
      INSERT INTO credit_reports (user_id, pools_defaulted, reported_to, report_date, status)
      VALUES (v_user_id, 1, 'CIBIL', CURRENT_DATE, 'pending');
    END IF;
    
    IF v_new_stage >= 4 THEN
      -- Ban from platform
      UPDATE profiles
      SET defaulter_status = 'banned'
      WHERE id = v_user_id;
    END IF;
  END IF;
  
  RETURN v_new_stage;
END;
$$ LANGUAGE plpgsql;

-- 11. Trigger: Auto-calculate late fees daily
CREATE OR REPLACE FUNCTION auto_calculate_late_fees()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process if payment is pending or overdue and past due date
  IF (NEW.status IS NULL OR NEW.status IN ('pending', 'overdue')) AND NEW.due_date < CURRENT_DATE THEN
    PERFORM calculate_late_fees(NEW.id);
    PERFORM process_recovery_stage(NEW.id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_late_fees
AFTER INSERT OR UPDATE ON payment_tracking
FOR EACH ROW
EXECUTE FUNCTION auto_calculate_late_fees();

-- 12. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_kyc_documents_user_id ON kyc_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_kyc_documents_status ON kyc_documents(status);
CREATE INDEX IF NOT EXISTS idx_payment_tracking_status ON payment_tracking(status);
CREATE INDEX IF NOT EXISTS idx_payment_tracking_user_pool ON payment_tracking(user_id, pool_id);
CREATE INDEX IF NOT EXISTS idx_default_actions_user_id ON default_actions(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_defaulter_status ON profiles(defaulter_status);

-- 13. RLS Policies
ALTER TABLE kyc_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_agreements ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE default_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_reports ENABLE ROW LEVEL SECURITY;

-- Users can view their own KYC
CREATE POLICY kyc_documents_select_own ON kyc_documents
  FOR SELECT USING (auth.uid() = user_id);

-- Users can insert/update their own KYC (only if pending)
CREATE POLICY kyc_documents_insert_own ON kyc_documents
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY kyc_documents_update_own ON kyc_documents
  FOR UPDATE USING (auth.uid() = user_id AND status = 'pending');

-- Users can view their own legal agreements
CREATE POLICY legal_agreements_select_own ON legal_agreements
  FOR SELECT USING (auth.uid() = user_id);

-- Users can view their own payment tracking
CREATE POLICY payment_tracking_select_own ON payment_tracking
  FOR SELECT USING (auth.uid() = user_id);

-- Users can view their own default actions
CREATE POLICY default_actions_select_own ON default_actions
  FOR SELECT USING (auth.uid() = user_id);

-- ========================================
-- VERIFICATION
-- ========================================
SELECT 'Tables created:' as status;
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('kyc_documents', 'legal_agreements', 'payment_tracking', 'default_actions', 'credit_reports');

SELECT 'Functions created:' as status;
SELECT routine_name FROM information_schema.routines
WHERE routine_name IN ('can_participate_in_pools', 'calculate_late_fees', 'process_recovery_stage');
