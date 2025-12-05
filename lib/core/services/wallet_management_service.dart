import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class WalletManagementService {
  static final SupabaseClient _client = SupabaseConfig.client;

  /// Add a new bank account
  static Future<String> addBankAccount({
    required String accountHolderName,
    required String accountNumber,
    required String bankName,
    required String ifscCode,
    required String accountType,
    bool isPrimary = false,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    final response = await _client.from('bank_accounts').insert({
      'user_id': user.id,
      'account_holder_name': accountHolderName,
      'account_number': accountNumber,
      'bank_name': bankName,
      'ifsc_code': ifscCode,
      'account_type': accountType,
      'is_primary': isPrimary,
      'is_verified': false,
    }).select().single();

    return response['id'];
  }

  /// Get user's bank accounts
  static Future<List<Map<String, dynamic>>> getBankAccounts() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    final response = await _client
        .from('bank_accounts')
        .select()
        .eq('user_id', user.id)
        .order('is_primary', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Set primary bank account
  static Future<void> setPrimaryBankAccount(String accountId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    await _client
        .from('bank_accounts')
        .update({'is_primary': true})
        .eq('id', accountId)
        .eq('user_id', user.id);
  }

  /// Delete bank account

  /// Process a withdrawal (admin only)
  ///
  /// `action` should be either 'approve' or 'reject'.
  /// For 'reject', a non‑empty `notes` reason is required.
  static Future<void> processWithdrawal({
    required String withdrawalId,
    required String action,
    String? notes,
  }) async {
    final validActions = {'approve', 'reject'};
    if (!validActions.contains(action.toLowerCase())) {
      throw ArgumentError('Invalid action: $action. Use "approve" or "reject".');
    }
    final status = action.toLowerCase() == 'approve' ? 'completed' : 'rejected';
    if (status == 'rejected' && (notes == null || notes.trim().isEmpty)) {
      throw ArgumentError('Rejection reason must be provided when rejecting a withdrawal.');
    }
    await _client.rpc('process_withdrawal', params: {
      'p_withdrawal_id': withdrawalId,
      'p_status': status,
      'p_rejection_reason': notes ?? '',
    });
  }

  /// Approve withdrawal (admin only) - convenience wrapper
  static Future<void> approveWithdrawal(String withdrawalId, String? notes) async {
    await processWithdrawal(
      withdrawalId: withdrawalId,
      action: 'approve',
      notes: notes,
    );
  }

  /// Reject withdrawal (admin only) - convenience wrapper
  static Future<void> rejectWithdrawal(String withdrawalId, String notes) async {
    await processWithdrawal(
      withdrawalId: withdrawalId,
      action: 'reject',
      notes: notes,
    );
  }


  /// Delete bank account
  static Future<void> deleteBankAccount(String accountId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    await _client
        .from('bank_accounts')
        .delete()
        .eq('id', accountId)
        .eq('user_id', user.id);
  }

  /// Request withdrawal
  static Future<String> requestWithdrawal({
    required double amount,
    required String bankAccountId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    // Calculate processing fee (e.g., 1% or minimum ₹10)
    final processingFee = (amount * 0.01).clamp(10.0, double.infinity);

    final response = await _client.from('withdrawal_requests').insert({
      'user_id': user.id,
      'amount': amount,
      'bank_account_id': bankAccountId,
      'processing_fee': processingFee,
      'status': 'pending',
    }).select().single();

    return response['id'];
  }

  /// Get withdrawal history
  static Future<List<Map<String, dynamic>>> getWithdrawalHistory() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    final response = await _client
        .from('withdrawal_requests')
        .select('*, bank_account:bank_accounts(bank_name, account_number)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get available balance (total balance - locked in pools)
  static Future<Map<String, double>> getBalanceBreakdown() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    // Get total wallet balance
    final walletResponse = await _client
        .from('wallets')
        .select('balance')
        .eq('user_id', user.id)
        .maybeSingle();

    final totalBalance = (walletResponse?['balance'] as num?)?.toDouble() ?? 0.0;

    // Get locked balance (sum of contributions in active pools)
    final poolsResponse = await _client
        .from('pool_members')
        .select('pool:pools(contribution_amount, status)')
        .eq('user_id', user.id);

    double lockedBalance = 0;
    for (var member in poolsResponse) {
      final pool = member['pool'];
      if (pool != null && pool['status'] == 'active') {
        lockedBalance += (pool['contribution_amount'] as num).toDouble();
      }
    }

    return {
      'total': totalBalance,
      'locked': lockedBalance,
      'available': totalBalance - lockedBalance,
    };
  }

  /// Initiate deposit (placeholder for payment gateway integration)
  /// Initiate deposit (Simulated for now, but records to DB)
  static Future<Map<String, dynamic>> initiateDeposit(double amount) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    // 1. Create a transaction record in Supabase
    final response = await _client.from('transactions').insert({
      'user_id': user.id,
      'amount': amount,
      'type': 'deposit',
      'description': 'Wallet Deposit',
      'status': 'completed', // Auto-complete for demo purposes
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    // 2. Update wallet balance
    // Note: In a real app, this would happen via webhook after payment success.
    // For recovery/demo, we update immediately.
    await _client.rpc('increment_wallet_balance', params: {
      'p_user_id': user.id,
      'p_amount': amount,
    });

    return {
      'order_id': response['id'],
      'amount': amount,
      'currency': 'INR',
      'status': 'completed',
      'message': 'Deposit successful',
    };
  }

  /// Get all withdrawal requests (Admin only)
  static Future<List<Map<String, dynamic>>> getAllWithdrawalRequests() async {
    final response = await _client
        .from('withdrawal_requests')
        .select('''
          *,
          user:profiles(full_name, email),
          bank_account:bank_accounts(bank_name, account_number)
        ''')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get transactions with optional filter
  static Future<List<Map<String, dynamic>>> getTransactions({String? filter}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    var query = _client
        .from('transactions')
        .select('*, pool:pools(name)')
        .eq('user_id', user.id);

    if (filter != null && filter != 'All') {
      if (filter == 'Credits') {
        query = query.eq('type', 'deposit'); // Assuming 'deposit' is the type for credits
      } else if (filter == 'Debits') {
        query = query.neq('type', 'deposit'); // Everything else is a debit
      } else if (filter == 'Late Fees') {
        query = query.gt('late_fee', 0);
      }
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
