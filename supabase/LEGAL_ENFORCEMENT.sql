-- ============================================
-- LEGAL ENFORCEMENT SYSTEM
-- Digital Agreements, Legal Notices, and Enforcement
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Create legal_agreements table
CREATE TABLE IF NOT EXISTS legal_agreements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE,
  agreement_type VARCHAR(50) NOT NULL, -- 'pool_terms', 'platform_terms', 'payment_commitment'
  agreement_text TEXT NOT NULL,
  version VARCHAR(20) NOT NULL,
  signed_at TIMESTAMPTZ DEFAULT NOW(),
  ip_address VARCHAR(45),
  device_info TEXT,
  signature_hash VARCHAR(255), -- Digital signature
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create legal_notices table
CREATE TABLE IF NOT EXISTS legal_notices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE,
  notice_type VARCHAR(50) NOT NULL, -- 'warning', 'legal_notice', 'final_notice', 'police_complaint'
  subject VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  amount_owed DECIMAL(10,2),
  due_date TIMESTAMPTZ,
  issued_at TIMESTAMPTZ DEFAULT NOW(),
  issued_by UUID REFERENCES auth.users(id),
  status VARCHAR(50) DEFAULT 'sent', -- 'sent', 'acknowledged', 'resolved', 'escalated'
  acknowledged_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  escalated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create legal_actions table
CREATE TABLE IF NOT EXISTS legal_actions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE,
  notice_id UUID REFERENCES legal_notices(id) ON DELETE SET NULL,
  action_type VARCHAR(50) NOT NULL, -- 'legal_notice', 'police_complaint', 'collection_agency', 'court_case'
  action_status VARCHAR(50) DEFAULT 'initiated', -- 'initiated', 'in_progress', 'completed', 'resolved'
  amount_claimed DECIMAL(10,2),
  description TEXT,
  case_number VARCHAR(100),
  filed_at TIMESTAMPTZ,
  agency_name VARCHAR(255), -- Collection agency or legal firm
  agency_contact TEXT,
  resolution_details TEXT,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Create payment_commitments table
CREATE TABLE IF NOT EXISTS payment_commitments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE,
  agreement_id UUID REFERENCES legal_agreements(id) ON DELETE SET NULL,
  commitment_amount DECIMAL(10,2) NOT NULL,
  commitment_date TIMESTAMPTZ NOT NULL,
  payment_schedule TEXT, -- JSON with payment dates
  is_fulfilled BOOLEAN DEFAULT false,
  fulfilled_at TIMESTAMPTZ,
  breach_count INT DEFAULT 0,
  last_breach_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Create enforcement_escalations table (tracks escalation timeline)
CREATE TABLE IF NOT EXISTS enforcement_escalations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE,
  escalation_level INT NOT NULL, -- 1=warning, 2=legal notice, 3=final notice, 4=police, 5=collection
  escalation_type VARCHAR(50) NOT NULL,
  triggered_at TIMESTAMPTZ DEFAULT NOW(),
  triggered_by VARCHAR(50), -- 'auto', 'admin', 'system'
  days_overdue INT,
  amount_overdue DECIMAL(10,2),
  action_taken TEXT,
  next_escalation_date TIMESTAMPTZ,
  is_resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMPTZ
);

-- 6. Enable RLS
ALTER TABLE legal_agreements ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_notices ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_commitments ENABLE ROW LEVEL SECURITY;
ALTER TABLE enforcement_escalations ENABLE ROW LEVEL SECURITY;

-- 7. RLS Policies for legal_agreements
DROP POLICY IF EXISTS "Users can view their own agreements" ON legal_agreements;
CREATE POLICY "Users can view their own agreements" ON legal_agreements
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can sign agreements" ON legal_agreements;
CREATE POLICY "Users can sign agreements" ON legal_agreements
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 8. RLS Policies for legal_notices
DROP POLICY IF EXISTS "Users can view their own notices" ON legal_notices;
CREATE POLICY "Users can view their own notices" ON legal_notices
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can create notices" ON legal_notices;
CREATE POLICY "Admins can create notices" ON legal_notices
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM pool_members
      WHERE pool_id = legal_notices.pool_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- 9. RLS Policies for legal_actions
