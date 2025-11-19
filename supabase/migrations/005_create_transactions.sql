-- Create transactions table
-- Records all financial transactions

CREATE TYPE transaction_type_enum AS ENUM ('deposit', 'withdrawal', 'contribution', 'winning', 'refund');
CREATE TYPE transaction_status_enum AS ENUM ('pending', 'completed', 'failed', 'cancelled');
CREATE TYPE payment_method_enum AS ENUM ('bank_transfer', 'upi', 'card', 'wallet');

CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  pool_id UUID REFERENCES pools(id) ON DELETE SET NULL,
  transaction_type transaction_type_enum NOT NULL,
  amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
  currency TEXT DEFAULT 'INR' NOT NULL,
  status transaction_status_enum DEFAULT 'pending' NOT NULL,
  payment_method payment_method_enum,
  payment_reference TEXT,
  description TEXT,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own transactions"
  ON transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Only system/admin can update transactions (via RPC functions)
CREATE POLICY "System can update transactions"
  ON transactions FOR UPDATE
  USING (false); -- Will be handled by RPC functions

-- Create trigger for updated_at
CREATE TRIGGER set_transaction_updated_at
  BEFORE UPDATE ON transactions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_transactions_user ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_pool ON transactions(pool_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC);

-- Create function to update wallet balance on transaction completion
CREATE OR REPLACE FUNCTION public.handle_transaction_completion()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process if status changed to 'completed'
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    CASE NEW.transaction_type
      WHEN 'deposit' THEN
        UPDATE wallets 
        SET available_balance = available_balance + NEW.amount
        WHERE user_id = NEW.user_id;
        
      WHEN 'withdrawal' THEN
        UPDATE wallets 
        SET available_balance = available_balance - NEW.amount
        WHERE user_id = NEW.user_id;
        
      WHEN 'contribution' THEN
        UPDATE wallets 
        SET available_balance = available_balance - NEW.amount,
            locked_balance = locked_balance + NEW.amount
        WHERE user_id = NEW.user_id;
        
        -- Update pool member contribution
        UPDATE pool_members
        SET total_contributed = total_contributed + NEW.amount,
            payment_status = 'paid',
            last_payment_date = NOW()
        WHERE pool_id = NEW.pool_id AND user_id = NEW.user_id;
        
      WHEN 'winning' THEN
        UPDATE wallets 
        SET locked_balance = locked_balance - NEW.amount,
            available_balance = available_balance + NEW.amount,
            total_winnings = total_winnings + NEW.amount
        WHERE user_id = NEW.user_id;
        
        -- Update pool member winning
        UPDATE pool_members
        SET total_won = total_won + NEW.amount
        WHERE pool_id = NEW.pool_id AND user_id = NEW.user_id;
        
      WHEN 'refund' THEN
        UPDATE wallets 
        SET available_balance = available_balance + NEW.amount
        WHERE user_id = NEW.user_id;
    END CASE;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for transaction completion
DROP TRIGGER IF EXISTS on_transaction_completed ON transactions;
CREATE TRIGGER on_transaction_completed
  AFTER UPDATE ON transactions
  FOR EACH ROW 
  WHEN (NEW.status = 'completed' AND OLD.status != 'completed')
  EXECUTE FUNCTION public.handle_transaction_completion();
