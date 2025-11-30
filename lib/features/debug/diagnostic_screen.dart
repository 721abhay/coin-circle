import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/wallet_service.dart';
import '../../../core/services/pool_service.dart';
import '../../../core/config/supabase_config.dart';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  final List<String> _logs = [];
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    _addLog('🔍 Starting Diagnostics...');
    _addLog('');

    // Check 1: Authentication
    _addLog('1️⃣ Checking Authentication...');
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _addLog('✅ User authenticated');
        _addLog('   User ID: ${user.id}');
        _addLog('   Email: ${user.email}');
      } else {
        _addLog('❌ User NOT authenticated');
        return;
      }
    } catch (e) {
      _addLog('❌ Auth Error: $e');
    }
    _addLog('');

    // Check 2: Wallet
    _addLog('2️⃣ Checking Wallet...');
    try {
      final wallet = await WalletService.getWallet();
      _addLog('✅ Wallet loaded successfully');
      _addLog('   Available: ₹${wallet['available_balance']}');
      _addLog('   Locked: ₹${wallet['locked_balance']}');
      _addLog('   Winnings: ₹${wallet['total_winnings']}');
    } catch (e) {
      _addLog('❌ Wallet Error: $e');
    }
    _addLog('');

    // Check 3: Pools
    _addLog('3️⃣ Checking Pools...');
    try {
      final pools = await PoolService.getUserPools();
      _addLog('✅ Pools loaded successfully');
      _addLog('   Total pools: ${pools.length}');
      for (var pool in pools.take(3)) {
        _addLog('   - ${pool['name']} (${pool['status']})');
      }
    } catch (e) {
      _addLog('❌ Pools Error: $e');
    }
    _addLog('');

    // Check 4: Transactions
    _addLog('4️⃣ Checking Transactions...');
    try {
      final transactions = await WalletService.getTransactions(limit: 5);
      _addLog('✅ Transactions loaded successfully');
      _addLog('   Total transactions: ${transactions.length}');
    } catch (e) {
      _addLog('❌ Transactions Error: $e');
    }
    _addLog('');

    // Check 5: Supabase Connection
    _addLog('5️⃣ Checking Supabase Connection...');
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('id', SupabaseConfig.currentUserId!)
          .maybeSingle();
      
      if (response != null) {
        _addLog('✅ Supabase connection working');
      } else {
        _addLog('⚠️ Profile not found in database');
      }
    } catch (e) {
      _addLog('❌ Supabase Error: $e');
    }
    _addLog('');

    _addLog('🏁 Diagnostics Complete!');
    setState(() => _isRunning = false);
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
    debugPrint(message); // Also print to console
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRunning ? null : _runDiagnostics,
          ),
        ],
      ),
      body: _isRunning
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: log.contains('❌')
                          ? Colors.red
                          : log.contains('✅')
                              ? Colors.green
                              : log.contains('⚠️')
                                  ? Colors.orange
                                  : Colors.black87,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
