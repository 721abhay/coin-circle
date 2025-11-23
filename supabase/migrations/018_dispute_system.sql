-- 1. Create Enums
CREATE TYPE dispute_category AS ENUM ('payment_issue', 'harassment', 'fraud', 'other');
CREATE TYPE dispute_status AS ENUM ('open', 'under_review', 'resolved', 'dismissed');

-- 2. Create Disputes Table
CREATE TABLE IF NOT EXISTS disputes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pool_id UUID REFERENCES pools(id) ON DELETE SET NULL,
    creator_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    reported_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    category dispute_category NOT NULL,
    description TEXT NOT NULL,
    status dispute_status DEFAULT 'open' NOT NULL,
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create Dispute Evidence Table
CREATE TABLE IF NOT EXISTS dispute_evidence (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dispute_id UUID REFERENCES disputes(id) ON DELETE CASCADE NOT NULL,
    uploader_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    file_url TEXT NOT NULL,
    file_type TEXT, -- 'image', 'pdf', etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Enable RLS
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE dispute_evidence ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for Disputes

-- Users can view their own disputes
DROP POLICY IF EXISTS "Users can view own disputes" ON disputes;
CREATE POLICY "Users can view own disputes" ON disputes
    FOR SELECT
    USING (auth.uid() = creator_id OR auth.uid() = reported_user_id);

-- Admins can view all disputes
DROP POLICY IF EXISTS "Admins can view all disputes" ON disputes;
CREATE POLICY "Admins can view all disputes" ON disputes
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND is_admin = TRUE
        )
    );

-- Users can create disputes
DROP POLICY IF EXISTS "Users can create disputes" ON disputes;
CREATE POLICY "Users can create disputes" ON disputes
    FOR INSERT
    WITH CHECK (auth.uid() = creator_id);

-- Admins can update disputes (for resolution)
DROP POLICY IF EXISTS "Admins can update disputes" ON disputes;
CREATE POLICY "Admins can update disputes" ON disputes
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND is_admin = TRUE
        )
    );

-- 6. RLS Policies for Evidence

-- Users can view evidence for their disputes
DROP POLICY IF EXISTS "Users can view dispute evidence" ON dispute_evidence;
CREATE POLICY "Users can view dispute evidence" ON dispute_evidence
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM disputes
            WHERE id = dispute_evidence.dispute_id
            AND (creator_id = auth.uid() OR reported_user_id = auth.uid())
        )
    );

-- Admins can view all evidence
DROP POLICY IF EXISTS "Admins can view all evidence" ON dispute_evidence;
CREATE POLICY "Admins can view all evidence" ON dispute_evidence
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND is_admin = TRUE
        )
    );

-- Users can upload evidence to their disputes
DROP POLICY IF EXISTS "Users can upload evidence" ON dispute_evidence;
CREATE POLICY "Users can upload evidence" ON dispute_evidence
    FOR INSERT
    WITH CHECK (
        auth.uid() = uploader_id AND
        EXISTS (
            SELECT 1 FROM disputes
            WHERE id = dispute_evidence.dispute_id
            AND (creator_id = auth.uid() OR reported_user_id = auth.uid())
        )
    );

-- 7. Create Storage Bucket for Evidence (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('dispute-evidence', 'dispute-evidence', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies
DROP POLICY IF EXISTS "Evidence Public Access" ON storage.objects;
CREATE POLICY "Evidence Public Access" ON storage.objects
  FOR SELECT
  USING ( bucket_id = 'dispute-evidence' );

DROP POLICY IF EXISTS "Users can upload evidence files" ON storage.objects;
CREATE POLICY "Users can upload evidence files" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'dispute-evidence' AND
    auth.uid() = owner
  );
