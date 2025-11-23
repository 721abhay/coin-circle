import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/support_service.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  bool _isLoading = true;
  List<TutorialCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadTutorials();
  }

  Future<void> _loadTutorials() async {
    setState(() => _isLoading = true);
    try {
      final tutorials = await SupportService.getTutorials();
      
      if (tutorials.isEmpty) {
        // Fallback to default tutorials if DB is empty
        _categories = [
          TutorialCategory(
            title: 'Getting Started',
            icon: Icons.rocket_launch,
            color: Colors.blue,
            tutorials: [
              Tutorial(
                title: 'How to Create Your First Pool',
                duration: '3 min',
                description: 'Learn how to set up a savings pool with your friends or family',
                videoUrl: 'https://example.com/tutorial1',
                steps: [
                  'Tap "Create Pool" on the home screen',
                  'Enter pool name and description',
                  'Set contribution amount and frequency',
                  'Define pool rules and duration',
                  'Invite members and start saving!',
                ],
              ),
              Tutorial(
                title: 'Joining an Existing Pool',
                duration: '2 min',
                description: 'Step-by-step guide to join a pool using invitation codes',
                videoUrl: 'https://example.com/tutorial2',
                steps: [
                  'Get invitation code from pool creator',
                  'Tap "Join Pool" on home screen',
                  'Enter the invitation code',
                  'Review pool details and rules',
                  'Confirm and make first payment',
                ],
              ),
              // ... more defaults
            ],
          ),
          // ... more categories
        ];
      } else {
        // Group tutorials by category
        final Map<String, List<Tutorial>> grouped = {};
        
        for (var t in tutorials) {
          final category = t['category'] ?? 'General';
          if (!grouped.containsKey(category)) {
            grouped[category] = [];
          }
          
          grouped[category]!.add(Tutorial(
            title: t['title'],
            duration: t['duration'] ?? 'Unknown',
            description: t['description'],
            videoUrl: t['video_url'] ?? '',
            steps: List<String>.from(t['steps'] ?? []),
          ));
        }

        _categories = grouped.entries.map((entry) {
          IconData icon = Icons.school;
          Color color = Colors.purple;
          
          switch (entry.key) {
            case 'Getting Started':
              icon = Icons.rocket_launch;
              color: Colors.blue;
              break;
            case 'Payments & Wallet':
              icon = Icons.account_balance_wallet;
              color: Colors.green;
              break;
            case 'Winner Selection':
              icon = Icons.emoji_events;
              color: Colors.orange;
              break;
            case 'Security & Privacy':
              icon = Icons.security;
              color = Colors.red;
              break;
            default:
              icon = Icons.school;
              color = Colors.purple;
          }

          return TutorialCategory(
            title: entry.key,
            icon: icon,
            color: color,
            tutorials: entry.value,
          );
        }).toList();
      }
    } catch (e) {
      print('Error loading tutorials: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tutorials')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTutorials,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          return _CategoryCard(category: _categories[index]);
        },
      ),
    );
  }
}

class TutorialCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<Tutorial> tutorials;

  TutorialCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.tutorials,
  });
}

class Tutorial {
  final String title;
  final String duration;
  final String description;
  final String videoUrl;
  final List<String> steps;

  Tutorial({
    required this.title,
    required this.duration,
    required this.description,
    required this.videoUrl,
    required this.steps,
  });
}

class _CategoryCard extends StatelessWidget {
  final TutorialCategory category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: category.color.withOpacity(0.1),
          child: Icon(category.icon, color: category.color),
        ),
        title: Text(
          category.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${category.tutorials.length} tutorials'),
        children: category.tutorials.map((tutorial) {
          return _TutorialTile(tutorial: tutorial, color: category.color);
        }).toList(),
      ),
    );
  }
}

class _TutorialTile extends StatelessWidget {
  final Tutorial tutorial;
  final Color color;

  const _TutorialTile({required this.tutorial, required this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.play_circle_outline, color: color),
      ),
      title: Text(tutorial.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(tutorial.description),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                tutorial.duration,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showTutorialDetails(context, tutorial, color);
      },
      isThreeLine: true,
    );
  }

  void _showTutorialDetails(BuildContext context, Tutorial tutorial, Color color) {
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
              Text(
                tutorial.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    tutorial.duration,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                tutorial.description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_filled, size: 64, color: color),
                      const SizedBox(height: 8),
                      const Text('Video Tutorial'),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to play',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Steps',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...tutorial.steps.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: color,
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 15, height: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Video player coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Watch Tutorial'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: color,
                    foregroundColor: Colors.white,
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
