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
        .from('kyc_documents')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      if (existing['verification_status'] == 'pending') {
        throw const AuthException('KYC verification is already in progress');
      } else if (existing['verification_status'] == 'approved') {
        throw const AuthException('KYC is already approved');
      }
    }

    // Insert or Update
    await _supabase.from('kyc_documents').upsert({
      'user_id': user.id,
      // 'full_name': fullName, // kyc_documents doesn't have full_name, it's in profiles
      'document_type': documentType,
      'document_number': documentNumber,
      'document_url': documentUrl,
      'verification_status': 'pending',
      'submitted_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get current user's KYC status
  static Future<Map<String, dynamic>?> getKYCStatus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('kyc_documents')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    
    return response;
  }

  /// Get all pending KYC requests (Admin only)
  static Future<List<Map<String, dynamic>>> getPendingKYCRequests() async {
    try {
      // Fetch KYC documents
      final kycDocs = await _supabase
          .from('kyc_documents')
          .select()
          .eq('verification_status', 'pending')
          .order('submitted_at', ascending: false);
      
      final List<Map<String, dynamic>> result = [];
      
      // Fetch profile data for each KYC document
      for (var doc in kycDocs) {
        try {
          final profile = await _supabase
              .from('profiles')
              .select('email, avatar_url, full_name')
              .eq('id', doc['user_id'])
              .maybeSingle();
          
          // Combine KYC doc with profile data
          result.add({
            ...doc,
            'profiles': profile ?? {
              'email': 'Unknown',
              'avatar_url': null,
              'full_name': 'Unknown User',
            },
          });
        } catch (e) {
          // If profile fetch fails, add doc without profile data
          result.add({
            ...doc,
            'profiles': {
              'email': 'Unknown',
              'avatar_url': null,
              'full_name': 'Unknown User',
            },
          });
        }
      }
      
      return result;
    } catch (e) {
      print('Error fetching KYC requests: $e');
      // Return empty list on error
      return [];
    }
  }

  /// Approve KYC request
  static Future<void> approveKYC(String userId) async {
    // 1. Update KYC request status
    await _supabase
        .from('kyc_documents')
        .update({
          'verification_status': 'approved',
          'verified_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId);

    // 2. Update user profile to verified
    await _supabase
        .from('profiles')
        .update({
          'is_verified': true,
          'kyc_verified': true, // Update both flags to be safe
        })
        .eq('id', userId);
  }

  /// Reject KYC request
  static Future<void> rejectKYC(String userId, String reason) async {
    await _supabase
        .from('kyc_documents')
        .update({
          'verification_status': 'rejected',
          'rejection_reason': reason,
          'verified_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId);
        
    // Ensure profile is not verified
    await _supabase
        .from('profiles')
        .update({
          'is_verified': false,
          'kyc_verified': false,
        })
        .eq('id', userId);
  }
}
