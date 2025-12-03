# WINNER SELECTION & WITHDRAWAL PROCESS - COMPLETE GUIDE

## 📋 Overview
This guide explains how pool winners are selected, how much they win, and how they withdraw their winnings.

---

## 🎯 WINNER SELECTION PROCESS

### **Step 1: Pool Admin Initiates Draw**

**Navigation:**
```
Pool Details → Menu → Draw Winner
```

**What Happens:**
1. Admin clicks "Draw Winner" for current round
2. System checks if draw is allowed for this round
3. System calls the appropriate winner selection method based on pool rules

---

## 🎲 THREE WINNER SELECTION METHODS

### **Method 1: Random Draw** (Default)

**How It Works:**
```sql
-- Function: select_random_winner
-- Randomly selects from eligible members who haven't won yet

SELECT user_id 
FROM pool_members
WHERE pool_id = '<pool_id>'
  AND (has_won = FALSE OR has_won IS NULL)
  AND status = 'active'
ORDER BY random()
LIMIT <winners_needed_this_round>;
```

**Who Can Win:**
- Active pool members
- Have NOT won before (`has_won = FALSE`)
- Have paid their contributions on time

**Example:**
- Pool has 10 members
- Round 5 draw
- 3 members already won
- System randomly selects 1-2 members from remaining 7

---

### **Method 2: Sequential Rotation**

**How It Works:**
```sql
-- Function: select_sequential_winner
-- Selects in order of who joined first

SELECT user_id 
FROM pool_members
WHERE pool_id = '<pool_id>'
  AND (has_won = FALSE OR has_won IS NULL)
  AND status = 'active'
ORDER BY joined_at ASC
LIMIT 1;
```

**Who Wins:**
- The member who joined earliest and hasn't won yet
- Fair "first come, first serve" approach

**Example:**
- Alice joined Jan 1
- Bob joined Jan 5
- Charlie joined Jan 10
- **Alice wins Round 1**, Bob wins Round 2, Charlie wins Round 3

---

### **Method 3: Member Voting**

**How It Works:**
```sql
-- Function: select_voted_winner
-- Member with most votes wins

SELECT v.candidate_id, COUNT(*) as votes
FROM votes v
WHERE v.pool_id = '<pool_id>'
  AND v.round_number = <current_round>
  AND candidate has NOT won before
GROUP BY v.candidate_id
ORDER BY COUNT(*) DESC
LIMIT 1;
```

**Process:**
1. Pool members cast votes for who should win
2. Voting period closes
3. Member with most votes wins
4. In case of tie, earliest vote timestamp wins

**Example:**
- Alice: 5 votes
- Bob: 3 votes
- Charlie: 2 votes
- **Alice wins!**

---

## 💰 WINNING AMOUNT CALCULATION

### **Formula:**

```
Winning Amount = (Total Contributions This Round) / (Winners This Round)
```

### **Proportional Draw Logic:**

The system uses **dynamic proportional distribution** to ensure all members win exactly once.

**Example Pool:**
- **Members:** 10
- **Duration:** 10 months
- **Contribution:** ₹1,000/month
- **Start Draw Month:** 6 (60/40 rule)

**Round-by-Round Breakdown:**

| Round | Remaining Members | Remaining Months | Winners This Round | Winning Amount |
|-------|------------------|------------------|-------------------|----------------|
| 1-5   | 10              | -                | 0 (Accumulation)  | ₹0             |
| **6** | **10**          | **5**            | **CEIL(10/5) = 2**| **₹5,000 each**|
| 7     | 8               | 4                | CEIL(8/4) = 2     | ₹5,000 each    |
| 8     | 6               | 3                | CEIL(6/3) = 2     | ₹5,000 each    |
| 9     | 4               | 2                | CEIL(4/2) = 2     | ₹5,000 each    |
| 10    | 2               | 1                | CEIL(2/1) = 2     | ₹5,000 each    |

**Calculation for Round 6:**
```
Total Pool This Round = 10 members × ₹1,000 = ₹10,000
Winners This Round = CEIL(10 remaining / 5 remaining months) = 2
Winning Amount = ₹10,000 / 2 = ₹5,000 per winner
```

