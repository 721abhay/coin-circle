import 'package:supabase_flutter/supabase_flutter.dart';

class KYCService {
  static final _supabase = Supabase.instance.client;

  /// Submit KYC details
  static Future<void> submitKYC({
    required String fullName,
    required String documentType,
    required String documentNumber,
    required String documentUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    // Check if already submitted
    final existing = await _supabase
        .from('kyc_requests')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      if (existing['status'] == 'pending') {
        throw const AuthException('KYC verification is already in progress');
      } else if (existing['status'] == 'approved') {
        throw const AuthException('KYC is already approved');
      }
    }

    // Insert or Update
    await _supabase.from('kyc_requests').upsert({
      'user_id': user.id,
      'full_name': fullName,
      'document_type': documentType,
      'document_number': documentNumber,
      'document_url': documentUrl,
      'status': 'pending',
      'submitted_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get current user's KYC status
  static Future<Map<String, dynamic>?> getKYCStatus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('kyc_requests')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    
    return response;
  }

  /// Get all pending KYC requests (Admin only)
  static Future<List<Map<String, dynamic>>> getPendingKYCRequests() async {
    final response = await _supabase
        .from('kyc_requests')
        .select('*, profiles(email, avatar_url)')
        .eq('status', 'pending')
        .order('submitted_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Approve KYC request
  static Future<void> approveKYC(String userId) async {
    // 1. Update KYC request status
    await _supabase
        .from('kyc_requests')
        .update({
          'status': 'approved',
          'verified_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId);

    // 2. Update user profile to verified
    await _supabase
        .from('profiles')
        .update({'is_verified': true})
        .eq('id', userId);
  }

  /// Reject KYC request
  static Future<void> rejectKYC(String userId, String reason) async {
    await _supabase
        .from('kyc_requests')
        .update({
          'status': 'rejected',
          'rejection_reason': reason,
          'verified_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId);
  }
}
