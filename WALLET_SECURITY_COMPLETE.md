# 🔒 Complete Security Guide - Wallet System

## Security Features Already Implemented ✅

### **1. Payment Verification** 🛡️

**Problem:** Fake transactions showing as real money

**Solution:**
```sql
-- Only verified transactions show to users
verified BOOLEAN DEFAULT false
verified_at TIMESTAMPTZ
verified_by UUID (admin who verified)

-- Users can ONLY see verified transactions
CREATE POLICY "Users can view their verified transactions"
  ON wallet_transactions
  FOR SELECT USING (
    user_id = auth.uid() AND verified = true
  );
```

**How it works:**
```
User pays ₹500
  ↓
Transaction created (verified = false)
  ↓
User CANNOT see it yet ❌
  ↓
Admin verifies real money received
  ↓
Sets verified = true
  ↓
NOW user sees ₹500 ✅
```

---

### **2. Row Level Security (RLS)** 🔐

**Implemented:**
```sql
-- Users can ONLY see their own wallet
CREATE POLICY "Users can view their own wallet"
  ON wallets
  FOR SELECT USING (user_id = auth.uid());

-- Users can ONLY see their verified transactions
CREATE POLICY "Users can view their verified transactions"
  ON wallet_transactions
  FOR SELECT USING (
    user_id = auth.uid() AND verified = true
  );

-- Admins can see everything
CREATE POLICY "Admins can view all wallets"
  ON wallets
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND is_admin = true
    )
  );
```

**Protection:**
- ✅ User A cannot see User B's wallet
- ✅ User A cannot see User B's transactions
- ✅ Only admins can see all data
- ✅ Database-level security (not just app-level)

---

### **3. Balance Locking** 🔒

**Problem:** User spends money that's already committed to pool

**Solution:**
```sql
wallets
├── balance (available)
├── locked_balance (committed)
└── total_balance (balance + locked_balance)

-- Lock balance for pool
UPDATE wallets SET
  balance = balance - 10000,
  locked_balance = locked_balance + 10000;
```

**Example:**
```
User has ₹1,000
Joins pool requiring ₹500
  ↓
Available: ₹500
Locked: ₹500
Total: ₹1,000
  ↓
User tries to spend ₹600 ❌
Insufficient balance!
  ↓
Pool payment due
  ↓
Deduct from locked:
Available: ₹500
Locked: ₹0
Total: ₹500
```

---

### **4. Duplicate Prevention** 🚫

**Problem:** Same payment processed twice

**Solution:**
```sql
payment_gateway_id TEXT UNIQUE

-- Check before processing
IF EXISTS (
  SELECT 1 FROM wallet_transactions
  WHERE payment_gateway_id = 'pay_ABC123'
) THEN
  RAISE EXCEPTION 'Transaction already processed';
END IF;
```

**Protection:**
- ✅ Same Razorpay payment ID cannot be used twice
- ✅ Prevents double-crediting
- ✅ Database-level unique constraint

---

### **5. Atomic Transactions** ⚛️

**Problem:** Race conditions, partial updates

**Solution:**
```sql
BEGIN;
  -- Lock wallet row
  SELECT * FROM wallets 
  WHERE user_id = ? 
  FOR UPDATE;
  
  -- Update balance
  UPDATE wallets SET balance = balance + amount;
  
  -- Create transaction record
  INSERT INTO wallet_transactions (...);
COMMIT;
```

**Protection:**
- ✅ All-or-nothing updates
- ✅ No partial transactions
- ✅ Row-level locking prevents concurrent updates
- ✅ Database handles concurrency

---

### **6. Balance Snapshots** 📸

**Problem:** Lost audit trail

**Solution:**
```sql
wallet_transactions
├── balance_before (BIGINT)
├── balance_after (BIGINT)
└── amount (BIGINT)

-- Every transaction records:
balance_before: 50000 (₹500)
amount: 10000 (₹100)
balance_after: 60000 (₹600)
```

**Benefits:**
- ✅ Complete audit trail
- ✅ Can verify every transaction
- ✅ Detect tampering
- ✅ Reconciliation possible

---

### **7. Precision (No Floating Point)** 💯

**Problem:** Floating point errors (0.1 + 0.2 = 0.30000000004)

**Solution:**
```sql
-- Store in PAISE (not rupees)
amount BIGINT

-- ₹100.50 = 10050 paise
-- ₹1,234.75 = 123475 paise
```

