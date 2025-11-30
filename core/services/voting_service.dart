import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class VotingService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch active votes for a given pool
  Future<List<Map<String, dynamic>>> fetchActiveVotes(String poolId) async {
    try {
      final data = await _client
          .from('pool_votes')
          .select()
          .eq('pool_id', poolId)
          .order('created_at', ascending: true);
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Failed to fetch active votes: $e');
      throw Exception('Failed to fetch active votes: $e');
    }
  }

  // Cast a vote using the RPC function defined in Supabase
  Future<bool> castVote(String poolId, int roundNumber, bool approve) async {
    try {
      final result = await _client.rpc('cast_vote', params: {
        'p_pool_id': poolId,
        'p_round': roundNumber,
        'p_vote': approve,
      });
      
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('Failed to cast vote: $e');
      throw Exception('Failed to cast vote: $e');
    }
  }
}

// Provider for the VotingService
final votingServiceProvider = Provider<VotingService>((ref) => VotingService());
