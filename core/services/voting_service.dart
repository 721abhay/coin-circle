import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vote.dart'; // We'll define a simple Vote model here or reuse

class VotingService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch active votes for a given pool
  Future<List<Vote>> fetchActiveVotes(String poolId) async {
    try {
      final response = await _client
          .from('pool_votes')
          .select()
          .eq('pool_id', poolId)
          .order('created_at', ascending: true)
          .execute();
      if (response.error != null) {
        throw response.error!;
      }
      final data = response.data as List<dynamic>;
      // Map to Vote objects; assuming columns: member_name, reason, vote (bool), round_number, created_at
      return data.map((e) {
        return Vote(
          memberName: e['member_name'] ?? 'Unknown',
          reason: e['reason'] ?? '',
          approvedCount: (e['vote'] == true) ? 1 : 0,
          totalMembers: 0, // placeholder; can be fetched separately if needed
          timeLeft: 'N/A', // placeholder
          isUrgent: false,
          roundNumber: e['round_number'] ?? 0,
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Cast a vote using the RPC function defined in Supabase
  Future<bool> castVote(String poolId, int roundNumber, bool approve) async {
    final response = await _client.rpc('cast_vote', params: {
      'p_pool_id': poolId,
      'p_round': roundNumber,
      'p_vote': approve,
    }).execute();
    if (response.error != null) {
      throw response.error!;
    }
    // The RPC returns boolean indicating approval status
    return response.data as bool;
  }
}

// Provider for the VotingService
final votingServiceProvider = Provider<VotingService>((ref) => VotingService());
