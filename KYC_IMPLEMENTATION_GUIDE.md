# KYC & LEGAL ENFORCEMENT SYSTEM - IMPLEMENTATION GUIDE

## 📋 **Overview**
This guide outlines the complete KYC verification and legal enforcement system that ensures users are verified and accountable before joining pools.

---

## 🗂️ **Database Setup**

### **Step 1: Run Migrations**

1. **Go to your Supabase Dashboard** → SQL Editor
2. **Run the following in order:**
   - `APPLY_MIGRATIONS.sql` (fixes existing issues)
   - `KYC_LEGAL_SYSTEM.sql` (adds KYC and legal enforcement)

### **What Gets Created:**

#### **Tables:**
- `kyc_documents` - Stores Aadhaar, PAN, Bank, Photos
- `legal_agreements` - Digital signatures for pool joining
- `payment_tracking` - Tracks dues, late fees, defaults
- `default_actions` - Logs recovery actions
- `credit_reports` - Credit bureau reporting

#### **Functions:**
- `can_participate_in_pools()` - Checks if user can create/join pools
- `calculate_late_fees()` - Auto-calculates daily late fees
- `process_recovery_stage()` - Handles 6-stage recovery process

#### **Triggers:**
- Auto-late-fee calculation on payment due dates
- Auto-account suspension after 7 days overdue
- Auto-credit bureau reporting after 14 days

---

## 📱 **Frontend Implementation**

### **KYC Verification Screen Created:**
`lib/features/kyc/presentation/screens/kyc_verification_screen.dart`

**Features:**
- ✅ Aadhaar card number + photo upload
- ✅ PAN card number + photo upload
- ✅ Bank account + IFSC verification
- ✅ Selfie with ID verification
- ✅ Optional address proof
- ✅ Real-time status checking (Pending/Approved/Rejected)

### **Pool Service Updates Needed:**

Add to `pool_service.dart` in `createPool()` method BEFORE pool creation:

```dart
// 🛑 KYC CHECK: Must be KYC verified to create pools
final canParticipate = await _client.rpc('can_participate_in_pools', params: {
  'p_user_id': user.id,
});

if (canParticipate == false) {
  throw Exception('KYC verification required. Please complete your KYC verification to create pools.');
}
```

Add to `joinPool()` method BEFORE joining:

```dart
// 🛑 KYC CHECK: Must be KYC verified and account not suspended/banned
final canParticipate = await _client.rpc('can_participate_in_pools', params: {
  'p_user_id': user.id,
});

if (canParticipate == false) {
  // Get detailed reason
  final profile = await _client
      .from('profiles')
      .select('kyc_verified, account_suspended, defaulter_status, suspension_reason')
      .eq('id', user.id)
      .single();
  
  if (profile['account_suspended'] == true) {
    throw Exception('Account suspended: ${profile['suspension_reason'] ?? 'Payment overdue'}');
  }
  
  if (profile['defaulter_status'] == 'banned') {
    throw Exception('Account banned due to payment defaults.');
  }
  
  if (profile['kyc_verified'] != true) {
    throw Exception('KYC verification required.');
  }
}
```

---

## ⚖️ **Legal Enforcement Flow**

### **Recovery Process Stages:**

| Stage | Days | Action | Automated |
|-------|------|---------|-----------|
| **0** | 0 | Payment due | ✅ Notification |
| **1** | 1-3 | Daily reminders + ₹50/day late fee | ✅ SMS/Email/Push |
| **2** | 7 | Legal notice + Account suspension | ✅ Account frozen |
| **3** | 14 | Credit bureau report (CIBIL) + Defaulter badge | ✅ Auto-reported |
| **4** | 30 | Legal action (if >₹10,000) | ⚠️ Manual |
| **5** | 60+ | Collection agency | ⚠️ Manual |

### **User Consequences:**

**Immediate (Day 0-3):**
- ❌ Late fee ₹50/day
- ⚠️ Payment reminders (SMS/Email/Push)

