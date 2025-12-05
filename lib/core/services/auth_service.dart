import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Service class for authentication operations
class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: userData,
    );
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.winpool://login-callback/',
    );
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.winpool://login-callback/',
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Update user password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get auth state changes stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Resend email verification
  Future<void> resendVerificationEmail() async {
    final user = currentUser;
    if (user != null && user.email != null) {
      await _client.auth.resend(
        type: OtpType.signup,
        email: user.email!,
      );
    }
  }

  /// Update user metadata
  Future<UserResponse> updateUserMetadata(Map<String, dynamic> data) async {
    return await _client.auth.updateUser(
      UserAttributes(data: data),
    );
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user != null) {
      // Note: This requires admin privileges or RPC function
      // You'll need to create a Supabase Edge Function for this
      await _client.rpc('delete_user_account');
    }
  }
  /// Update user profile
  /// Update user profile
  Future<void> updateProfile({
    required String fullName,
    required String phoneNumber,
    String? bio,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user != null) {
      final updates = {
        'full_name': fullName,
        'phone_number': phoneNumber,
        'updated_at': DateTime.now().toIso8601String(),
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

      try {
        // Try to update with bio first
        if (bio != null) {
          updates['bio'] = bio;
        }
        await _client.from('profiles').update(updates).eq('id', user.id);
      } catch (e) {
        // If bio column doesn't exist, try updating without bio
        if (e.toString().contains('bio')) {
          updates.remove('bio');
          await _client.from('profiles').update(updates).eq('id', user.id);
          
          // Save bio to metadata as fallback
          await updateUserMetadata({'bio': bio});
        } else {
          rethrow;
        }
      }
      
      // Also update auth metadata for consistency
      await updateUserMetadata({
        'full_name': fullName,
        if (bio != null) 'bio': bio,
      });
    }
  }
}
