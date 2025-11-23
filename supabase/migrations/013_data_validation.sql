-- Add CHECK constraints for data validation

-- Wallets: Ensure balances are non-negative
ALTER TABLE public.wallets DROP CONSTRAINT IF EXISTS wallets_available_balance_check;
ALTER TABLE public.wallets DROP CONSTRAINT IF EXISTS wallets_locked_balance_check;

ALTER TABLE public.wallets
ADD CONSTRAINT wallets_available_balance_check CHECK (available_balance >= 0),
ADD CONSTRAINT wallets_locked_balance_check CHECK (locked_balance >= 0);

-- Transactions: Ensure amount is positive
ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_amount_check;

ALTER TABLE public.transactions
ADD CONSTRAINT transactions_amount_check CHECK (amount > 0);

-- Pools: Ensure valid configuration
ALTER TABLE public.pools DROP CONSTRAINT IF EXISTS pools_contribution_amount_check;
ALTER TABLE public.pools DROP CONSTRAINT IF EXISTS pools_max_members_check;
ALTER TABLE public.pools DROP CONSTRAINT IF EXISTS pools_total_rounds_check;

ALTER TABLE public.pools
ADD CONSTRAINT pools_contribution_amount_check CHECK (contribution_amount > 0),
ADD CONSTRAINT pools_max_members_check CHECK (max_members > 1),
ADD CONSTRAINT pools_total_rounds_check CHECK (total_rounds > 0);

-- Bids: Ensure bid amount is positive
ALTER TABLE public.bids DROP CONSTRAINT IF EXISTS bids_amount_check;

-- Corrected column name: bid_amount instead of amount
ALTER TABLE public.bids
ADD CONSTRAINT bids_amount_check CHECK (bid_amount > 0);