---

## 📊 DATABASE FLOW

### **When Winner is Selected:**

```sql
-- 1. Insert into winner_history
INSERT INTO winner_history (
  pool_id,
  user_id,
  round_number,
  winning_amount,
  selection_method,
  payout_status,
  selected_at
) VALUES (
  '<pool_id>',
  '<winner_user_id>',
  6, -- current round
  5000.00,
  'random', -- or 'sequential' or 'voting'
  'pending',
  NOW()
);

-- 2. Mark user as having won
UPDATE pool_members
SET has_won = TRUE
WHERE pool_id = '<pool_id>' 
  AND user_id = '<winner_user_id>';

-- 3. Create wallet transaction (locked balance)
INSERT INTO transactions (
  user_id,
  type,
  amount,
  status,
  pool_id,
  description
) VALUES (
  '<winner_user_id>',
  'winning',
  5000.00,
  'pending',
  '<pool_id>',
  'Pool Round 6 Winning'
);

-- 4. Update wallet
UPDATE wallets
SET locked_balance = locked_balance + 5000.00
WHERE user_id = '<winner_user_id>';
```

---

## 💸 WITHDRAWAL PROCESS

### **Step 1: Winner Gets Notified**

**Notification:**
```
🎉 Congratulations! You won ₹5,000 in Pool Round 6!
Your winnings are locked and will be available for withdrawal once the pool admin approves payout.
```

**Winner's Wallet Shows:**
- **Locked Balance:** ₹5,000 (Cannot withdraw yet)
- **Available Balance:** ₹X (Other funds)

---

### **Step 2: Admin Approves Payout**

**Navigation:**
```
Pool Details → Menu → Manage Pool → Financial Controls
```

**Admin Screen Shows:**
- List of pending payouts
- Winner name
- Round number  
- Winning amount
- Status: Pending

**Admin Clicks "Approve Payout":**

```sql
-- 1. Update winner_history
UPDATE winner_history
SET 
  payout_status = 'approved',
  payout_approved_at = NOW(),
  payout_approved_by = '<admin_id>'
WHERE id = '<winner_history_id>';

-- 2. Move from locked to available balance
UPDATE wallets
SET 
  locked_balance = locked_balance - 5000.00,
  available_balance = available_balance + 5000.00
WHERE user_id = '<winner_user_id>';

-- 3. Update transaction status
UPDATE transactions
SET status = 'completed'
WHERE user_id = '<winner_user_id>'
  AND pool_id = '<pool_id>'
  AND type = 'winning'
  AND status = 'pending';
```

**Result:**
- Winner's **Available Balance** increases by ₹5,000
- Winner can now withdraw to bank account

---

### **Step 3: Winner Withdraws to Bank**

**Navigation:**
```
Wallet → Withdraw Funds
```

**Winner Enters:**
- Amount: ₹5,000 (or less)
- Bank Account: (from saved accounts)
- Clicks "Withdraw"

**What Happens:**

```sql
-- 1. Deduct from available balance
UPDATE wallets
SET available_balance = available_balance - 5000.00
WHERE user_id = '<winner_user_id>';

-- 2. Create withdrawal transaction
INSERT INTO transactions (
  user_id,
  type,
  amount,
  status,
  bank_account_id,
  description
) VALUES (
  '<winner_user_id>',
  'withdrawal',
  5000.00,
  'pending', -- Admin needs to approve
  '<bank_account_id>',
  'Withdrawal to bank'
);

-- 3. Create withdrawal request (for admin approval)
INSERT INTO withdrawal_requests (
  user_id,
  amount,
  bank_account_id,
  status
) VALUES (
  '<winner_user_id>',
  5000.00,
  '<bank_account_id>',
  'pending'
);
```

---

### **Step 4: Admin Processes Withdrawal**

**Admin Dashboard:**
```
Admin → Withdrawal Requests → Pending
```

**Admin Sees:**
- User: Abhay vishwakarma
- Amount: ₹5,000
- Bank: HDFC Bank ****1234
- Status: Pending

