import 'package:coin_circle/features/pools/presentation/providers/create_pool_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/pool_service.dart';

class CreatePoolScreen extends ConsumerStatefulWidget {
  const CreatePoolScreen({super.key});

  @override
  ConsumerState<CreatePoolScreen> createState() => _CreatePoolScreenState();
}

class _CreatePoolScreenState extends ConsumerState<CreatePoolScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Pool'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / 5,
            backgroundColor: Colors.grey.shade200,
            color: Theme.of(context).primaryColor,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _BasicInfoStep(onNext: _nextStep),
                _FinancialDetailsStep(onNext: _nextStep, onBack: _prevStep),
                _PoolRulesStep(onNext: _nextStep, onBack: _prevStep),
                _AdditionalSettingsStep(onNext: _nextStep, onBack: _prevStep),
                _ReviewStep(onPublish: _publishPool, onBack: _prevStep),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _publishPool() async {
    final state = ref.read(createPoolProvider);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Auto-calculate joining fee based on contribution amount (capped at ₹100)
      double joiningFee = 50.0;
      if (state.amount < 1000) {
        joiningFee = 50.0;
      } else if (state.amount < 3000) {
        joiningFee = 60.0;
      } else if (state.amount < 5000) {
        joiningFee = 70.0;
      } else if (state.amount < 10000) {
        joiningFee = 80.0;
      } else {
        joiningFee = 100.0; // Capped at ₹100
      }
      
      await PoolService.createPool(
        name: state.name,
        description: state.description,
        contributionAmount: state.amount,
        frequency: state.frequency.toLowerCase(),
        maxMembers: state.maxMembers,
        durationMonths: state.duration,
        startDate: DateTime.now().add(const Duration(days: 1)),
        privacy: state.isPrivate ? 'private' : 'public',
        type: 'standard', // Default type
        paymentDay: state.paymentDay, // Day of month for payment
        joiningFee: joiningFee, // Auto-calculated joining fee
      );

      if (mounted) {
        Navigator.pop(context); // Pop loading
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Pool Published!'),
            content: const Text('Your pool has been successfully created. Share the invite code with your friends.'),
            actions: [
              TextButton(
                onPressed: () {
                  context.pop(); // Close dialog
                  context.go('/my-pools'); // Go to My Pools to see the new pool
                },
                child: const Text('View My Pools'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating pool: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _BasicInfoStep extends ConsumerWidget {
  final VoidCallback onNext;

  const _BasicInfoStep({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createPoolProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Basic Information', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade200,
                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: state.name,
            decoration: const InputDecoration(labelText: 'Pool Name', hintText: 'e.g., Office Savings Circle'),
            onChanged: (value) => ref.read(createPoolProvider.notifier).updateName(value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: state.description,
            decoration: const InputDecoration(labelText: 'Description (Optional)', hintText: 'What is this pool for?'),
            maxLines: 3,
            onChanged: (value) => ref.read(createPoolProvider.notifier).updateDescription(value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: state.category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: ['Family', 'Friends', 'Colleagues', 'Community'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) {
              if (value != null) ref.read(createPoolProvider.notifier).updateCategory(value);
            },
          ),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onNext, child: const Text('Next'))),
        ],
      ),
    );
  }
}

class _FinancialDetailsStep extends ConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _FinancialDetailsStep({required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createPoolProvider);
    final totalAmount = state.amount * state.duration * state.maxMembers;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Financial Details', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Text('Contribution Amount', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [50, 100, 200, 500].map((amount) {
              return ChoiceChip(
                label: Text('₹$amount'),
                selected: state.amount == amount,
                onSelected: (selected) {
                  if (selected) ref.read(createPoolProvider.notifier).updateAmount(amount.toDouble());
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: state.amount.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Custom Amount', prefixText: '₹'),
            onChanged: (value) {
              if (value.isNotEmpty) ref.read(createPoolProvider.notifier).updateAmount(double.tryParse(value) ?? 0);
            },
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: state.frequency,
            decoration: const InputDecoration(labelText: 'Frequency'),
            items: ['Weekly', 'Bi-weekly', 'Monthly'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) {
              if (value != null) ref.read(createPoolProvider.notifier).updateFrequency(value);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: state.duration.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Duration (Cycles)'),
            onChanged: (value) {
              if (value.isNotEmpty) ref.read(createPoolProvider.notifier).updateDuration(int.tryParse(value) ?? 10);
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Pool Value:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('₹${NumberFormat('#,###').format(totalAmount)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: onBack, child: const Text('Back'))),
              const SizedBox(width: 16),
              Expanded(child: ElevatedButton(onPressed: onNext, child: const Text('Next'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _PoolRulesStep extends ConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _PoolRulesStep({required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createPoolProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pool Rules', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Text('Maximum Members: ${state.maxMembers}', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: state.maxMembers.toDouble(),
            min: 2,
            max: 50,
            divisions: 48,
            label: state.maxMembers.toString(),
            onChanged: (value) => ref.read(createPoolProvider.notifier).updateMaxMembers(value.toInt()),
          ),
          const SizedBox(height: 24),
          
          // Payment Day - Only for Monthly pools
          if (state.frequency == 'Monthly') ...[
            Text('Payment Day', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: state.paymentDay,
              decoration: const InputDecoration(
                labelText: 'Day of Month',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                helperText: 'Select which day of the month members must pay',
              ),
              items: List.generate(28, (index) => index + 1)
                  .map((day) => DropdownMenuItem(
                        value: day,
                        child: Text('Day $day of every month'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(createPoolProvider.notifier).updatePaymentDay(value);
                }
              },
            ),
            const SizedBox(height: 24),
          ] else if (state.frequency == 'Weekly') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payments due every 7 days from pool start date',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else if (state.frequency == 'Bi-weekly') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payments due every 14 days from pool start date',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          Text('Late Payment Policy', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Late Fee: ₹50 on first day late, then +₹10 each day (50, 60, 70, 80...)',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: state.winnerSelectionMethod,
            decoration: const InputDecoration(labelText: 'Winner Selection Method'),
            items: ['Random Draw', 'Member Voting', 'Sequential Rotation'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) {
              if (value != null) ref.read(createPoolProvider.notifier).updateWinnerSelection(value);
            },
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Private Pool'),
            subtitle: const Text('Only people with the link can join'),
            value: state.isPrivate,
            onChanged: (value) => ref.read(createPoolProvider.notifier).updatePrivacy(value),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: onBack, child: const Text('Back'))),
              const SizedBox(width: 16),
              Expanded(child: ElevatedButton(onPressed: onNext, child: const Text('Next'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdditionalSettingsStep extends ConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _AdditionalSettingsStep({required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createPoolProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Additional Settings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Text('Emergency Fund Allocation: ${state.emergencyFund.toInt()}%', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: state.emergencyFund,
            min: 0,
            max: 20,
            divisions: 20,
            label: '${state.emergencyFund.toInt()}%',
            onChanged: (value) => ref.read(createPoolProvider.notifier).updateEmergencyFund(value),
          ),
          SwitchListTile(
            title: const Text('Enable Chat'),
            value: state.enableChat,
            onChanged: (value) => ref.read(createPoolProvider.notifier).updateEnableChat(value),
          ),
          SwitchListTile(
            title: const Text('Require ID Verification'),
            value: state.requireIdVerification,
            onChanged: (value) => ref.read(createPoolProvider.notifier).updateIdVerification(value),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: onBack, child: const Text('Back'))),
              const SizedBox(width: 16),
              Expanded(child: ElevatedButton(onPressed: onNext, child: const Text('Next'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewStep extends ConsumerWidget {
  final VoidCallback onPublish;
  final VoidCallback onBack;

  const _ReviewStep({required this.onPublish, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createPoolProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review & Publish', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Basic Info'),
          _buildSummaryRow('Name', state.name),
          _buildSummaryRow('Category', state.category),
          const Divider(),
          _buildSectionHeader(context, 'Financials'),
          _buildSummaryRow('Amount', '₹${state.amount}'),
          _buildSummaryRow('Frequency', state.frequency),
          _buildSummaryRow('Duration', '${state.duration} cycles'),
          const Divider(),
          _buildSectionHeader(context, 'Rules'),
          _buildSummaryRow('Members', '${state.maxMembers}'),
          _buildSummaryRow(
            'Payment Schedule',
            state.frequency == 'Monthly'
                ? 'Day ${state.paymentDay} of every month'
                : state.frequency == 'Weekly'
                    ? 'Every 7 days from start date'
                    : 'Every 14 days from start date',
          ),
          _buildSummaryRow('Winner Selection', state.winnerSelectionMethod),
          _buildSummaryRow('Late Fees', '₹50 + ₹10/day (auto-calculated)'),
          _buildSummaryRow('Joining Fee', 'Auto-calculated based on amount'),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: onBack, child: const Text('Back'))),
              const SizedBox(width: 16),
              Expanded(child: ElevatedButton(onPressed: onPublish, child: const Text('Publish Pool'))),
            ],
          ),
          const SizedBox(height: 16),
          Center(child: TextButton(onPressed: () {}, child: const Text('Save as Draft'))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(title, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
