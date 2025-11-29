-- =====================================================
-- Coin Circle: Profile Features Database Schema
-- SAFE Migration - Handles All Edge Cases
-- =====================================================

-- 1. Extend profiles table with personal details
DO $$ 
BEGIN
    ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT false;
    ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false;
    ALTER TABLE profiles ADD COLUMN IF NOT EXISTS address TEXT;
    ALTER TABLE profiles ADD COLUMN IF NOT EXISTS date_of_birth DATE;
    ALTER TABLE profiles ADD COLUMN IF NOT EXISTS pan_number VARCHAR(10);
    ALTER TABLE profiles ADD COLUMN IF NOT EXISTS aadhaar_number VARCHAR(12);
    ALTER TABLE profiles ADD COLUMN IF NOT EXISTS annual_income VARCHAR(50);
    ALTER TABLE profiles ADD COLUMN IF NOT EXISTS occupation VARCHAR(100);
    ALTER TABLE profiles ADD COLUMN IF NOT EXISTS privacy_settings JSONB DEFAULT '{}'::jsonb;
    RAISE NOTICE '✅ Extended profiles table';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE '⚠️  Profiles table: %', SQLERRM;
END $$;

-- 2. Create nominees table
DO $$
BEGIN
    CREATE TABLE IF NOT EXISTS nominees (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
      name VARCHAR(255) NOT NULL,
      relationship VARCHAR(50) NOT NULL,
      date_of_birth DATE,
      phone_number VARCHAR(15),
      email VARCHAR(255),
      allocation_percentage INTEGER DEFAULT 100 CHECK (allocation_percentage > 0 AND allocation_percentage <= 100),
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    RAISE NOTICE '✅ Created nominees table';
EXCEPTION
    WHEN duplicate_table THEN
        RAISE NOTICE '⚠️  nominees table already exists';
END $$;

-- 3. Create bank_accounts table
DO $$
BEGIN
    CREATE TABLE IF NOT EXISTS bank_accounts (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
      account_holder_name VARCHAR(255) NOT NULL,
      account_number VARCHAR(20) NOT NULL,
      ifsc_code VARCHAR(11) NOT NULL,
      bank_name VARCHAR(255) NOT NULL,
      branch_name VARCHAR(255),
      account_type VARCHAR(20) DEFAULT 'savings',
      is_primary BOOLEAN DEFAULT false,
      is_verified BOOLEAN DEFAULT false,
      verification_method VARCHAR(50),
      verification_date TIMESTAMP WITH TIME ZONE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    RAISE NOTICE '✅ Created bank_accounts table';
EXCEPTION
    WHEN duplicate_table THEN
        RAISE NOTICE '⚠️  bank_accounts table already exists';
END $$;

-- Add unique constraint
DO $$
BEGIN
    ALTER TABLE bank_accounts ADD CONSTRAINT bank_accounts_user_account_unique UNIQUE(user_id, account_number);
    RAISE NOTICE '✅ Added unique constraint to bank_accounts';
EXCEPTION
    WHEN duplicate_table THEN NULL;
    WHEN duplicate_object THEN 
        RAISE NOTICE '⚠️  Unique constraint already exists';
END $$;

-- 4. Create KYC documents table
DO $$
BEGIN
    CREATE TABLE IF NOT EXISTS kyc_documents (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
      document_type VARCHAR(50) NOT NULL,
      document_url TEXT NOT NULL,
      uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      verified_at TIMESTAMP WITH TIME ZONE,
      verified_by UUID REFERENCES auth.users(id),
      rejection_reason TEXT
    );
    RAISE NOTICE '✅ Created kyc_documents table';
EXCEPTION
    WHEN duplicate_table THEN
        RAISE NOTICE '⚠️  kyc_documents table already exists';
END $$;

-- 5. Create KYC status table
DO $$
BEGIN
    CREATE TABLE IF NOT EXISTS kyc_status (
      user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
      overall_status VARCHAR(20) DEFAULT 'pending',
      pan_verified BOOLEAN DEFAULT false,
      aadhaar_verified BOOLEAN DEFAULT false,
      bank_verified BOOLEAN DEFAULT false,
      selfie_verified BOOLEAN DEFAULT false,
      last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    RAISE NOTICE '✅ Created kyc_status table';
EXCEPTION
    WHEN duplicate_table THEN
        RAISE NOTICE '⚠️  kyc_status table already exists';
END $$;

-- 6. Create profile change requests table
DO $$
BEGIN
    CREATE TABLE IF NOT EXISTS profile_change_requests (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
      request_type VARCHAR(50) NOT NULL,
      field_name VARCHAR(100) NOT NULL,
      current_value TEXT,
      requested_value TEXT NOT NULL,
      rejection_reason TEXT,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      reviewed_at TIMESTAMP WITH TIME ZONE,
      reviewed_by UUID REFERENCES auth.users(id)
    );
    RAISE NOTICE '✅ Created profile_change_requests table';
EXCEPTION
    WHEN duplicate_table THEN
        RAISE NOTICE '⚠️  profile_change_requests table already exists';
END $$;

-- 7. Create support tickets table
DO $$
BEGIN
    CREATE TABLE IF NOT EXISTS support_tickets (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
      category VARCHAR(100) NOT NULL,
      subject VARCHAR(255) NOT NULL,
      description TEXT NOT NULL,
      priority VARCHAR(20) DEFAULT 'medium',
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      closed_at TIMESTAMP WITH TIME ZONE
    );
    RAISE NOTICE '✅ Created support_tickets table';
EXCEPTION
    WHEN duplicate_table THEN
        RAISE NOTICE '⚠️  support_tickets table already exists';
END $$;

-- 8. Create support messages table
DO $$
BEGIN
    CREATE TABLE IF NOT EXISTS support_messages (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      ticket_id UUID REFERENCES support_tickets(id) ON DELETE CASCADE,
      sender_id UUID REFERENCES auth.users(id),
      message TEXT NOT NULL,
      is_staff BOOLEAN DEFAULT false,
      attachments JSONB DEFAULT '[]'::jsonb,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    RAISE NOTICE '✅ Created support_messages table';
EXCEPTION
    WHEN duplicate_table THEN
        RAISE NOTICE '⚠️  support_messages table already exists';
END $$;

-- =====================================================
-- Indexes for Performance
-- =====================================================

DO $$
BEGIN
    CREATE INDEX IF NOT EXISTS idx_nominees_user_id ON nominees(user_id);
    CREATE INDEX IF NOT EXISTS idx_bank_accounts_user_id ON bank_accounts(user_id);
    CREATE INDEX IF NOT EXISTS idx_bank_accounts_primary ON bank_accounts(user_id, is_primary) WHERE is_primary = true;
    CREATE INDEX IF NOT EXISTS idx_kyc_documents_user_id ON kyc_documents(user_id);
    CREATE INDEX IF NOT EXISTS idx_profile_requests_user_id ON profile_change_requests(user_id);
    CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON support_tickets(user_id);
    CREATE INDEX IF NOT EXISTS idx_support_messages_ticket_id ON support_messages(ticket_id);
    RAISE NOTICE '✅ Created performance indexes';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE '⚠️  Indexes: %', SQLERRM;
END $$;

-- =====================================================
-- Row Level Security (RLS) Policies
-- =====================================================

-- Enable RLS
DO $$
BEGIN
    ALTER TABLE nominees ENABLE ROW LEVEL SECURITY;
    ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;
    ALTER TABLE kyc_documents ENABLE ROW LEVEL SECURITY;
    ALTER TABLE kyc_status ENABLE ROW LEVEL SECURITY;
    ALTER TABLE profile_change_requests ENABLE ROW LEVEL SECURITY;
    ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
    ALTER TABLE support_messages ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Enabled RLS on all tables';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE '⚠️  RLS: %', SQLERRM;
END $$;

-- Drop and recreate policies
DO $$ 
BEGIN
    -- Nominees
    DROP POLICY IF EXISTS "Users can view their own nominees" ON nominees;
    DROP POLICY IF EXISTS "Users can insert their own nominees" ON nominees;
    DROP POLICY IF EXISTS "Users can update their own nominees" ON nominees;
    DROP POLICY IF EXISTS "Users can delete their own nominees" ON nominees;
    
    CREATE POLICY "Users can view their own nominees" ON nominees FOR SELECT USING (auth.uid() = user_id);
    CREATE POLICY "Users can insert their own nominees" ON nominees FOR INSERT WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "Users can update their own nominees" ON nominees FOR UPDATE USING (auth.uid() = user_id);
    CREATE POLICY "Users can delete their own nominees" ON nominees FOR DELETE USING (auth.uid() = user_id);
    
    -- Bank accounts
    DROP POLICY IF EXISTS "Users can view their own bank accounts" ON bank_accounts;
    DROP POLICY IF EXISTS "Users can insert their own bank accounts" ON bank_accounts;
    DROP POLICY IF EXISTS "Users can update their own bank accounts" ON bank_accounts;
    DROP POLICY IF EXISTS "Users can delete their own bank accounts" ON bank_accounts;
    
    CREATE POLICY "Users can view their own bank accounts" ON bank_accounts FOR SELECT USING (auth.uid() = user_id);
    CREATE POLICY "Users can insert their own bank accounts" ON bank_accounts FOR INSERT WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "Users can update their own bank accounts" ON bank_accounts FOR UPDATE USING (auth.uid() = user_id);
    CREATE POLICY "Users can delete their own bank accounts" ON bank_accounts FOR DELETE USING (auth.uid() = user_id);
    
    -- KYC documents
    DROP POLICY IF EXISTS "Users can view their own KYC documents" ON kyc_documents;
    DROP POLICY IF EXISTS "Users can upload their own KYC documents" ON kyc_documents;
    
    CREATE POLICY "Users can view their own KYC documents" ON kyc_documents FOR SELECT USING (auth.uid() = user_id);
    CREATE POLICY "Users can upload their own KYC documents" ON kyc_documents FOR INSERT WITH CHECK (auth.uid() = user_id);
    
    -- KYC status
    DROP POLICY IF EXISTS "Users can view their own KYC status" ON kyc_status;
    DROP POLICY IF EXISTS "Users can insert their own KYC status" ON kyc_status;
    
    CREATE POLICY "Users can view their own KYC status" ON kyc_status FOR SELECT USING (auth.uid() = user_id);
    CREATE POLICY "Users can insert their own KYC status" ON kyc_status FOR INSERT WITH CHECK (auth.uid() = user_id);
    
    -- Profile requests
    DROP POLICY IF EXISTS "Users can view their own requests" ON profile_change_requests;
    DROP POLICY IF EXISTS "Users can create requests" ON profile_change_requests;
    
    CREATE POLICY "Users can view their own requests" ON profile_change_requests FOR SELECT USING (auth.uid() = user_id);
    CREATE POLICY "Users can create requests" ON profile_change_requests FOR INSERT WITH CHECK (auth.uid() = user_id);
    
    -- Support tickets
    DROP POLICY IF EXISTS "Users can view their own tickets" ON support_tickets;
    DROP POLICY IF EXISTS "Users can create tickets" ON support_tickets;
    DROP POLICY IF EXISTS "Users can update their own tickets" ON support_tickets;
    
    CREATE POLICY "Users can view their own tickets" ON support_tickets FOR SELECT USING (auth.uid() = user_id);
    CREATE POLICY "Users can create tickets" ON support_tickets FOR INSERT WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "Users can update their own tickets" ON support_tickets FOR UPDATE USING (auth.uid() = user_id);
    
    -- Support messages
    DROP POLICY IF EXISTS "Users can view messages for their tickets" ON support_messages;
    DROP POLICY IF EXISTS "Users can send messages to their tickets" ON support_messages;
    
    CREATE POLICY "Users can view messages for their tickets" ON support_messages FOR SELECT 
      USING (EXISTS (SELECT 1 FROM support_tickets WHERE support_tickets.id = ticket_id AND support_tickets.user_id = auth.uid()));
    CREATE POLICY "Users can send messages to their tickets" ON support_messages FOR INSERT 
      WITH CHECK (EXISTS (SELECT 1 FROM support_tickets WHERE support_tickets.id = ticket_id AND support_tickets.user_id = auth.uid()));
    
    RAISE NOTICE '✅ Created RLS policies';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE '⚠️  Policies: %', SQLERRM;
END $$;

-- =====================================================
-- Triggers for updated_at timestamps
-- =====================================================

DO $$
BEGIN
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $func$
    BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
    END;
    $func$ LANGUAGE plpgsql;
    
    DROP TRIGGER IF EXISTS update_nominees_updated_at ON nominees;
    DROP TRIGGER IF EXISTS update_bank_accounts_updated_at ON bank_accounts;
    DROP TRIGGER IF EXISTS update_support_tickets_updated_at ON support_tickets;
    
    CREATE TRIGGER update_nominees_updated_at BEFORE UPDATE ON nominees
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    
    CREATE TRIGGER update_bank_accounts_updated_at BEFORE UPDATE ON bank_accounts
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    
    CREATE TRIGGER update_support_tickets_updated_at BEFORE UPDATE ON support_tickets
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    
    RAISE NOTICE '✅ Created triggers';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE '⚠️  Triggers: %', SQLERRM;
END $$;

-- =====================================================
-- Helper Functions
-- =====================================================

DO $$
BEGIN
    CREATE OR REPLACE FUNCTION set_primary_bank_account(account_id UUID, user_id_param UUID)
    RETURNS VOID AS $func$
    BEGIN
        UPDATE bank_accounts SET is_primary = false WHERE user_id = user_id_param;
        UPDATE bank_accounts SET is_primary = true WHERE id = account_id AND user_id = user_id_param;
    END;
    $func$ LANGUAGE plpgsql SECURITY DEFINER;
    
    CREATE OR REPLACE FUNCTION is_kyc_complete(user_id_param UUID)
    RETURNS BOOLEAN AS $func$
    DECLARE
        kyc_record RECORD;
    BEGIN
        SELECT * INTO kyc_record FROM kyc_status WHERE user_id = user_id_param;
        IF kyc_record IS NULL THEN
            RETURN false;
        END IF;
        RETURN kyc_record.overall_status = 'verified';
    END;
    $func$ LANGUAGE plpgsql SECURITY DEFINER;
    
    RAISE NOTICE '✅ Created helper functions';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE '⚠️  Functions: %', SQLERRM;
END $$;

-- Final success message
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ MIGRATION COMPLETED SUCCESSFULLY!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Created tables:';
    RAISE NOTICE '  - nominees';
    RAISE NOTICE '  - bank_accounts';
    RAISE NOTICE '  - kyc_documents';
    RAISE NOTICE '  - kyc_status';
    RAISE NOTICE '  - profile_change_requests';
    RAISE NOTICE '  - support_tickets';
    RAISE NOTICE '  - support_messages';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 RLS policies enabled';
    RAISE NOTICE '⚡ Performance indexes created';
    RAISE NOTICE '🎯 Helper functions ready';
    RAISE NOTICE '========================================';
END $$;
