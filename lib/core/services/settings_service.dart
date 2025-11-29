// lib/core/services/settings_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsService {
  static final _client = Supabase.instance.client;

  /// Fetch security limits for the current user (deposit, withdrawal, contribution)
  static Future<Map<String, dynamic>> getSecurityLimits() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');
    final resp = await _client.from('security_limits').select().eq('user_id', user.id).single();
    return Map<String, dynamic>.from(resp);
  }

  /// Update a specific limit (key: e.g., 'daily_deposit_limit')
  static Future<void> updateLimit(String key, num value) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('User not logged in');
    await _client.from('security_limits').upsert({
      'user_id': user.id,
      key: value,
    }, onConflict: 'user_id');
  }
}
