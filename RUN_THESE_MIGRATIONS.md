# 🔧 Required Database Migrations - Run in Order

Run these SQL scripts in your Supabase Dashboard → SQL Editor

---

## **Migration 1: Add is_suspended Column**
**File:** `add_is_suspended_column.sql`

```sql
-- Add is_suspended column to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_suspended BOOLEAN DEFAULT false;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_profiles_is_suspended ON profiles(is_suspended);
```

**Fixes:** User Management suspend/unsuspend feature

---

## **Migration 2: Create Force Close Pool Function**
**File:** `create_force_close_pool_function.sql`

```sql
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
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true) THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  SELECT * INTO v_pool FROM pools WHERE id = p_pool_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pool not found';
  END IF;

  UPDATE pools 
  SET status = 'completed', updated_at = NOW()
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

GRANT EXECUTE ON FUNCTION force_close_pool_admin(UUID, TEXT) TO authenticated;
```

**Fixes:** Pool Oversight force close feature

---

## **Migration 3: Fix Support Tickets Table**
**File:** `fix_support_tickets_table.sql`

```sql
-- Ensure support_tickets table has all necessary columns
ALTER TABLE support_tickets ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
ALTER TABLE support_tickets ADD COLUMN IF NOT EXISTS subject TEXT;
ALTER TABLE support_tickets ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE support_tickets ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'open';
ALTER TABLE support_tickets ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE support_tickets ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);

-- Enable RLS
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own tickets" ON support_tickets;
DROP POLICY IF EXISTS "Users can create their own tickets" ON support_tickets;
DROP POLICY IF EXISTS "Admins can view all tickets" ON support_tickets;
DROP POLICY IF EXISTS "Admins can update all tickets" ON support_tickets;

-- Create policies
CREATE POLICY "Users can view their own tickets" ON support_tickets
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create their own tickets" ON support_tickets
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can view all tickets" ON support_tickets
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );

CREATE POLICY "Admins can update all tickets" ON support_tickets
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  );
```

**Fixes:** Support Tickets dismiss/resolve with notifications

---

## **Migration 4: System Settings (Optional)**
**File:** `create_system_settings.sql`

Already created earlier for Admin Settings tab.

---

## **Quick Run - All at Once**

Copy and paste this entire block into Supabase SQL Editor:

```sql
-- Migration 1: is_suspended
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_suspended BOOLEAN DEFAULT false;
CREATE INDEX IF NOT EXISTS idx_profiles_is_suspended ON profiles(is_suspended);

-- Migration 2: force_close_pool_admin
CREATE OR REPLACE FUNCTION force_close_pool_admin(p_pool_id UUID, p_reason TEXT)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_pool RECORD; v_result jsonb;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  SELECT * INTO v_pool FROM pools WHERE id = p_pool_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Pool not found'; END IF;
  UPDATE pools SET status = 'completed', updated_at = NOW() WHERE id = p_pool_id;
  v_result := jsonb_build_object('success', true, 'message', 'Pool closed', 'pool_id', p_pool_id);
  RETURN v_result;
END; $$;
GRANT EXECUTE ON FUNCTION force_close_pool_admin(UUID, TEXT) TO authenticated;

-- Migration 3: support_tickets
ALTER TABLE support_tickets ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
ALTER TABLE support_tickets ADD COLUMN IF NOT EXISTS subject TEXT;
ALTER TABLE support_tickets ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE support_tickets ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'open';
ALTER TABLE support_tickets ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE support_tickets ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own tickets" ON support_tickets;
DROP POLICY IF EXISTS "Users can create their own tickets" ON support_tickets;
DROP POLICY IF EXISTS "Admins can view all tickets" ON support_tickets;
DROP POLICY IF EXISTS "Admins can update all tickets" ON support_tickets;

CREATE POLICY "Users can view their own tickets" ON support_tickets FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can create their own tickets" ON support_tickets FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Admins can view all tickets" ON support_tickets FOR SELECT USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true));
CREATE POLICY "Admins can update all tickets" ON support_tickets FOR UPDATE USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true));
```

---

## **Verification**

After running migrations, test:

1. ✅ Admin → Users → Suspend user (should work)
2. ✅ Admin → Pool Oversight → Force Close (should work)
3. ✅ Admin → Tickets → Dismiss/Mark Solved (should work)

---

## **What Each Migration Fixes**

| Migration | Fixes | Feature |
|-----------|-------|---------|
| 1 | `is_suspended` column | User suspend/unsuspend |
| 2 | `force_close_pool_admin` RPC | Force close pools |
| 3 | `support_tickets` structure | Ticket management + notifications |

All admin features will work after running these! 🚀
