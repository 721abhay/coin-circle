-- Add enable_chat and require_kyc columns to pools table
ALTER TABLE pools ADD COLUMN IF NOT EXISTS enable_chat BOOLEAN DEFAULT TRUE;
ALTER TABLE pools ADD COLUMN IF NOT EXISTS require_kyc BOOLEAN DEFAULT FALSE;

-- Add comment for documentation
COMMENT ON COLUMN pools.enable_chat IS 'Whether chat is enabled for this pool';
COMMENT ON COLUMN pools.require_kyc IS 'Whether KYC verification is required to join this pool';

-- Create function to check if user can join pool based on KYC requirement
CREATE OR REPLACE FUNCTION check_kyc_requirement(
  p_pool_id UUID,
  p_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_require_kyc BOOLEAN;
  v_user_kyc_verified BOOLEAN;
BEGIN
  -- Get pool's KYC requirement
  SELECT require_kyc INTO v_require_kyc
  FROM pools
  WHERE id = p_pool_id;
  
  -- If pool doesn't require KYC, allow join
  IF v_require_kyc = FALSE THEN
    RETURN TRUE;
  END IF;
  
  -- Check if user is KYC verified
  SELECT kyc_verified INTO v_user_kyc_verified
  FROM profiles
  WHERE id = p_user_id;
  
  -- Return whether user meets requirement
  RETURN COALESCE(v_user_kyc_verified, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
