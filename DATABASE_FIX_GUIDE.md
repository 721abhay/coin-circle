# 📋 STEP-BY-STEP GUIDE TO FIX DATABASE

## 🎯 Goal
Fix all user data issues and set yourself as admin.

---

## 📍 Where to Run This
**Supabase Dashboard** → **SQL Editor**

---

## ⚠️ IMPORTANT
**DO NOT run the entire file at once!**
Run each step ONE AT A TIME and check the results.

---

## 🔧 Step-by-Step Instructions

### STEP 1: Set Yourself as Admin ⭐

**What to do:**
1. Open `supabase/STEP_BY_STEP_FIX.sql`
2. Find line 9: `WHERE email = 'YOUR_EMAIL@gmail.com';`
3. Replace `YOUR_EMAIL@gmail.com` with your actual email
4. Copy ONLY these lines:

```sql
UPDATE profiles 
SET role = 'admin' 
WHERE email = 'your-actual-email@gmail.com';

SELECT id, email, role FROM profiles WHERE role = 'admin';
```

5. Paste in Supabase SQL Editor
6. Click **RUN**
7. You should see 1 row with your email and role = 'admin'

✅ **Success:** You see your email with role = 'admin'
❌ **Failed:** No rows returned → Check your email is correct

---

### STEP 2: Fix Null User Names

**What to do:**
1. Copy these lines:

```sql
UPDATE profiles 
SET full_name = 'User ' || SUBSTRING(id::text, 1, 8)
WHERE full_name IS NULL OR full_name = '' OR full_name = 'null null';

SELECT id, full_name FROM profiles WHERE full_name LIKE 'User %';
```

2. Paste in SQL Editor
3. Click **RUN**
4. You should see users with names like "User 12345678"

✅ **Success:** See list of users with generated names
❌ **Failed:** Error message → Copy error and ask for help

---

### STEP 3: Create Missing Wallets

**What to do:**
1. Copy these lines:

```sql
INSERT INTO wallets (user_id, available_balance, locked_balance, created_at)
SELECT id, 0, 0, NOW() 
FROM profiles 
WHERE id NOT IN (SELECT user_id FROM wallets)
ON CONFLICT (user_id) DO NOTHING;

SELECT COUNT(*) as wallets_created FROM wallets;
```

2. Paste in SQL Editor
3. Click **RUN**
4. You should see the total number of wallets

✅ **Success:** See wallet count
❌ **Failed:** Error → Skip this step for now

---

### STEP 4: Check for Orphaned Users

**What to do:**
1. Copy these lines:

```sql
SELECT 
  u.id, 
  u.email,
  u.created_at
FROM auth.users u 
LEFT JOIN profiles p ON p.id = u.id 
WHERE p.id IS NULL;
```

2. Paste in SQL Editor
3. Click **RUN**

✅ **If you see 0 rows:** Good! Skip STEP 5
✅ **If you see some rows:** Continue to STEP 5

---

### STEP 5: Create Profiles for Orphaned Users
**(Only if STEP 4 found users)**

**What to do:**
1. Copy these lines:

```sql
INSERT INTO profiles (id, email, full_name, created_at)
SELECT 
  u.id,
  u.email,
  'User ' || SUBSTRING(u.id::text, 1, 8),
  u.created_at
FROM auth.users u
LEFT JOIN profiles p ON p.id = u.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;
```

2. Paste in SQL Editor
3. Click **RUN**

✅ **Success:** Profiles created
❌ **Failed:** Skip for now

---

### STEP 6: Remove Old Admin Policies

**What to do:**
1. Copy these lines:

```sql
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can delete profiles" ON profiles;
```

2. Paste in SQL Editor
3. Click **RUN**

✅ **Success:** "DROP POLICY" message (or "does not exist" is OK)
❌ **Failed:** Error → Continue anyway

---

### STEP 7: Create New Admin Policies

**What to do:**
1. Copy these lines (ALL 3 policies together):

```sql
CREATE POLICY "Admins can view all profiles"
ON profiles FOR SELECT
TO authenticated
USING (
  auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  )
);

CREATE POLICY "Admins can update all profiles"
ON profiles FOR UPDATE
TO authenticated
USING (
  auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  )
);

CREATE POLICY "Admins can delete profiles"
ON profiles FOR DELETE
TO authenticated
USING (
  auth.uid() IN (
    SELECT id FROM profiles WHERE role = 'admin'
  )
);
```

2. Paste in SQL Editor
3. Click **RUN**

✅ **Success:** "CREATE POLICY" messages
❌ **Failed:** "already exists" → Run STEP 6 again first

---

### STEP 8: Verify Everything

**What to do:**
1. Copy these lines:

```sql
-- Check users
SELECT 
  COUNT(*) as total_users,
  COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_count,
  COUNT(CASE WHEN full_name IS NULL OR full_name = '' THEN 1 END) as null_names
FROM profiles;

-- Check wallets
SELECT 
  COUNT(DISTINCT p.id) as users_with_profiles,
  COUNT(DISTINCT w.user_id) as users_with_wallets
FROM profiles p
LEFT JOIN wallets w ON w.user_id = p.id;

-- Check policies
SELECT policyname 
FROM pg_policies 
WHERE tablename = 'profiles' AND policyname LIKE 'Admins%';
```

2. Paste in SQL Editor
3. Click **RUN**

**You should see:**
- admin_count: 1 (you)
- null_names: 0 (no null names)
- users_with_profiles = users_with_wallets (same number)
- 3 policies listed

✅ **All Good!** → Continue to rebuild APK
❌ **Issues:** → Note which step failed and ask for help

---

## 🚀 After All Steps Complete

### Rebuild APK:
```bash
cd "c:\Users\ABHAY\coin circle\coin_circle"
flutter build apk --release
```

### APK Location:
```
build\app\outputs\flutter-apk\app-release.apk
```

### Test:
1. Install new APK on phone
2. Sign up new user
3. Enter date of birth
4. Check user appears in admin panel
5. Verify name shows (not "null null")

---

## 🆘 Common Errors

### "syntax error at or near NOT"
→ You're running old file. Use `STEP_BY_STEP_FIX.sql`

### "policy already exists"
→ Run STEP 6 first to drop old policies

### "relation does not exist"
→ Table doesn't exist. Skip that step.

### "permission denied"
→ You're not admin yet. Make sure STEP 1 worked.

---

## ✅ Success Checklist

After completing all steps:
- [ ] You are admin (STEP 1)
- [ ] No users with null names (STEP 2)
- [ ] All users have wallets (STEP 3)
- [ ] 3 admin policies created (STEP 7)
- [ ] Verification queries pass (STEP 8)
- [ ] APK rebuilt
- [ ] Tested signup on phone

---

**Good luck! Take it slow, one step at a time.** 🎉