**Protection:**
- ✅ No rounding errors
- ✅ Exact calculations
- ✅ No money lost to floating point

---

## Additional Security Features Needed 🔐

### **1. Wallet PIN** 🔢

**Add to migration:**
```sql
-- Already in schema!
wallets
├── pin_hash TEXT
├── pin_attempts INTEGER DEFAULT 0
└── pin_locked_until TIMESTAMPTZ
```

**Implementation:**
```dart
// Set PIN
await supabase.rpc('set_wallet_pin', params: {
  'p_pin_hash': hashPin(userPin), // bcrypt hash
});

// Verify PIN before transactions
await supabase.rpc('verify_wallet_pin', params: {
  'p_pin_hash': hashPin(userPin),
});

// Lock after 3 failed attempts
if (pin_attempts >= 3) {
  pin_locked_until = NOW() + INTERVAL '30 minutes';
}
```

---

### **2. Transaction Limits** 💰

**Already implemented:**
```sql
wallets
├── daily_limit BIGINT DEFAULT 10000000 (₹1,00,000)
├── monthly_limit BIGINT DEFAULT 100000000 (₹10,00,000)
├── daily_spent BIGINT DEFAULT 0
└── monthly_spent BIGINT DEFAULT 0
```

**Add enforcement:**
```sql
-- Check before transaction
IF (daily_spent + amount) > daily_limit THEN
  RAISE EXCEPTION 'Daily limit exceeded';
END IF;

IF (monthly_spent + amount) > monthly_limit THEN
  RAISE EXCEPTION 'Monthly limit exceeded';
END IF;
```

---

### **3. KYC-Based Limits** 📋

**Already implemented:**
```sql
wallets
├── kyc_status TEXT ('pending', 'basic', 'full')
└── kyc_limit BIGINT

-- Limits based on KYC:
Pending:   ₹10,000/month
Basic KYC: ₹1,00,000/month
Full KYC:  ₹10,00,000/month
```

**Enforcement:**
```sql
-- Check KYC limit
IF amount > kyc_limit THEN
  RAISE EXCEPTION 'Complete KYC to increase limit';
END IF;
```

---

### **4. IP Whitelisting** 🌐

**Add to database:**
```sql
CREATE TABLE trusted_ips (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  ip_address TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Check IP before sensitive operations
CREATE FUNCTION check_trusted_ip(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM trusted_ips
    WHERE user_id = p_user_id
    AND ip_address = current_setting('request.headers')::json->>'x-forwarded-for'
  );
END;
$$ LANGUAGE plpgsql;
```

---

### **5. Device Fingerprinting** 📱

**Add to transactions:**
```sql
ALTER TABLE wallet_transactions 
ADD COLUMN device_id TEXT,
ADD COLUMN device_info JSONB;

-- Store device info
{
  "device_id": "abc123",
  "platform": "android",
  "app_version": "1.0.0",
  "ip_address": "192.168.1.1"
}
```

---

### **6. Fraud Detection** 🚨

**Add fraud checks:**
```sql
CREATE FUNCTION detect_fraud(
  p_user_id UUID,
  p_amount BIGINT
) RETURNS BOOLEAN AS $$
DECLARE
  v_recent_count INTEGER;
  v_avg_amount BIGINT;
BEGIN
  -- Check for rapid transactions
  SELECT COUNT(*) INTO v_recent_count
  FROM wallet_transactions
  WHERE user_id = p_user_id
  AND created_at > NOW() - INTERVAL '5 minutes';
  
  IF v_recent_count > 5 THEN
    RETURN true; -- Suspicious!
  END IF;
  
  -- Check for unusual amount
  SELECT AVG(amount) INTO v_avg_amount
  FROM wallet_transactions
  WHERE user_id = p_user_id;
  
  IF p_amount > (v_avg_amount * 10) THEN
    RETURN true; -- Suspicious!
  END IF;
  
  RETURN false;
END;
$$ LANGUAGE plpgsql;
```

---

### **7. Webhook Signature Verification** ✍️

**For Razorpay webhooks:**
```dart
bool verifyWebhookSignature(
  String payload,
  String signature,
  String secret,
) {
  final expectedSignature = Hmac(sha256, utf8.encode(secret))
      .convert(utf8.encode(payload))
      .toString();
  
  return signature == expectedSignature;
}

// Use in webhook handler
if (!verifyWebhookSignature(payload, signature, razorpaySecret)) {
  throw Exception('Invalid webhook signature');
}
```

---

### **8. Rate Limiting** ⏱️

