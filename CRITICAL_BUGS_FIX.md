# CRITICAL BUGS - IMMEDIATE FIXES NEEDED

## 🔴 Issue 1: Sign Up - Phone Number & Date of Birth Not Saving

### Problem:
- Error: `date/time field value out of range: "27/02/2004"`
- Phone number not being saved to database
- User profile incomplete (showing "null null")

### Root Cause:
Date format mismatch - App sends DD/MM/YYYY but database expects YYYY-MM-DD

### Fix Required:

**File: `lib/features/auth/presentation/screens/signup_screen.dart`**

Find the date formatting code and change from:
```dart
// WRONG - DD/MM/YYYY format
DateFormat('dd/MM/yyyy').format(selectedDate)
```

To:
```dart
// CORRECT - YYYY-MM-DD format for database
DateFormat('yyyy-MM-dd').format(selectedDate)
```

Also ensure phone number is being sent:
```dart
await AuthService.signUp(
  email: email,
  password: password,
  fullName: fullName,
  phoneNumber: phoneNumber, // Make sure this is included
  dateOfBirth: DateFormat('yyyy-MM-dd').format(selectedDate), // Correct format
);
```

---

## 🔴 Issue 2: Email Verification Opens Browser - "Not Found"

### Problem:
- Email verification link opens Chrome browser
- Shows "Not Found" error
- Should redirect to app or show success message

### Root Cause:
Deep linking not configured properly for email verification

### Fix Required:

**Option 1: Configure Deep Links (Recommended)**

1. Update `android/app/src/main/AndroidManifest.xml`:
```xml
<activity android:name=".MainActivity">
    <!-- Add deep link intent filter -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="coincircle"
            android:host="auth" />
    </intent-filter>
    
    <!-- Add HTTPS deep link -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="https"
            android:host="YOUR_SUPABASE_PROJECT.supabase.co" />
    </intent-filter>
</activity>
```

2. In Supabase Dashboard → Authentication → URL Configuration:
   - Site URL: `coincircle://auth`
   - Redirect URLs: Add `coincircle://auth/callback`

**Option 2: Use OTP Instead (Quick Fix)**

Change email verification to use OTP code instead of magic link.

---

## 🔴 Issue 3: Users Showing as "null null"

### Problem:
- User names not being fetched/displayed
- Shows "null null" in Winner Selection
- Profile data incomplete

### Root Cause:
Profile not being created after signup OR profile fetch failing

### Fix Required:

**File: `lib/core/services/auth_service.dart`**

Ensure profile is created immediately after signup:
```dart
static Future<void> signUp({
  required String email,
  required String password,
  required String fullName,
  required String phoneNumber,
  required String dateOfBirth,
}) async {
  // Sign up user
  final response = await _client.auth.signUp(
    email: email,
    password: password,
  );

  if (response.user != null) {
    // CRITICAL: Create profile immediately
    await _client.from('profiles').insert({
      'id': response.user!.id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth, // MUST be YYYY-MM-DD format
      'created_at': DateTime.now().toIso8601String(),
    });

    // CRITICAL: Create wallet for user
    await _client.from('wallets').insert({
      'user_id': response.user!.id,
      'available_balance': 0,
      'locked_balance': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
```

---

## 🔴 Issue 4: Users Not Showing in Admin Panel

### Problem:
- New users not visible in admin panel
- Cannot manage users

### Root Cause:
- Profile not being created
- RLS policies blocking admin access
- Admin role not set

### Fix Required:

**1. Check RLS Policies in Supabase:**

Run this SQL in Supabase SQL Editor:
```sql
-- Allow admins to see all profiles
CREATE POLICY "Admins can view all profiles"
ON profiles FOR SELECT
TO authenticated
USING (
  auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  )
);

-- Allow admins to update any profile
CREATE POLICY "Admins can update all profiles"
ON profiles FOR UPDATE
TO authenticated
USING (
  auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  )
);
```

**2. Set Your Account as Admin:**

```sql
-- Replace with your email
UPDATE profiles 
SET role = 'admin' 
WHERE email = 'your-email@gmail.com';
```

---

## 🔴 Issue 5: Winner Selection Error - "No eligible members"

### Problem:
- Error: `PostgrestException: No eligible members found to win`
- Shows "null null" for member name

### Root Cause:
- Members don't have proper profile data
- Winner selection RPC not finding members correctly

### Fix Required:

**File: Database RPC Function**

