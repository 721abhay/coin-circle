import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AdminService {
  static final SupabaseClient _client = SupabaseConfig.client;

  /// Check if current user is admin
  static Future<bool> isAdmin() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final response = await _client
          .from('profiles')
          .select('is_admin')
          .eq('id', user.id)
          .single();

      return response['is_admin'] == true;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Get all users (admin only)
  static Future<List<Map<String, dynamic>>> getAllUsers({int? limit, int? offset, String? search}) async {
    try {
      dynamic query = _client.from('profiles').select('*');
      
      if (search != null && search.isNotEmpty) {
        query = query.or('full_name.ilike.%$search%,email.ilike.%$search%');
      }
      
      query = query.order('created_at', ascending: false);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }
      
      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      return [];
    }
  }

  /// Get user details (admin only)
  static Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final response = await _client.rpc('get_user_details_admin', params: {
        'p_user_id': userId,
      });
      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error fetching user details: $e');
      return null;
    }
  }

  /// Suspend user (admin only)
  static Future<void> suspendUser(String userId, String reason) async {
    try {
      await _client.rpc('suspend_user_admin', params: {
        'p_user_id': userId,
        'p_reason': reason,
      });
    } catch (e) {
      debugPrint('Error suspending user: $e');
      rethrow;
    }
  }

  /// Unsuspend user (admin only)
  static Future<void> unsuspendUser(String userId) async {
    try {
      await _client.rpc('unsuspend_user_admin', params: {
        'p_user_id': userId,
      });
    } catch (e) {
      debugPrint('Error unsuspending user: $e');
      rethrow;
    }
  }

  /// Get all pools (admin only)
  static Future<List<Map<String, dynamic>>> getAllPools({int? limit, int? offset, String? status}) async {
    try {
      dynamic query = _client
          .from('pools')
          .select('*, creator:profiles!creator_id(full_name, email)');
      
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }
      
      query = query.order('created_at', ascending: false);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }
      
      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching all pools: $e');
      return [];
    }
  }

  /// Get all withdrawal requests (admin only)
  static Future<List<Map<String, dynamic>>> getAllWithdrawalRequests() async {
    try {
      final response = await _client
          .from('withdrawal_requests')
          .select('''
            *,
            user:profiles(full_name, email),
            bank_account:bank_accounts(bank_name, account_number)
          ''')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching withdrawal requests: $e');
      return [];
    }
  }

  /// Approve withdrawal (admin only)
  static Future<void> approveWithdrawal(String withdrawalId, {String? notes}) async {
    try {
      await _client.rpc('process_withdrawal', params: {
        'p_withdrawal_id': withdrawalId,
        'p_status': 'completed',
        'p_rejection_reason': notes ?? '',
      });
    } catch (e) {
      debugPrint('Error approving withdrawal: $e');
      rethrow;
    }
  }

  /// Reject withdrawal (admin only)
  static Future<void> rejectWithdrawal(String withdrawalId, String reason) async {
    try {
      await _client.rpc('process_withdrawal', params: {
        'p_withdrawal_id': withdrawalId,
        'p_status': 'rejected',
        'p_rejection_reason': reason,
      });
    } catch (e) {
      debugPrint('Error rejecting withdrawal: $e');
      rethrow;
    }
  }

  /// Get all disputes (admin only)
  static Future<List<Map<String, dynamic>>> getAllDisputes() async {
    try {
      final response = await _client
          .from('disputes')
          .select('''
            *,
            pool:pools(name),
            creator:profiles!creator_id(full_name, email),
            reported_user:profiles!reported_user_id(full_name, email)
          ''')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching disputes: $e');
      return [];
    }
  }

  /// Force close a pool (admin only)
  static Future<void> forceClosePool({required String poolId, required String reason}) async {
    try {
      await _client.rpc('force_close_pool_admin', params: {
        'p_pool_id': poolId,
        'p_reason': reason,
      });
    } catch (e) {
      debugPrint('Error force closing pool: $e');
      rethrow;
    }
  }

  /// Get platform statistics (admin only)
  static Future<Map<String, dynamic>> getPlatformStats() async {
    try {
      // Get user count
      final userCount = await _client
          .from('profiles')
          .select()
          .count(CountOption.exact);

      // Get pool count
      final poolCount = await _client
          .from('pools')
          .select()
          .count(CountOption.exact);

      // Get active pool count
      final activePoolCount = await _client
          .from('pools')
          .select()
          .eq('status', 'active')
          .count(CountOption.exact);

      // Get total transaction volume
      final transactions = await _client
          .from('transactions')
          .select('amount')
          .eq('status', 'completed');

      double totalVolume = 0;
      for (var txn in transactions) {
        totalVolume += (txn['amount'] as num).toDouble();
      }

      return {
        'total_users': userCount.count ?? 0,
        'total_pools': poolCount.count ?? 0,
        'active_pools': activePoolCount.count ?? 0,
        'total_volume': totalVolume,
      };
    } catch (e) {
      debugPrint('Error fetching platform stats: $e');
      return {
        'total_users': 0,
        'total_pools': 0,
        'active_pools': 0,
        'total_volume': 0.0,
      };
    }
  }

  /// Get admin dashboard statistics
  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await _client.rpc('get_admin_stats');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error fetching admin stats: $e');
      return {};
    }
  }

  /// Get revenue chart data
  static Future<List<Map<String, dynamic>>> getRevenueChartData() async {
    try {
      final response = await _client.rpc('get_revenue_chart_data');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching revenue data: $e');
      return [];
    }
  }

  /// Get all deposit requests (admin only)
  static Future<List<Map<String, dynamic>>> getDepositRequests() async {
    try {
      final response = await _client
          .from('deposit_requests')
          .select('*, user:profiles(full_name, email)')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching deposit requests: $e');
      return [];
    }
  }

  /// Approve deposit request (admin only)
  static Future<void> approveDeposit(String requestId, String userId, double amount) async {
    try {
      // Use atomic RPC
      await _client.rpc('approve_deposit_request', params: {
        'p_request_id': requestId,
      });

    } catch (e) {
      debugPrint('Error approving deposit: $e');
      rethrow;
    }
  }

  /// Reject deposit request (admin only)
  static Future<void> rejectDeposit(String requestId, String reason) async {
    try {
      await _client
          .from('deposit_requests')
          .update({
            'status': 'rejected',
            'admin_notes': reason,
          })
          .eq('id', requestId);
    } catch (e) {
      debugPrint('Error rejecting deposit: $e');
      rethrow;
    }
  }

  /// Get recent system activities (admin only)
  static Future<List<Map<String, dynamic>>> getRecentActivities({int limit = 10}) async {
    try {
      // Fetch recent transactions, user registrations, pool creations
      final activities = <Map<String, dynamic>>[];
      
      // Recent transactions
      final transactions = await _client
          .from('transactions')
          .select('*, user:profiles(full_name)')
          .order('created_at', ascending: false)
          .limit(limit);
      
      for (var txn in transactions) {
        activities.add({
          'type': txn['transaction_type'] ?? 'transaction',
          'title': _getActivityTitle(txn['transaction_type']),
          'description': '₹${txn['amount']} by ${txn['user']?['full_name'] ?? 'Unknown'}',
          'time': _formatTimeAgo(txn['created_at']),
          'color': _getActivityColor(txn['transaction_type']),
        });
      }
      
      // Sort by time and limit
      activities.sort((a, b) => (b['time'] as String).compareTo(a['time'] as String));
      return activities.take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching activities: $e');
      return [];
    }
  }

  static String _getActivityTitle(String? type) {
    switch (type) {
      case 'contribution':
        return 'Pool Contribution';
      case 'payout':
        return 'Payout Processed';
      case 'deposit':
        return 'Wallet Deposit';
      case 'withdrawal':
        return 'Withdrawal Request';
      default:
        return 'Transaction';
    }
  }

  static Color _getActivityColor(String? type) {
    switch (type) {
      case 'contribution':
        return Colors.blue;
      case 'payout':
        return Colors.green;
      case 'deposit':
        return Colors.purple;
      case 'withdrawal':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  static String _formatTimeAgo(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return 'Unknown';
    }
  }
}
