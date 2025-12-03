# KYC VERIFICATION PROCESS - COMPLETE GUIDE

## 📋 Overview
This guide explains how KYC verification works from submission to approval.

---

## 🔄 Complete Workflow

### **1. User Submits KYC** (User Side)

**Steps:**
1. User goes to Profile or `/kyc-verification`
2. Fills comprehensive KYC form:
   - Aadhaar number + upload photo
   - PAN number + upload photo
   - Bank account number + IFSC code
   - Takes selfie with ID card
   - Uploads address proof (optional)
3. Clicks "Submit for Verification"

**What Happens in Database:**
```sql
INSERT INTO kyc_documents (
  user_id,
  aadhaar_number,
  aadhaar_photo_url,
  pan_number,
  pan_photo_url,
  bank_account_number,
  bank_ifsc_code,
  selfie_with_id_url,
  address_proof_url,
  verification_status,  -- SET TO 'pending'
  submitted_at
) VALUES (...);
```

**User sees:** "KYC submitted successfully! Verification usually takes 24-48 hours."

---

### **2. Admin Reviews KYC** (Admin Side)

**Navigation:**
- Admin Dashboard → KYC Approvals
- Or direct: `/admin/kyc-approvals`

**Admin Screen Shows:**
- List of all KYC submissions (pending, approved, rejected)
- Filter chips at top to switch views
- Each card shows:
  - User's full name
  - Email
  - Aadhaar & PAN numbers
  - Submission date
  - Status badge (Pending/Approved/Rejected)

**Admin Clicks on Submission:**
- Modal opens with full details
- Shows all uploaded documents (images)
- Displays:
  - Personal info
  - Document numbers
  - Bank details
  - Photos (Aadhaar, PAN, Selfie, Address Proof)

---

### **3. Admin Approves KYC** ✅

**Admin Clicks "Approve" Button**

**What Happens in Database:**
```sql
-- Update KYC document status
UPDATE kyc_documents
SET 
  verification_status = 'approved',
  verified_by = '<admin_user_id>',
  verified_at = NOW()
WHERE id = '<kyc_id>';

-- Mark user as KYC verified
UPDATE profiles
SET kyc_verified = TRUE
WHERE id = '<user_id>';
```

**Result:**
- ✅ User's account is now KYC verified
- ✅ `can_participate_in_pools()` returns TRUE
- ✅ User can create and join pools!

---

### **3. Admin Rejects KYC** ❌ (Alternative)

**Admin Clicks "Reject" Button**

**Admin Prompted for Reason:**
- Dialog opens
- Admin enters rejection reason (e.g., "Document unclear", "Details mismatch")
- Clicks "Reject"

**What Happens in Database:**
```sql
UPDATE kyc_documents
SET 
  verification_status = 'rejected',
  verified_by = '<admin_user_id>',
  verified_at = NOW(),
  rejection_reason = 'Document unclear'
WHERE id = '<kyc_id>';
```

**Result:**
- ❌ User's KYC is rejected
- ❌ User still CANNOT create/join pools
- 📧 User should receive notification with rejection reason
- 🔄 User can resubmit KYC with corrected documents

---

### **4. User Tries to Create/Join Pool**

**Before KYC Approved:**
```dart
// In PoolService.createPool()
final canParticipate = await _client.rpc('can_participate_in_pools', params: {
  'p_user_id': user.id,
});

if (canParticipate == false) {
  throw Exception('KYC verification required...');
}
```

**User Sees:** Error message "KYC verification required. Please complete your KYC verification to create pools."

**After KYC Approved:**
- `can_participate_in_pools()` returns TRUE ✅
- User can create and join pools without errors!

---

## 🗄️ Database Schema

