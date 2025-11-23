import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AutoPaySetupScreen extends StatefulWidget {
  final String? poolId;

  const AutoPaySetupScreen({super.key, this.poolId});

  @override
  State<AutoPaySetupScreen> createState() => _AutoPaySetupScreenState();
}

class _AutoPaySetupScreenState extends State<AutoPaySetupScreen> {
  bool _autoPayEnabled = false;
  String _selectedPaymentMethod = 'card_1';
  String _selectedBackupMethod = 'bank_1';
  int _daysBeforeDueDate = 1;
  bool _emailNotification = true;
  bool _pushNotification = true;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'card_1',
      'name': 'Visa ending in 4242',
      'type': 'card',
      'icon': Icons.credit_card,
    },
    {
      'id': 'bank_1',
      'name': 'Chase Bank ••••1234',
      'type': 'bank',
      'icon': Icons.account_balance,
    },
    {
      'id': 'upi_1',
      'name': 'UPI: user@okaxis',
      'type': 'upi',
      'icon': Icons.payment,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-Pay Setup'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildEnableToggle(),
            if (_autoPayEnabled) ...[
              const SizedBox(height: 32),
              _buildPaymentMethodSection(),
              const SizedBox(height: 32),
              _buildBackupMethodSection(),
              const SizedBox(height: 32),
              _buildTimingSection(),
              const SizedBox(height: 32),
              _buildNotificationSection(),
              const SizedBox(height: 32),
              _buildSummaryCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Never Miss a Payment',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Auto-pay ensures your contributions are made on time, every time.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnableToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _autoPayEnabled
                  ? Colors.green.shade100
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.autorenew,
              color: _autoPayEnabled ? Colors.green : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enable Auto-Pay',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _autoPayEnabled ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 13,
                    color: _autoPayEnabled ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _autoPayEnabled,
            onChanged: (value) {
              setState(() => _autoPayEnabled = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Primary Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'This method will be charged automatically',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ..._paymentMethods.map((method) => _buildPaymentMethodCard(
              method,
              _selectedPaymentMethod == method['id'],
              () => setState(() => _selectedPaymentMethod = method['id']),
            )),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            // Navigate to add payment method
          },
          icon: const Icon(Icons.add),
          label: const Text('Add New Payment Method'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Backup Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Used if primary method fails',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ..._paymentMethods
            .where((m) => m['id'] != _selectedPaymentMethod)
            .map((method) => _buildPaymentMethodCard(
                  method,
                  _selectedBackupMethod == method['id'],
                  () => setState(() => _selectedBackupMethod = method['id']),
                )),
      ],
    );
  }

  Widget _buildPaymentMethodCard(
    Map<String, dynamic> method,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: RadioListTile(
        value: method['id'],
        groupValue: isSelected ? method['id'] : null,
        onChanged: (_) => onTap(),
        title: Text(
          method['name'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          method['type'].toString().toUpperCase(),
          style: const TextStyle(fontSize: 12),
        ),
        secondary: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(method['icon'], color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }

  Widget _buildTimingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Timing',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'When should we charge your payment method?',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Days before due date',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '$_daysBeforeDueDate ${_daysBeforeDueDate == 1 ? 'day' : 'days'} before',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: _daysBeforeDueDate.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            label: '$_daysBeforeDueDate days',
            onChanged: (value) {
              setState(() => _daysBeforeDueDate = value.toInt());
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 day', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('7 days', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Get notified about auto-pay activity',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            value: _emailNotification,
            onChanged: (value) => setState(() => _emailNotification = value),
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive email confirmations'),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          SwitchListTile(
            value: _pushNotification,
            onChanged: (value) => setState(() => _pushNotification = value),
            title: const Text('Push Notifications'),
            subtitle: const Text('In-app notifications'),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final primaryMethod = _paymentMethods.firstWhere(
      (m) => m['id'] == _selectedPaymentMethod,
    );
    final backupMethod = _paymentMethods.firstWhere(
      (m) => m['id'] == _selectedBackupMethod,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              const Text(
                'Auto-Pay Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Primary Method', primaryMethod['name']),
          _buildSummaryRow('Backup Method', backupMethod['name']),
          _buildSummaryRow(
            'Payment Timing',
            '$_daysBeforeDueDate ${_daysBeforeDueDate == 1 ? 'day' : 'days'} before due date',
          ),
          _buildSummaryRow(
            'Notifications',
            [
              if (_emailNotification) 'Email',
              if (_pushNotification) 'Push',
            ].join(', '),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    if (!_autoPayEnabled) {
      // Just save the disabled state
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auto-pay disabled')),
      );
      context.pop();
      return;
    }

    // TODO: Save to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Auto-pay settings saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    context.pop();
  }
}
