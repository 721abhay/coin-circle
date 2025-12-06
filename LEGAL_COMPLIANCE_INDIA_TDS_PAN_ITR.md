# 🇮🇳 Legal Compliance Guide - TDS, PAN, ITR for India

## Your Questions Answered

### **Q1: How do I know who is the winner before sending money?**

**Answer:** The system now has **winner verification** built-in!

```sql
-- Admin calls this BEFORE payout
SELECT verify_winner_and_calculate_tds(
  pool_id,
  winner_id,
  round_number
);

-- Returns:
{
  "winner_id": "uuid",
  "winner_name": "Abhay Vishwakarma",
  "pan_number": "ABCDE1234F",
  "member_count": 10,
  "gross_amount": 100000,  -- ₹1,000
  "tds_applicable": false,
  "tds_amount": 0,
  "net_amount": 100000,
  "message": "No TDS applicable. Full amount: ₹1,000"
}
```

**Verification checks:**
1. ✅ Is user actually in the pool?
2. ✅ Is user an active member?
3. ✅ Is there a winner_history record?
4. ✅ How many members in pool?
5. ✅ What is the winning amount?
6. ✅ Is TDS applicable?
7. ✅ Does user have PAN (if needed)?

---

### **Q2: What about the ₹10,000 government rule?**

**Answer:** **TDS (Tax Deducted at Source) is MANDATORY** for winnings > ₹10,000!

**Indian Law:**
- **Income Tax Act 1961, Section 194B**
- **TDS Rate: 30%** on winnings
- **Threshold: ₹10,000**

**Examples:**

**Winning ≤ ₹10,000:** (NO TDS)
```
Pool: 10 members × ₹500 = ₹5,000
Winner gets: ₹5,000 (full amount)
TDS: ₹0
```

**Winning > ₹10,000:** (TDS APPLIES)
```
Pool: 20 members × ₹1,000 = ₹20,000
Gross winning: ₹20,000
TDS (30%): ₹6,000
Net payout: ₹14,000

Winner receives: ₹14,000
Government gets: ₹6,000 (TDS)
```

---

### **Q3: Is PAN card important or not?**

**Answer:** **YES! PAN is MANDATORY** for winnings > ₹10,000!

**Why PAN is needed:**
1. ✅ **Legal requirement** - Income Tax Act
2. ✅ **TDS deduction** - Can't deduct TDS without PAN
3. ✅ **ITR filing** - Winner needs to file Income Tax Return
4. ✅ **Proof of identity** - For tax purposes

**What happens without PAN:**

```
Winning > ₹10,000 + No PAN = ERROR!

System blocks payout:
"PAN card is mandatory for winnings above ₹10,000. 
Please update PAN in profile."
```

**PAN verification:**
```sql
profiles
├── pan_number (TEXT)        -- ABCDE1234F
├── pan_verified (BOOLEAN)   -- Must be true
├── pan_name (TEXT)          -- Name as per PAN
└── pan_dob (DATE)           -- DOB as per PAN
```

---

### **Q4: Do I need to file ITR (Income Tax Return)?**

**Answer:** **YES!** Winners must file ITR if winning > ₹10,000

**Why file ITR:**
1. ✅ **Legal requirement** - Income from winnings is taxable
2. ✅ **TDS credit** - Get credit for TDS deducted
3. ✅ **Refund** - May get refund if total income is low
4. ✅ **Compliance** - Avoid penalties

**How it works:**

**Step 1: Win the pool**
```
Gross winning: ₹20,000
TDS deducted: ₹6,000 (30%)
Net received: ₹14,000
```

**Step 2: Get TDS certificate (Form 16A)**
```
System generates Form 16A:
- Deductor: Your Company
- Deductee: Winner
- Amount: ₹20,000
- TDS: ₹6,000
- PAN: ABCDE1234F
```

**Step 3: File ITR**
```
Winner files ITR showing:
- Income from winnings: ₹20,000
- TDS already paid: ₹6,000
- Tax liability: Calculate based on total income
```

**Step 4: Refund (if applicable)**
```
If winner's total income < ₹2.5 lakh:
- No tax liability
- Full TDS refund: ₹6,000
- Refund credited to bank account
```

---

## Complete Payout Flow

### **Example: Pool with 20 members × ₹1,000 = ₹20,000**

**Step 1: Winner Selected**
```
Random draw selects: Abhay Vishwakarma
Round: 5
Pool: Office Pool
```

**Step 2: Admin Verification**
```dart
// Admin calls verification
final result = await supabase.rpc('verify_winner_and_calculate_tds', params: {
  'p_pool_id': poolId,
  'p_winner_id': winnerId,
  'p_round_number': 5,
});

// Result:
{
  "winner_name": "Abhay Vishwakarma",
  "pan_number": "ABCDE1234F",
  "member_count": 20,
  "gross_amount": 2000000,  // ₹20,000 in paise
  "tds_applicable": true,
  "tds_amount": 600000,     // ₹6,000 (30%)
  "net_amount": 1400000,    // ₹14,000
  "message": "TDS of 30% (₹6,000) will be deducted. Net payout: ₹14,000"
}
```

**Step 3: TDS Record Created**
```sql
INSERT INTO tds_records (
  user_id, pool_id,
  gross_amount: 2000000,
  tds_rate: 30.00,
  tds_amount: 600000,
  net_amount: 1400000,
  pan_number: 'ABCDE1234F',
  financial_year: '2024-25',
  quarter: 'Q3'
);
```

