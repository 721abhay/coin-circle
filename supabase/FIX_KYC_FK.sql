-- Add Foreign Key constraint to kyc_documents if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_kyc_profiles' 
        AND table_name = 'kyc_documents'
    ) THEN
        ALTER TABLE kyc_documents
        ADD CONSTRAINT fk_kyc_profiles
        FOREIGN KEY (user_id)
        REFERENCES profiles(id)
        ON DELETE CASCADE;
    END IF;
END $$;
