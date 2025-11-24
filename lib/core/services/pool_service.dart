import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_service.dart';
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
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

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
  static Future<List<Map<String, dynamic>>> getPublicPools() async {
    final response = await _client
        .from('pools')
        .select()
        .inFilter('status', ['pending', 'active']) // Show pending and active
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get pools the current user has joined
  static Future<List<Map<String, dynamic>>> getUserPools() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    // We need to join pool_members with pools
    final response = await _client
        .from('pool_members')
        .select('pool:pools(*)')
        .eq('user_id', user.id);
    
    // Extract the pool data from the response
    return response.map((item) => item['pool'] as Map<String, dynamic>).toList();
  }

  /// Get details of a specific pool
  static Future<Map<String, dynamic>> getPoolDetails(String poolId) async {
    final poolResponse = await _client
        .from('pools')
        .select('*, members:pool_members(*, profile:profiles(*))')
        .eq('id', poolId)
        .single();
    
    // Fetch latest winner
    final winnerResponse = await _client
        .from('winner_history')
        .select('*, profiles(*)') // Fetch profile of the winner
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
      print('RPC findPoolByCode failed, falling back to direct select: $e');
      // Fallback to direct select (works for public pools or if user is already member)
      return await _client
          .from('pools')
          .select()
          .eq('invite_code', inviteCode)
          .maybeSingle();
    }
  }

  /// Join a pool with invite code
  static Future<void> joinPool(String poolId, String inviteCode) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    // Use secure RPC to join (bypasses RLS)
    await _client.rpc('join_pool_secure', params: {
      'p_pool_id': poolId,
      'p_invite_code': inviteCode,
    });

    // Send chat notification about request
    try {
      final userName = user.userMetadata?['full_name'] ?? 'A user';
      await ChatService.sendSystemMessage(
        poolId: poolId,
        content: '$userName has requested to join the pool.',
        messageType: 'system_notification',
      );
    } catch (e) {
      print('Failed to send chat notification: $e');
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
    if (approve) {
      await _client
          .from('pool_members')
          .update({'status': 'active'})
          .eq('pool_id', poolId)
          .eq('user_id', userId);
          
      // Increment current_members count in pools table
      // Note: Ideally this should be a trigger or RPC, but doing it client-side for now
      await _client.rpc('increment_pool_members', params: {'p_pool_id': poolId});
      
    } else {
      await _client
          .from('pool_members')
          .delete()
          .eq('pool_id', poolId)
          .eq('user_id', userId);
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
      print('Error fetching contribution status: $e');
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
}
