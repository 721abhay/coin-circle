# Profile Image Display Fix

## Issue:
Profile images not showing on home screen and profile screen - only showing placeholder icons.

## Root Cause:
The CircleAvatar widgets are hardcoded to show icons instead of loading actual user avatars from the database.

## Quick Fix:

### For Home Screen (`home_screen.dart`):

Replace the CircleAvatar at line ~490 with:

```dart
FutureBuilder<Map<String, dynamic>?>(
  future: _client.auth.currentUser != null
      ? _client
          .from('profiles')
          .select('avatar_url')
          .eq('id', _client.auth.currentUser!.id)
          .maybeSingle()
      : Future.value(null),
  builder: (context, snapshot) {
    final avatarUrl = snapshot.data?['avatar_url'] as String?;
    
    return GestureDetector(
      onTap: () => context.go('/profile'),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.white.withOpacity(0.2),
        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
            ? NetworkImage(avatarUrl)
            : null,
        child: (avatarUrl == null || avatarUrl.isEmpty)
            ? const Icon(Icons.person, color: Colors.white)
            : null,
      ),
    );
  },
)
```

### For Profile Screen (`profile_screen.dart`):

The profile screen at line ~287-297 already has the correct logic but may need the avatar URL to be properly formatted.

Check if avatar URLs in database are:
1. Full URLs (https://...)
2. Or just file names that need to be prefixed with storage URL

## Storage Bucket Check:

Run this SQL to verify avatars bucket exists:
```sql
SELECT * FROM storage.buckets WHERE id = 'avatars';
```

If it doesn't exist, create it:
```sql
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;
```

## Storage Policies:

```sql
-- Allow public viewing
CREATE POLICY "Public can view avatars"
ON storage.objects FOR SELECT
USING ( bucket_id = 'avatars' );

-- Allow authenticated users to upload
CREATE POLICY "Users can upload their own avatars"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' AND
  auth.role() = 'authenticated'
);
```

## Test:

1. Upload a profile picture from the profile screen
2. Check if it appears on home screen header
3. Check if it appears on profile screen

## Alternative: Use Supabase Storage Helper

If images still don't load, the URLs might need to be constructed:

```dart
final avatarUrl = snapshot.data?['avatar_url'] as String?;
final imageUrl = avatarUrl != null && avatarUrl.isNotEmpty
    ? _client.storage.from('avatars').getPublicUrl(avatarUrl)
    : null;

// Then use imageUrl in NetworkImage
```
