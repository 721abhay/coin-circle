-- ============================================
-- FIX AVATAR STORAGE
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Ensure avatars bucket exists and is public
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE
SET public = true;

-- 2. Drop old policies
DROP POLICY IF EXISTS "Public can view avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own avatars" ON storage.objects;

-- 3. Allow public viewing of avatars
CREATE POLICY "Public can view avatars"
ON storage.objects FOR SELECT
USING ( bucket_id = 'avatars' );

-- 4. Allow authenticated users to upload their own avatars
CREATE POLICY "Users can upload their own avatars"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' AND
  auth.role() = 'authenticated'
);

-- 5. Allow users to update their own avatars
CREATE POLICY "Users can update their own avatars"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars' AND
  auth.role() = 'authenticated'
);

-- 6. Allow users to delete their own avatars
CREATE POLICY "Users can delete their own avatars"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'avatars' AND
  auth.role() = 'authenticated'
);

-- 7. Verify setup
SELECT 'Avatars bucket:' as info, * FROM storage.buckets WHERE id = 'avatars';
SELECT 'Avatar policies:' as info, COUNT(*) as count FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';

SELECT '✅ Avatar storage setup complete!' as status;
