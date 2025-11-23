import 'package:flutter/material.dart';

class PoolSettingsScreen extends StatefulWidget {
  final String? poolId;
  const PoolSettingsScreen({super.key, this.poolId});

  @override
  State<PoolSettingsScreen> createState() => _PoolSettingsScreenState();
}

class _PoolSettingsScreenState extends State<PoolSettingsScreen> {
  final _nameController = TextEditingController(text: 'Family Savings #12');
  bool _isPrivate = true;
  bool _autoPayAllowed = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pool Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('General Configuration'),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Pool Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Private Pool'),
            subtitle: const Text('Only invited members can join'),
            value: _isPrivate,
            onChanged: (val) => setState(() => _isPrivate = val),
          ),
          SwitchListTile(
            title: const Text('Allow Auto-Pay'),
            subtitle: const Text('Members can enable automatic contributions'),
            value: _autoPayAllowed,
            onChanged: (val) => setState(() => _autoPayAllowed = val),
          ),

          _buildSectionHeader('Danger Zone'),
          Card(
            color: Colors.red.shade50,
            child: Column(
              children: [
                _buildDangerTile(
                  'Close Pool Early',
                  'Requires member vote',
                  () => _showConfirmation(context, 'Close Pool'),
                ),
                const Divider(height: 1),
                _buildDangerTile(
                  'Extend Duration',
                  'Add more cycles (Requires vote)',
                  () => _showConfirmation(context, 'Extend Duration'),
                ),
                const Divider(height: 1),
                _buildDangerTile(
                  'Dissolve Pool',
                  'Emergency only - Refunds all funds',
                  () => _showConfirmation(context, 'Dissolve Pool'),
                ),
                const Divider(height: 1),
                _buildDangerTile(
                  'Transfer Ownership',
                  'Make another member the admin',
                  () => _showConfirmation(context, 'Transfer Ownership'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildDangerTile(String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: Colors.red),
      onTap: onTap,
    );
  }

  void _showConfirmation(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action),
        content: const Text('Are you sure? This action may require member approval.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }
}
