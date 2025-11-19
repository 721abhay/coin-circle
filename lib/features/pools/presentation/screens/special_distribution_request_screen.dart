import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SpecialDistributionRequestScreen extends StatefulWidget {
  const SpecialDistributionRequestScreen({super.key});

  @override
  State<SpecialDistributionRequestScreen> createState() => _SpecialDistributionRequestScreenState();
}

class _SpecialDistributionRequestScreenState extends State<SpecialDistributionRequestScreen> {
  String? _selectedMember;
  String _selectedReason = 'Medical emergency';
  String _urgency = 'Normal';
  final TextEditingController _detailsController = TextEditingController();
  final List<String> _members = [
    'Alice Johnson',
    'Bob Smith',
    'Charlie Brown',
    'Diana Prince',
    'Evan Wright',
  ];

  final List<String> _reasons = [
    'Medical emergency',
    'Job loss',
    'Educational expense',
    'Family emergency',
    'Business opportunity',
    'Other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submitRequest() {
    if (_selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Submitted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your special distribution request has been sent to all pool members.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _urgency == 'Urgent' 
                          ? 'Voting period: 48 hours'
                          : 'Voting period: 7 days',
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pop(); // Close dialog
              context.pop(); // Go back to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Special Distribution'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Requires unanimous approval from all pool members',
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Select Member
            Text(
              'Select Member to Receive Funds',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedMember,
              decoration: const InputDecoration(
                hintText: 'Choose a member',
                prefixIcon: Icon(Icons.person),
              ),
              items: _members.map((member) {
                return DropdownMenuItem(
                  value: member,
                  child: Text(member),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMember = value;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Reason
            Text(
              'Reason for Request',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category),
              ),
              items: _reasons.map((reason) {
                return DropdownMenuItem(
                  value: reason,
                  child: Text(reason),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedReason = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Details
            Text(
              'Additional Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailsController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Explain the situation in detail...',
              ),
            ),
            const SizedBox(height: 24),
            
            // Supporting Documents
            Text(
              'Supporting Documents (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.attach_file),
              label: const Text('Upload Documents'),
            ),
            const SizedBox(height: 24),
            
            // Urgency Level
            Text(
              'Urgency Level',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Normal'),
                    subtitle: const Text('7 days'),
                    value: 'Normal',
                    groupValue: _urgency,
                    onChanged: (value) {
                      setState(() {
                        _urgency = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Urgent'),
                    subtitle: const Text('48 hours'),
                    value: 'Urgent',
                    groupValue: _urgency,
                    onChanged: (value) {
                      setState(() {
                        _urgency = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Submit Request', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
