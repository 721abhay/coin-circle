import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/legal_service.dart';

class UserLegalNoticesScreen extends StatefulWidget {
  const UserLegalNoticesScreen({super.key});

  @override
  State<UserLegalNoticesScreen> createState() => _UserLegalNoticesScreenState();
}

class _UserLegalNoticesScreenState extends State<UserLegalNoticesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notices = [];

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    setState(() => _isLoading = true);
    try {
      final notices = await LegalService.getLegalNotices();
      if (mounted) {
        setState(() {
          _notices = notices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notices: $e')),
        );
      }
    }
  }

  Future<void> _acknowledgeNotice(String noticeId) async {
    try {
      await LegalService.acknowledgeLegalNotice(noticeId);
      _loadNotices(); // Reload to update status
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notice acknowledged')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error acknowledging notice: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal Notices'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'No Legal Notices',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You have no pending legal notices.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notices.length,
                  itemBuilder: (context, index) {
                    final notice = _notices[index];
                    final isAcknowledged = notice['status'] == 'acknowledged';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isAcknowledged ? Colors.grey.shade300 : Colors.red.shade300,
                          width: isAcknowledged ? 1 : 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: isAcknowledged ? Colors.grey : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    notice['notice_type'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isAcknowledged ? Colors.grey.shade700 : Colors.red.shade900,
                                    ),
                                  ),
                                ),
                                if (!isAcknowledged)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'ACTION REQUIRED',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              notice['subject'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(notice['content']),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Issued: ${DateFormat('MMM d, yyyy').format(DateTime.parse(notice['issued_at']))}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                                if (!isAcknowledged)
                                  ElevatedButton(
                                    onPressed: () => _acknowledgeNotice(notice['id']),
                                    child: const Text('Acknowledge'),
                                  )
                                else
                                  Row(
                                    children: [
                                      Icon(Icons.check, size: 16, color: Colors.green.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Acknowledged',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
