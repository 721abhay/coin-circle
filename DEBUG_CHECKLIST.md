# 🔍 DEBUGGING CHECKLIST - Post-Login Issues

## Common Issues After Login:

### 1. Check User Authentication
- Is user ID being retrieved correctly?
- Check SupabaseConfig.currentUserId

### 2. Check Wallet Loading
- Does wallet exist in database?
- Is getWallet() being called?
- Any errors in console?

### 3. Check Pools Loading
- Are pools being fetched?
- Check getUserPools() response
- Any RLS (Row Level Security) issues?

### 4. Check Navigation
- Can you navigate between screens?
- Any routing errors?

---

## Quick Fixes to Try:

### Fix 1: Check if User ID is Available
The issue might be that services are trying to access data before user ID is ready.

### Fix 2: Add Error Logging
Add console logs to see what's failing.

### Fix 3: Check Supabase Connection
Verify .env file has correct credentials.

---

## Files to Check:

1. `lib/core/config/supabase_config.dart` - User ID
2. `lib/core/services/wallet_service.dart` - Wallet loading
3. `lib/core/services/pool_service.dart` - Pool loading
4. `lib/features/dashboard/presentation/screens/home_screen.dart` - Data loading

---

## Debug Steps:

1. Check console for errors
2. Verify user is authenticated
3. Check if wallet is created
4. Verify pools are loading
5. Check navigation works

---

**Please provide**:
- Which features are broken?
- Any error messages?
- Screenshots if possible?
