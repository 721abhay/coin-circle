# KYC CONSOLIDATION PLAN

## Problem
Currently there are 3 different screens collecting KYC information:
1. Edit Personal Details - Has PAN/Aadhaar NUMBER fields
2. KYC Submission Screen - Has document type selector
3. KYC Verification Screen (new) - Comprehensive with photos

This creates confusion and duplicate data.

## Solution: Consolidate to Single KYC Screen

### Step 1: Update Personal Details Screen
**File:** `lib/features/profile/presentation/screens/edit_personal_details_screen.dart`

**Remove these fields:**
- PAN Number field
- Aadhaar Number field

**Keep only:**
- Full Name
- Phone Number  
- Address (Street, City, State, Postal Code)
- Date of Birth
- Financial Information (Occupation, Annual Income)
- Emergency Contact

**Add a button:**
```dart
ElevatedButton.icon(
  onPressed: () => context.push('/kyc-verification'),
  icon: Icon(Icons.verified_user),
  label: Text('Complete KYC Verification'),
  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
)
```

### Step 2: Remove Old KYC Submission Screen
**File:** `lib/features/profile/presentation/screens/kyc_submission_screen.dart`

**Action:** Delete this file or mark as deprecated

### Step 3: Update Routes
**File:** `lib/core/router/app_router.dart`

**Remove route:**
```dart
// Old - REMOVE
GoRoute(
  path: '/kyc-submission',
  name: 'kyc-submission',
  builder: (context, state) => const KYCSubmissionScreen(),
),
```

**Add route:**
```dart
// New - ADD
GoRoute(
  path: '/kyc-verification',
  name: 'kyc-verification',
  builder: (context, state) => const KYCVerificationScreen(),
),
```

### Step 4: Update Profile Screen Navigation
**File:** `lib/features/profile/presentation/screens/profile_screen.dart`

**Change:**
```dart
// Old
onTap: () => context.push('/kyc-submission'),

// New
onTap: () => context.push('/kyc-verification'),
```

### Step 5: Database Schema
**The new KYC system uses:**
- `kyc_documents` table (already created in KYC_SIMPLE.sql)
- Fields: aadhaar_number, aadhaar_photo_url, pan_number, pan_photo_url, bank details, selfie

**Remove from profiles table:** (if they exist)
- `pan_number` column
- `aadhaar_number` column

These should ONLY be in `kyc_documents` table.

## Benefits

✅ **Single source of truth** for KYC data
✅ **Better UX** - users don't fill same info twice  
✅ **Proper photo uploads** with Supabase Storage
✅ **Admin approval workflow** built-in
✅ **Secure** - RLS policies protect user data

## Migration Steps

1. Backup existing PAN/Aadhaar data from profiles table
2. Migrate data to kyc_documents table
3. Remove fields from edit_personal_details_screen.dart
4. Delete kyc_submission_screen.dart
5. Update all navigation to use kyc_verification_screen.dart
6. Test end-to-end flow

## User Flow (After Consolidation)

1. User goes to Profile
2. Clicks "Edit Personal Details"
   - Enters basic info (name, phone, address, DOB)
   - Enters financial info (occupation, income)
   - Enters emergency contact
   - **Sees "Complete KYC Verification" button**
3. Clicks "Complete KYC Verification"
   - Taken to comprehensive KYC screen
   - Uploads Aadhaar photo + number
   - Uploads PAN photo + number
   - Enters bank details
   - Takes selfie with ID
   - Submits for approval
4. Admin approves KYC
5. User can now create/join pools!

## Files to Modify

1. `lib/features/profile/presentation/screens/edit_personal_details_screen.dart` - Remove PAN/Aadhaar fields
2. `lib/features/profile/presentation/screens/kyc_submission_screen.dart` - DELETE
3. `lib/core/router/app_router.dart` - Update routes
4. `lib/features/profile/presentation/screens/profile_screen.dart` - Update navigation

## Files to Keep

1. ✅ `lib/features/kyc/presentation/screens/kyc_verification_screen.dart` (Master KYC screen)
2. ✅ `supabase/KYC_SIMPLE.sql` (Database schema)
