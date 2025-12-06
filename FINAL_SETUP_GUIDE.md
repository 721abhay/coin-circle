# 🚀 Coin Circle - Final Database Setup Guide

To ensure the app works correctly, you MUST run the following SQL scripts in your Supabase SQL Editor in this EXACT order.

## 1️⃣ Step 1: Profile & Bank Accounts
**File:** `STEP1_SAFE_SETUP.sql`
- Creates `profiles` columns (KYC data).
- Creates `bank_accounts` table.

## 2️⃣ Step 2: Wallet & Transactions (CRITICAL NEW STEP)
**File:** `STEP4_WALLET_SETUP.sql`
- Creates `wallets` table.
- Creates `transactions` table.
- Creates `deposit_requests` and `withdrawal_requests` tables.
- Creates `increment_wallet_balance` and `decrement_wallet_balance` RPCs.

## 3️⃣ Step 3: Pool Joining Logic
**File:** `STEP2_POOL_JOIN_RPC.sql`
- Creates `request_join_pool` RPC.
- Creates `complete_join_payment` RPC.

## 4️⃣ Step 4: Admin Dashboard Logic
**File:** `STEP3_ADMIN_RPC.sql`
- Creates Admin stats and chart RPCs.
- Creates `process_withdrawal` and `approve_deposit_request` RPCs.

---

### ⚠️ Important Note
If you have already run Steps 1, 3, and 4, **you MUST run Step 2 (`STEP4_WALLET_SETUP.sql`) NOW.**
The app will crash without the `wallets` and `transactions` tables.

### ✅ Verification
After running all scripts, your database should have:
- Tables: `profiles`, `bank_accounts`, `wallets`, `transactions`, `deposit_requests`, `withdrawal_requests`, `pools`, `pool_members`.
- Functions: `increment_wallet_balance`, `decrement_wallet_balance`, `request_join_pool`, `complete_join_payment`, `get_admin_stats`.
