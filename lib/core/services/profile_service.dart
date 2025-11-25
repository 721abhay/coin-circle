import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class ProfileService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<Map<String, dynamic>?> getProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      return response;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  Future<void> updateProfileVisibility(String visibility) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('profiles').update({
        'profile_visibility': visibility,
      }).eq('id', user.id);
    } catch (e) {
      print('Error updating profile visibility: $e');
      // Fallback to metadata if column doesn't exist
      await _client.auth.updateUser(
        UserAttributes(data: {'profile_visibility': visibility}),
      );
    }
  }

  Future<String> getVerificationStatus() async {
    final profile = await getProfile();
    if (profile != null && profile['kyc_verified'] == true) {
      return 'Verified';
    }
    return 'Not Verified';
  }
  
  String getLinkedProvider() {
    final user = _client.auth.currentUser;
    if (user == null) return 'None';
    
    final providers = user.appMetadata['providers'] as List<dynamic>?;
    if (providers != null && providers.isNotEmpty) {
      // Capitalize first letter
      final provider = providers.first.toString();
      return provider[0].toUpperCase() + provider.substring(1);
    }
    return 'Email';
  }
}
