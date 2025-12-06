# URGENT FIX - Database Setup Guide

## Problem Identified ❌
The error "Could not find the 'phone' column" means the database columns haven't been created yet.

## Solution - Follow These Steps EXACTLY:

### Step 1: Open Supabase Dashboard
1. Go to your Supabase project dashboard
2. Click on **SQL Editor** in the left sidebar

### Step 2: Run Profile Columns Script
1. Open the file: `supabase/ADD_PROFILE_COLUMNS.sql`
2. **Copy ALL the content** from that file
3. **Paste** it into the Supabase SQL Editor
4. Click **Run** (or press Ctrl+Enter)
5. **Wait** for it to complete
6. You should see: "✅ Profile columns added successfully!"

### Step 3: Run Bank Accounts Script
1. Open the file: `supabase/CREATE_BANK_ACCOUNTS.sql`
2. **Copy ALL the content** from that file
3. **Paste** it into the Supabase SQL Editor
4. Click **Run** (or press Ctrl+Enter)
5. **Wait** for it to complete
6. You should see: "✅ Bank accounts table created successfully!"

### Step 4: Verify Setup
Run this query in Supabase SQL Editor to verify:
```sql
-- Check if columns exist
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
  AND column_name IN ('phone', 'address', 'pan_number')
ORDER BY column_name;

-- Check if bank_accounts table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_name = 'bank_accounts';
```

You should see:
- 3 rows for profiles columns (address, pan_number, phone)
- 1 row for bank_accounts table

### Step 5: Restart Your App
**IMPORTANT:** You MUST do a full restart, not hot reload!

1. **Stop** the current `flutter run` command (Ctrl+C or terminate)
2. **Run again:**
   ```bash
   flutter run
   ```

### Step 6: Test Personal Details
1. Open the app
2. Go to **Settings → Personal Details**
3. Click the **Edit icon** (pencil)
4. Fill in your information:
   - Phone: Your phone number
   - Address: Your address
   - City: Your city
   - State: Your state
   - Postal Code: Your PIN code
   - Date of Birth: Select a date
   - PAN: ABCDE1234F (example format)
   - Aadhaar: 123456789012 (12 digits)
   - Occupation: Your job
   - Annual Income: Your income
5. Click **Save**
6. You should see: "✅ Profile updated successfully!"
7. Go back and verify your data is displayed

## What Each Script Does:

### ADD_PROFILE_COLUMNS.sql
Adds these columns to the `profiles` table:
- phone, phone_verified, email_verified
- address, city, state, postal_code, country
- date_of_birth
- pan_number, aadhaar_number
- occupation, annual_income
- emergency_contact_name, emergency_contact_phone
- privacy_settings

### CREATE_BANK_ACCOUNTS.sql
Creates the `bank_accounts` table with:
- All bank account fields
- Row Level Security (RLS)
- Policies so users can only see their own accounts
- Indexes for performance

## Troubleshooting:

### If you get "column already exists" error:
✅ This is GOOD! It means the column was already created. Continue with the next step.

### If you get "relation already exists" error:
✅ This is GOOD! It means the table was already created. Continue with the next step.

### If you still get "Could not find column" error after running scripts:
1. Make sure you ran BOTH scripts
2. Make sure you did a FULL app restart (not hot reload)
3. Check the Supabase logs for any errors
4. Verify columns exist using the verification query above

### If Save button doesn't work:
1. Check if you're logged in
2. Check the app console for error messages
3. Make sure RLS policies are created (run CREATE_BANK_ACCOUNTS.sql again)

## Quick Checklist:

- [ ] Ran ADD_PROFILE_COLUMNS.sql in Supabase
- [ ] Saw success message
- [ ] Ran CREATE_BANK_ACCOUNTS.sql in Supabase
- [ ] Saw success message
- [ ] Verified columns exist (ran verification query)
- [ ] Stopped flutter run
- [ ] Started flutter run again (full restart)
- [ ] Opened app and navigated to Personal Details
- [ ] Clicked edit icon
- [ ] Filled in data
- [ ] Clicked Save
- [ ] Saw success message
- [ ] Data is now displayed correctly

## Expected Result:

After completing all steps, you should be able to:
1. ✅ View your personal details (real data from database)
2. ✅ Edit your personal details
3. ✅ Save changes to database
4. ✅ See updated data immediately
5. ✅ Data persists after app restart

## Next: Bank Accounts

Once Personal Details is working, we'll add the same edit functionality for Bank Accounts!