DROP POLICY IF EXISTS "Users can view their own legal actions" ON legal_actions;
CREATE POLICY "Users can view their own legal actions" ON legal_actions
  FOR SELECT USING (auth.uid() = user_id);

-- 10. RLS Policies for payment_commitments
DROP POLICY IF EXISTS "Users can view their own commitments" ON payment_commitments;
CREATE POLICY "Users can view their own commitments" ON payment_commitments
  FOR SELECT USING (auth.uid() = user_id);

-- 11. RLS Policies for enforcement_escalations
DROP POLICY IF EXISTS "Users can view their own escalations" ON enforcement_escalations;
CREATE POLICY "Users can view their own escalations" ON enforcement_escalations
  FOR SELECT USING (auth.uid() = user_id);

-- 12. Function to sign digital agreement
CREATE OR REPLACE FUNCTION sign_agreement(
  p_user_id UUID,
  p_pool_id UUID,
  p_agreement_type VARCHAR(50),
  p_agreement_text TEXT,
  p_version VARCHAR(20),
  p_ip_address VARCHAR(45),
  p_device_info TEXT
)
RETURNS UUID AS $$
DECLARE
  v_agreement_id UUID;
  v_signature_hash VARCHAR(255);
BEGIN
  -- Generate signature hash (timestamp + user_id + pool_id)
  v_signature_hash := md5(NOW()::TEXT || p_user_id::TEXT || p_pool_id::TEXT);

  -- Insert agreement
  INSERT INTO legal_agreements (
    user_id,
    pool_id,
    agreement_type,
    agreement_text,
    version,
    ip_address,
    device_info,
    signature_hash
  ) VALUES (
    p_user_id,
    p_pool_id,
    p_agreement_type,
    p_agreement_text,
    p_version,
    p_ip_address,
    p_device_info,
    v_signature_hash
  ) RETURNING id INTO v_agreement_id;

  RETURN v_agreement_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13. Function to issue legal notice
CREATE OR REPLACE FUNCTION issue_legal_notice(
  p_user_id UUID,
  p_pool_id UUID,
  p_notice_type VARCHAR(50),
  p_subject VARCHAR(255),
  p_content TEXT,
  p_amount_owed DECIMAL(10,2),
  p_due_date TIMESTAMPTZ
)
RETURNS UUID AS $$
DECLARE
  v_notice_id UUID;
BEGIN
  -- Insert legal notice
  INSERT INTO legal_notices (
    user_id,
    pool_id,
    notice_type,
    subject,
    content,
    amount_owed,
    due_date,
    issued_by
  ) VALUES (
    p_user_id,
    p_pool_id,
    p_notice_type,
    p_subject,
    p_content,
    p_amount_owed,
    p_due_date,
    auth.uid()
  ) RETURNING id INTO v_notice_id;

  -- Send notification
  INSERT INTO notifications (user_id, type, title, message, data)
  VALUES (
    p_user_id,
    'legal_notice',
    p_subject,
    'You have received a legal notice. Please review immediately.',
    json_build_object('notice_id', v_notice_id, 'pool_id', p_pool_id)
  );

  RETURN v_notice_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 14. Function to escalate enforcement
CREATE OR REPLACE FUNCTION escalate_enforcement(
  p_user_id UUID,
  p_pool_id UUID,
  p_days_overdue INT,
  p_amount_overdue DECIMAL(10,2)
)
RETURNS VOID AS $$
DECLARE
  v_escalation_level INT;
  v_notice_type VARCHAR(50);
  v_subject VARCHAR(255);
  v_content TEXT;
