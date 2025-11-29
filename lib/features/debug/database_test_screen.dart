import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  State<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  final List<String> _testResults = [];
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    setState(() {
      _isTesting = true;
      _testResults.clear();
    });

    await _addResult('🔍 Starting database tests...');
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final client = Supabase.instance.client;
      await _addResult('✅ Supabase client initialized');

      // Test 1: Check if user is logged in
      final user = client.auth.currentUser;
      if (user != null) {
        await _addResult('✅ User logged in: ${user.email}');
      } else {
        await _addResult('❌ No user logged in');
      }

      // Test 2: Check profiles table
      try {
        final profile = await client
            .from('profiles')
            .select()
            .eq('id', user?.id ?? '')
            .maybeSingle();
        
        if (profile != null) {
          await _addResult('✅ Profiles table exists and accessible');
          await _addResult('   Name: ${profile['full_name'] ?? 'Not set'}');
        } else {
          await _addResult('⚠️ Profile not found');
        }
      } catch (e) {
        await _addResult('❌ Profiles table error: $e');
      }

      // Test 3: Check if phone column exists
      try {
        final profile = await client
            .from('profiles')
            .select('phone')
            .eq('id', user?.id ?? '')
            .maybeSingle();
        
        await _addResult('✅ Phone column exists');
        await _addResult('   Phone: ${profile?['phone'] ?? 'Not set'}');
      } catch (e) {
        await _addResult('❌ Phone column MISSING! Run ADD_PROFILE_COLUMNS.sql');
      }

      // Test 4: Check if address column exists
      try {
        final profile = await client
            .from('profiles')
            .select('address, city, state')
            .eq('id', user?.id ?? '')
            .maybeSingle();
        
        await _addResult('✅ Address columns exist');
        await _addResult('   Address: ${profile?['address'] ?? 'Not set'}');
      } catch (e) {
        await _addResult('❌ Address columns MISSING! Run ADD_PROFILE_COLUMNS.sql');
      }

      // Test 5: Check if PAN column exists
      try {
        final profile = await client
            .from('profiles')
            .select('pan_number, aadhaar_number')
            .eq('id', user?.id ?? '')
            .maybeSingle();
        
        await _addResult('✅ Identity document columns exist');
        await _addResult('   PAN: ${profile?['pan_number'] ?? 'Not set'}');
      } catch (e) {
        await _addResult('❌ Identity columns MISSING! Run ADD_PROFILE_COLUMNS.sql');
      }

      // Test 6: Check bank_accounts table
      try {
        final accounts = await client
            .from('bank_accounts')
            .select()
            .eq('user_id', user?.id ?? '')
            .limit(1);
        
        await _addResult('✅ Bank accounts table exists');
        await _addResult('   Accounts: ${accounts.length}');
      } catch (e) {
        await _addResult('❌ Bank accounts table MISSING! Run CREATE_BANK_ACCOUNTS.sql');
      }

      // Test 7: Check pools table
      try {
        final pools = await client
            .from('pools')
            .select()
            .limit(1);
        
        await _addResult('✅ Pools table exists');
      } catch (e) {
        await _addResult('❌ Pools table error: $e');
      }

      // Test 8: Check wallets table
      try {
        final wallets = await client
            .from('wallets')
            .select()
            .eq('user_id', user?.id ?? '')
            .limit(1);
        
        await _addResult('✅ Wallets table exists');
      } catch (e) {
        await _addResult('❌ Wallets table error: $e');
      }

      await _addResult('');
      await _addResult('📋 SUMMARY:');
      
      final hasErrors = _testResults.any((r) => r.contains('❌'));
      if (hasErrors) {
        await _addResult('⚠️ Some tests failed!');
        await _addResult('');
        await _addResult('TO FIX:');
        await _addResult('1. Go to Supabase Dashboard → SQL Editor');
        await _addResult('2. Run ADD_PROFILE_COLUMNS.sql');
        await _addResult('3. Run CREATE_BANK_ACCOUNTS.sql');
        await _addResult('4. Restart the app');
      } else {
        await _addResult('✅ All tests passed!');
        await _addResult('Database is properly configured.');
      }

    } catch (e) {
      await _addResult('❌ CRITICAL ERROR: $e');
    }

    setState(() => _isTesting = false);
  }

  Future<void> _addResult(String result) async {
    setState(() => _testResults.add(result));
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isTesting ? null : _runTests,
          ),
        ],
      ),
      body: _isTesting && _testResults.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _testResults.length,
              itemBuilder: (context, index) {
                final result = _testResults[index];
                Color? color;
                
                if (result.contains('✅')) {
                  color = Colors.green;
                } else if (result.contains('❌')) {
                  color = Colors.red;
                } else if (result.contains('⚠️')) {
                  color = Colors.orange;
                } else if (result.contains('🔍')) {
                  color = Colors.blue;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    result,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: color,
                      fontWeight: result.contains('SUMMARY') || result.contains('TO FIX')
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: _isTesting
          ? const LinearProgressIndicator()
          : null,
    );
  }
}
