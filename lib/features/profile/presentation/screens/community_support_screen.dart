import 'package:flutter/material.dart';

class CommunitySupportScreen extends StatelessWidget {
  const CommunitySupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Forum')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
                      const SizedBox(width: 8),
                      Text('User ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('2h ago', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How do I handle late payments in my pool?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'I have a member who is consistently late. What are the best practices for handling this without ruining the relationship?',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.comment_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text('12 Comments', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 16),
                      const Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text('5 Likes', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