**Medium (Day 7):**
- 🔒 Account suspended
- ❌ Cannot

 join/create pools
- 🚫 Winnings frozen

**Long-term (Day 14+):**
- 📊 Credit score impacted (CIBIL)
- 🏷️ "Defaulter" badge visible
- ⛔ Permanent ban from platform

**Legal (Day 30+):**
- 📜 Legal notice sent
- 👮 Police complaint (Section 420 - Fraud)
- ⚖️ Small claims court

---

## 🎯 **KYC Approval Process**

### **Admin Dashboard Needed:**

Create `lib/features/admin/presentation/screens/kyc_approval_screen.dart`

**Features:**
- View pending KYC submissions
- View uploaded documents (Aadhaar, PAN, Bank, Selfie)
- Approve/Reject with reason
- Batch approval

**SQL to Approve:**
```sql
UPDATE kyc_documents
SET status = 'approved', verified_at = NOW(), verified_by = <admin_id>
WHERE id = <kyc_id>;

UPDATE profiles
SET kyc_verified = TRUE
WHERE id = <user_id>;
```

**SQL to Reject:**
```sql
UPDATE kyc_documents
SET status = 'rejected', rejection_reason = 'Invalid document'
WHERE id = <kyc_id>;
```

---

## 🔐 **Security Features**

1. **Row Level Security (RLS):**
   - Users can only see their own KYC documents
   - Pool creators can see member payment status
   - Admins have full access

2. **Data Encryption:**
   - Aadhaar/PAN stored encrypted
   - Bank details encrypted at rest
   - Photo URLs use Supabase Storage (secure)

3. **Audit Trail:**
   - All actions logged in `default_actions`
   - Credit reports tracked
   - Legal agreements digitally signed with IP + timestamp

---

## 📊 **Required Navigation Updates**

Add to router (`app_router.dart`):

```dart
GoRoute(
  path: '/kyc-verification',
  name: 'kyc-verification',
  builder: (context, state) => const KYCVerificationScreen(),
),
GoRoute(
  path: '/admin/kyc-approvals',
  name: 'kyc-approvals',
  builder: (context, state) => const KYCApprovalScreen(),
),
```

Add to Profile screen:

```dart
ListTile(
  leading: Icon(Icons.verified_user),
  title: Text('KYC Verification'),
  subtitle: Text(kycStatus), // pending/approved
  onTap: () => context.push('/kyc-verification'),
),
```

---

## ✅ **Testing Checklist**

### **1. KYC Flow:**
- [ ] User submits KYC with valid documents
- [ ] Status shows "Pending"
- [ ] Admin approves KYC
- [ ] User `kyc_verified` = TRUE in database
- [ ] User can now create/join pools

### **2. Pool Creation:**
- [ ] Non-KYC user tries to create pool → Error shown
- [ ] KYC user creates pool → Success
- [ ] Suspended user tries to create pool → Error shown

### **3. Payment Default:**
- [ ] Payment becomes overdue
- [ ] Late fee calculated (₹50/day)
- [ ] User receives reminders
- [ ] After 7 days: Account suspended
- [ ] After 14 days: Defaulter badge + Credit report

### **4. Recovery:**
- [ ] User pays overdue amount
- [ ] Late fees cleared
- [ ] Account un-suspended
- [ ] Defaulter status removed (if paid all)

---

## 🚀 **Next Steps**

1. **Run both SQL files in Supabase**
2. **Add KYC checks to pool_service.dart** (code above)
3. **Add KYC nav to profile screen**
4. **Create admin KYC approval screen**
5. **Set up email/SMS for reminders** (Supabase Edge Functions)
6. **Test entire flow end-to-end**

---

## 🆘 **Support**

If you encounter issues:
1. Check Supabase logs for RPC errors
2. Verify RLS policies are enabled
3. Ensure migrations ran successfully
4. Check user has KYC approved in database

---

**This system makes defaulting EXTREMELY painful while keeping good users protected! 💪**
