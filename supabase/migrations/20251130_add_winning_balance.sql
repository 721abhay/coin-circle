-- Add winning_balance to wallets table
ALTER TABLE wallets ADD COLUMN IF NOT EXISTS winning_balance DECIMAL(10,2) DEFAULT 0.0;

-- Update existing wallets to have winning_balance = 0 (or some logic if needed, but 0 is safe)
-- If we wanted to be smart, we could try to calculate it from transactions, but that's complex.
-- For now, we assume 0 for existing users until they win something.

-- Verify
SELECT * FROM wallets LIMIT 1;
