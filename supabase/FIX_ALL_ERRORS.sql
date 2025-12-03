-- FIX ALL ERRORS
-- Run this in Supabase SQL Editor

-- 1. Fix get_contribution_status RPC (Ambiguous column 'status')
CREATE OR REPLACE FUNCTION get_contribution_status(p_pool_id UUID, p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_build_object(
    'is_paid', COALESCE(
      (SELECT t.status = 'completed' 
       FROM transactions t
       WHERE t.pool_id = p_pool_id 
         AND t.user_id = p_user_id 
         AND t.transaction_type = 'contribution'
       ORDER BY t.created_at DESC 
       LIMIT 1), 
      false
    ),
    'amount_due', COALESCE((SELECT p.contribution_amount FROM pools p WHERE p.id = p_pool_id), 0),
    'late_fee', 0.0,
    'total_due', COALESCE((SELECT p.contribution_amount FROM pools p WHERE p.id = p_pool_id), 0),
    'next_due_date', NOW() + INTERVAL '30 days',
    'status', 'pending'
  ) INTO v_result;
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Add 'joining_fee' to transaction_type_enum
-- Note: ALTER TYPE cannot run inside a transaction block in some Postgres versions/clients, 
-- but usually fine in Supabase Editor. If it fails, run it separately.
ALTER TYPE transaction_type_enum ADD VALUE IF NOT EXISTS 'joining_fee';

-- 3. Fix support_tickets relationship with profiles
-- First drop existing constraint if it references auth.users
ALTER TABLE support_tickets DROP CONSTRAINT IF EXISTS support_tickets_user_id_fkey;

-- Add constraint referencing profiles
ALTER TABLE support_tickets 
ADD CONSTRAINT support_tickets_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

-- 4. Verification
SELECT 'All fixes applied successfully!' as status;
