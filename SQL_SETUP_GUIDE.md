# Coin Circle - SQL Setup Guide

## 🎯 What You Need to Do

You have **3 SQL files** that need to be run in your **Supabase SQL Editor** in the correct order.

---

## 📝 Step-by-Step Instructions

### Step 1: Open Supabase Dashboard
1. Go to https://supabase.com
2. Select your "Coin Circle" project
3. Click on **SQL Editor** in the left sidebar

### Step 2: Run SQL Scripts (IN THIS ORDER!)

#### Script 1: SAFE_SETUP.sql
**Location:** `coin_circle/supabase/SAFE_SETUP.sql`

**What it does:**
- Adds personal details columns to profiles table
- Creates bank_accounts table
- Sets up RLS policies
- Creates helper functions

**How to run:**
1. Open the file in VS Code
2. Copy ALL content (Ctrl+A, Ctrl+C)
3. Paste into Supabase SQL Editor
4. Click "Run" button
5. Wait for success message ✅

---

#### Script 2: FIX_POOL_JOIN_RPC.sql
**Location:** `FIX_POOL_JOIN_RPC.sql` (in root folder)

**What it does:**
- Creates `request_join_pool()` function - handles join requests
- Creates `complete_join_payment()` function - handles payment after approval

**How to run:**
1. Open the file in VS Code
2. Copy ALL content (Ctrl+A, Ctrl+C)
3. Paste into Supabase SQL Editor
4. Click "Run" button
5. Wait for success message ✅

---

#### Script 3: FIX_ADMIN_RPC.sql
**Location:** `FIX_ADMIN_RPC.sql` (in root folder)

**What it does:**
- Creates `get_admin_stats()` - provides admin dashboard statistics
- Creates `get_revenue_chart_data()` - provides revenue chart data
- Creates `process_withdrawal()` - handles withdrawal requests
- Creates `approve_deposit_request()` - handles deposit approvals

**How to run:**
1. Open the file in VS Code
2. Copy ALL content (Ctrl+A, Ctrl+C)
3. Paste into Supabase SQL Editor
4. Click "Run" button
5. Wait for success message ✅

---

## ✅ Verification

After running all 3 scripts, verify they worked:

```sql
-- Run this query in Supabase SQL Editor to check if functions exist
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
  'request_join_pool',
  'complete_join_payment',
  'get_admin_stats',
  'get_revenue_chart_data',
  'process_withdrawal',
  'approve_deposit_request'
);
```

You should see all 6 function names listed.

---

## 🚨 Common Issues

### Issue: "function already exists"
**Solution:** This is OK! It means the function was created before. The `CREATE OR REPLACE` will update it.

### Issue: "column does not exist"
**Solution:** Make sure you ran `SAFE_SETUP.sql` first.

### Issue: "table does not exist"
**Solution:** You need to run the main database setup scripts first. Check if you have:
- `01_setup_tables.sql`
- `02_setup_functions.sql`

---

## 🎉 After Running All Scripts

Your app will have:
1. ✅ Secure pool joining with approval flow
2. ✅ Working admin dashboard with real stats
3. ✅ Proper payment processing
4. ✅ Withdrawal and deposit management
5. ✅ Profile and bank account management

---

## 📱 Google OAuth Setup (Separate)

After SQL setup, configure Google Sign-In:

1. Go to Supabase Dashboard → Authentication → Providers
2. Enable Google
3. Add Client ID: `230304073460-rdk5ffqtf9uecllum568unm41d2c6joh.apps.googleusercontent.com`
4. Add Client Secret (from Google Cloud Console)
5. Add redirect URI: `https://your-project-ref.supabase.co/auth/v1/callback`

---

## 🆘 Need Help?

If you encounter any errors:
1. Copy the exact error message
2. Note which SQL script caused it
3. Check if you ran scripts in the correct order
4. Verify your database has the required tables

---

**Created:** 2025-12-01
**Version:** 1.0
