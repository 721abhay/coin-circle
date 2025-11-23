import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_service.dart';

class WalletService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Get the current user's ID
  static String? get _userId => _client.auth.currentUser?.id;

  /// Get the current user's wallet (creates if doesn't exist)
  static Future<Map<String, dynamic>> getWallet() async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Try to get existing wallet
      final response = await _client
          .from('wallets')
          .select()
          .eq('user_id', _userId!)
          .maybeSingle();

      if (response != null) {
        return response;
      }

      // Create new wallet if doesn't exist
      print('Wallet not found, creating new wallet for user $_userId');
      final newWallet = await _client
          .from('wallets')
          .insert({
            'user_id': _userId!,
            'available_balance': 0.0,
            'locked_balance': 0.0,
            'total_winnings': 0.0,
          })
          .select()
          .single();

      return newWallet;
    } catch (e) {
      print('Error fetching/creating wallet: $e');
      rethrow;
    }
  }

  /// Get transaction history
  static Future<List<Map<String, dynamic>>> getTransactions({
    int limit = 20,
    int offset = 0,
    String? type, // 'deposit', 'withdrawal', 'contribution', 'winning'
  }) async {
    if (_userId == null) return [];

    try {
      var query = _client
          .from('transactions')
          .select()
          .eq('user_id', _userId!);

      if (type != null) {
        query = query.eq('transaction_type', type);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching transactions: $e');
      rethrow;
    }
  }

  /// Deposit funds (Simulated for now - creates a completed deposit transaction)
  static Future<void> deposit({
    required double amount,
    String method = 'bank_transfer',
    String? reference,
  }) async {
    if (_userId == null) throw Exception('User not logged in');

    try {
      await _client.from('transactions').insert({
        'user_id': _userId,
        'transaction_type': 'deposit',
        'amount': amount,
        'currency': 'INR',
        'status': 'completed', // Auto-complete for simulation
        'payment_method': method,
        'payment_reference': reference ?? 'DEP-${DateTime.now().millisecondsSinceEpoch}',
        'description': 'Deposit via $method',
      });
    } catch (e) {
      print('Error depositing funds: $e');
      rethrow;
    }
  }

  /// Withdraw funds
  static Future<void> withdraw({
    required double amount,
    String method = 'bank_transfer',
    required String bankDetails,
  }) async {
    if (_userId == null) throw Exception('User not logged in');

    // First check balance
    final wallet = await getWallet();
    if (wallet == null) throw Exception('Wallet not found');
    
    final double available = (wallet['available_balance'] as num).toDouble();
    if (available < amount) {
      throw Exception('Insufficient funds');
    }

    try {
      await _client.from('transactions').insert({
        'user_id': _userId,
        'transaction_type': 'withdrawal',
        'amount': amount,
        'currency': 'INR',
        'status': 'pending', // Withdrawals need approval
        'payment_method': method,
        'metadata': {'bank_details': bankDetails},
        'description': 'Withdrawal request to $method',
      });
    } catch (e) {
      print('Error withdrawing funds: $e');
      rethrow;
    }
  }

  /// Contribute to a pool
  static Future<void> contributeToPool({
    required String poolId,
    required double amount,
    required int round,
  }) async {
    if (_userId == null) throw Exception('User not logged in');

    // First check balance
    final wallet = await getWallet();
    if (wallet == null) throw Exception('Wallet not found');
    
    final double available = (wallet['available_balance'] as num).toDouble();
    if (available < amount) {
      throw Exception('Insufficient funds');
    }

    try {
      await _client.from('transactions').insert({
        'user_id': _userId,
        'pool_id': poolId,
        'transaction_type': 'contribution',
        'amount': amount,
        'currency': 'INR',
        'status': 'completed',
        'payment_method': 'wallet',
        'description': 'Contribution for Round $round',
        'metadata': {'round': round},
      });

      // Send chat notification
      try {
        final user = _client.auth.currentUser;
        final userName = user?.userMetadata?['full_name'] ?? 'A member';
        
        await ChatService.sendPaymentConfirmation(
          poolId: poolId,
          userName: userName,
          amount: amount,
        );
      } catch (e) {
        // Don't fail the transaction if chat notification fails
        print('Failed to send chat notification: $e');
      }
    } catch (e) {
      print('Error contributing to pool: $e');
      rethrow;
    }
  }
}