BEGIN
  -- Determine escalation level based on days overdue
  IF p_days_overdue >= 30 THEN
    v_escalation_level := 5; -- Collection agency
    v_notice_type := 'collection_agency';
    v_subject := 'FINAL NOTICE: Account Sent to Collection Agency';
    v_content := 'Your account has been sent to a collection agency due to non-payment of ₹' || p_amount_overdue || '. Legal action will be taken.';
  ELSIF p_days_overdue >= 21 THEN
    v_escalation_level := 4; -- Police complaint
    v_notice_type := 'police_complaint';
    v_subject := 'URGENT: Police Complaint Will Be Filed';
    v_content := 'A police complaint for fraud will be filed if payment of ₹' || p_amount_overdue || ' is not received within 48 hours.';
  ELSIF p_days_overdue >= 14 THEN
    v_escalation_level := 3; -- Final notice
    v_notice_type := 'final_notice';
    v_subject := 'FINAL LEGAL NOTICE';
    v_content := 'This is your final notice before legal action. Pay ₹' || p_amount_overdue || ' immediately to avoid legal consequences.';
  ELSIF p_days_overdue >= 7 THEN
    v_escalation_level := 2; -- Legal notice
    v_notice_type := 'legal_notice';
    v_subject := 'Legal Notice: Payment Overdue';
    v_content := 'You are legally obligated to pay ₹' || p_amount_overdue || '. Failure to pay will result in legal action.';
  ELSE
    v_escalation_level := 1; -- Warning
    v_notice_type := 'warning';
    v_subject := 'Payment Reminder';
    v_content := 'Your payment of ₹' || p_amount_overdue || ' is overdue. Please pay immediately to avoid penalties.';
  END IF;

  -- Log escalation
  INSERT INTO enforcement_escalations (
    user_id,
    pool_id,
    escalation_level,
    escalation_type,
    triggered_by,
    days_overdue,
    amount_overdue,
    action_taken,
    next_escalation_date
  ) VALUES (
    p_user_id,
    p_pool_id,
    v_escalation_level,
    v_notice_type,
    'auto',
    p_days_overdue,
    p_amount_overdue,
    'Notice issued: ' || v_subject,
    NOW() + INTERVAL '7 days'
  );

  -- Issue notice
  PERFORM issue_legal_notice(
    p_user_id,
    p_pool_id,
    v_notice_type,
    v_subject,
    v_content,
    p_amount_overdue,
    NOW() + INTERVAL '7 days'
  );

  -- If police complaint level, create legal action
  IF v_escalation_level >= 4 THEN
    INSERT INTO legal_actions (
      user_id,
      pool_id,
      action_type,
      amount_claimed,
      description
    ) VALUES (
      p_user_id,
      p_pool_id,
      CASE 
        WHEN v_escalation_level = 5 THEN 'collection_agency'
        ELSE 'police_complaint'
      END,
      p_amount_overdue,
      v_content
    );
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 15. Function to file police complaint
CREATE OR REPLACE FUNCTION file_police_complaint(
  p_user_id UUID,
  p_pool_id UUID,
  p_amount_owed DECIMAL(10,2),
  p_case_details TEXT
)
RETURNS UUID AS $$
DECLARE
  v_action_id UUID;
  v_case_number VARCHAR(100);
BEGIN
  -- Generate case number
  v_case_number := 'PC-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || SUBSTRING(p_user_id::TEXT, 1, 8);

  -- Create legal action
  INSERT INTO legal_actions (
    user_id,
    pool_id,
    action_type,
    action_status,
    amount_claimed,
    description,
    case_number,
    filed_at
  ) VALUES (
    p_user_id,
    p_pool_id,
    'police_complaint',
    'initiated',
    p_amount_owed,
    p_case_details,
    v_case_number,
    NOW()
  ) RETURNING id INTO v_action_id;

  -- Update user status
  UPDATE profiles
  SET is_banned = true
  WHERE id = p_user_id;

  -- Notify user
  INSERT INTO notifications (user_id, type, title, message, data)
  VALUES (
    p_user_id,
    'police_complaint',
    'Police Complaint Filed',
    'A police complaint has been filed against you for fraud. Case Number: ' || v_case_number,
    json_build_object('action_id', v_action_id, 'case_number', v_case_number)
  );

  RETURN v_action_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 16. Function to send to collection agency
