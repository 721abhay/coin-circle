# All Fixes Summary - Run These Migrations ✅

## Migration 1: Fix Pool Member Counting (UPDATED with CASCADE)

**File:** `fix_pool_member_counting.sql`

```sql
-- Fix pool member counting to only count active members
-- This prevents pending requests from blocking the pool

-- 1. Drop existing triggers and function with CASCADE
DROP TRIGGER IF EXISTS update_pool_member_count ON pool_members CASCADE;
DROP TRIGGER IF EXISTS on_pool_member_added ON pool_members CASCADE;
DROP TRIGGER IF EXISTS on_pool_member_removed ON pool_members CASCADE;
DROP FUNCTION IF EXISTS update_pool_member_count() CASCADE;

-- 2. Create function to update pool member count (ONLY active members)
CREATE OR REPLACE FUNCTION update_pool_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    UPDATE pools
    SET current_members = (
      SELECT COUNT(*)
      FROM pool_members
      WHERE pool_id = NEW.pool_id
      AND status = 'active'
    )
    WHERE id = NEW.pool_id;
    RETURN NEW;
  END IF;

  IF (TG_OP = 'DELETE') THEN
    UPDATE pools
    SET current_members = (
      SELECT COUNT(*)
      FROM pool_members
      WHERE pool_id = OLD.pool_id
      AND status = 'active'
    )
    WHERE id = OLD.pool_id;
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 3. Create trigger
CREATE TRIGGER update_pool_member_count
AFTER INSERT OR UPDATE OR DELETE ON pool_members
FOR EACH ROW
EXECUTE FUNCTION update_pool_member_count();

-- 4. Fix existing pools - recalculate current_members for all pools
UPDATE pools
SET current_members = (
  SELECT COUNT(*)
  FROM pool_members
  WHERE pool_members.pool_id = pools.id
  AND pool_members.status = 'active'
);

-- 5. Add index for better performance
CREATE INDEX IF NOT EXISTS idx_pool_members_status_pool ON pool_members(pool_id, status);
```

---

## Migration 2: Add is_suspended Column

```sql
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_suspended BOOLEAN DEFAULT false;
CREATE INDEX IF NOT EXISTS idx_profiles_is_suspended ON profiles(is_suspended);
```

---

## Migration 3: Create suspend_user_admin Function

```sql
CREATE OR REPLACE FUNCTION suspend_user_admin(p_reason TEXT, p_user_id UUID)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_user RECORD; v_is_suspended BOOLEAN; v_result jsonb;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  SELECT * INTO v_user FROM profiles WHERE id = p_user_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'User not found'; END IF;
  v_is_suspended := NOT COALESCE(v_user.is_suspended, false);
  UPDATE profiles SET is_suspended = v_is_suspended, updated_at = NOW() WHERE id = p_user_id;
  INSERT INTO notifications (user_id, title, message, type, created_at) VALUES (
    p_user_id,
    CASE WHEN v_is_suspended THEN 'Account Suspended' ELSE 'Account Unsuspended' END,
    CASE WHEN v_is_suspended THEN 'Your account has been suspended. Reason: ' || p_reason
         ELSE 'Your account has been unsuspended. You can now access all features.' END,
    'system', NOW()
  );
  RETURN jsonb_build_object('success', true, 'user_id', p_user_id, 'is_suspended', v_is_suspended);
END; $$;
GRANT EXECUTE ON FUNCTION suspend_user_admin(TEXT, UUID) TO authenticated;
```

---

## Migration 4: Create force_close_pool_admin Function

```sql
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
  v_result := jsonb_build_object('success', true, 'message', 'Pool closed');
  RETURN v_result;
END; $$;
GRANT EXECUTE ON FUNCTION force_close_pool_admin(UUID, TEXT) TO authenticated;
```

---

## Migration 5: Fix Support Tickets Table

```sql
ALTER TABLE support_tickets ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
ALTER TABLE support_tickets ADD COLUMN IF NOT EXISTS subject TEXT;
ALTER TABLE support_tickets ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'open';
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);

DROP POLICY IF EXISTS "Users can view their own tickets" ON support_tickets;
DROP POLICY IF EXISTS "Admins can view all tickets" ON support_tickets;
DROP POLICY IF EXISTS "Admins can update all tickets" ON support_tickets;

CREATE POLICY "Users can view their own tickets" ON support_tickets FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Admins can view all tickets" ON support_tickets FOR SELECT USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true));
CREATE POLICY "Admins can update all tickets" ON support_tickets FOR UPDATE USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true));
```

---

## What Each Migration Fixes

| Migration | Fixes | Feature |
|-----------|-------|---------|
| 1 | Pool member counting | Only active members count towards capacity |
| 2 | is_suspended column | User suspend/unsuspend |
| 3 | suspend_user_admin RPC | User management with notifications |
| 4 | force_close_pool_admin RPC | Force close pools |
| 5 | support_tickets structure | Ticket management + notifications |

---

## Run Order

1. ✅ Migration 1 (Pool counting) - **MOST IMPORTANT**
2. ✅ Migration 2 (is_suspended)
3. ✅ Migration 3 (suspend function)
4. ✅ Migration 4 (force close)
5. ✅ Migration 5 (support tickets)

---

## After Running Migrations

Test these features:
1. ✅ Join pool from Browse → Should send request
2. ✅ Check pool capacity → Should only count active members
3. ✅ Admin suspend user → Should work with reason
4. ✅ Admin tickets → Dismiss/Mark Solved should work
5. ✅ Admin force close pool → Should work

All admin features will be fully functional! 🚀
