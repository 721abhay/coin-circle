import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/bank_account_model.dart';

class BankService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all bank accounts for the current user
  Future<List<BankAccount>> getBankAccounts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('bank_accounts')
          .select()
          .eq('user_id', userId)
          .order('is_primary', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BankAccount.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching bank accounts: $e');
      rethrow;
    }
  }

  // Get primary bank account
  Future<BankAccount?> getPrimaryBankAccount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('bank_accounts')
          .select()
          .eq('user_id', userId)
          .eq('is_primary', true)
          .maybeSingle();

      if (response == null) return null;
      return BankAccount.fromJson(response);
    } catch (e) {
      print('Error fetching primary bank account: $e');
      return null;
    }
  }

  // Add a new bank account
  Future<BankAccount> addBankAccount({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
    String? branchName,
    String accountType = 'savings',
    bool setPrimary = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // If this is the first account or setPrimary is true, make it primary
      final existingAccounts = await getBankAccounts();
      final shouldBePrimary = existingAccounts.isEmpty || setPrimary;

      final data = {
        'user_id': userId,
        'account_holder_name': accountHolderName,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
        'bank_name': bankName,
        'branch_name': branchName,
        'account_type': accountType,
        'is_primary': shouldBePrimary,
        'is_verified': false,
      };

      final response = await _supabase
          .from('bank_accounts')
          .insert(data)
          .select()
          .single();

      final newAccount = BankAccount.fromJson(response);

      // If setting as primary, update other accounts
      if (shouldBePrimary) {
        await setPrimaryBankAccount(newAccount.id);
      }

      return newAccount;
    } catch (e) {
      print('Error adding bank account: $e');
      rethrow;
    }
  }

  // Update bank account
  Future<BankAccount> updateBankAccount({
    required String accountId,
    String? accountHolderName,
    String? branchName,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};
      if (accountHolderName != null) updates['account_holder_name'] = accountHolderName;
      if (branchName != null) updates['branch_name'] = branchName;

      if (updates.isEmpty) throw Exception('No fields to update');

      final response = await _supabase
          .from('bank_accounts')
          .update(updates)
          .eq('id', accountId)
          .eq('user_id', userId)
          .select()
          .single();

      return BankAccount.fromJson(response);
    } catch (e) {
      print('Error updating bank account: $e');
      rethrow;
    }
  }

  // Set a bank account as primary
  Future<void> setPrimaryBankAccount(String accountId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Call the database function to handle primary account logic
      await _supabase.rpc('set_primary_bank_account', params: {
        'account_id': accountId,
        'user_id_param': userId,
      });
    } catch (e) {
      print('Error setting primary bank account: $e');
      rethrow;
    }
  }

  // Delete bank account
  Future<void> deleteBankAccount(String accountId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Check if this is the primary account
      final account = await _supabase
          .from('bank_accounts')
          .select()
          .eq('id', accountId)
          .eq('user_id', userId)
          .single();

      final wasPrimary = account['is_primary'] as bool;

      // Delete the account
      await _supabase
          .from('bank_accounts')
          .delete()
          .eq('id', accountId)
          .eq('user_id', userId);

      // If it was primary, set another account as primary
      if (wasPrimary) {
        final remainingAccounts = await getBankAccounts();
        if (remainingAccounts.isNotEmpty) {
          await setPrimaryBankAccount(remainingAccounts.first.id);
        }
      }
    } catch (e) {
      print('Error deleting bank account: $e');
      rethrow;
    }
  }

  // Verify bank account (admin function or after penny drop)
  Future<void> verifyBankAccount({
    required String accountId,
    required String verificationMethod,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('bank_accounts')
          .update({
            'is_verified': true,
            'verification_method': verificationMethod,
            'verification_date': DateTime.now().toIso8601String(),
          })
          .eq('id', accountId)
          .eq('user_id', userId);
    } catch (e) {
      print('Error verifying bank account: $e');
      rethrow;
    }
  }

  // Get bank details from IFSC code (using external API)
  Future<Map<String, String>> getBankDetailsFromIFSC(String ifscCode) async {
    try {
      // You can integrate with IFSC API like https://ifsc.razorpay.com/
      // For now, returning a placeholder
      // TODO: Implement actual IFSC lookup
      return {
        'bank_name': 'Bank Name',
        'branch_name': 'Branch Name',
      };
    } catch (e) {
      print('Error fetching bank details from IFSC: $e');
      rethrow;
    }
  }
}
