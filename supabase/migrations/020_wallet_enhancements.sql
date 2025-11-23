-- 1. Create Enums
CREATE TYPE account_type AS ENUM ('savings', 'checking');
CREATE TYPE withdrawal_status AS ENUM ('pending', 'processing', 'completed', 'rejected');
CREATE TYPE transaction_category AS ENUM ('deposit', 'withdrawal', 'pool_contribution', 'pool_payout', 'fee', 'refund');

-- 2. Add category to transactions table
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS category transaction_category DEFAULT 'pool_contribution';

-- 3. Create Bank Accounts Table
CREATE TABLE IF NOT EXISTS bank_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    account_holder_name TEXT NOT NULL,
    account_number TEXT NOT NULL, -- Should be encrypted in production
    bank_name TEXT NOT NULL,
    ifsc_code TEXT NOT NULL, -- or routing_number for international
    account_type account_type DEFAULT 'savings',
    is_primary BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create Withdrawal Requests Table
CREATE TABLE IF NOT EXISTS withdrawal_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    bank_account_id UUID REFERENCES bank_accounts(id) ON DELETE SET NULL,
    status withdrawal_status DEFAULT 'pending',
    processing_fee DECIMAL(15, 2) DEFAULT 0,
    rejection_reason TEXT,
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Enable RLS
ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies for Bank Accounts
DROP POLICY IF EXISTS "Users can view own bank accounts" ON bank_accounts;
CREATE POLICY "Users can view own bank accounts" ON bank_accounts
    FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own bank accounts" ON bank_accounts;
CREATE POLICY "Users can insert own bank accounts" ON bank_accounts
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own bank accounts" ON bank_accounts;
CREATE POLICY "Users can update own bank accounts" ON bank_accounts
    FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own bank accounts" ON bank_accounts;
CREATE POLICY "Users can delete own bank accounts" ON bank_accounts
    FOR DELETE
    USING (auth.uid() = user_id);

-- Admins can view all bank accounts
DROP POLICY IF EXISTS "Admins can view all bank accounts" ON bank_accounts;
CREATE POLICY "Admins can view all bank accounts" ON bank_accounts
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND is_admin = TRUE
        )
    );

-- 7. RLS Policies for Withdrawal Requests
DROP POLICY IF EXISTS "Users can view own withdrawal requests" ON withdrawal_requests;
CREATE POLICY "Users can view own withdrawal requests" ON withdrawal_requests
    FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create withdrawal requests" ON withdrawal_requests;
CREATE POLICY "Users can create withdrawal requests" ON withdrawal_requests
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Admins can view and update all withdrawal requests
DROP POLICY IF EXISTS "Admins can view all withdrawals" ON withdrawal_requests;
CREATE POLICY "Admins can view all withdrawals" ON withdrawal_requests
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND is_admin = TRUE
        )
    );

DROP POLICY IF EXISTS "Admins can update withdrawals" ON withdrawal_requests;
CREATE POLICY "Admins can update withdrawals" ON withdrawal_requests
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND is_admin = TRUE
        )
    );

-- 8. Function to ensure only one primary bank account per user
CREATE OR REPLACE FUNCTION public.ensure_single_primary_bank_account()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_primary = TRUE THEN
        -- Set all other accounts for this user to non-primary
        UPDATE bank_accounts
        SET is_primary = FALSE
        WHERE user_id = NEW.user_id AND id != NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS ensure_single_primary_trigger ON bank_accounts;
CREATE TRIGGER ensure_single_primary_trigger
    BEFORE INSERT OR UPDATE ON bank_accounts
    FOR EACH ROW
    EXECUTE FUNCTION public.ensure_single_primary_bank_account();

-- 9. Function to process withdrawal (admin only)
CREATE OR REPLACE FUNCTION public.process_withdrawal(
    p_withdrawal_id UUID,
    p_status withdrawal_status,
    p_rejection_reason TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_withdrawal RECORD;
BEGIN
    -- Check if user is admin
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = TRUE) THEN
        RAISE EXCEPTION 'Access denied: Admin only';
    END IF;

    -- Get withdrawal details
    SELECT * INTO v_withdrawal
    FROM withdrawal_requests
    WHERE id = p_withdrawal_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Withdrawal request not found';
    END IF;

    -- Update withdrawal status
    UPDATE withdrawal_requests
    SET 
        status = p_status,
        rejection_reason = p_rejection_reason,
        processed_at = CASE WHEN p_status IN ('completed', 'rejected') THEN NOW() ELSE NULL END
    WHERE id = p_withdrawal_id;

    -- If completed, deduct from wallet and create transaction
    IF p_status = 'completed' THEN
        -- Deduct from wallet
        UPDATE wallets
        SET balance = balance - (v_withdrawal.amount + v_withdrawal.processing_fee)
        WHERE user_id = v_withdrawal.user_id;

        -- Create transaction record
        INSERT INTO transactions (user_id, amount, type, category, description, status)
        VALUES (
            v_withdrawal.user_id,
            -(v_withdrawal.amount + v_withdrawal.processing_fee),
            'debit',
            'withdrawal',
            'Withdrawal to bank account',
            'completed'
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_bank_accounts_user ON bank_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_bank_accounts_primary ON bank_accounts(user_id, is_primary) WHERE is_primary = TRUE;
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_user ON withdrawal_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_status ON withdrawal_requests(status);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category);
CREATE INDEX IF NOT EXISTS idx_transactions_user_category ON transactions(user_id, category);
