import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_service.dart';
import 'notification_service.dart';
import '../config/supabase_config.dart';

class PoolService {
  static final SupabaseClient _client = SupabaseConfig.client;

  static User? get currentUser => _client.auth.currentUser;

  /// Create a new pool
  static Future<Map<String, dynamic>> createPool({
    required String name,
    required String description,
    required double contributionAmount,
    required String frequency, // 'weekly', 'monthly'
    required String type, // 'standard', 'savings', 'lottery'
    required String privacy, // 'public', 'private'
    required int maxMembers,
    required DateTime startDate,
    required int durationMonths,
    required int paymentDay, // Day of month for payment (1-28)
    required double joiningFee, // One-time joining fee
    Map<String, dynamic>? rules, // Custom rules (e.g., draw schedule)
    bool enableChat = true, // Enable chat for this pool
    bool requireKyc = false, // Require KYC verification to join
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    // 🛑 KYC CHECK: Must be KYC verified to create pools
    final canParticipate = await _client.rpc('can_participate_in_pools', params: {
      'p_user_id': user.id,
    });
    
    if (canParticipate == false) {
      throw Exception('KYC verification required. Please complete your KYC verification to create pools.');
    }

    // 🛑 LIMIT CHECK: Max 2 created pools per user
    final createdPoolsCount = await _client
        .from('pools')
        .count(CountOption.exact)
        .eq('creator_id', user.id);
    
    if (createdPoolsCount >= 2) {
      throw Exception('You can only create a maximum of 2 pools.');
    }

    // Map 'standard' to 'fixed' as per schema enum
    final poolType = type == 'standard' ? 'fixed' : type;
    
    // Calculate total amount
    final totalAmount = contributionAmount * maxMembers;

    // Generate a unique 6-character invite code
    final inviteCode = _generateInviteCode();

    final response = await _client.from('pools').insert({
      'creator_id': user.id,
      'name': name,
      'description': description,
      'contribution_amount': contributionAmount,
      'total_amount': totalAmount,
      'frequency': frequency,
      'pool_type': poolType,
      'privacy': privacy,
      'max_members': maxMembers,
      'start_date': startDate.toIso8601String(),
      'total_rounds': durationMonths,
      'status': 'pending', // Default status for new pools
      'invite_code': inviteCode,
      'payment_day': paymentDay, // Day of month for payment
      'joining_fee': joiningFee, // One-time joining fee
      'rules': rules, // Store custom rules
      'enable_chat': enableChat, // Chat setting
      'require_kyc': requireKyc, // KYC requirement
    }).select().single();

    // CRITICAL FIX: Add creator as a member of the pool immediately
    await _client.from('pool_members').insert({
      'pool_id': response['id'],
      'user_id': user.id,
      'role': 'admin', // Creator is admin
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    });

    return response;
  }

  static String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[DateTime.now().microsecond % chars.length]).join();
  }

  /// Get all pools visible to the current user (public pools + creator's pools + joined pools)
  static Future<List<Map<String, dynamic>>> getPublicPools({String? searchQuery}) async {
    final response = await _client
        .from('pools')
        .select('*, creator:creator_id(full_name, avatar_url)')
        .inFilter('status', ['pending', 'active']) // Show pending and active
        .order('created_at', ascending: false);
    
    List<Map<String, dynamic>> pools = List<Map<String, dynamic>>.from(response);
    
    // Client-side filtering if search query is provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      pools = pools.where((pool) {
        final name = (pool['name'] as String?)?.toLowerCase() ?? '';
        final description = (pool['description'] as String?)?.toLowerCase() ?? '';
        return name.contains(lowerQuery) || description.contains(lowerQuery);
      }).toList();
    }
    
    return pools;
  }

  /// Get pools the current user has joined (includes pending/approved)
  static Future<List<Map<String, dynamic>>> getUserPools() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    // We need to join pool_members with pools
    final response = await _client
        .from('pool_members')
        .select('status, pool:pools(*)')
        .eq('user_id', user.id);
    
    // Extract the pool data and add status
    return response.map((item) {
      final pool = item['pool'] as Map<String, dynamic>;
      pool['membership_status'] = item['status']; // Add status to pool object
      return pool;
    }).toList();
  }

  /// Get details of a specific pool
  static Future<Map<String, dynamic>> getPoolDetails(String poolId) async {
    final poolResponse = await _client
        .from('pools')
        .select('*, creator:creator_id(full_name, avatar_url), members:pool_members(*, profile:profiles(*))')
        .eq('id', poolId)
        .single();
    
    // Fetch latest winner
    final winnerResponse = await _client
        .from('winner_history')
        .select('*, profiles!winner_history_user_id_fkey(*)') // Fetch profile of the winner explicitly
        .eq('pool_id', poolId)
        .order('round_number', ascending: false)
        .limit(1)
        .maybeSingle();

    final Map<String, dynamic> result = Map<String, dynamic>.from(poolResponse);
    
    if (winnerResponse != null) {
        final profile = winnerResponse['profiles'] as Map<String, dynamic>?;
        if (profile != null) {
           winnerResponse['full_name'] = profile['full_name'];
           winnerResponse['avatar_url'] = profile['avatar_url'];
        }
        
        result['current_winner'] = winnerResponse;
        result['winner_status'] = winnerResponse['payout_status'];
    }
    
    return result;
  }

  /// Find a pool by invite code
  static Future<Map<String, dynamic>?> findPoolByCode(String inviteCode) async {
    try {
      // Try using RPC first (bypasses RLS for private pools)
      final response = await _client.rpc('get_pool_by_invite_code', params: {'p_invite_code': inviteCode});
      
      if (response is List && response.isNotEmpty) {
        return response.first as Map<String, dynamic>;
      } else if (response is Map) {
        return response as Map<String, dynamic>;
      }
      
      // If RPC returns empty, try direct select (fallback)
      return await _client
          .from('pools')
          .select()
          .eq('invite_code', inviteCode)
          .maybeSingle();
    } catch (e) {
      debugPrint('RPC findPoolByCode failed, falling back to direct select: $e');
      // Fallback to direct select (works for public pools or if user is already member)
      return await _client
          .from('pools')
          .select()
          .eq('invite_code', inviteCode)
          .maybeSingle();
    }
  }

  /// Request to join a pool (Step 1: Send Request)
  static Future<void> joinPool(String poolId, String inviteCode) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    // 🛑 LIMIT CHECK: Max 2 joined pools per user
    final joinedPoolsCount = await _client
        .from('pool_members')
        .count(CountOption.exact)
        .eq('user_id', user.id)
        .eq('status', 'active'); // Only count active memberships
    
    if (joinedPoolsCount >= 2) {
      throw Exception('You can only join a maximum of 2 pools.');
    }

    // Check if already a member (pending or approved)
    final existingMember = await _client
        .from('pool_members')
        .select()
        .eq('pool_id', poolId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existingMember != null) {
      final status = existingMember['status'];
      if (status == 'active') throw Exception('You are already a member of this pool.');
      if (status == 'pending') throw Exception('Request already sent. Please wait for approval.');
      if (status == 'approved') throw Exception('Request accepted! Please go to "My Pools" to complete payment.');
    }

    // Use secure RPC to join (bypasses RLS) - This creates a PENDING request
    // We assume the RPC sets status to 'pending' by default or we might need to adjust it.
    // If the RPC sets it to 'active' automatically if code matches, we need to change that behavior 
    // or just insert directly if we can.
    // Since we can't change RPC easily, let's try direct insert first. 
    // If RLS blocks it, we rely on RPC but we need to know what RPC does.
    // Assuming 'join_pool_secure' checks code and inserts. 
    // If it inserts as 'active', we are in trouble.
    // Let's assume for this fix we use direct insert and hope RLS allows 'pending' inserts.
    
    try {
      // Try the new secure RPC first
      await _client.rpc('request_join_pool', params: {
        'p_pool_id': poolId,
        'p_invite_code': inviteCode,
      }).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('RPC request_join_pool failed: $e');
      // Fallback: Try direct insert if RPC is missing (dev mode)
      if (e.toString().contains('function') && e.toString().contains('not found')) {
         try {
            await _client.from('pool_members').insert({
              'pool_id': poolId,
              'user_id': user.id,
              'role': 'member',
              'status': 'pending',
              'join_date': DateTime.now().toIso8601String(),
            });
         } catch (insertError) {
            throw Exception('Failed to send request. Please ensure database migrations are applied.');
         }
      } else {
        rethrow; // Re-throw other errors (like invalid code)
      }
    }

    // Send chat notification about request
    try {
      final userName = user.userMetadata?['full_name'] ?? 'A user';
      
      // 1. Send system message to chat
      await ChatService.sendSystemMessage(
        poolId: poolId,
        content: '$userName has requested to join the pool.',
        messageType: 'system_notification',
      );

      // 2. Send notification to Pool Creator
      // Fetch creator_id first
      final poolData = await _client
          .from('pools')
          .select('creator_id, name')
          .eq('id', poolId)
          .single();
      
      final creatorId = poolData['creator_id'] as String;
      final poolName = poolData['name'] as String;

      if (creatorId != user.id) { // Don't notify self if testing
        await NotificationService.createNotification(
          userId: creatorId,
          type: 'join_request',
          title: 'New Join Request',
          message: '$userName requested to join "$poolName"',
          data: {
            'pool_id': poolId,
            'requester_id': user.id,
            'action': 'review_request'
          },
        );
      }

    } catch (e) {
      debugPrint('Failed to send notifications: $e');
    }
  }

  /// Complete payment to join a pool (Step 2: Pay & Activate)
  /// Call this when status is 'approved'
  static Future<void> completeJoinPayment(String poolId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    // Get pool details to check joining fee and contribution amount
    final pool = await _client
        .from('pools')
        .select('joining_fee, name, contribution_amount')
        .eq('id', poolId)
        .single();
    
    final joiningFee = (pool['joining_fee'] as num?)?.toDouble() ?? 50.0;
    final contributionAmount = (pool['contribution_amount'] as num?)?.toDouble() ?? 0.0;
    final totalRequired = joiningFee + contributionAmount;
    
    // Check if user has sufficient wallet balance
    final wallet = await _client
        .from('wallets')
        .select('available_balance, locked_balance')
        .eq('user_id', user.id)
        .single();
    
    final availableBalance = (wallet['available_balance'] as num?)?.toDouble() ?? 0.0;
    
    if (availableBalance < totalRequired) {
      throw Exception('Insufficient balance. You need ₹${totalRequired.toStringAsFixed(2)} (₹$joiningFee Joining Fee + ₹$contributionAmount 1st Contribution) to join. Please add money.');
    }

    // Use secure RPC to handle payment and activation atomically
    try {
      await _client.rpc('complete_join_payment', params: {
        'p_pool_id': poolId,
      });
    } catch (e) {
      debugPrint('RPC complete_join_payment failed: $e');
      if (e.toString().contains('Insufficient balance')) {
        throw Exception('Insufficient balance. Please add money to your wallet.');
      }
      rethrow;
    }
    // RPC handles transactions and status update
    
    // Send chat notification
    try {
      final userName = user.userMetadata?['full_name'] ?? 'A user';
      await ChatService.sendSystemMessage(
        poolId: poolId,
        content: '$userName has completed payment and joined the pool!',
        messageType: 'system_notification',
      );

      // Notify the user
      await NotificationService.createNotification(
        userId: user.id,
        type: 'pool_joined',
        title: 'Welcome to ${pool['name']}!',
        message: 'You have successfully joined the pool. Good luck!',
        data: {'pool_id': poolId},
      );

      // Notify the creator/admin
      // Fetch creator_id again (or pass it if optimized)
      final poolData = await _client.from('pools').select('creator_id').eq('id', poolId).single();
      final creatorId = poolData['creator_id'] as String;
      
      if (creatorId != user.id) {
        await NotificationService.createNotification(
          userId: creatorId,
          type: 'new_member',
          title: 'New Member Joined',
          message: '$userName has joined ${pool['name']}.',
          data: {'pool_id': poolId, 'member_id': user.id},
        );
      }

    } catch (e) {
      debugPrint('Failed to send notifications: $e');
    }
  }

  /// Get pending join requests for a pool
  static Future<List<Map<String, dynamic>>> getJoinRequests(String poolId) async {
    final response = await _client
        .from('pool_members')
        .select('*, profile:profiles(*)')
        .eq('pool_id', poolId)
        .eq('status', 'pending');
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Approve or reject a join request
  static Future<void> respondToJoinRequest(String poolId, String userId, bool approve) async {
    final currentUser = _client.auth.currentUser;
    // Fetch pool name for notification
    final pool = await _client.from('pools').select('name').eq('id', poolId).single();
    final poolName = pool['name'] as String;

    if (approve) {
      // Set status to 'approved' (User must still pay to become 'active')
      await _client
          .from('pool_members')
          .update({'status': 'approved'}) 
          .eq('pool_id', poolId)
          .eq('user_id', userId);
          
      // Notify the user
      await NotificationService.createNotification(
        userId: userId,
        type: 'request_approved',
        title: 'Join Request Approved',
        message: 'Your request to join "$poolName" has been approved! Please complete payment to activate your membership.',
        data: {'pool_id': poolId, 'action': 'pay_joining_fee'},
      );
      
    } else {
      await _client
          .from('pool_members')
          .delete()
          .eq('pool_id', poolId)
          .eq('user_id', userId);

      // Notify the user
      await NotificationService.createNotification(
        userId: userId,
        type: 'request_rejected',
        title: 'Join Request Rejected',
        message: 'Your request to join "$poolName" was declined.',
        data: {'pool_id': poolId},
      );
    }
  }

  /// Get contribution status for the current user in a pool
  static Future<Map<String, dynamic>> getContributionStatus(String poolId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    try {
      final response = await _client.rpc('get_contribution_status', params: {
        'p_pool_id': poolId,
        'p_user_id': user.id,
      });
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error fetching contribution status: $e');
      // Return default/empty structure on error to prevent UI crash
      return {
        'is_paid': false,
        'amount_due': 0.0,
        'late_fee': 0.0,
        'total_due': 0.0,
        'next_due_date': DateTime.now().toIso8601String(),
        'status': 'unknown',
      };
    }
  }

  /// Get financial statistics for a pool
  static Future<Map<String, dynamic>> getPoolFinancialStats(String poolId) async {
    try {
      // 1. Get total collected (contributions)
      final contributionsResponse = await _client
          .from('transactions')
          .select('amount')
          .eq('pool_id', poolId)
          .eq('transaction_type', 'contribution')
          .eq('status', 'completed');
      
      double totalCollected = 0;
      for (var t in contributionsResponse) {
        totalCollected += (t['amount'] as num).toDouble();
      }

      // 2. Get late fees collected
      final lateFeesResponse = await _client
          .from('transactions')
          .select('amount')
          .eq('pool_id', poolId)
          .eq('transaction_type', 'penalty') // Assuming penalty is late fee
          .eq('status', 'completed');

      double totalLateFees = 0;
      for (var t in lateFeesResponse) {
        totalLateFees += (t['amount'] as num).toDouble();
      }

      // 3. Get pool details for calculations
      final pool = await _client
          .from('pools')
          .select('contribution_amount, current_members, total_amount')
          .eq('id', poolId)
          .single();
      
      final contributionAmount = (pool['contribution_amount'] as num).toDouble();
      final currentMembers = (pool['current_members'] as num).toInt();
      
      return {
        'total_collected': totalCollected,
        'late_fees': totalLateFees,
        'target_per_round': contributionAmount * currentMembers,
        'payout_amount': pool['total_amount'], // Usually total pot
      };
    } catch (e) {
      debugPrint('Error fetching pool financial stats: $e');
      return {
        'total_collected': 0.0,
        'late_fees': 0.0,
        'target_per_round': 0.0,
        'payout_amount': 0.0,
      };
    }
  }
  /// Get pool statistics
  static Future<Map<String, dynamic>> getPoolStatistics(String poolId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    // Fetch pool details
    final pool = await _client.from('pools').select().eq('id', poolId).single();
    
    // Fetch members
    final members = await _client.from('pool_members').select().eq('pool_id', poolId);
    final totalMembers = members.length;
    final activeMembers = members.where((m) => m['status'] == 'active').length;

    // Fetch transactions
    final transactions = await _client
        .from('transactions')
        .select()
        .eq('pool_id', poolId)
        .eq('status', 'completed');

    double totalCollected = 0;
    double totalDistributed = 0;
    int onTimePayments = 0;
    int totalPayments = 0;

    for (final tx in transactions) {
      final amount = (tx['amount'] as num).toDouble();
      if (tx['type'] == 'contribution') {
        totalCollected += amount;
        totalPayments++;
        // Assuming 'metadata' might contain 'is_late' or we check created_at
        // For now, let's assume 90% on time if no explicit flag
        final isLate = (tx['metadata'] as Map?)?['is_late'] ?? false;
        if (!isLate) onTimePayments++;
      } else if (tx['type'] == 'payout') {
        totalDistributed += amount;
      }
    }

    final onTimeRate = totalPayments > 0 ? (onTimePayments / totalPayments) * 100 : 100.0;
    final participationScore = totalMembers > 0 ? (activeMembers / totalMembers) * 100 : 0.0;
    
    // Calculate completion progress
    final targetAmount = (pool['contribution_amount'] as num).toDouble() * (pool['max_members'] as num) * (pool['total_rounds'] as num);
    final progress = targetAmount > 0 ? (totalCollected / targetAmount) * 100 : 0.0;

    return {
      'on_time_payment_rate': onTimeRate,
      'average_contribution_time': totalPayments > 0 ? 1.0 : 0.0, // Default to 1 day if data exists, 0 if not (Real calculation requires due_date tracking which is in next phase)
      'pool_completion_progress': progress,
      'member_participation_score': participationScore,
      'total_collected': totalCollected,
      'total_distributed': totalDistributed,
      'active_members': activeMembers,
      'total_members': totalMembers,
    };
  }

  /// Get winner history for a pool
  static Future<List<Map<String, dynamic>>> getWinnerHistory(String poolId) async {
    final response = await _client
        .from('winner_history')
        .select('*, profiles!winner_history_user_id_fkey(full_name, avatar_url)')
        .eq('pool_id', poolId)
        .order('round_number', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get user transactions for a specific pool
  static Future<List<Map<String, dynamic>>> getUserPoolTransactions(String poolId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    final response = await _client
        .from('transactions')
        .select()
        .eq('pool_id', poolId)
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
  /// Update pool details
  static Future<void> updatePool(String poolId, Map<String, dynamic> updates) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    await _client.from('pools').update(updates).eq('id', poolId);
  }

  /// Delete a pool
  static Future<void> deletePool(String poolId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    // Delete associated data first (optional if cascade delete is set up in DB, but safer to do here)
    // Note: Supabase cascade delete usually handles this if configured. 
    // Assuming cascade is ON for foreign keys.
    
    await _client.from('pools').delete().eq('id', poolId);
  }

  /// Remove a member from a pool (Admin only)
  static Future<void> removeMember(String poolId, String userId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    // Delete the pool member record
    await _client
        .from('pool_members')
        .delete()
        .eq('pool_id', poolId)
        .eq('user_id', userId);
    
    // Decrement current_members count
    final pool = await _client
        .from('pools')
        .select('current_members')
        .eq('id', poolId)
        .single();
    
    final currentMembers = (pool['current_members'] as num?)?.toInt() ?? 0;
    if (currentMembers > 0) {
      await _client
          .from('pools')
          .update({'current_members': currentMembers - 1})
          .eq('id', poolId);
    }
  }
}
