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
        // Flatten the profile into the winner object if needed, or keep as is
        // The frontend expects 'full_name' directly on the winner object in VotingTab
        // But let's see how VotingTab uses it: widget.winner['full_name']
        // If profiles is a nested object, we might need to map it.
        // winnerResponse['profiles'] will be a Map.
        
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

  /// Join a pool
  static Future<void> joinPool(String poolId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');

    // Check if already a member (RLS might handle this, but good to check)
    final existing = await _client
        .from('pool_members')
        .select()
        .eq('pool_id', poolId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      throw const AuthException('Already a member of this pool');
    }

    // Check if pool is full
    final pool = await _client.from('pools').select('current_members, max_members').eq('id', poolId).single();
    if (pool['current_members'] >= pool['max_members']) {
      throw const AuthException('Pool is full');
    }

    await _client.from('pool_members').insert({
      'pool_id': poolId,
      'user_id': user.id,
      'role': 'member',
      'status': 'active',
      'joined_at': DateTime.now().toIso8601String(),
    });

    // Send chat notification
    try {
      final userName = user.userMetadata?['full_name'] ?? 'A new member';
      await ChatService.sendMemberJoinedMessage(
        poolId: poolId,
        memberName: userName,
      );
    } catch (e) {
      // Don't fail the join if chat notification fails
      print('Failed to send chat notification: $e');
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
