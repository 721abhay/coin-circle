import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VotingService {
  static final _supabase = Supabase.instance.client;

  /// Cast a vote for the current round
  static Future<bool?> castVote({
    required String poolId,
    required int round,
    required bool vote,
  }) async {
    try {
      final response = await _supabase.rpc('cast_vote', params: {
        'p_pool_id': poolId,
        'p_round': round,
        'p_vote': vote,
      });
      return response as bool?;
    } catch (e) {
      throw Exception('Failed to cast vote: $e');
    }
  }

  /// Get voting status for the current round
  static Future<Map<String, dynamic>> getVotingStatus({
    required String poolId,
    required int round,
  }) async {
    try {
      final response = await _supabase.rpc('get_voting_status', params: {
        'p_pool_id': poolId,
        'p_round': round,
      });
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get voting status: $e');
    }
  }

  /// Subscribe to voting updates
  static Stream<List<Map<String, dynamic>>> subscribeToVotes(String poolId) {
    return _supabase
        .from('pool_votes')
        .stream(primaryKey: ['id'])
        .eq('pool_id', poolId);
  }
  /// Fetch active votes for a pool
  static Future<List<Map<String, dynamic>>> fetchActiveVotes(String poolId) async {
    try {
      // This assumes an RPC or table query. Using RPC for consistency.
      final response = await _supabase.rpc('get_active_votes', params: {
        'p_pool_id': poolId,
      });
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback to empty list if RPC missing, to avoid runtime crash during dev
      debugPrint('Error fetching active votes: $e');
      return [];
    }
  }
}
