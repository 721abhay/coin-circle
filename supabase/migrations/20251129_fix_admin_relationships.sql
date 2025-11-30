-- Fix relationships for Admin Dashboard

-- 1. Fix Disputes -> Pools relationship
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_disputes_pool') THEN
        ALTER TABLE disputes 
        ADD CONSTRAINT fk_disputes_pool 
        FOREIGN KEY (pool_id) 
        REFERENCES pools(id) 
        ON DELETE CASCADE;
    END IF;
END $$;

-- 2. Fix Withdrawal Requests -> Profiles relationship
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_withdrawals_user') THEN
        ALTER TABLE withdrawal_requests 
        ADD CONSTRAINT fk_withdrawals_user 
        FOREIGN KEY (user_id) 
        REFERENCES profiles(id) 
        ON DELETE CASCADE;
    END IF;
END $$;

-- 3. Fix Pools -> Profiles (Creator) relationship
-- This likely exists but might be named differently. We ensure it's explicit.
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pools_creator') THEN
        ALTER TABLE pools 
        ADD CONSTRAINT fk_pools_creator 
        FOREIGN KEY (creator_id) 
        REFERENCES profiles(id) 
        ON DELETE CASCADE;
    END IF;
END $$;

-- 4. Fix Disputes -> Profiles (Creator of dispute) relationship
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_disputes_user') THEN
        ALTER TABLE disputes 
        ADD CONSTRAINT fk_disputes_user 
        FOREIGN KEY (created_by) 
        REFERENCES profiles(id) 
        ON DELETE CASCADE;
    END IF;
END $$;