**Admin Clicks "Approve":**

```sql
-- Mark withdrawal as completed
UPDATE withdrawal_requests
SET 
  status = 'approved',
  processed_at = NOW(),
  processed_by = '<admin_id>'
WHERE id = '<withdrawal_request_id>';

-- Update transaction
UPDATE transactions
SET status = 'completed'
WHERE id = '<transaction_id>';
```

**Admin Transfers Money:**
- Admin manually transfers ₹5,000 to user's bank account via banking portal
- Marks as "Paid" in system
- User receives money in 1-3 business days

---

## 🔄 COMPLETE FLOW DIAGRAM

```
┌─────────────────────────────────────────────────────────┐
│  ROUND 6 BEGINS                                         │
└─────────────────────────────────────────────────────────┘
   All 10 members contribute ₹1,000 each
   Total Pool = ₹10,000
   ↓

┌─────────────────────────────────────────────────────────┐
│  ADMIN DRAWS WINNER                                     │
└─────────────────────────────────────────────────────────┘
   Admin → Pool Details → Draw Winner
   ↓
   System Calculates:
   • Remaining Members: 10
   • Remaining Months: 5
   • Winners Needed: CEIL(10/5) = 2
   • Amount Per Winner: ₹10,000 / 2 = ₹5,000
   ↓
   System Selects 2 Winners (Random/Sequential/Voting)
   • Winner 1: Alice
   • Winner 2: Bob


┌─────────────────────────────────────────────────────────┐
│  WINNERS GET NOTIFIED                                   │
└─────────────────────────────────────────────────────────┘
   Alice & Bob receive notification:
   "🎉 You won ₹5,000!"
   ↓
   Their wallets show:
   • Locked Balance: +₹5,000


┌─────────────────────────────────────────────────────────┐
│  ADMIN APPROVES PAYOUT                                  │
└─────────────────────────────────────────────────────────┘
   Admin → Financial Controls → Approve Payout
   ↓
   Alice & Bob's wallets updated:
   • Locked Balance: -₹5,000
   • Available Balance: +₹5,000 ✅


┌─────────────────────────────────────────────────────────┐
│  WINNERS WITHDRAW TO BANK                               │
└─────────────────────────────────────────────────────────┘
   Alice → Wallet → Withdraw → ₹5,000
   ↓
   Withdrawal Request Created (Pending)


┌─────────────────────────────────────────────────────────┐
│  ADMIN PROCESSES WITHDRAWAL                             │
└─────────────────────────────────────────────────────────┘
   Admin → Withdrawal Requests → Approve
   ↓
   Admin transfers ₹5,000 to Alice's bank
   ↓
   Alice receives money in 1-3 days 💰
```

---

## 🛠️ IMPLEMENTING THE WITHDRAWAL FLOW

### **Files Needed:**

1. **Winner Selection:**
   - ✅ Already exists: `lib/features/pools/presentation/screens/winner_selection_screen.dart`
   - ✅ Already exists: `lib/core/services/winner_service.dart`

2. **Payout Approval:**
   - 🔄 Need to add to: `lib/features/admin/presentation/screens/financial_controls_screen.dart`

3. **Withdrawal Request:**
   - ✅ Already exists: `lib/features/wallet/presentation/screens/withdraw_funds_screen.dart`

4. **Admin Withdrawal Approval:**
   - 🆕 Need to create: `lib/features/admin/presentation/screens/withdrawal_requests_screen.dart`

---

## 📝 SUMMARY

### **Winner Selection:**
- 3 Methods: Random, Sequential, Voting
- Dynamic proportional

 distribution
- Ensures all members win exactly once

### **Winning Amount:**
```
Amount = (Total Pool This Round) / (Winners This Round)
Winners This Round = CEIL(Remaining Members / Remaining Months)
```

### **Withdrawal:**
1. Winner selected → Locked Balance increases
2. Admin approves payout → Available Balance increases
3. Winner requests withdrawal → Withdrawal request created
4. Admin approves withdrawal → Money transferred to bank
5. User receives money in 1-3 days

**Everything is tracked in the database for transparency and audit!** 📊
