import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class StorageService {
  static final SupabaseClient _client = SupabaseConfig.client;

  /// Upload profile image to Supabase Storage
  /// Returns the public URL of the uploaded image
  static Future<String> uploadProfileImage(File file, String userId) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      await _client.storage.from('avatars').upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = _client.storage.from('avatars').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
