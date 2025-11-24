import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_service.dart';
import 'security_service.dart';

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

  /// Deposit funds with security checks
  static Future<void> deposit({
    required double amount,
    String method = 'bank_transfer',
    String? reference,
  }) async {
    if (_userId == null) throw Exception('User not logged in');

    // Security checks
    await SecurityService.validateSession();
    
    // Rate limiting
    final rateLimitOk = await SecurityService.checkRateLimit('deposit');
    if (!rateLimitOk) {
      throw Exception('Rate limit exceeded. Please try again in a minute.');
    }
    
    // Check transaction limits
    final withinLimit = await SecurityService.checkTransactionLimit(amount, 'deposit');
    if (!withinLimit) {
      throw Exception('Daily deposit limit exceeded. Maximum ₹50,000 per day.');
    }

    // Check velocity
    final velocityOk = await SecurityService.checkVelocity();
    if (!velocityOk) {
      throw Exception('Too many transactions. Please wait a few minutes.');
    }

    // Track location
    await SecurityService.trackLocation('deposit', metadata: {'amount': amount, 'method': method});

    try {
      // Insert transaction
      await _client.from('transactions').insert({
        'user_id': _userId,
        'transaction_type': 'deposit',
        'amount': amount,
        'currency': 'INR',
        'status': 'completed',
        'payment_method': method,
        'payment_reference': reference ?? 'DEP-${DateTime.now().millisecondsSinceEpoch}',
        'description': 'Deposit via $method',
      });

      // Update wallet balance manually
      await _client.rpc('increment_wallet_balance', params: {
        'p_user_id': _userId,
        'p_amount': amount,
      });
      
      // Log security event
      await SecurityService.logSecurityEvent('deposit', {
        'amount': amount,
        'method': method,
        'device_info': await SecurityService.getDeviceFingerprint(),
      });
    } catch (e) {
      print('Error depositing funds: $e');
      // Fallback: Try direct update if RPC fails
      try {
        final wallet = await getWallet();
        final currentBalance = (wallet['available_balance'] as num).toDouble();
        await _client.from('wallets').update({
          'available_balance': currentBalance + amount,
        }).eq('user_id', _userId!);
      } catch (e2) {
        print('Fallback balance update failed: $e2');
        rethrow;
      }
    }
  }

  /// Withdraw funds with enhanced security
  static Future<void> withdraw({
    required double amount,
    String method = 'bank_transfer',
    required String bankDetails,
    String? pin,
    String? otp,
  }) async {
    if (_userId == null) throw Exception('User not logged in');

    // Security checks
    await SecurityService.validateSession();
    
    // Rate limiting
    final rateLimitOk = await SecurityService.checkRateLimit('withdrawal');
    if (!rateLimitOk) {
      throw Exception('Rate limit exceeded. Please try again in a minute.');
    }
    
    // Verify PIN if provided
    if (pin != null) {
      final pinValid = await SecurityService.verifyTransactionPin(pin);
      if (!pinValid) {
        await SecurityService.incrementFailedPinAttempts();
        throw Exception('Invalid transaction PIN');
      }
      await SecurityService.resetFailedPinAttempts();
    }

    // Verify OTP for withdrawals
    if (otp != null) {
      final otpValid = await SecurityService.verifyWithdrawalOTP(otp);
      if (!otpValid) {
        throw Exception('Invalid or expired OTP');
      }
    }

    // Check transaction limits
    final withinLimit = await SecurityService.checkTransactionLimit(amount, 'withdrawal');
    if (!withinLimit) {
      throw Exception('Daily withdrawal limit exceeded. Maximum ₹50,000 per day.');
    }

    // Check velocity
    final velocityOk = await SecurityService.checkVelocity();
    if (!velocityOk) {
      throw Exception('Too many transactions. Please wait a few minutes.');
    }

    // Check for suspicious location
    final suspiciousLocation = await SecurityService.checkSuspiciousLocation();
    if (suspiciousLocation) {
      throw Exception('Suspicious activity detected. Please contact support.');
    }

    // Track location
    await SecurityService.trackLocation('withdrawal', metadata: {'amount': amount, 'method': method});

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

      // Deduct from available balance immediately to prevent double spend
      await _client.rpc('decrement_wallet_balance', params: {
        'p_user_id': _userId,
        'p_amount': amount,
      });
      
      // Log security event
      await SecurityService.logSecurityEvent('withdrawal', {
        'amount': amount,
        'method': method,
        'device_info': await SecurityService.getDeviceFingerprint(),
      });
    } catch (e) {
      print('Error withdrawing funds: $e');
      // Fallback
      try {
        await _client.from('wallets').update({
          'available_balance': available - amount,
        }).eq('user_id', _userId!);
      } catch (e2) {
        rethrow;
      }
    }
  }

  /// Contribute to a pool with security checks
  static Future<void> contributeToPool({
    required String poolId,
    required double amount,
    required int round,
    String? pin,
  }) async {
    if (_userId == null) throw Exception('User not logged in');

    // Security checks
    await SecurityService.validateSession();
    
    // Verify PIN if provided
    if (pin != null) {
      final pinValid = await SecurityService.verifyTransactionPin(pin);
      if (!pinValid) {
        await SecurityService.incrementFailedPinAttempts();
        throw Exception('Invalid transaction PIN');
      }
      await SecurityService.resetFailedPinAttempts();
    }

    // Check transaction limits
    final withinLimit = await SecurityService.checkTransactionLimit(amount, 'contribution');
    if (!withinLimit) {
      throw Exception('Daily contribution limit exceeded. Maximum ₹1,00,000 per day.');
    }

    // Check velocity
    final velocityOk = await SecurityService.checkVelocity();
    if (!velocityOk) {
      throw Exception('Too many transactions. Please wait a few minutes.');
    }

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

      // Update wallet: Deduct from available, Add to locked
      final currentLocked = (wallet['locked_balance'] as num).toDouble();
      
      await _client.from('wallets').update({
        'available_balance': available - amount,
        'locked_balance': currentLocked + amount,
      }).eq('user_id', _userId!);

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
        print('Failed to send chat notification: $e');
      }
      
      // Log security event
      await SecurityService.logSecurityEvent('contribution', {
        'amount': amount,
        'pool_id': poolId,
        'round': round,
        'device_info': await SecurityService.getDeviceFingerprint(),
      });
    } catch (e) {
      print('Error contributing to pool: $e');
      rethrow;
    }
  }

  /// Credit winnings with automatic TDS deduction
  static Future<Map<String, dynamic>> creditWinnings({
    required String poolId,
    required double amount,
    required int round,
  }) async {
    if (_userId == null) throw Exception('User not logged in');

    try {
      // Create winning transaction
      final transactionResult = await _client.from('transactions').insert({
        'user_id': _userId,
        'pool_id': poolId,
        'transaction_type': 'winning',
        'amount': amount,
        'currency': 'INR',
        'status': 'completed',
        'payment_method': 'wallet',
        'description': 'Pool winning for Round $round',
        'metadata': {'round': round},
      }).select().single();

      final transactionId = transactionResult['id'];

      // Calculate and deduct TDS if applicable
      final tdsResult = await SecurityService.calculateTDS(
        winningAmount: amount,
        transactionId: transactionId,
      );

      final netAmount = tdsResult['net_amount'] as double;
      final tdsAmount = tdsResult['tds_amount'] as double;

      // Credit net amount to wallet
      final wallet = await getWallet();
      final currentBalance = (wallet['available_balance'] as num).toDouble();
      final currentWinnings = (wallet['total_winnings'] as num).toDouble();

      await _client.from('wallets').update({
        'available_balance': currentBalance + netAmount,
        'total_winnings': currentWinnings + amount, // Track gross winnings
      }).eq('user_id', _userId!);

      // Log security event
      await SecurityService.logSecurityEvent('winning_credited', {
        'pool_id': poolId,
        'gross_amount': amount,
        'tds_amount': tdsAmount,
        'net_amount': netAmount,
        'round': round,
      });

      return {
        'success': true,
        'gross_amount': amount,
        'tds_amount': tdsAmount,
        'net_amount': netAmount,
        'tds_applicable': tdsResult['tds_applicable'],
        'financial_year': tdsResult['financial_year'],
        'quarter': tdsResult['quarter'],
      };
    } catch (e) {
      print('Error crediting winnings: $e');
      rethrow;
    }
  }
}
