# 🚀 READY FOR LAUNCH: Phase 1 Instructions

**Status**: Code is fixed and ready!
**Next Step**: Database Setup

---

## 1️⃣ Run Database Migration (Required)

I cannot access your Supabase dashboard directly. You must do this:

1.  **Copy** the SQL code below.
2.  Go to your **Supabase Dashboard** → **SQL Editor**.
3.  **Paste** and click **Run**.

```sql
-- Create deposit_requests table
CREATE TABLE IF NOT EXISTS deposit_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    transaction_reference TEXT NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE deposit_requests ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own requests" 
ON deposit_requests FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can create requests" 
ON deposit_requests FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all requests" 
ON deposit_requests FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND is_admin = true
  )
);

CREATE POLICY "Admins can update requests" 
ON deposit_requests FOR UPDATE 
USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND is_admin = true
  )
);
```

---

## 2️⃣ Set Yourself as Admin

In the same **Supabase SQL Editor**, run this command (replace with your email):

```sql
UPDATE profiles 
SET is_admin = TRUE 
WHERE email = 'YOUR_EMAIL@example.com';
```

---

## 3️⃣ Update Bank Details (Easy Mode)

I have moved the bank details to a configuration file for you!

1.  Open `lib/core/config/app_config.dart`
2.  Update the values with your real details:

```dart
class AppConfig {
  static const String adminUpiId = 'YOUR_REAL_UPI@okicici'; 
  static const String adminBankName = 'YOUR BANK NAME';
  static const String adminAccountNo = 'YOUR ACCOUNT NUMBER';
  static const String adminIfsc = 'YOUR IFSC CODE';
  // ...
}
```

---

## 4️⃣ Test the App

Run the app to verify everything works:

```powershell
flutter run
```

**You are all set!** 🚀
