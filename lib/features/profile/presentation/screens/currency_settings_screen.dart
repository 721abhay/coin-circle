import 'package:flutter/material.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  String _primaryCurrency = 'INR';
  bool _autoConvert = true;
  bool _showMultipleCurrencies = false;

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

  @override
  Widget build(BuildContext context) {
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
                    setState(() {
                      _primaryCurrency = value!;
                    });
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
                return ListTile(
                  leading: Text(
                    _supportedCurrencies.firstWhere((c) => c['code'] == entry.key)['flag'],
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(entry.key),
                  trailing: Text(
                    '1 $_primaryCurrency = ${entry.value.toStringAsFixed(4)} ${entry.key}',
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
              final amount = 1000 * entry.value; // Example with 1000
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
