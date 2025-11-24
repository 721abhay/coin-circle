import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/services/community_service.dart';

class CommunitySupportScreen extends StatefulWidget {
  const CommunitySupportScreen({super.key});

  @override
  State<CommunitySupportScreen> createState() => _CommunitySupportScreenState();
}

class _CommunitySupportScreenState extends State<CommunitySupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Forum')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: CommunityService.getForumPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No posts yet. Start a discussion!'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final profile = post['profiles'] as Map<String, dynamic>?;
              final name = profile?['full_name'] ?? 'Unknown User';
              final createdAt = DateTime.parse(post['created_at']);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16, 
                            backgroundImage: profile?['avatar_url'] != null 
                                ? NetworkImage(profile!['avatar_url']) 
                                : null,
                            child: profile?['avatar_url'] == null 
                                ? const Icon(Icons.person, size: 16) 
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text(
                            timeago.format(createdAt), 
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post['title'] ?? 'No Title',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post['content'] ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.comment_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${post['comments_count'] ?? 0} Comments', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(width: 16),
                          const Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${post['likes_count'] ?? 0} Likes', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreatePostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (titleController.text.isEmpty || contentController.text.isEmpty) return;
                
                setState(() => isLoading = true);
                try {
                  await CommunityService.createPost(
                    titleController.text,
                    contentController.text,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    // Refresh the list
                    this.setState(() {}); 
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                    setState(() => isLoading = false);
                  }
                }
              },
              child: isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