Update `select_random_winner` function:
```sql
CREATE OR REPLACE FUNCTION select_random_winner(p_pool_id UUID)
RETURNS JSON AS $$
DECLARE
  v_winner RECORD;
  v_pool RECORD;
BEGIN
  -- Get pool details
  SELECT * INTO v_pool FROM pools WHERE id = p_pool_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pool not found';
  END IF;
  
  -- Get eligible members (paid current cycle, not won yet)
  SELECT 
    pm.user_id,
    p.full_name,
    p.email
  INTO v_winner
  FROM pool_members pm
  JOIN profiles p ON p.id = pm.user_id
  WHERE pm.pool_id = p_pool_id
    AND pm.status = 'active'
    AND pm.user_id NOT IN (
      SELECT winner_id 
      FROM pool_winners 
      WHERE pool_id = p_pool_id
    )
  ORDER BY RANDOM()
  LIMIT 1;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No eligible members found to win' USING ERRCODE = 'P0001';
  END IF;
  
  -- Record winner
  INSERT INTO pool_winners (pool_id, winner_id, round_number, amount)
  VALUES (p_pool_id, v_winner.user_id, v_pool.current_round, v_pool.contribution_amount);
  
  RETURN json_build_object(
    'winner_id', v_winner.user_id,
    'winner_name', v_winner.full_name,
    'winner_email', v_winner.email,
    'amount', v_pool.contribution_amount
  );
END;
$$ LANGUAGE plpgsql;
```

---

## 🔴 Issue 6: Wallet Rate Limit Error

### Problem:
- "Rate limit exceeded. Please try again in a minute."

### Root Cause:
Too many wallet update requests in short time

### Fix Required:

**File: `lib/core/services/wallet_service.dart`**

Add debouncing to wallet updates:
```dart
static DateTime? _lastWalletUpdate;

static Future<Map<String, dynamic>> getWalletBalance() async {
  // Prevent rapid successive calls
  if (_lastWalletUpdate != null) {
    final diff = DateTime.now().difference(_lastWalletUpdate!);
    if (diff.inSeconds < 2) {
      await Future.delayed(Duration(seconds: 2 - diff.inSeconds));
    }
  }
  
  _lastWalletUpdate = DateTime.now();
  
  // Rest of the code...
}
```

---

## 🔴 Issue 7: Delete User Failing

### Problem:
- "Failed to delete user: Database error deleting user"

### Root Cause:
Foreign key constraints preventing deletion

### Fix Required:

**Option 1: Soft Delete (Recommended)**
```sql
-- Add deleted_at column
ALTER TABLE profiles ADD COLUMN deleted_at TIMESTAMP;

-- Update delete function to soft delete
CREATE OR REPLACE FUNCTION soft_delete_user(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE profiles 
  SET deleted_at = NOW(),
      status = 'deleted'
  WHERE id = p_user_id;
  
  -- Disable auth
  UPDATE auth.users 
  SET banned_until = 'infinity'
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Option 2: Cascade Delete**
```sql
-- Delete all related records first
CREATE OR REPLACE FUNCTION delete_user_cascade(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Delete in order of dependencies
  DELETE FROM transactions WHERE user_id = p_user_id;
  DELETE FROM pool_members WHERE user_id = p_user_id;
  DELETE FROM wallets WHERE user_id = p_user_id;
  DELETE FROM notifications WHERE user_id = p_user_id;
  DELETE FROM profiles WHERE id = p_user_id;
  
  -- Delete from auth
  DELETE FROM auth.users WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 📋 IMMEDIATE ACTION ITEMS

### Priority 1 (Fix Now):
1. ✅ Fix date format in signup (DD/MM/YYYY → YYYY-MM-DD)
2. ✅ Ensure profile creation after signup
3. ✅ Ensure wallet creation after signup
4. ✅ Set your account as admin

### Priority 2 (Fix Today):
5. ✅ Fix winner selection to show proper names
6. ✅ Add wallet rate limiting
7. ✅ Fix user deletion (use soft delete)

### Priority 3 (Fix This Week):
8. ✅ Configure deep linking for email verification
9. ✅ Add proper error messages
10. ✅ Test complete signup flow

---

## 🧪 Testing Checklist

After fixes:
- [ ] Sign up new user with phone number
- [ ] Verify date of birth saves correctly
- [ ] Check user appears in admin panel
- [ ] Verify user name shows (not "null null")
- [ ] Test winner selection
- [ ] Test wallet operations
- [ ] Test user deletion

---

## 🔧 Quick SQL Fixes to Run Now

```sql
-- 1. Set yourself as admin
UPDATE profiles SET role = 'admin' WHERE email = 'YOUR_EMAIL@gmail.com';

-- 2. Fix existing users with null names
UPDATE profiles 
SET full_name = 'User ' || SUBSTRING(id::text, 1, 8)
WHERE full_name IS NULL OR full_name = '';

-- 3. Create missing wallets
INSERT INTO wallets (user_id, available_balance, locked_balance)
SELECT id, 0, 0 
FROM profiles 
WHERE id NOT IN (SELECT user_id FROM wallets);

-- 4. Check for users without profiles
SELECT u.id, u.email 
FROM auth.users u 
LEFT JOIN profiles p ON p.id = u.id 
WHERE p.id IS NULL;
```

---

All issues are fixable! Start with Priority 1 fixes first.
