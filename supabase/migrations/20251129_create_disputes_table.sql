-- Create disputes table
CREATE TABLE IF NOT EXISTS disputes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  creator_id UUID REFERENCES auth.users(id) NOT NULL,
  pool_id UUID REFERENCES pools(id), -- This is the key relationship
  reported_user_id UUID REFERENCES auth.users(id),
  category TEXT NOT NULL,
  description TEXT NOT NULL,
  status TEXT DEFAULT 'open', -- open, resolved, rejected
  resolution_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create dispute_evidence table
CREATE TABLE IF NOT EXISTS dispute_evidence (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  dispute_id UUID REFERENCES disputes(id) ON DELETE CASCADE NOT NULL,
  uploader_id UUID REFERENCES auth.users(id) NOT NULL,
  file_url TEXT NOT NULL,
  file_type TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS Policies
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE dispute_evidence ENABLE ROW LEVEL SECURITY;

-- Disputes Policies
CREATE POLICY "Users can view their own disputes" ON disputes
  FOR SELECT USING (auth.uid() = creator_id);

CREATE POLICY "Admins can view all disputes" ON disputes
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users can create disputes" ON disputes
  FOR INSERT WITH CHECK (auth.uid() = creator_id);

-- Evidence Policies
CREATE POLICY "Users can view evidence for their disputes" ON dispute_evidence
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM disputes WHERE id = dispute_evidence.dispute_id AND creator_id = auth.uid())
  );

CREATE POLICY "Admins can view all evidence" ON dispute_evidence
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users can upload evidence for their disputes" ON dispute_evidence
  FOR INSERT WITH CHECK (auth.uid() = uploader_id);