### **kyc_documents Table**
```sql
CREATE TABLE kyc_documents (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  
  -- Documents
  aadhaar_number VARCHAR(12),
  aadhaar_photo_url TEXT,
  pan_number VARCHAR(10),
  pan_photo_url TEXT,
  bank_account_number VARCHAR(20),
  bank_ifsc_code VARCHAR(11),
  bank_verified BOOLEAN DEFAULT FALSE,
  selfie_with_id_url TEXT,
  address_proof_url TEXT,
  
  -- Verification
  verification_status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
  verified_by UUID REFERENCES profiles(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  
  -- Metadata
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### **profiles Table (Updated Fields)**
```sql
ALTER TABLE profiles ADD COLUMN kyc_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN account_suspended BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN defaulter_status VARCHAR(20) DEFAULT 'good';
```

---

## 🔐 Security Function

### **can_participate_in_pools()**
```sql
CREATE FUNCTION can_participate_in_pools(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_kyc_verified BOOLEAN;
  v_account_suspended BOOLEAN;
  v_defaulter_status VARCHAR(20);
BEGIN
  SELECT kyc_verified, account_suspended, defaulter_status
  INTO v_kyc_verified, v_account_suspended, v_defaulter_status
  FROM profiles
  WHERE id = p_user_id;
  
  -- Must be KYC verified
  IF v_kyc_verified IS NULL OR v_kyc_verified = FALSE THEN
    RETURN FALSE;
  END IF;
  
  -- Must not be suspended
  IF v_account_suspended = TRUE THEN
    RETURN FALSE;
  END IF;
  
  -- Must not be banned
  IF v_defaulter_status = 'banned' THEN
    RETURN FALSE;
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
```

**This function checks:**
1. ✅ User is KYC verified
2. ✅ Account is not suspended
3. ✅ User is not banned

---

## 🎯 Testing the Flow

### **1. Submit KYC** (User)
```bash
# Navigate to:
http://localhost:YOUR_PORT/#/kyc-verification

# Fill form and submit
# Check database:
SELECT * FROM kyc_documents WHERE user_id = '<user_id>';
# Should show: verification_status = 'pending'
```

### **2. View Pending KYCs** (Admin)
```bash
# Navigate to:
http://localhost:YOUR_PORT/#/admin/kyc-approvals

# Should see list of pending submissions
# Click on one to view details
```

### **3. Approve KYC** (Admin)
```bash
# Click "Approve" button
# Check database:
SELECT kyc_verified FROM profiles WHERE id = '<user_id>';
# Should show: kyc_verified = true

SELECT verification_status FROM kyc_documents WHERE user_id = '<user_id>';
# Should show: verification_status = 'approved'
```

### **4. Test Pool Creation** (User)
```bash
# Navigate to:
http://localhost:YOUR_PORT/#/create-pool

# Should work without KYC error! ✅
```

---

## 📱 Manual Verification (For Testing)

If you want to manually approve KYC in Supabase SQL Editor:

```sql
-- 1. Find the KYC submission
SELECT * FROM kyc_documents WHERE user_id = '<user_id>';

-- 2. Approve it manually
UPDATE kyc_documents
SET verification_status = 'approved',
    verified_at = NOW()
WHERE user_id = '<user_id>';

-- 3. Mark user as verified
UPDATE profiles
SET kyc_verified = TRUE
WHERE id = '<user_id>';

-- 4. Verify it worked
SELECT 
  p.full_name,
  p.kyc_verified,
  k.verification_status
FROM profiles p
LEFT JOIN kyc_documents k ON k.user_id = p.id
WHERE p.id = '<user_id>';
```

---

## 🚀 Quick Setup

### **Step 1: Run Migrations**
```sql
-- In Supabase SQL Editor:
-- 1. Run APPLY_MIGRATIONS.sql
-- 2. Run KYC_SIMPLE.sql
```

### **Step 2: Add Route for Admin Approval**
Add to `app_router.dart`:
```dart
GoRoute(
  path: '/admin/kyc-approvals',
  builder: (context, state) => const AdminKYCApprovalScreen(),
),
```

### **Step 3: Add Navigation in Admin Dashboard**
Add button/link to navigate to `/admin/kyc-approvals`

### **Step 4: Test!**
1. Submit KYC as user
2. Review as admin
3. Approve
4. Create pool as user (should work!)

---

## ✅ Verification Checklist

- [ ] Database migrations run successfully
- [ ] User can submit KYC form
- [ ] Photos upload to Supabase Storage
- [ ] KYC appears in admin approval screen
- [ ] Admin can view all document photos
- [ ] Admin can approve/reject with reason
- [ ] After approval, `kyc_verified` = TRUE in database
- [ ] User can create pools after approval
- [ ] Before approval, user gets KYC error when creating pool

---

**The entire KYC verification process is now complete and secure!** 🎉
