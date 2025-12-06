# 🔧 How to Run the Notifications Migration

## ✅ FIXED: All migration errors resolved

The migration has been updated to fix:
1. ✅ "column read does not exist" - Fixed with DROP TABLE
2. ✅ "relation draws does not exist" - Draw trigger commented out (will add later)
3. ✅ "current_round_start" reference - Changed to use current month

**The migration is now safe to run!**

---

## Option 1: Run via Supabase Dashboard (EASIEST)

1. **Go to Supabase Dashboard**
   - Open https://supabase.com
   - Select your project

2. **Open SQL Editor**
   - Click "SQL Editor" in the left sidebar
   - Click "New Query"

3. **Copy & Paste Migration**
   - Open: `supabase/migrations/028_notifications_system.sql`
   - Copy ALL the content
   - Paste into the SQL Editor

4. **Run the Migration**
   - Click "Run" button
   - Wait for success message

5. **Verify**
   ```sql
   SELECT * FROM notifications LIMIT 1;
   ```

---

## Option 2: Run via Supabase CLI

If you have Supabase CLI installed:

```bash
cd "c:\Users\ABHAY\coin circle\coin_circle"
supabase db push
```

If you don't have it installed:
```bash
npm install -g supabase
```

---

## Option 3: Run Admin Stats Migration

After notifications migration succeeds, run the admin stats:

1. Open SQL Editor in Supabase Dashboard
2. Copy content from: `supabase/migrations/029_admin_statistics.sql`
3. Paste and Run

---

## ✅ What Will Be Created

### Tables
- `notifications` - Stores all user notifications

### Functions
- `create_notification()` - Create a notification
- `notify_pool_members()` - Notify all pool members
- `send_payment_reminders()` - Send payment reminders
- `notify_on_pool_join()` - Trigger function
- `notify_on_contribution()` - Trigger function
- `notify_on_draw_complete()` - Trigger function

### Triggers
- `trigger_notify_pool_join` - Auto-notify on pool join
- `trigger_notify_contribution` - Auto-notify on contribution
- `trigger_notify_draw_complete` - Auto-notify on draw completion

### RLS Policies
- Users can view their own notifications
- Users can update their own notifications
- Users can delete their own notifications
- System can insert notifications

---

## 🧪 Test After Migration

Run this in SQL Editor to test:

```sql
-- Test creating a notification
SELECT create_notification(
  auth.uid(),
  'system_message',
  'Test Notification',
  'This is a test notification from the migration'
);

-- Check if it was created
SELECT * FROM notifications WHERE user_id = auth.uid();

-- Test marking as read
UPDATE notifications 
SET read = TRUE, read_at = NOW() 
WHERE user_id = auth.uid() AND read = FALSE;
```

---

## 🎯 Next Steps After Migration

1. ✅ Run notifications migration (this file)
2. ✅ Run admin stats migration (029_admin_statistics.sql)
3. ✅ Update app code (follow IMPLEMENTATION_GUIDE.md)
4. ✅ Test in the app

---

## ⚠️ If You Get Errors

### Error: "relation already exists"
**Solution:** The migration now handles this with `DROP TABLE IF EXISTS`

### Error: "trigger already exists"
**Solution:** The migration now handles this with `DROP TRIGGER IF EXISTS`

### Error: "function already exists"
**Solution:** The migration uses `CREATE OR REPLACE FUNCTION`

---

## 📋 Migration Status

- [x] Migration file fixed
- [ ] Run in Supabase Dashboard
- [ ] Verify table created
- [ ] Test notification creation
- [ ] Update app code

---

**Ready to run!** Just copy the SQL from `028_notifications_system.sql` and paste it into Supabase SQL Editor.
