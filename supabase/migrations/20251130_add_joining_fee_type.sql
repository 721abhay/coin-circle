-- Add 'joining_fee' to transaction_type enum if not exists
DO $$ 
BEGIN
    -- Check if 'joining_fee' type already exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'joining_fee' 
        AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'transaction_type')
    ) THEN
        -- Add 'joining_fee' to the enum
        ALTER TYPE transaction_type ADD VALUE 'joining_fee';
    END IF;
END $$;

COMMENT ON TYPE transaction_type IS 'Transaction types: deposit, withdrawal, contribution, payout, penalty, refund, joining_fee';