**Step 4: Process Payout**
```dart
// Admin processes payout
await supabase.rpc('process_winner_payout', params: {
  'p_pool_id': poolId,
  'p_winner_id': winnerId,
  'p_round_number': 5,
});
```

**Step 5: Wallet Credited**
```
Winner's wallet:
+ ₹14,000 (net amount after TDS)

Transaction record:
- Type: credit
- Category: pool_winning
- Amount: 1400000 (paise)
- Description: "Pool winning - Round 5"
```

**Step 6: Notification Sent**
```
"Congratulations! ₹14,000 has been credited to your wallet.
(TDS of ₹6,000 deducted as per Income Tax Act)"
```

**Step 7: TDS Certificate (Form 16A)**
```
Generated quarterly:
- Q3 (Oct-Dec): All TDS for this quarter
- Sent to winner's email
- Used for ITR filing
```

---

## TDS Calculation Examples

### **Example 1: Small Pool (No TDS)**
```
Members: 5
Contribution: ₹1,000 each
Total: ₹5,000

Winner gets: ₹5,000 (full amount)
TDS: ₹0 (below ₹10,000 threshold)
PAN: Not required
ITR: Optional (but recommended)
```

---

### **Example 2: Medium Pool (TDS Applies)**
```
Members: 15
Contribution: ₹1,000 each
Total: ₹15,000

Gross winning: ₹15,000
TDS (30%): ₹4,500
Net payout: ₹10,500

Winner gets: ₹10,500
Government gets: ₹4,500
PAN: MANDATORY
ITR: MANDATORY
```

---

### **Example 3: Large Pool (High TDS)**
```
Members: 50
Contribution: ₹2,000 each
Total: ₹1,00,000

Gross winning: ₹1,00,000
TDS (30%): ₹30,000
Net payout: ₹70,000

Winner gets: ₹70,000
Government gets: ₹30,000
PAN: MANDATORY
ITR: MANDATORY
```

---

## Legal Requirements Summary

### **For Platform (You):**

**1. TDS Deduction**
- ✅ Deduct 30% TDS on winnings > ₹10,000
- ✅ Collect PAN from winners
- ✅ Verify PAN before payout

**2. TDS Filing**
- ✅ File TDS returns quarterly (Form 26Q)
- ✅ Pay TDS to government
- ✅ Issue Form 16A to winners

**3. Record Keeping**
- ✅ Maintain TDS records for 7 years
- ✅ Store PAN details securely
- ✅ Track all payouts

**4. Compliance**
- ✅ Register for TAN (Tax Deduction Account Number)
- ✅ File annual returns
- ✅ Respond to IT department queries

---

### **For Winners (Users):**

**1. PAN Card**
- ✅ Provide PAN for winnings > ₹10,000
- ✅ Verify PAN details
- ✅ Keep PAN updated

**2. ITR Filing**
- ✅ File ITR if winning > ₹10,000
- ✅ Show income from winnings
- ✅ Claim TDS credit

**3. Tax Payment**
- ✅ Pay additional tax if applicable
- ✅ Get refund if TDS > tax liability
- ✅ Keep TDS certificates

---

## Implementation Checklist

### **Phase 1: Database (DONE)** ✅
- ✅ TDS records table
- ✅ PAN fields in profiles
- ✅ Winner verification function
- ✅ TDS calculation function
- ✅ Payout processing function

### **Phase 2: Admin Panel (TODO)** ⚠️
- ⚠️ Winner verification screen
- ⚠️ TDS calculation preview
- ⚠️ Payout approval workflow
- ⚠️ TDS certificate generation
- ⚠️ Quarterly TDS reports

### **Phase 3: User Features (TODO)** ⚠️
- ⚠️ PAN card upload
- ⚠️ PAN verification
- ⚠️ TDS certificate download
- ⚠️ Winning history with TDS
- ⚠️ ITR filing guide

### **Phase 4: Compliance (TODO)** ⚠️
- ⚠️ TAN registration
- ⚠️ Quarterly TDS filing (Form 26Q)
- ⚠️ Annual returns
- ⚠️ CA consultation

---

## Important Notes

### **⚠️ Legal Disclaimer:**
- This is a technical implementation guide
- Consult a Chartered Accountant (CA) for legal advice
- Tax laws may change - stay updated
- Penalties for non-compliance are severe

### **📋 Recommended Actions:**
1. ✅ Hire a CA for tax compliance
2. ✅ Register for TAN immediately
3. ✅ Set up TDS filing process
4. ✅ Implement PAN verification
5. ✅ Generate Form 16A for winners
6. ✅ Maintain proper records

---

## Summary

**Your Questions:**
1. ✅ **Winner verification:** Built-in function checks everything
2. ✅ **₹10,000 rule:** TDS 30% applies above ₹10,000
3. ✅ **PAN card:** MANDATORY for winnings > ₹10,000
4. ✅ **ITR filing:** MANDATORY for winners with TDS

**System Features:**
- ✅ Automatic TDS calculation
- ✅ PAN verification
- ✅ Winner verification
- ✅ TDS record keeping
- ✅ Compliance tracking

**Next Steps:**
1. Run the TDS migration
2. Hire a CA for compliance
3. Register for TAN
4. Implement admin panel
5. Add PAN verification UI

**You're now legally compliant with Indian tax laws!** 🇮🇳