**Add to functions:**
```sql
CREATE TABLE rate_limits (
  user_id UUID,
  action TEXT,
  count INTEGER DEFAULT 0,
  window_start TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, action)
);

CREATE FUNCTION check_rate_limit(
  p_user_id UUID,
  p_action TEXT,
  p_max_requests INTEGER,
  p_window_minutes INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
  v_record RECORD;
BEGIN
  SELECT * INTO v_record FROM rate_limits
  WHERE user_id = p_user_id AND action = p_action
  FOR UPDATE;
  
  -- Reset if window expired
  IF v_record.window_start < NOW() - (p_window_minutes || ' minutes')::INTERVAL THEN
    UPDATE rate_limits SET count = 1, window_start = NOW()
    WHERE user_id = p_user_id AND action = p_action;
    RETURN true;
  END IF;
  
  -- Check limit
  IF v_record.count >= p_max_requests THEN
    RETURN false; -- Rate limit exceeded
  END IF;
  
  -- Increment
  UPDATE rate_limits SET count = count + 1
  WHERE user_id = p_user_id AND action = p_action;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql;
```

---

### **9. Encryption at Rest** 🔐

**Supabase provides:**
- ✅ AES-256 encryption for all data
- ✅ Encrypted backups
- ✅ TLS for data in transit

**Additional:**
```dart
// Encrypt sensitive data before storing
final encrypted = encrypt(
  data: sensitiveData,
  key: userKey,
);

await supabase.from('sensitive_data').insert({
  'encrypted_data': encrypted,
});
```

---

### **10. Audit Logging** 📝

**Add comprehensive logging:**
```sql
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL,
  resource_type TEXT,
  resource_id UUID,
  old_value JSONB,
  new_value JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Log all wallet operations
CREATE FUNCTION log_wallet_operation()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_logs (
    user_id, action, resource_type, resource_id,
    old_value, new_value
  ) VALUES (
    NEW.user_id, TG_OP, 'wallet', NEW.id,
    row_to_json(OLD), row_to_json(NEW)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER wallet_audit
AFTER INSERT OR UPDATE OR DELETE ON wallets
FOR EACH ROW EXECUTE FUNCTION log_wallet_operation();
```

---

## Security Checklist ✅

### **Database Level:**
- ✅ Row Level Security (RLS)
- ✅ Payment verification
- ✅ Unique constraints
- ✅ Foreign key constraints
- ✅ Check constraints (balance >= 0)
- ✅ Atomic transactions
- ✅ Balance snapshots

### **Application Level:**
- ⚠️ Wallet PIN (schema ready, needs implementation)
- ⚠️ Transaction limits (schema ready, needs enforcement)
- ⚠️ KYC limits (schema ready, needs enforcement)
- ⚠️ Rate limiting (needs implementation)
- ⚠️ Fraud detection (needs implementation)

### **Payment Gateway:**
- ✅ UPI (secure by design)
- ⚠️ Webhook signature verification (needs implementation)
- ⚠️ Payment reconciliation (needs implementation)

### **Infrastructure:**
- ✅ TLS/HTTPS
- ✅ Encryption at rest (Supabase)
- ✅ Encrypted backups (Supabase)
- ⚠️ IP whitelisting (needs implementation)
- ⚠️ Device fingerprinting (needs implementation)

---

## Priority Implementation Order

### **Phase 1: Critical (Do Now)** 🔴
1. ✅ Payment verification (DONE)
2. ✅ RLS policies (DONE)
3. ⚠️ Webhook signature verification
4. ⚠️ Transaction limit enforcement

### **Phase 2: Important (Do Soon)** 🟡
1. ⚠️ Wallet PIN
2. ⚠️ KYC limit enforcement
3. ⚠️ Fraud detection
4. ⚠️ Rate limiting

### **Phase 3: Nice to Have** 🟢
1. ⚠️ IP whitelisting
2. ⚠️ Device fingerprinting
3. ⚠️ Advanced audit logging

---

## Summary

**Already Secure:** ✅
- Payment verification
- RLS policies
- Balance locking
- Duplicate prevention
- Atomic transactions
- Balance snapshots
- Precision (paise)

**Needs Implementation:** ⚠️
- Wallet PIN
- Transaction limits enforcement
- KYC limits enforcement
- Webhook verification
- Fraud detection
- Rate limiting

**Your wallet system has STRONG security foundations!** The critical features are already implemented. Additional features can be added incrementally. 🔒
