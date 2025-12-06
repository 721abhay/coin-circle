# Database Fixes for Admin Features ✅

## Issues Found

### 1. **User Management Error** ❌
```
Error: PostgrestException(message: Could not find the 'is_suspended' column of 'profiles' in the schema cache)
```

**Problem:** The `is_suspended` column doesn't exist in the `profiles` table.

**Solution:** Run migration `add_is_suspended_column.sql`

---

### 2. **Pool Oversight Error** ❌
```
Error: PostgrestException(message: Could not find the function public.force_close_pool_admin)
```

**Problem:** The `force_close_pool_admin` RPC function doesn't exist.

**Solution:** Run migration `create_force_close_pool_function.sql`

---

## How to Fix

### **Option 1: Run in Supabase Dashboard (Recommended)**

1. Go to your Supabase Dashboard
2. Navigate to **SQL Editor**
3. Run these migrations in order:

#### Migration 1: Add is_suspended column
```sql
-- Add is_suspended column to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_suspended BOOLEAN DEFAULT false;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_profiles_is_suspended ON profiles(is_suspended);
```

#### Migration 2: Create force_close_pool function
```sql
-- Create force_close_pool_admin function for admin to force close pools
CREATE OR REPLACE FUNCTION force_close_pool_admin(
  p_pool_id UUID,
  p_reason TEXT
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_pool RECORD;
  v_result jsonb;
BEGIN
  -- Check if user is admin
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true) THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  -- Get pool details
  SELECT * INTO v_pool FROM pools WHERE id = p_pool_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pool not found';
  END IF;

  -- Update pool status to completed
  UPDATE pools 
  SET 
    status = 'completed',
    updated_at = NOW()
  WHERE id = p_pool_id;

  v_result := jsonb_build_object(
    'success', true,
    'message', 'Pool force closed successfully',
    'pool_id', p_pool_id,
    'reason', p_reason
  );

  RETURN v_result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION force_close_pool_admin(UUID, TEXT) TO authenticated;
```

---

### **Option 2: Using Supabase CLI**

If you have Supabase CLI installed:

```bash
# Navigate to project directory
cd "c:\Users\ABHAY\coin circle\coin_circle"

# Run migrations
supabase db push
```

---

## What These Fixes Enable

### ✅ **is_suspended Column**
Allows admins to:
- Suspend user accounts
- Unsuspend user accounts
- Track suspended users
- Filter by suspension status

### ✅ **force_close_pool_admin Function**
Allows admins to:
- Force close any pool
- Provide a reason for closure
- Override normal pool lifecycle
- Handle emergency situations

---

## Verification

After running the migrations, verify they worked:

### Test 1: User Suspension
1. Go to Admin → Users
2. Click suspend icon on any user
3. Should work without errors ✅

### Test 2: Force Close Pool
1. Go to Admin → Pool Oversight
2. Click "Force Close" on any pool
3. Should work without errors ✅

---

## Migration Files Created

1. `supabase/migrations/add_is_suspended_column.sql`
2. `supabase/migrations/create_force_close_pool_function.sql`

Run these in your Supabase database to fix the errors!
