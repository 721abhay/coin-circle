-- ============================================
-- FIX NOTIFICATIONS AND PHONE NUMBERS
-- Run this in Supabase SQL Editor
-- ============================================

-- STEP 1: Ensure notifications table exists with correct structure
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- STEP 2: Enable RLS on notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- STEP 3: Drop old notification policies
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
DROP POLICY IF EXISTS "System can insert notifications" ON notifications;

-- STEP 4: Create notification policies
CREATE POLICY "Users can view own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications" ON notifications
  FOR INSERT WITH CHECK (true);  -- Allow system to create notifications for any user

-- STEP 5: Sync phone numbers from auth.users to profiles
UPDATE public.profiles p
SET phone = u.phone
FROM auth.users u
WHERE p.id = u.id
AND u.phone IS NOT NULL;

-- STEP 6: Create trigger to auto-sync phone numbers
CREATE OR REPLACE FUNCTION public.sync_phone_number() 
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.profiles
  SET phone = NEW.phone
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_phone_update ON auth.users;
CREATE TRIGGER on_auth_user_phone_update
AFTER UPDATE OF phone ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.sync_phone_number();

-- STEP 7: Create function to send KYC approval notification
CREATE OR REPLACE FUNCTION send_kyc_approval_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- Only send notification when status changes to 'approved'
  IF NEW.verification_status = 'approved' AND OLD.verification_status != 'approved' THEN
    INSERT INTO notifications (user_id, type, title, message, metadata)
    VALUES (
      NEW.user_id,
      'kyc_approved',
      'KYC Verified!',
      'Your identity verification has been approved. You can now create and join pools.',
      jsonb_build_object('kyc_id', NEW.id)
    );
  END IF;
  
  -- Send notification when status changes to 'rejected'
  IF NEW.verification_status = 'rejected' AND OLD.verification_status != 'rejected' THEN
    INSERT INTO notifications (user_id, type, title, message, metadata)
    VALUES (
      NEW.user_id,
      'kyc_rejected',
      'KYC Verification Failed',
      COALESCE('Your KYC was rejected: ' || NEW.rejection_reason, 'Your KYC verification was rejected. Please resubmit with correct documents.'),
      jsonb_build_object('kyc_id', NEW.id, 'reason', NEW.rejection_reason)
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- STEP 8: Create trigger for KYC approval notifications
DROP TRIGGER IF EXISTS kyc_status_notification ON kyc_documents;
CREATE TRIGGER kyc_status_notification
AFTER UPDATE OF verification_status ON kyc_documents
FOR EACH ROW EXECUTE FUNCTION send_kyc_approval_notification();

-- STEP 9: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON profiles(phone);

-- STEP 10: Verify setup
SELECT 'Notifications table exists:' as info, EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_name = 'notifications'
) as result;

SELECT 'Phone numbers synced:' as info, COUNT(*) as count 
FROM profiles 
WHERE phone IS NOT NULL;

SELECT 'Notification policies created:' as info, COUNT(*) as count 
FROM pg_policies 
WHERE tablename = 'notifications';

-- Success message
SELECT '✅ Notifications and phone sync setup complete!' as status;