CREATE OR REPLACE FUNCTION send_to_collection(
  p_user_id UUID,
  p_pool_id UUID,
  p_amount_owed DECIMAL(10,2),
  p_agency_name VARCHAR(255),
  p_agency_contact TEXT
)
RETURNS UUID AS $$
DECLARE
  v_action_id UUID;
BEGIN
  -- Create legal action
  INSERT INTO legal_actions (
    user_id,
    pool_id,
    action_type,
    action_status,
    amount_claimed,
    description,
    agency_name,
    agency_contact,
    filed_at
  ) VALUES (
    p_user_id,
    p_pool_id,
    'collection_agency',
    'in_progress',
    p_amount_owed,
    'Account sent to collection agency for recovery of ₹' || p_amount_owed,
    p_agency_name,
    p_agency_contact,
    NOW()
  ) RETURNING id INTO v_action_id;

  -- Ban user
  UPDATE profiles
  SET is_banned = true
  WHERE id = p_user_id;

  -- Notify user
  INSERT INTO notifications (user_id, type, title, message, data)
  VALUES (
    p_user_id,
    'collection_agency',
    'Account Sent to Collection',
    'Your account has been sent to ' || p_agency_name || ' for debt collection.',
    json_build_object('action_id', v_action_id, 'agency', p_agency_name)
  );

  RETURN v_action_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 17. Function to check and auto-escalate overdue payments
CREATE OR REPLACE FUNCTION auto_escalate_overdue_payments()
RETURNS VOID AS $$
DECLARE
  v_member RECORD;
  v_days_overdue INT;
BEGIN
  -- Find all members with overdue payments
  FOR v_member IN
    SELECT DISTINCT
      pm.user_id,
      pm.pool_id,
      p.contribution_amount,
      MAX(t.created_at) as last_payment
    FROM pool_members pm
    JOIN pools p ON p.id = pm.pool_id
    LEFT JOIN transactions t ON t.user_id = pm.user_id 
      AND t.pool_id = pm.pool_id 
      AND t.transaction_type = 'contribution'
      AND t.status = 'completed'
    WHERE pm.status = 'active'
    AND pm.has_won = false
    GROUP BY pm.user_id, pm.pool_id, p.contribution_amount
    HAVING MAX(t.created_at) < NOW() - INTERVAL '30 days'
      OR MAX(t.created_at) IS NULL
  LOOP
    -- Calculate days overdue
    v_days_overdue := EXTRACT(DAY FROM (NOW() - COALESCE(v_member.last_payment, NOW() - INTERVAL '30 days')));

    -- Escalate if needed
    IF v_days_overdue > 0 THEN
      PERFORM escalate_enforcement(
        v_member.user_id,
        v_member.pool_id,
        v_days_overdue,
        v_member.contribution_amount
      );
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 18. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_legal_agreements_user ON legal_agreements(user_id, pool_id);
CREATE INDEX IF NOT EXISTS idx_legal_notices_user ON legal_notices(user_id, status);
CREATE INDEX IF NOT EXISTS idx_legal_actions_user ON legal_actions(user_id, action_status);
CREATE INDEX IF NOT EXISTS idx_payment_commitments_user ON payment_commitments(user_id, is_fulfilled);
CREATE INDEX IF NOT EXISTS idx_enforcement_escalations_user ON enforcement_escalations(user_id, is_resolved);

-- Success message
SELECT 'Legal Enforcement System created successfully!' as status;
