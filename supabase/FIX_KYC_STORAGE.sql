-- 1. Update bucket to be public so getPublicUrl works as expected by the app
UPDATE storage.buckets
SET public = true
WHERE id = 'kyc-documents';

-- 2. Ensure the bucket exists if it doesn't
INSERT INTO storage.buckets (id, name, public)
VALUES ('kyc-documents', 'kyc-documents', true)
ON CONFLICT (id) DO UPDATE
SET public = true;

-- 3. Drop restrictive policies
DROP POLICY IF EXISTS "Users can view their own KYC documents" ON storage.objects;
DROP POLICY IF EXISTS "Public can view KYC documents" ON storage.objects;

-- 4. Allow public viewing of KYC documents (Required for Image.network with getPublicUrl)
CREATE POLICY "Public can view KYC documents"
ON storage.objects FOR SELECT
USING ( bucket_id = 'kyc-documents' );

-- 5. Allow authenticated users to upload
DROP POLICY IF EXISTS "Users can upload their own KYC documents" ON storage.objects;
CREATE POLICY "Users can upload their own KYC documents"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'kyc-documents' AND
  auth.role() = 'authenticated'
);
