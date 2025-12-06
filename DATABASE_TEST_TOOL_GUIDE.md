# 🧪 DATABASE TEST TOOL - Quick Setup Guide

## ✅ **NEW FEATURE ADDED: Database Test Screen**

I've added a built-in database testing tool to your app that will help you verify if everything is set up correctly!

## 📱 **How to Use the Database Test Tool:**

### Step 1: Restart the App
```bash
# Stop the current flutter run
# Then restart:
flutter run
```

### Step 2: Access the Test Screen
1. Open the app
2. Go to **Settings** (bottom navigation)
3. Scroll down to the **Account** section
4. Tap on **"Database Test"**

### Step 3: Review Test Results
The screen will automatically run tests and show you:

- ✅ **Green checkmarks** = Everything is working
- ❌ **Red X marks** = Something needs to be fixed
- ⚠️ **Orange warnings** = Optional issues

## 🔍 **What the Test Checks:**

1. **Supabase Connection** - Is the app connected to Supabase?
2. **User Login** - Are you logged in?
3. **Profiles Table** - Does it exist and is it accessible?
4. **Phone Column** - Does the phone column exist in profiles?
5. **Address Columns** - Do address, city, state columns exist?
6. **Identity Columns** - Do PAN and Aadhaar columns exist?
7. **Bank Accounts Table** - Does the table exist?
8. **Pools Table** - Does it exist?
9. **Wallets Table** - Does it exist?

## 📋 **If You See Red X Marks:**

The test screen will tell you exactly what to do! Usually:

### Fix Missing Columns:
1. Go to **Supabase Dashboard** → **SQL Editor**
2. Copy content from `supabase/ADD_PROFILE_COLUMNS.sql`
3. Paste and **Run** in SQL Editor
4. Wait for success message

### Fix Missing Bank Accounts Table:
1. Go to **Supabase Dashboard** → **SQL Editor**
2. Copy content from `supabase/CREATE_BANK_ACCOUNTS.sql`
3. Paste and **Run** in SQL Editor
4. Wait for success message

### After Running SQL Scripts:
1. Go back to the app
2. Tap the **refresh icon** (top right of Database Test screen)
3. All tests should now pass! ✅

## 🎯 **Expected Results:**

### ✅ All Tests Passing:
```
✅ Supabase client initialized
✅ User logged in: your@email.com
✅ Profiles table exists and accessible
   Name: Your Name
✅ Phone column exists
   Phone: +91 1234567890
✅ Address columns exist
   Address: Your address
✅ Identity document columns exist
   PAN: ABCDE1234F
✅ Bank accounts table exists
   Accounts: 0
✅ Pools table exists
✅ Wallets table exists

📋 SUMMARY:
✅ All tests passed!
Database is properly configured.
```

### ❌ Tests Failing (Before Running SQL):
```
✅ Supabase client initialized
✅ User logged in: your@email.com
✅ Profiles table exists and accessible
   Name: Your Name
❌ Phone column MISSING! Run ADD_PROFILE_COLUMNS.sql
❌ Address columns MISSING! Run ADD_PROFILE_COLUMNS.sql
❌ Identity columns MISSING! Run ADD_PROFILE_COLUMNS.sql
❌ Bank accounts table MISSING! Run CREATE_BANK_ACCOUNTS.sql
✅ Pools table exists
✅ Wallets table exists

📋 SUMMARY:
⚠️ Some tests failed!

TO FIX:
1. Go to Supabase Dashboard → SQL Editor
2. Run ADD_PROFILE_COLUMNS.sql
3. Run CREATE_BANK_ACCOUNTS.sql
4. Restart the app
```

## 🚀 **Quick Fix Workflow:**

1. **Open Database Test** (Settings → Database Test)
2. **See what's missing** (red X marks)
3. **Run SQL scripts** in Supabase
4. **Tap refresh** in the test screen
5. **Verify all green** ✅
6. **Test Personal Details** (Settings → Personal Details → Edit)

## 📁 **Files Created:**

1. ✅ `lib/features/debug/database_test_screen.dart` - Test screen
2. ✅ Updated `lib/core/router/app_router.dart` - Added route
3. ✅ Updated `lib/features/profile/presentation/screens/settings_screen.dart` - Added menu item

## 💡 **Pro Tips:**

1. **Run this test FIRST** before trying to edit personal details
2. **Use the refresh button** after running SQL scripts
3. **Share the test results** if you need help debugging
4. **All tests must pass** before Personal Details will work

## 🎉 **Benefits:**

- ✅ **No more guessing** - Know exactly what's wrong
- ✅ **Quick diagnosis** - See all issues at once
- ✅ **Clear instructions** - Tells you exactly how to fix
- ✅ **Built-in** - No need to check logs or console
- ✅ **Instant feedback** - Refresh to see if fixes worked

## 📸 **How to Share Results:**

If you need help, you can:
1. Take a screenshot of the Database Test screen
2. Share it to get specific help
3. The test results show exactly what's configured

---

**Now you have a powerful diagnostic tool built right into your app!** 🎊

Just go to **Settings → Database Test** to verify everything is working correctly!
