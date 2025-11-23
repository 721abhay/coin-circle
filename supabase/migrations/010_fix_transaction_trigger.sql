-- Fix handle_transaction_completion to handle INSERTs
CREATE OR REPLACE FUNCTION public.handle_transaction_completion()
RETURNS TRIGGER AS $$
BEGIN
  -- Process if status is 'completed' and (it's a new record OR status changed)
  IF NEW.status = 'completed' AND (TG_OP = 'INSERT' OR OLD.status != 'completed') THEN
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

-- Drop existing trigger
DROP TRIGGER IF EXISTS on_transaction_completed ON transactions;

-- Create updated trigger for INSERT and UPDATE
CREATE TRIGGER on_transaction_completed
  AFTER INSERT OR UPDATE ON transactions
  FOR EACH ROW 
  EXECUTE FUNCTION public.handle_transaction_completion();
