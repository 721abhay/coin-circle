import 'package:flutter/material.dart';
import '../../../../core/services/voting_service.dart';

class VotingTab extends StatefulWidget {
  final String poolId;
  final int round;
  final Map<String, dynamic> winner;

  const VotingTab({
    super.key,
    required this.poolId,
    required this.round,
    required this.winner,
  });

  @override
  State<VotingTab> createState() => _VotingTabState();
}

class _VotingTabState extends State<VotingTab> {
  bool _isLoading = false;
  Map<String, dynamic>? _votingStatus;

  @override
  void initState() {
    super.initState();
    _loadVotingStatus();
  }

  Future<void> _loadVotingStatus() async {
    try {
      final status = await VotingService.getVotingStatus(
        poolId: widget.poolId,
        round: widget.round,
      );
      if (mounted) {
        setState(() {
          _votingStatus = status;
        });
      }
    } catch (e) {
      // Handle error
      debugPrint('Error loading voting status: $e');
    }
  }

  Future<void> _castVote(bool vote) async {
    setState(() => _isLoading = true);
    try {
      await VotingService.castVote(
        poolId: widget.poolId,
        round: widget.round,
        vote: vote,
      );
      await _loadVotingStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error casting vote: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_votingStatus == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalMembers = _votingStatus!['total_members'] as int;
    final totalVotes = _votingStatus!['total_votes'] as int;
    final hasVoted = _votingStatus!['has_voted'] as bool;
    final myVote = _votingStatus!['my_vote'] as bool?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWinnerCard(),
          const SizedBox(height: 24),
          _buildProgressCard(totalVotes, totalMembers),
          const SizedBox(height: 24),
          if (!hasVoted)
            _buildVotingActions()
          else
            _buildVotedStatus(myVote),
        ],
      ),
    );
  }

  Widget _buildWinnerCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Proposed Winner',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              widget.winner['full_name'] ?? 'Unknown User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Winning Amount: ?${widget.winner['winning_amount']}',
              style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(int votes, int total) {
    final progress = total > 0 ? votes / total : 0.0;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Voting Progress', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('$votes / $total Votes', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 12),
            const Text(
              'All members must approve the winner for funds to be released.',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingActions() {
    return Column(
      children: [
        const Text(
          'Do you approve this winner?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _castVote(false),
                icon: const Icon(Icons.close),
                label: const Text('Reject'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _castVote(true),
                icon: const Icon(Icons.check),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVotedStatus(bool? vote) {
    final isApproved = vote == true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isApproved ? Colors.green : Colors.red),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isApproved ? Icons.check_circle : Icons.cancel,
            color: isApproved ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Text(
            isApproved ? 'You approved this winner' : 'You rejected this winner',
            style: TextStyle(
              color: isApproved ? Colors.green.shade900 : Colors.red.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
