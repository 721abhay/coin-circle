# Quick Fix Instructions

## Problem
1. Admin tab showing for all users (should only show for admin)
2. KYC approval not working (users still can't create pools after approval)

## Solution - Follow These Steps EXACTLY:

### Step 1: Run SQL Script in Supabase
1. Open Supabase Dashboard → SQL Editor
2. Copy and paste the content from: `supabase/FIX_ADMIN_AND_KYC.sql`
3. **IMPORTANT**: Update line 9 with YOUR admin email:
   ```sql
   WHERE email IN (
     'YOUR_ADMIN_EMAIL@gmail.com',  -- Replace with your actual email
   );
   ```
4. Click **Run**

### Step 2: Verify in Supabase
After running the script, you should see output showing:
- Only your email has `is_admin = true`
- All other users have `is_admin = false`
- Users with approved KYC have `kyc_verified = true`

### Step 3: Restart the App
**IMPORTANT**: You MUST do a FULL restart, not just hot reload!

In your terminal where `flutter run` is running:
1. Press `R` (capital R) for full restart
2. OR stop the app (Ctrl+C) and run `flutter run` again

### Step 4: Test
1. **As Regular User** (sb7327905@gmail.com):
   - Bottom navigation should show: Home, My Pools, Wallet, Profile
   - NO Admin tab
   
2. **As Admin User** (your email):
   - Bottom navigation should show: Home, My Pools, Wallet, Profile, Admin
   - Admin tab visible

3. **After KYC Approval**:
   - User should be able to create pools
   - No "KYC verification required" error

## If It Still Doesn't Work:

### Check 1: Verify Database
Run this in Supabase SQL Editor:
```sql
SELECT email, is_admin, kyc_verified FROM profiles;
```

You should see:
- Your admin email: `is_admin = true`
- Other users: `is_admin = false`

### Check 2: Check App Logs
Look at the Flutter console output for:
```
Admin status check: true   (for admin user)
Admin status check: false  (for regular users)
```

### Check 3: Clear App Data
If the app is caching old data:
1. Uninstall the app from your phone
2. Run `flutter run` again
3. Login and test

## What Each File Does:

1. **FIX_ADMIN_AND_KYC.sql** - Main fix script
   - Removes admin from all users
   - Sets admin only for your email
   - Syncs KYC verification status

2. **SET_ADMIN_ONLY.sql** - Simpler version (just admin fix)
   - Use this if you only want to fix admin access

## Common Mistakes:

❌ **Don't**: Run `COMPLETE_KYC_SETUP.sql` - it sets ALL users as admin
✅ **Do**: Run `FIX_ADMIN_AND_KYC.sql` with your email updated

❌ **Don't**: Just hot reload (press 'r')
✅ **Do**: Full restart (press 'R' or restart flutter run)

❌ **Don't**: Forget to update the email in the SQL script
✅ **Do**: Replace 'santoshbs4842795@gmail.com' with your actual admin email
