# 🚀 CRITICAL: Database Setup Guide

## ⚠️ **STOP! READ THIS FIRST**

Your app **WILL NOT WORK** until you run these SQL scripts in Supabase!

---

## 📋 **STEP-BY-STEP SETUP PROCESS**

### **Step 1: Access Supabase SQL Editor**

1. Go to [https://supabase.com](https://supabase.com)
2. Login to your account
3. Select your project
4. Click **"SQL Editor"** in the left sidebar
5. Click **"New Query"**

---

### **Step 2: Run Scripts IN THIS EXACT ORDER**

⚠️ **IMPORTANT**: Run these ONE AT A TIME, in order. Wait for each to complete before running the next.

#### **Phase 1: Core Setup (REQUIRED)**

```sql
-- 1. FIRST: Run complete_setup.sql
-- This creates all base tables and enums
-- File: supabase/complete_setup.sql
-- Expected: "Success. No rows returned"
```

```sql
-- 2. SECOND: Run fix_join_pool.sql
-- This adds 'pending' status and join functions
-- File: supabase/fix_join_pool.sql
-- Expected: "Success. No rows returned"
```

```sql
-- 3. THIRD: Run security_tables.sql
-- This creates security-related tables
-- File: supabase/security_tables.sql
-- Expected: "Success. No rows returned"
```

```sql
-- 4. FOURTH: Run rpc_definitions.sql
-- This creates all RPC functions
-- File: supabase/rpc_definitions.sql
-- Expected: "Success. No rows returned"
```

```sql
-- 5. FIFTH: Run triggers.sql
-- This creates all database triggers
-- File: supabase/triggers.sql
-- Expected: "Success. No rows returned"
```

```sql
-- 6. SIXTH: Run advanced_security.sql
-- This adds advanced security features
-- File: supabase/advanced_security.sql
-- Expected: "Success. No rows returned"
```

#### **Phase 2: Migrations (OPTIONAL - Only if needed)**

These are incremental updates. Only run if you need specific features:

```sql
-- Chat System
-- File: supabase/migrations/014_create_pool_messages.sql
-- File: supabase/migrations/015_fix_chat_rls.sql

-- Admin Features
-- File: supabase/migrations/016_admin_system.sql

-- Voting System
-- File: supabase/migrations/017_democratic_voting.sql

-- Notifications
-- File: supabase/migrations/028_notifications_system.sql

-- Gamification
-- File: supabase/migrations/027_gamification_and_features.sql
```

---

## ✅ **VERIFICATION CHECKLIST**

After running the scripts, verify everything is set up correctly:

### **1. Check Tables Exist**

Go to Supabase → **Table Editor** → Verify these tables exist:

- [ ] `profiles`
- [ ] `wallets`
- [ ] `pools`
- [ ] `pool_members`
- [ ] `transactions`
- [ ] `notifications`
- [ ] `winner_history`
- [ ] `security_logs`
- [ ] `user_sessions`
- [ ] `kyc_submissions`

### **2. Check RPC Functions**

Go to Supabase → **Database** → **Functions** → Verify these exist:

- [ ] `get_pool_by_invite_code`
- [ ] `join_pool_secure`
- [ ] `select_random_winner`
- [ ] `cast_vote`
- [ ] `get_user_stats`
- [ ] `verify_transaction_pin`

### **3. Check Triggers**

Go to Supabase → **Database** → **Triggers** → Verify these exist:

- [ ] `update_wallet_on_transaction`
- [ ] `create_wallet_on_signup`
- [ ] `update_pool_statistics`

### **4. Test Basic Functionality**

Run these test queries in SQL Editor:

```sql
-- Test 1: Check if you can create a profile
SELECT * FROM profiles LIMIT 1;

-- Test 2: Check if wallets table is ready
SELECT * FROM wallets LIMIT 1;

-- Test 3: Check if RPC works
SELECT get_pool_by_invite_code('TEST123');

-- Test 4: Check if enums are correct
SELECT enum_range(NULL::member_status_enum);
-- Should return: {active,inactive,removed,pending}
```

---

## 🐛 **TROUBLESHOOTING**

### **Error: "relation already exists"**

**Solution**: The table already exists. Skip that script or run `reset_db.sql` first (⚠️ WARNING: This deletes ALL data!)

### **Error: "function already exists"**

**Solution**: The function already exists. You can either:
1. Skip it
2. Drop and recreate: `DROP FUNCTION function_name CASCADE;`

### **Error: "type already exists"**

**Solution**: The enum already exists. Skip it.

### **Error: "permission denied"**

**Solution**: Make sure you're logged in as the project owner.

---

## 🚨 **EMERGENCY RESET (Use with Caution!)**

⚠️ **WARNING**: This will DELETE ALL DATA!

Only use if you need to start fresh:

```sql
-- File: supabase/reset_db.sql
-- This drops all tables and starts over
-- ⚠️ YOU WILL LOSE ALL DATA!
```

---

## 📊 **WHAT EACH SCRIPT DOES**

### **complete_setup.sql**
- Creates all base tables (profiles, wallets, pools, etc.)
- Creates all enums (pool_status, member_status, etc.)
- Sets up Row Level Security (RLS) policies
- Creates indexes for performance

### **fix_join_pool.sql**
- Adds 'pending' to member_status_enum
- Creates `get_pool_by_invite_code` RPC
- Creates `join_pool_secure` RPC
- Adds notification logic for join requests

### **security_tables.sql**
- Creates security_logs table
- Creates user_sessions table
- Creates kyc_submissions table
- Creates fraud_detection table
- Sets up security monitoring

### **rpc_definitions.sql**
- Creates all RPC (Remote Procedure Call) functions
- These are server-side functions that bypass RLS
- Used for complex operations like winner selection

### **triggers.sql**
- Creates database triggers
- Auto-updates wallet balances
- Auto-creates wallets on signup
- Auto-updates pool statistics

### **advanced_security.sql**
- Adds rate limiting
- Adds transaction velocity checks
- Adds IP whitelisting
- Adds device fingerprinting
- Adds audit trails

---

## 🎯 **QUICK START (Copy-Paste Method)**

### **Method 1: Run All at Once (Risky)**

⚠️ Only if you're sure your database is empty:

```sql
-- Copy entire contents of complete_setup.sql and paste here
-- Then run

-- Copy entire contents of fix_join_pool.sql and paste here
-- Then run

-- Copy entire contents of security_tables.sql and paste here
-- Then run

-- Copy entire contents of rpc_definitions.sql and paste here
-- Then run

-- Copy entire contents of triggers.sql and paste here
-- Then run

-- Copy entire contents of advanced_security.sql and paste here
-- Then run
```

### **Method 2: Run One by One (Recommended)**

1. Open `complete_setup.sql` in your editor
2. Copy ALL contents (Ctrl+A, Ctrl+C)
3. Paste in Supabase SQL Editor
4. Click "Run"
5. Wait for "Success"
6. Repeat for each file in order

---

## ✅ **AFTER SETUP**

Once all scripts are run successfully:

1. ✅ **Test the app**:
   - Try creating an account
   - Check if wallet is created automatically
   - Try creating a pool
   - Try joining a pool

2. ✅ **Check Supabase Dashboard**:
   - Go to Table Editor
   - Verify data is being saved
   - Check wallet balances
   - Check transactions

3. ✅ **Monitor for errors**:
   - Check Supabase Logs
   - Look for any RLS policy errors
   - Look for any trigger errors

---

## 🆘 **NEED HELP?**

If you encounter errors:

1. **Check the error message** - It usually tells you what's wrong
2. **Check if table/function already exists** - Skip if it does
3. **Check your Supabase plan** - Free tier has limits
4. **Check RLS policies** - Make sure they're not blocking you

---

## 📝 **COMPLETION CHECKLIST**

- [ ] Ran `complete_setup.sql` successfully
- [ ] Ran `fix_join_pool.sql` successfully
- [ ] Ran `security_tables.sql` successfully
- [ ] Ran `rpc_definitions.sql` successfully
- [ ] Ran `triggers.sql` successfully
- [ ] Ran `advanced_security.sql` successfully
- [ ] Verified all tables exist
- [ ] Verified all RPC functions exist
- [ ] Verified all triggers exist
- [ ] Tested basic app functionality
- [ ] No errors in Supabase logs

---

**Once this checklist is complete, your database is ready!** ✅

**Next Step**: Test the app end-to-end and fix any bugs you find.
