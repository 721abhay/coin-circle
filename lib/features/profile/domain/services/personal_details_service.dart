import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/personal_details_model.dart';

class PersonalDetailsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get personal details for current user
  Future<PersonalDetails?> getPersonalDetails() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      // Merge with auth user data
      final user = _supabase.auth.currentUser;
      final data = {
        ...response,
        'user_id': userId,
        'email': user?.email ?? response['email'],
        'phone_number': user?.phone ?? response['phone_number'],
      };

      return PersonalDetails.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching personal details: $e');
      rethrow;
    }
  }

  // Update contact details
  Future<void> updateContactDetails({
    String? phoneNumber,
    String? email,
    String? address,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (email != null) updates['email'] = email;
      if (address != null) updates['address'] = address;

      if (updates.isEmpty) return;

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error updating contact details: $e');
      rethrow;
    }
  }

  // Update identity details
  Future<void> updateIdentityDetails({
    DateTime? dateOfBirth,
    String? panNumber,
    String? aadhaarNumber,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};
      if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth.toIso8601String();
      if (panNumber != null) updates['pan_number'] = panNumber.toUpperCase();
      if (aadhaarNumber != null) updates['aadhaar_number'] = aadhaarNumber;

      if (updates.isEmpty) return;

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error updating identity details: $e');
      rethrow;
    }
  }

  // Update income details
  Future<void> updateIncomeDetails({
    String? annualIncome,
    String? occupation,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};
      if (annualIncome != null) updates['annual_income'] = annualIncome;
      if (occupation != null) updates['occupation'] = occupation;

      if (updates.isEmpty) return;

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error updating income details: $e');
      rethrow;
    }
  }

  // Verify phone number (send OTP)
  Future<void> sendPhoneVerificationOTP(String phoneNumber) async {
    try {
      // Trigger OTP by updating user attributes
      // This requires SMS provider to be configured in Supabase
      await _supabase.auth.updateUser(
        UserAttributes(phone: phoneNumber),
      );
    } catch (e) {
      debugPrint('Error sending phone OTP: $e');
      // If SMS is not configured, we might want to simulate it for development
      if (e.toString().contains('SMS provider not configured')) {
        throw Exception('SMS provider not configured. Please contact support.');
      }
      rethrow;
    }
  }

  // Verify phone number (verify OTP)
  Future<void> verifyPhoneOTP(String phoneNumber, String otp) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Verify OTP with Supabase
      await _supabase.auth.verifyOTP(
        token: otp,
        type: OtpType.phoneChange,
        phone: phoneNumber,
      );
      
      // Update profile status
      await _supabase
          .from('profiles')
          .update({
            'phone_number': phoneNumber,
            'phone_verified': true,
          })
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error verifying phone OTP: $e');
      rethrow;
    }
  }

  // Verify email (send verification link)
  Future<void> sendEmailVerification(String email) async {
    try {
      // TODO: Use Supabase email verification
      await _supabase.auth.updateUser(
        UserAttributes(email: email),
      );
    } catch (e) {
      debugPrint('Error sending email verification: $e');
      rethrow;
    }
  }
}
