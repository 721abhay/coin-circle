import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class DisputeService {
  static final SupabaseClient _client = SupabaseConfig.client;

  /// Create a new dispute
  static Future<String> createDispute({
    required String category,
    required String description,
    String? poolId,
    String? reportedUserId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    final response = await _client.from('disputes').insert({
      'creator_id': user.id,
      'category': category,
      'description': description,
      'pool_id': poolId,
      'reported_user_id': reportedUserId,
      'status': 'open',
    }).select().single();

    return response['id'];
  }

  /// Upload evidence for a dispute
  static Future<void> uploadEvidence({
    required String disputeId,
    required File file,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    final fileExt = file.path.split('.').last;
    final fileName = '${DateTime.now().toIso8601String()}_${user.id}.$fileExt';
    final filePath = '$disputeId/$fileName';

    // Upload file to storage
    await _client.storage.from('dispute-evidence').upload(
      filePath,
      file,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );

    // Get public URL
    final fileUrl = _client.storage.from('dispute-evidence').getPublicUrl(filePath);

    // Create evidence record
    await _client.from('dispute_evidence').insert({
      'dispute_id': disputeId,
      'uploader_id': user.id,
      'file_url': fileUrl,
      'file_type': fileExt,
    });
  }

  /// Get disputes created by the current user
  static Future<List<Map<String, dynamic>>> getUserDisputes() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    final response = await _client
        .from('disputes')
        .select('''
          *,
          pool:pools(name),
          reported_user:profiles!reported_user_id(full_name)
        ''')
        .eq('creator_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get details of a specific dispute
  static Future<Map<String, dynamic>> getDisputeDetails(String disputeId) async {
    final response = await _client
        .from('disputes')
        .select('''
          *,
          pool:pools(name),
          reported_user:profiles!reported_user_id(full_name, avatar_url),
          creator:profiles!creator_id(full_name, avatar_url),
          evidence:dispute_evidence(*)
        ''')
        .eq('id', disputeId)
        .single();

    return response;
  }

  /// Get all disputes (Admin only)
  static Future<List<Map<String, dynamic>>> getAllDisputes() async {
    // RLS will ensure only admins can fetch this
    final response = await _client
        .from('disputes')
        .select('''
          *,
          pool:pools(name),
          creator:profiles!creator_id(full_name, email),
          reported_user:profiles!reported_user_id(full_name)
        ''')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Resolve a dispute (Admin only)
  static Future<void> resolveDispute({
    required String disputeId,
    required String status,
    required String resolutionNotes,
  }) async {
    await _client.from('disputes').update({
      'status': status,
      'resolution_notes': resolutionNotes,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', disputeId);
  }
}
