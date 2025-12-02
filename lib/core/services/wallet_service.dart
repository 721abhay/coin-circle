import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_service.dart';
import 'security_service.dart';
import 'platform_revenue_service.dart';

class WalletService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Get the current user's ID
  static String? get _userId => _client.auth.currentUser?.id;

  // Cache for wallet data to prevent rate limiting
  static Map<String, dynamic>? _cachedWallet;
  static DateTime? _lastWalletFetchTime;
  static const Duration _walletCacheDuration = Duration(seconds: 2);

  /// Get the current user's wallet (creates if doesn't exist)
  static Future<Map<String, dynamic>> getWallet({bool forceRefresh = false}) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    // Return cached wallet if valid and not forced refresh
    if (!forceRefresh && 
        _cachedWallet != null && 
        _lastWalletFetchTime != null && 
        DateTime.now().difference(_lastWalletFetchTime!) < _walletCacheDuration) {
      return _cachedWallet!;
    }

    try {
      // Try to get existing wallet
      final response = await _client
          .from('wallets')
          .select()
          .eq('user_id', _userId!)
          .maybeSingle();

      if (response != null) {
        _cachedWallet = response;
        _lastWalletFetchTime = DateTime.now();
        return response;
      }

      // Create new wallet if doesn't exist
      debugPrint('Wallet not found, creating new wallet for user $_userId');
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

      _cachedWallet = newWallet;
      _lastWalletFetchTime = DateTime.now();
      return newWallet;
    } catch (e) {
      debugPrint('Error fetching/creating wallet: $e');
      // If error (e.g. rate limit), return cache if available even if expired
      if (_cachedWallet != null) return _cachedWallet!;
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
      debugPrint('Error fetching transactions: $e');
      rethrow;
    }
  }

  // Simple client-side rate limiter
  static DateTime? _lastDepositRequestTime;

  /// Request a manual deposit (User sends money, Admin approves)
  static Future<void> requestDeposit({
    required double amount,
    required String transactionReference,
    String? proofUrl,
  }) async {
    if (_userId == null) throw Exception('User not logged in');

    // 🛑 KYC CHECK: Must be verified to add money
    final isVerified = await SecurityService.checkKYCStatus();
    if (!isVerified) {
      throw Exception('KYC Verification Required. Please complete your profile verification (Government ID) to add money.');
    }

    // Client-side rate limit (prevent button spamming)
    if (_lastDepositRequestTime != null && 
        DateTime.now().difference(_lastDepositRequestTime!) < const Duration(seconds: 30)) {
      throw Exception('Please wait 30 seconds before submitting another request.');
    }

    try {
      // Server-side rate limit check (if available in SecurityService)
      try {
        final rateLimitOk = await SecurityService.checkRateLimit('deposit_request');
        if (!rateLimitOk) {
          throw Exception('Rate limit exceeded. Please try again later.');
        }
      } catch (e) {
        // Ignore if SecurityService fails, fallback to client-side check
        debugPrint('SecurityService rate limit check failed: $e');
      }

      await _client.from('deposit_requests').insert({
        'user_id': _userId,
        'amount': amount,
        'transaction_reference': transactionReference,
        'proof_url': proofUrl,
        'status': 'pending',
      });
      
      _lastDepositRequestTime = DateTime.now();
      
      // Log for audit
      debugPrint('Deposit request submitted: $amount, Ref: $transactionReference');
    } catch (e) {
      debugPrint('Error requesting deposit: $e');
      rethrow;
    }
  }

  /// Deposit funds (Internal/Admin use or after Gateway success)
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
      debugPrint('Error depositing funds: $e');
      // Fallback: Try direct update if RPC fails
      try {
        final wallet = await getWallet();
        final currentBalance = (wallet['available_balance'] as num).toDouble();
        await _client.from('wallets').update({
          'available_balance': currentBalance + amount,
        }).eq('user_id', _userId!);
      } catch (e2) {
        debugPrint('Fallback balance update failed: $e2');
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

    // 🛑 KYC CHECK: Must be verified to withdraw
    final isVerified = await SecurityService.checkKYCStatus();
    if (!isVerified) {
      throw Exception('KYC Verification Required. Please complete your profile verification (Government ID) to withdraw funds.');
    }
    
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
    
    final double available = (wallet['available_balance'] as num).toDouble();
    final double winningBalance = (wallet['winning_balance'] as num?)?.toDouble() ?? 0.0;
    
    // Check if user has enough winning balance (only winnings are withdrawable)
    if (winningBalance < amount) {
      throw Exception('Insufficient withdrawable winnings. You can only withdraw your winnings (₹${winningBalance.toStringAsFixed(2)}).');
    }
    
    // Also check total available just in case (though winning <= available usually)
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
      
      // Manually decrement winning balance since RPC might not handle it yet
      // Or we should update the RPC. For now, let's do a direct update for winning_balance
      // Note: decrement_wallet_balance only updates available_balance. We need to update winning_balance too.
      
      await _client.from('wallets').update({
        'winning_balance': winningBalance - amount,
      }).eq('user_id', _userId!);
      
      // Log security event
      await SecurityService.logSecurityEvent('withdrawal', {
        'amount': amount,
        'method': method,
        'device_info': await SecurityService.getDeviceFingerprint(),
      });
    } catch (e) {
      debugPrint('Error withdrawing funds: $e');
      // Fallback
      try {
        // We might need to revert both if one fails, but for now let's assume RPC works or fails atomically-ish
        // If RPC succeeded but winning_balance update failed, we are in a weird state.
        // Ideally we should use a stored procedure for both.
        // For now, let's just rethrow.
        rethrow;
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
    
    final double available = (wallet['available_balance'] as num).toDouble();
    final double winningBalance = (wallet['winning_balance'] as num?)?.toDouble() ?? 0.0;
    
    // Get pool details to calculate late fee
    final pool = await _client.from('pools').select().eq('id', poolId).single();
    final gracePeriod = (pool['late_grace_period'] as int?) ?? 3;
    
    // Calculate due date based on pool frequency and start date
    final startDate = DateTime.parse(pool['start_date']);
    final frequency = pool['frequency'] as String;
    DateTime dueDate;
    
    switch (frequency.toLowerCase()) {
      case 'weekly':
        dueDate = startDate.add(Duration(days: 7 * round));
        break;
      case 'bi-weekly':
        dueDate = startDate.add(Duration(days: 14 * round));
        break;
      case 'monthly':
      default:
        dueDate = DateTime(startDate.year, startDate.month + round, startDate.day);
        break;
    }
    
    // Add grace period
    dueDate = dueDate.add(Duration(days: gracePeriod));
    
    // Calculate days late
    final now = DateTime.now();
    final daysLate = now.difference(dueDate).inDays;
    
    // Calculate late fee using PlatformRevenueService
    double lateFee = 0;
    if (daysLate > 0) {
      lateFee = PlatformRevenueService.calculateLateFee(daysLate);
    }
    
    // Check if user has enough balance for contribution + late fee
    final totalRequired = amount + lateFee;
    if (available < totalRequired) {
      if (lateFee > 0) {
        throw Exception('Insufficient funds. Required: ₹${totalRequired.toStringAsFixed(2)} (₹${amount.toStringAsFixed(2)} contribution + ₹${lateFee.toStringAsFixed(2)} late fee)');
      } else {
        throw Exception('Insufficient funds');
      }
    }

    // Calculate how much to deduct from winning balance (spend non-winning funds first)
    final double nonWinningFunds = available - winningBalance;
    double deductionFromWinning = 0.0;
    
    if (totalRequired > nonWinningFunds) {
      deductionFromWinning = totalRequired - nonWinningFunds;
    }

    try {
      // Insert contribution transaction
      await _client.from('transactions').insert({
        'user_id': _userId,
        'pool_id': poolId,
        'transaction_type': 'contribution',
        'amount': amount,
        'currency': 'INR',
        'status': 'completed',
        'payment_method': 'wallet',
        'description': lateFee > 0 
            ? 'Contribution for Round $round (Late: $daysLate days, Fee: ₹${lateFee.toStringAsFixed(2)})'
            : 'Contribution for Round $round',
        'metadata': {
          'round': round,
          'days_late': daysLate,
          'late_fee': lateFee,
        },
      });

      // Update wallet: Deduct contribution + late fee from available, Add contribution to locked
      // Also update winning_balance if we dipped into it
      final currentLocked = (wallet['locked_balance'] as num).toDouble();
      
      await _client.from('wallets').update({
        'available_balance': available - totalRequired,
        'locked_balance': currentLocked + amount, // Only contribution goes to locked, not late fee
        'winning_balance': winningBalance - deductionFromWinning,
      }).eq('user_id', _userId!);

      // Record late fee to platform revenue if applicable
      if (lateFee > 0) {
        await PlatformRevenueService.recordLateFee(
          userId: _userId!,
          poolId: poolId,
          amount: lateFee,
          daysLate: daysLate,
        );
      }

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
        debugPrint('Failed to send chat notification: $e');
      }
      
      // Log security event
      await SecurityService.logSecurityEvent('contribution', {
        'amount': amount,
        'pool_id': poolId,
        'round': round,
        'late_fee': lateFee,
        'days_late': daysLate,
        'device_info': await SecurityService.getDeviceFingerprint(),
      });
    } catch (e) {
      debugPrint('Error contributing to pool: $e');
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
      final currentWinningBalance = (wallet['winning_balance'] as num?)?.toDouble() ?? 0.0;

      await _client.from('wallets').update({
        'available_balance': currentBalance + netAmount,
        'total_winnings': currentWinnings + amount, // Track gross winnings
        'winning_balance': currentWinningBalance + netAmount, // Add to withdrawable balance
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
      debugPrint('Error crediting winnings: $e');
      rethrow;
    }
  }
  /// Get user's payment methods (bank accounts)
  static Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    if (_userId == null) return [];

    try {
      final response = await _client
          .from('bank_accounts')
          .select()
          .eq('user_id', _userId!)
          .order('is_primary', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching payment methods: $e');
      return [];
    }
  }

  /// Deduct amount from wallet (for fees)
  static Future<void> deductFromWallet({
    required double amount,
    String? description,
  }) async {
    if (_userId == null) throw Exception('User not logged in');

    // First check balance
    final wallet = await getWallet();
    
    final double available = (wallet['available_balance'] as num).toDouble();
    if (available < amount) {
      throw Exception('Insufficient funds');
    }

    try {
      // Update wallet: Deduct from available
      await _client.from('wallets').update({
        'available_balance': available - amount,
      }).eq('user_id', _userId!);

      // Log transaction
      await _client.from('transactions').insert({
        'user_id': _userId,
        'transaction_type': 'fee',
        'amount': amount,
        'currency': 'INR',
        'status': 'completed',
        'payment_method': 'wallet',
        'description': description ?? 'Platform Fee Deduction',
      });
    } catch (e) {
      debugPrint('Error deducting from wallet: $e');
      rethrow;
    }
  }
}
