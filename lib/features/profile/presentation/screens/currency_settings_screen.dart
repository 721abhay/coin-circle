import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  String _primaryCurrency = 'INR';
  bool _autoConvert = true;
  bool _showMultipleCurrencies = false;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _supportedCurrencies = [
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹', 'flag': '🇮🇳'},
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£', 'flag': '🇬🇧'},
    {'code': 'AED', 'name': 'UAE Dirham', 'symbol': 'د.إ', 'flag': '🇦🇪'},
    {'code': 'SAR', 'name': 'Saudi Riyal', 'symbol': 'ر.س', 'flag': '🇸🇦'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'C\$', 'flag': '🇨🇦'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$', 'flag': '🇦🇺'},
  ];

  final Map<String, double> _exchangeRates = {
    'USD': 0.012,
    'EUR': 0.011,
    'GBP': 0.0095,
    'AED': 0.044,
    'SAR': 0.045,
    'CAD': 0.016,
    'AUD': 0.018,
    'INR': 1.0,
  };

  final TextEditingController _amountController = TextEditingController(text: '1000');

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCurrencyPreference();
  }

  Future<void> _loadCurrencyPreference() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('currency_preference')
            .eq('id', userId)
            .single();
        
        if (mounted && data['currency_preference'] != null) {
          setState(() {
            _primaryCurrency = data['currency_preference'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading currency preference: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCurrencyPreference(String newCurrency) async {
    setState(() => _primaryCurrency = newCurrency);
    
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'currency_preference': newCurrency})
            .eq('id', userId);
            
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Currency updated to $newCurrency')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating currency: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Currency Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Primary Currency',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: _supportedCurrencies.map((currency) {
                return RadioListTile<String>(
                  value: currency['code'],
                  groupValue: _primaryCurrency,
                  onChanged: (value) {
                    if (value != null) {
                      _updateCurrencyPreference(value);
                    }
                  },
                  title: Row(
                    children: [
                      Text(
                        currency['flag'],
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(currency['name']),
                      ),
                      Text(
                        currency['symbol'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(currency['code']),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Conversion Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Auto-Convert'),
                  subtitle: const Text('Automatically convert amounts to your primary currency'),
                  value: _autoConvert,
                  onChanged: (value) {
                    setState(() {
                      _autoConvert = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Show Multiple Currencies'),
                  subtitle: const Text('Display amounts in multiple currencies'),
                  value: _showMultipleCurrencies,
                  onChanged: (value) {
                    setState(() {
                      _showMultipleCurrencies = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Exchange Rates',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Last updated: ${DateTime.now().toString().substring(0, 16)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),


          Card(
            child: Column(
              children: _exchangeRates.entries.map((entry) {
                if (entry.key == _primaryCurrency) return const SizedBox.shrink();
                
                // Calculate rate relative to primary currency
                // _exchangeRates is based on INR. 
                // Rate = Target / Source
                final sourceRate = _exchangeRates[_primaryCurrency] ?? 1.0;
                final targetRate = entry.value;
                final rate = targetRate / sourceRate;

                return ListTile(
                  leading: Text(
                    _supportedCurrencies.firstWhere((c) => c['code'] == entry.key)['flag'],
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(entry.key),
                  trailing: Text(
                    '1 $_primaryCurrency = ${rate.toStringAsFixed(4)} ${entry.key}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _buildCurrencyConverter(),
        ],
      ),
    );
  }

  Widget _buildCurrencyConverter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Converter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount in $_primaryCurrency',
                border: const OutlineInputBorder(),
                prefixText: _supportedCurrencies.firstWhere((c) => c['code'] == _primaryCurrency)['symbol'] + ' ',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Converted Amounts:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._exchangeRates.entries.where((e) => e.key != _primaryCurrency).map((entry) {
              final inputAmount = double.tryParse(_amountController.text) ?? 0;
              
              final sourceRate = _exchangeRates[_primaryCurrency] ?? 1.0;
              final targetRate = entry.value;
              final rate = targetRate / sourceRate;
              
              final amount = inputAmount * rate;
              
              final currency = _supportedCurrencies.firstWhere((c) => c['code'] == entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${currency['flag']} ${entry.key}'),
                    Text(
                      '${currency['symbol']} ${amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
