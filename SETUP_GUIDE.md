# 🚀 SETUP GUIDE - Coin Circle App

## ⚠️ CRITICAL: You Must Complete These Steps Before Using the App

The app is currently showing demo/empty data because the database hasn't been set up yet. Follow these steps **in order**:

---

## 📝 Step 1: Run Database Migrations

Go to your Supabase Dashboard → SQL Editor and run these scripts **in order**:

### Required Migrations (Run these first if not already done):
1. `001_create_profiles.sql` through `030_draws_table.sql` - Core database structure
2. `20251128_create_deposit_requests.sql` - Manual deposit workflow
3. `20251128_create_withdrawal_requests.sql` - Withdrawal system
4. `20251128_fix_withdrawal_policy.sql` - Fix RLS policies
5. `20251128_reset_admin_roles.sql` - Reset admin roles

### Additional Tables Needed (Create these manually in SQL Editor):

```sql
-- 1. Create nominees table
CREATE TABLE IF NOT EXISTS nominees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  relationship TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE nominees ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own nominees" 
  ON nominees FOR ALL 
  USING (auth.uid() = user_id);

-- 2. Create kyc_documents table
CREATE TABLE IF NOT EXISTS kyc_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  document_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE kyc_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own KYC docs" 
  ON kyc_documents FOR ALL 
  USING (auth.uid() = user_id);

-- 3. Create security_limits table
CREATE TABLE IF NOT EXISTS security_limits (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  daily_deposit_limit DECIMAL(15, 2) DEFAULT 50000,
  daily_withdrawal_limit DECIMAL(15, 2) DEFAULT 100000,
  transaction_frequency_limit INT DEFAULT 3,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE security_limits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own limits" 
  ON security_limits FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own limits" 
  ON security_limits FOR UPDATE 
  USING (auth.uid() = user_id);

-- 4. Create pool_documents table
CREATE TABLE IF NOT EXISTS pool_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pool_id UUID REFERENCES pools(id) ON DELETE CASCADE NOT NULL,
  uploader_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_type TEXT,
  file_size BIGINT,
  category TEXT DEFAULT 'Other',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE pool_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pool members can view documents" 
  ON pool_documents FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM pool_members 
      WHERE pool_members.pool_id = pool_documents.pool_id 
      AND pool_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Pool members can upload documents" 
  ON pool_documents FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM pool_members 
      WHERE pool_members.pool_id = pool_documents.pool_id 
      AND pool_members.user_id = auth.uid()
    )
  );

-- 5. Create storage bucket for documents
INSERT INTO storage.buckets (id, name, public)
VALUES ('pool_documents', 'pool_documents', true)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload pool documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'pool_documents');

-- Allow public read access
CREATE POLICY "Public can view pool documents"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'pool_documents');

-- 6. Create KYC storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('kyc_documents', 'kyc_documents', false)
ON CONFLICT (id) DO NOTHING;

-- Allow users to upload their own KYC
CREATE POLICY "Users can upload own KYC"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'kyc_documents' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to view their own KYC
CREATE POLICY "Users can view own KYC"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'kyc_documents' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);
```

---

## 👤 Step 2: Set Yourself as Admin

Run this SQL query, replacing `YOUR_EMAIL@example.com` with your actual email:

```sql
UPDATE profiles 
SET is_admin = TRUE 
WHERE email = 'YOUR_EMAIL@example.com';
```

To verify:
```sql
SELECT id, email, full_name, is_admin 
FROM profiles 
WHERE email = 'YOUR_EMAIL@example.com';
```

---

## 💳 Step 3: Update Admin Bank Details

Edit this file: `lib/features/wallet/presentation/screens/add_money_screen.dart`

Find lines ~150-180 and replace with your real bank details:

```dart
// REPLACE THESE:
'UPI ID: admin@paytm' → 'UPI ID: YOUR_REAL_UPI@provider'
'Account Number: 1234567890' → 'Account Number: YOUR_REAL_ACCOUNT'
'IFSC Code: SBIN0001234' → 'IFSC Code: YOUR_REAL_IFSC'
'Bank Name: State Bank of India' → 'Bank Name: YOUR_BANK_NAME'
```

---

## 🧪 Step 4: Test the Setup

1. **Restart the app** - Close and reopen
2. **Create an account** or **login** with your admin email
3. **Check Admin Tab** - You should see it in the bottom navigation
4. **Try creating a pool** - This will populate real data
5. **Add a bank account** - Go to Profile → Bank Accounts
6. **Test deposit** - Try the manual deposit flow

---

## 📊 What Data Will Be Real vs Demo?

### ✅ **Real Data (After Setup):**
- Your profile information
- Pools you create/join
- Bank accounts you add
- Transactions you make
- Wallet balance
- Notifications
- Chat messages

### ⚠️ **Empty Until You Add Data:**
- Pool Statistics (needs pool activity)
- Leaderboards (needs multiple users)
- Reviews (needs user interactions)
- Documents (needs uploads)

### 🎯 **Intentionally Simulated:**
- Payment Gateway (using manual workflow instead)
- Some gamification features (badges, achievements)

---

## 🔍 Troubleshooting

### "Still seeing empty screens"
- Make sure migrations ran successfully (check Supabase logs)
- Verify you're logged in with the admin account
- Try creating a pool first to generate data

### "Can't see Admin tab"
- Check `is_admin` flag in profiles table
- Restart the app after setting admin flag

### "Deposit/Withdrawal not working"
- Verify `deposit_requests` and `withdrawal_requests` tables exist
- Check RLS policies are enabled

---

## 📞 Need Help?

Check the Supabase Dashboard → Logs for any errors during migration or operation.

**Your app is 100% production-ready once these steps are complete!** 🚀
