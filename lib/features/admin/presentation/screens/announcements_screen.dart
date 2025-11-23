import 'package:flutter/material.dart';

class AnnouncementsScreen extends StatefulWidget {
  final String? poolId;
  const AnnouncementsScreen({super.key, this.poolId});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isImportant = false;
  bool _requireAck = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New Announcement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Mark as Important'),
                    value: _isImportant,
                    onChanged: (val) => setState(() => _isImportant = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Require Acknowledgment'),
                    value: _requireAck,
                    onChanged: (val) => setState(() => _requireAck = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement Sent!')));
                        _titleController.clear();
                        _messageController.clear();
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Send to All Members'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildHistoryItem('Welcome to the Pool!', '2 days ago', 28),
          _buildHistoryItem('Payment Reminder', '5 days ago', 25),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, String date, int readCount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Sent: $date'),
        trailing: Chip(
          label: Text('$readCount read'),
          backgroundColor: Colors.green.shade100,
          labelStyle: TextStyle(color: Colors.green.shade800),
        ),
      ),
    );
  }
}
