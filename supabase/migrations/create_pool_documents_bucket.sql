-- Create 'pool_documents' storage bucket for chat attachments
-- Run this in Supabase SQL Editor

-- 1. Create the bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('pool_documents', 'pool_documents', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Enable RLS (Row Level Security) on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Create policies for the bucket
-- Allow public read access
DROP POLICY IF EXISTS "Public Access pool_documents" ON storage.objects;
CREATE POLICY "Public Access pool_documents"
ON storage.objects FOR SELECT
USING ( bucket_id = 'pool_documents' );

-- Allow authenticated users to upload
DROP POLICY IF EXISTS "Authenticated Upload pool_documents" ON storage.objects;
CREATE POLICY "Authenticated Upload pool_documents"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'pool_documents' 
  AND auth.role() = 'authenticated'
);
