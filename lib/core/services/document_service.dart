// lib/core/services/document_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class DocumentService {
  static final _client = Supabase.instance.client;
  static const _bucket = 'pool_documents';

  /// Fetch documents for a specific pool
  static Future<List<Map<String, dynamic>>> getDocuments(String poolId) async {
    final response = await _client
        .from('pool_documents')
        .select()
        .eq('pool_id', poolId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Upload a document
  static Future<void> uploadDocument({
    required String poolId,
    required File file,
    required String category,
    required String name,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    final fileExt = path.extension(file.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExt';
    final filePath = '$poolId/$fileName';

    // Upload to Storage
    await _client.storage.from(_bucket).upload(
      filePath,
      file,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );

    // Get Public URL
    final publicUrl = _client.storage.from(_bucket).getPublicUrl(filePath);

    // Insert record into DB
    await _client.from('pool_documents').insert({
      'pool_id': poolId,
      'uploader_id': user.id,
      'name': name,
      'file_path': filePath,
      'file_url': publicUrl,
      'file_type': fileExt.replaceAll('.', ''),
      'file_size': await file.length(), // in bytes
      'category': category,
    });
  }

  /// Delete a document
  static Future<void> deleteDocument(String docId, String filePath) async {
    // Delete from Storage
    await _client.storage.from(_bucket).remove([filePath]);

    // Delete from DB
    await _client.from('pool_documents').delete().eq('id', docId);
  }
}
