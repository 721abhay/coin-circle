import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SpecialDistributionRequestScreen extends StatefulWidget {
  final String poolId;
  
  const SpecialDistributionRequestScreen({super.key, required this.poolId});

  @override
  State<SpecialDistributionRequestScreen> createState() => _SpecialDistributionRequestScreenState();
}

class _SpecialDistributionRequestScreenState extends State<SpecialDistributionRequestScreen> {
  String? _selectedMemberId;
  String _selectedReason = 'medical_emergency';
  String _urgency = 'normal';
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  final List<Map<String, String>> _reasons = [
    {'value': 'medical_emergency', 'label': 'Medical emergency'},
    {'value': 'job_loss', 'label': 'Job loss'},
    {'value': 'educational_expense', 'label': 'Educational expense'},
    {'value': 'family_emergency', 'label': 'Family emergency'},
    {'value': 'business_opportunity', 'label': 'Business opportunity'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final response = await Supabase.instance.client
          .from('pool_members')
          .select('user_id, profiles(id, first_name, last_name)')
          .eq('pool_id', widget.poolId);

      if (mounted) {
        setState(() {
          _members = (response as List).map((m) {
            final profile = m['profiles'];
            return {
              'id': profile['id'],
              'name': '${profile['first_name']} ${profile['last_name']}',
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading members: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member')),
      );
      return;
    }

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final votingDeadline = _urgency == 'urgent'
          ? DateTime.now().add(const Duration(hours: 48))
          : DateTime.now().add(const Duration(days: 7));

      await Supabase.instance.client.from('special_distributions').insert({
        'pool_id': widget.poolId,
        'recipient_id': _selectedMemberId,
        'amount': amount,
        'reason': _selectedReason,
        'description': _detailsController.text.trim(),
        'urgency': _urgency,
        'voting_deadline': votingDeadline.toIso8601String(),
        'status': 'pending',
      });

      if (mounted) {
        setState(() => _isSubmitting = false);
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
                          _urgency == 'urgent'
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
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting request: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    initialValue: _selectedMemberId,
                    decoration: const InputDecoration(
                      hintText: 'Choose a member',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: _members.map<DropdownMenuItem<String>>((member) {
                      return DropdownMenuItem<String>(
                        value: member['id'] as String,
                        child: Text(member['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMemberId = value;
                      });
                    },
                  ),
            const SizedBox(height: 24),

            // Amount
            Text(
              'Amount Requested',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.attach_money),
                hintText: 'Enter amount',
              ),
            ),
            const SizedBox(height: 24),
            
            // Reason
            Text(
              'Reason for Request',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedReason,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category),
              ),
              items: _reasons.map((reason) {
                return DropdownMenuItem(
                  value: reason['value'],
                  child: Text(reason['label']!),
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
                    value: 'normal',
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
                    value: 'urgent',
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
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Request', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
