# 🔧 TROUBLESHOOTING GUIDE - Features Not Working After Login

## 🚨 IMMEDIATE ACTION

### Step 1: Run Diagnostic Tool

I've created a diagnostic screen to identify the exact issue!

**How to access**:
1. While app is running, manually navigate to: `/diagnostic`
2. Or add a button temporarily to home screen:
   ```dart
   ElevatedButton(
     onPressed: () => context.push('/diagnostic'),
     child: const Text('Run Diagnostics'),
   )
   ```

The diagnostic will check:
- ✅ User authentication
- ✅ Wallet loading
- ✅ Pools loading
- ✅ Transactions
- ✅ Supabase connection

---

## 🔍 COMMON ISSUES & FIXES

### Issue 1: "User not authenticated" Error
**Symptoms**: Can't load any data
**Fix**:
```dart
// Check if user is logged in
final user = Supabase.instance.client.auth.currentUser;
if (user == null) {
  // Navigate to login
  context.go('/login');
}
```

### Issue 2: Wallet Shows Nil/Error
**Symptoms**: Wallet screen crashes or shows error
**Possible Causes**:
1. Wallet table doesn't exist
2. RLS (Row Level Security) blocking access
3. User ID not matching

**Fix**: The auto-create wallet should handle this, but check:
```sql
-- In Supabase SQL Editor
SELECT * FROM wallets WHERE user_id = 'YOUR_USER_ID';
```

### Issue 3: Pools Not Loading
**Symptoms**: My Pools screen is empty
**Possible Causes**:
1. No pools created yet (expected)
2. RLS blocking access
3. Query error

**Fix**: Check console for errors

### Issue 4: Navigation Not Working
**Symptoms**: Can't navigate between screens
**Fix**: Check if routes are properly defined in `app_router.dart`

---

## 🛠️ MANUAL DEBUGGING STEPS

### 1. Check Console Output
Look for these messages:
- ✅ "Wallet not found, creating new wallet..." (Good!)
- ❌ "Error fetching wallet..." (Bad - check error)
- ❌ "User not authenticated" (Need to login)

### 2. Check Supabase Dashboard
1. Go to Supabase Dashboard
2. Check Table Editor
3. Look for:
   - `wallets` table - should have entry for your user
   - `profiles` table - should have your profile
   - `pools` table - check if pools exist

### 3. Check RLS Policies
In Supabase:
1. Go to Authentication > Policies
2. Check `wallets` table policies
3. Ensure SELECT policy allows users to see their own wallet

---

## 📋 SPECIFIC FEATURE CHECKS

### Home Screen Not Loading?
**Check**:
1. Is `_loadDashboardData()` being called?
2. Any errors in console?
3. Is `_isLoading` stuck at true?

**Quick Fix**:
```dart
// Add this to home_screen.dart initState
@override
void initState() {
  super.initState();
  print('🏠 Home Screen: Loading dashboard data...');
  _loadDashboardData();
}
```

### Wallet Screen Not Loading?
**Check**:
1. Is `WalletService.getWallet()` throwing error?
2. Check console for "Error fetching/creating wallet"

**Quick Fix**: Already applied - auto-create wallet

### Pools Screen Empty?
**This might be normal!**
- If you haven't created any pools, it will be empty
- Try creating a pool first

---

## 🔥 EMERGENCY FIXES

### Fix 1: Force Wallet Creation
```dart
// Run this once in Supabase SQL Editor
INSERT INTO wallets (user_id, available_balance, locked_balance, total_winnings)
VALUES ('YOUR_USER_ID', 0, 0, 0)
ON CONFLICT (user_id) DO NOTHING;
```

### Fix 2: Check User ID
```dart
// Add to any screen to see user ID
print('Current User ID: ${Supabase.instance.client.auth.currentUser?.id}');
```

### Fix 3: Reset App State
```bash
# Stop app
# Clear app data on device
# Restart app
flutter run
```

---

## 📞 WHAT TO TELL ME

Please provide:

1. **Which specific features aren't working?**
   - [ ] Home screen
   - [ ] Wallet screen
   - [ ] My Pools screen
   - [ ] Create Pool
   - [ ] Navigation
   - [ ] Other: ___________

2. **Error messages** (if any):
   ```
   Copy error from console here
   ```

3. **Diagnostic results** (after running diagnostic screen):
   ```
   Copy diagnostic output here
   ```

4. **Screenshots** (if possible)

---

## 🎯 NEXT STEPS

1. ✅ Run the diagnostic screen (`/diagnostic`)
2. ✅ Check console for errors
3. ✅ Tell me which specific features are broken
4. ✅ Share diagnostic output
5. ✅ I'll provide targeted fix

---

**Created**: 2025-11-22 23:32 IST
**Status**: Waiting for diagnostic results
**Priority**: HIGH
