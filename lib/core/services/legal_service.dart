import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class LegalService {
  static final SupabaseClient _client = SupabaseConfig.client;

  /// Sign digital agreement
  static Future<String> signAgreement({
    required String poolId,
    required String agreementType,
    required String agreementText,
    required String version,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      final result = await _client.rpc('sign_agreement', params: {
        'p_user_id': user.id,
        'p_pool_id': poolId,
        'p_agreement_type': agreementType,
        'p_agreement_text': agreementText,
        'p_version': version,
        'p_ip_address': ipAddress,
        'p_device_info': deviceInfo,
      });

      return result as String;
    } catch (e) {
      debugPrint('Error signing agreement: $e');
      rethrow;
    }
  }

  /// Get user's agreements
  static Future<List<Map<String, dynamic>>> getUserAgreements({
    String? poolId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      var query = _client
          .from('legal_agreements')
          .select('*')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .order('signed_at', ascending: false);

      if (poolId != null) {
        query = query.eq('pool_id', poolId);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching agreements: $e');
      return [];
    }
  }

  /// Issue legal notice
  static Future<String> issueLegalNotice({
    required String userId,
    required String poolId,
    required String noticeType,
    required String subject,
    required String content,
    required double amountOwed,
    DateTime? dueDate,
  }) async {
    try {
      final result = await _client.rpc('issue_legal_notice', params: {
        'p_user_id': userId,
        'p_pool_id': poolId,
        'p_notice_type': noticeType,
        'p_subject': subject,
        'p_content': content,
        'p_amount_owed': amountOwed,
        'p_due_date': dueDate?.toIso8601String(),
      });

      return result as String;
    } catch (e) {
      debugPrint('Error issuing legal notice: $e');
      rethrow;
    }
  }

  /// Get legal notices for user
  static Future<List<Map<String, dynamic>>> getLegalNotices({
    String? status,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      var query = _client
          .from('legal_notices')
          .select('*')
          .eq('user_id', user.id)
          .order('issued_at', ascending: false);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching legal notices: $e');
      return [];
    }
  }

  /// Acknowledge legal notice
  static Future<void> acknowledgeLegalNotice(String noticeId) async {
    try {
      await _client
          .from('legal_notices')
          .update({
            'status': 'acknowledged',
            'acknowledged_at': DateTime.now().toIso8601String(),
          })
          .eq('id', noticeId);
    } catch (e) {
      debugPrint('Error acknowledging notice: $e');
      rethrow;
    }
  }

  /// Escalate enforcement
  static Future<void> escalateEnforcement({
    required String userId,
    required String poolId,
    required int daysOverdue,
    required double amountOverdue,
  }) async {
    try {
      await _client.rpc('escalate_enforcement', params: {
        'p_user_id': userId,
        'p_pool_id': poolId,
        'p_days_overdue': daysOverdue,
        'p_amount_overdue': amountOverdue,
      });
    } catch (e) {
      debugPrint('Error escalating enforcement: $e');
      rethrow;
    }
  }

  /// File police complaint
  static Future<String> filePoliceComplaint({
    required String userId,
    required String poolId,
    required double amountOwed,
    required String caseDetails,
  }) async {
    try {
      final result = await _client.rpc('file_police_complaint', params: {
        'p_user_id': userId,
        'p_pool_id': poolId,
        'p_amount_owed': amountOwed,
        'p_case_details': caseDetails,
      });

      return result as String;
    } catch (e) {
      debugPrint('Error filing police complaint: $e');
      rethrow;
    }
  }

  /// Send to collection agency
  static Future<String> sendToCollection({
    required String userId,
    required String poolId,
    required double amountOwed,
    required String agencyName,
    required String agencyContact,
  }) async {
    try {
      final result = await _client.rpc('send_to_collection', params: {
        'p_user_id': userId,
        'p_pool_id': poolId,
        'p_amount_owed': amountOwed,
        'p_agency_name': agencyName,
        'p_agency_contact': agencyContact,
      });

      return result as String;
    } catch (e) {
      debugPrint('Error sending to collection: $e');
      rethrow;
    }
  }

  /// Get legal actions for user
  static Future<List<Map<String, dynamic>>> getLegalActions({
    String? actionType,
    String? status,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      var query = _client
          .from('legal_actions')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (actionType != null) {
        query = query.eq('action_type', actionType);
      }
      if (status != null) {
        query = query.eq('action_status', status);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching legal actions: $e');
      return [];
    }
  }

  /// Get enforcement escalations
  static Future<List<Map<String, dynamic>>> getEnforcementEscalations({
    String? poolId,
    bool? resolved,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      var query = _client
          .from('enforcement_escalations')
          .select('*')
          .eq('user_id', user.id)
          .order('triggered_at', ascending: false);

      if (poolId != null) {
        query = query.eq('pool_id', poolId);
      }
      if (resolved != null) {
        query = query.eq('is_resolved', resolved);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching escalations: $e');
      return [];
    }
  }

  /// Auto-escalate overdue payments (admin function)
  static Future<void> autoEscalateOverduePayments() async {
    try {
      await _client.rpc('auto_escalate_overdue_payments');
    } catch (e) {
      debugPrint('Error auto-escalating: $e');
      rethrow;
    }
  }

  /// Get escalation level description
  static Map<String, dynamic> getEscalationInfo(int level) {
    switch (level) {
      case 1:
        return {
          'level': 1,
          'name': 'Warning',
          'color': 0xFFF59E0B,
          'icon': '⚠️',
          'description': 'Payment reminder sent',
          'severity': 'Low',
        };
      case 2:
        return {
          'level': 2,
          'name': 'Legal Notice',
          'color': 0xFFEF4444,
          'icon': '📄',
          'description': 'Legal notice issued',
          'severity': 'Medium',
        };
      case 3:
        return {
          'level': 3,
          'name': 'Final Notice',
          'color': 0xFFDC2626,
          'icon': '⚡',
          'description': 'Final warning before legal action',
          'severity': 'High',
        };
      case 4:
        return {
          'level': 4,
          'name': 'Police Complaint',
          'color': 0xFF991B1B,
          'icon': '🚨',
          'description': 'Police complaint filed for fraud',
          'severity': 'Critical',
        };
      case 5:
        return {
          'level': 5,
          'name': 'Collection Agency',
          'color': 0xFF7F1D1D,
          'icon': '⛔',
          'description': 'Account sent to collection',
          'severity': 'Critical',
        };
      default:
        return {
          'level': 0,
          'name': 'None',
          'color': 0xFF6B7280,
          'icon': '✓',
          'description': 'No enforcement action',
          'severity': 'None',
        };
    }
  }

  /// Generate agreement text for pool
  static String generatePoolAgreementText({
    required String poolName,
    required double contributionAmount,
    required int totalRounds,
    required String paymentSchedule,
  }) {
    return '''
DIGITAL AGREEMENT FOR POOL PARTICIPATION

This agreement is made on ${DateTime.now().toString().split(' ')[0]} between:

1. The Pool Administrator of "$poolName"
2. The Pool Member (You)

TERMS AND CONDITIONS:

1. PAYMENT COMMITMENT
   - You agree to pay ₹$contributionAmount per $paymentSchedule
   - Total commitment: $totalRounds payments
   - Payments must be made on time as per the pool schedule

2. LEGAL OBLIGATIONS
   - This is a legally binding agreement
   - Late payments will incur penalties
   - Failure to pay may result in:
     * Legal notices
     * Police complaints for fraud
     * Collection agency action
     * Court proceedings

3. DEFAULT CONSEQUENCES
   - Your reputation score will drop to 0
   - You will be marked as a defaulter
   - You will be banned from the platform
   - Legal action will be taken to recover funds
   - Your information will be shared with authorities

4. CONSENT
   - You consent to automated payment reminders
   - You consent to legal action if you default
   - You consent to sharing your information with collection agencies if needed
   - You understand this is a legally enforceable contract

5. DISPUTE RESOLUTION
   - Any disputes will be resolved through arbitration
   - Jurisdiction: As per platform terms

By signing this agreement digitally, you acknowledge that you have read, understood, and agree to all terms and conditions.

DIGITAL SIGNATURE
Signed by: [Your Name]
Date: ${DateTime.now().toString()}
IP Address: [Recorded]
Device: [Recorded]
''';
  }
}
