import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PoolTemplatesScreen extends StatelessWidget {
  const PoolTemplatesScreen({super.key});

  final List<PoolTemplate> templates = const [
    PoolTemplate(
      id: 'family_savings',
      name: 'Family Savings Pool',
      description: 'Perfect for family members saving together for common goals',
      icon: Icons.family_restroom,
      color: Colors.blue,
      contributionAmount: 1000.0,
      frequency: 'Monthly',
      duration: 12,
      maxMembers: 6,
      category: 'Family',
      features: [
        'Emergency fund allocation (10%)',
        'Flexible payment dates',
        'Family-only privacy',
        'Voting-based winner selection',
      ],
    ),
    PoolTemplate(
      id: 'office_colleagues',
      name: 'Office Colleagues Pool',
      description: 'Ideal for workplace savings circles',
      icon: Icons.business_center,
      color: Colors.orange,
      contributionAmount: 500.0,
      frequency: 'Monthly',
      duration: 12,
      maxMembers: 12,
      category: 'Colleagues',
      features: [
        'Random draw selection',
        'Auto-pay enabled',
        'Strict late payment policy',
        'Professional verification required',
      ],
    ),
    PoolTemplate(
      id: 'friends_vacation',
      name: 'Friends Vacation Fund',
      description: 'Save together for an amazing group vacation',
      icon: Icons.beach_access,
      color: Colors.green,
      contributionAmount: 200.0,
      frequency: 'Weekly',
      duration: 24,
      maxMembers: 10,
      category: 'Friends',
      features: [
        'Goal-based savings',
        'Flexible contributions',
        'Group chat enabled',
        'Photo sharing',
      ],
    ),
    PoolTemplate(
      id: 'emergency_fund',
      name: 'Emergency Fund Pool',
      description: 'Build a safety net with your trusted circle',
      icon: Icons.health_and_safety,
      color: Colors.red,
      contributionAmount: 300.0,
      frequency: 'Monthly',
      duration: 6,
      maxMembers: 8,
      category: 'Community',
      features: [
        'Emergency withdrawal option',
        'Unanimous voting required',
        'Higher trust score needed',
        'Quick disbursement',
      ],
    ),
    PoolTemplate(
      id: 'holiday_savings',
      name: 'Holiday Savings Pool',
      description: 'Save throughout the year for holiday expenses',
      icon: Icons.celebration,
      color: Colors.purple,
      contributionAmount: 150.0,
      frequency: 'Monthly',
      duration: 12,
      maxMembers: 15,
      category: 'Community',
      features: [
        'Seasonal milestones',
        'Bonus contributions welcome',
        'Gift exchange integration',
        'Holiday reminders',
      ],
    ),
    PoolTemplate(
      id: 'education_fund',
      name: 'Education Fund Pool',
      description: 'Invest in education together',
      icon: Icons.school,
      color: Colors.indigo,
      contributionAmount: 800.0,
      frequency: 'Monthly',
      duration: 18,
      maxMembers: 10,
      category: 'Family',
      features: [
        'Long-term commitment',
        'Education expense tracking',
        'Milestone celebrations',
        'Scholarship integration',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pool Templates'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Choose a Template',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start with a pre-configured pool template and customize as needed',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ...templates.map((template) => _TemplateCard(template: template)),
        ],
      ),
    );
  }
}

class PoolTemplate {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final double contributionAmount;
  final String frequency;
  final int duration;
  final int maxMembers;
  final String category;
  final List<String> features;

  const PoolTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.contributionAmount,
    required this.frequency,
    required this.duration,
    required this.maxMembers,
    required this.category,
    required this.features,
  });
}

class _TemplateCard extends StatelessWidget {
  final PoolTemplate template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          _showTemplateDetails(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: template.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(template.icon, color: template.color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.account_balance_wallet,
                    label: '₹${template.contributionAmount.toStringAsFixed(0)}/${template.frequency}',
                  ),
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: '${template.duration} months',
                  ),
                  _InfoChip(
                    icon: Icons.people,
                    label: '${template.maxMembers} members',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplateDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: template.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(template.icon, color: template.color, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          template.category,
                          style: TextStyle(
                            color: template.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                template.description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
              const Text(
                'Template Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.account_balance_wallet,
                label: 'Contribution',
                value: '₹${template.contributionAmount.toStringAsFixed(0)} per ${template.frequency}',
              ),
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Duration',
                value: '${template.duration} months',
              ),
              _DetailRow(
                icon: Icons.people,
                label: 'Max Members',
                value: '${template.maxMembers} people',
              ),
              const SizedBox(height: 24),
              const Text(
                'Included Features',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...template.features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: template.color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(feature, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/create-pool', extra: {'template': template.id});
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: template.color,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Use This Template',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
