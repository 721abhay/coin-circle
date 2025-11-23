import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Get the current user's ID
  static String? get _userId => _client.auth.currentUser?.id;

  /// Stream of pool updates (for a specific pool)
  static Stream<List<Map<String, dynamic>>> getPoolUpdates(String poolId) {
    return _client
        .from('pools')
        .stream(primaryKey: ['id'])
        .eq('id', poolId);
  }

  /// Stream of user's active pools updates
  /// Note: Complex joins are not supported in realtime streams directly.
  /// We might need to listen to 'pool_members' and then fetch pool details, 
  /// or just listen to 'pools' table generally and filter client-side (inefficient for large datasets).
  /// For now, we'll listen to 'pool_members' for the current user.
  static Stream<List<Map<String, dynamic>>> getUserPoolsUpdates() {
    if (_userId == null) return const Stream.empty();
    return _client
        .from('pool_members')
        .stream(primaryKey: ['pool_id', 'user_id'])
        .eq('user_id', _userId!);
  }

  /// Stream of wallet updates
  static Stream<List<Map<String, dynamic>>> getWalletUpdates() {
    if (_userId == null) return const Stream.empty();
    return _client
        .from('wallets')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId!);
  }

  /// Stream of transaction updates
  static Stream<List<Map<String, dynamic>>> getTransactionUpdates() {
    if (_userId == null) return const Stream.empty();
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId!)
        .order('created_at', ascending: false)
        .limit(20);
  }

  /// Stream of notification updates
  static Stream<List<Map<String, dynamic>>> getNotificationUpdates() {
    if (_userId == null) return const Stream.empty();
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId!)
        .order('created_at', ascending: false)
        .limit(50);
  }
  
  /// Stream of pool members updates
  static Stream<List<Map<String, dynamic>>> getPoolMembersUpdates(String poolId) {
    return _client
        .from('pool_members')
        .stream(primaryKey: ['pool_id', 'user_id'])
        .eq('pool_id', poolId);
  }

  /// Stream of winner updates for a pool
  static Stream<List<Map<String, dynamic>>> getWinnerUpdates(String poolId) {
    return _client
        .from('winner_history')
        .stream(primaryKey: ['id'])
        .eq('pool_id', poolId)
        .order('created_at', ascending: false)
        .limit(1);
  }
}
