import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminKYCApprovalScreen extends StatefulWidget {
  const AdminKYCApprovalScreen({super.key});

  @override
  State<AdminKYCApprovalScreen> createState() => _AdminKYCApprovalScreenState();
}

class _AdminKYCApprovalScreenState extends State<AdminKYCApprovalScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _pendingKYCs = [];
  bool _isLoading = true;
  String _filter = 'pending'; // pending, approved, rejected, all

  @override
  void initState() {
    super.initState();
    _loadPendingKYCs();
  }

  Future<void> _loadPendingKYCs() async {
    setState(() => _isLoading = true);
    try {
      var query = _supabase
          .from('kyc_documents')
          .select('*, profiles!inner(id, full_name, email, phone)');

      if (_filter != 'all') {
        query = query.eq('verification_status', _filter);
      }

      final response = await query.order('submitted_at', ascending: false);

      if (mounted) {
        setState(() {
          _pendingKYCs = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading KYC submissions: $e')),
        );
      }
    }
  }

  Future<void> _approveKYC(String kycId, String userId) async {
    try {
      final adminId = _supabase.auth.currentUser?.id;

      // Update kyc_documents table
      await _supabase.from('kyc_documents').update({
        'verification_status': 'approved',
        'verified_by': adminId,
        'verified_at': DateTime.now().toIso8601String(),
      }).eq('id', kycId);

      // CRITICAL: Update profiles table to mark user as KYC verified
      await _supabase.from('profiles').update({
        'kyc_verified': true,
        'is_verified': true, // Also set is_verified for backward compatibility
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC Approved Successfully! User can now create and join pools.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        _loadPendingKYCs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving KYC: $e')),
        );
      }
    }
  }

  Future<void> _rejectKYC(String kycId, String reason) async {
    try {
      final adminId = _supabase.auth.currentUser?.id;

      await _supabase.from('kyc_documents').update({
        'verification_status': 'rejected',
        'verified_by': adminId,
        'verified_at': DateTime.now().toIso8601String(),
        'rejection_reason': reason,
      }).eq('id', kycId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC Rejected'),
            backgroundColor: Colors.red,
          ),
        );
        _loadPendingKYCs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting KYC: $e')),
        );
      }
    }
  }

  void _showRejectDialog(String kycId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject KYC'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Rejection Reason',
            hintText: 'e.g., Document unclear, details mismatch',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context);
                _rejectKYC(kycId, reasonController.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showKYCDetails(Map<String, dynamic> kyc) {
    final profile = kyc['profiles'] as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade700,
                child: Row(
                  children: [
                    const Icon(Icons.verified_user, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile['full_name'] ?? 'N/A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            profile['email'] ?? 'N/A',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Details
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildDetailRow('Phone', profile['phone'] ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow('Aadhaar Number', kyc['aadhaar_number'] ?? 'N/A'),
                    if (kyc['aadhaar_photo_url'] != null)
                      _buildImagePreview('Aadhaar Photo', kyc['aadhaar_photo_url']),
                    const Divider(),
                    _buildDetailRow('PAN Number', kyc['pan_number'] ?? 'N/A'),
                    if (kyc['pan_photo_url'] != null)
                      _buildImagePreview('PAN Photo', kyc['pan_photo_url']),
                    const Divider(),
                    _buildDetailRow('Bank Account', kyc['bank_account_number'] ?? 'N/A'),
                    _buildDetailRow('IFSC Code', kyc['bank_ifsc_code'] ?? 'N/A'),
                    _buildDetailRow('Bank Verified', kyc['bank_verified'] == true ? 'Yes' : 'No'),
                    const Divider(),
                    if (kyc['selfie_with_id_url'] != null)
                      _buildImagePreview('Selfie with ID', kyc['selfie_with_id_url']),
                    if (kyc['address_proof_url'] != null) ...[
                      const Divider(),
                      _buildImagePreview('Address Proof', kyc['address_proof_url']),
                    ],
                    const Divider(),
                    _buildDetailRow(
                      'Submitted At',
                      DateFormat('MMM dd, yyyy hh:mm a').format(
                        DateTime.parse(kyc['submitted_at']),
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              if (kyc['verification_status'] == 'pending')
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showRejectDialog(kyc['id']);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size(0, 50),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _approveKYC(kyc['id'], kyc['user_id']);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(0, 50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String label, String? url) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            height: 250, // Increased height for better visibility
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                fit: BoxFit.contain, // Ensures the whole image is seen
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / 
                            loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text('Could not load image\n$error', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Approvals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingKYCs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Pending'),
                  selected: _filter == 'pending',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filter = 'pending');
                      _loadPendingKYCs();
                    }
                  },
                ),
                FilterChip(
                  label: const Text('Approved'),
                  selected: _filter == 'approved',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filter = 'approved');
                      _loadPendingKYCs();
                    }
                  },
                ),
                FilterChip(
                  label: const Text('Rejected'),
                  selected: _filter == 'rejected',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filter = 'rejected');
                      _loadPendingKYCs();
                    }
                  },
                ),
                FilterChip(
                  label: const Text('All'),
                  selected: _filter == 'all',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filter = 'all');
                      _loadPendingKYCs();
                    }
                  },
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pendingKYCs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No $_filter KYC submissions',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingKYCs.length,
                        itemBuilder: (context, index) {
                          final kyc = _pendingKYCs[index];
                          final profile = kyc['profiles'] as Map<String, dynamic>;
                          final status = kyc['verification_status'] as String;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: status == 'approved'
                                    ? Colors.green
                                    : status == 'rejected'
                                        ? Colors.red
                                        : Colors.orange,
                                child: Icon(
                                  status == 'approved'
                                      ? Icons.check
                                      : status == 'rejected'
                                          ? Icons.close
                                          : Icons.hourglass_empty,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                profile['full_name'] ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(profile['email'] ?? 'N/A'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Aadhaar: ${kyc['aadhaar_number'] ?? 'N/A'} | PAN: ${kyc['pan_number'] ?? 'N/A'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    'Submitted: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(kyc['submitted_at']))}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showKYCDetails(kyc),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
