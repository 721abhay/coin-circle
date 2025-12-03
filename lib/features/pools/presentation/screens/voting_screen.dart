import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/voting_service.dart';

class VotingScreen extends ConsumerStatefulWidget {
  final String poolId;
  final int roundNumber;
  final List<Map<String, dynamic>> eligibleMembers;

  const VotingScreen({
    super.key,
    required this.poolId,
    required this.roundNumber,
    required this.eligibleMembers,
  });

  @override
  ConsumerState<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends ConsumerState<VotingScreen> {
  final Color _primaryColor = const Color(0xFFF97A53);
  final Color _lightPrimaryColor = const Color(0xFFFFF2EF);
  
  String? _selectedCandidateId;
  Map<String, dynamic>? _userVote;
  Map<String, dynamic>? _votingPeriod;
  Map<String, dynamic>? _votingStats;
  List<Map<String, dynamic>> _voteCounts = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _loadVotingData();
  }

  Future<void> _loadVotingData() async {
    setState(() => _isLoading = true);

    try {
      final period = await VotingService.getVotingPeriod(
        poolId: widget.poolId,
        roundNumber: widget.roundNumber,
      );

      final userVote = await VotingService.getUserVote(
        poolId: widget.poolId,
        roundNumber: widget.roundNumber,
      );

      final stats = await VotingService.getVotingStats(
        poolId: widget.poolId,
        roundNumber: widget.roundNumber,
      );

      // Load vote counts if voting is closed
      List<Map<String, dynamic>> counts = [];
      if (period?['status'] == 'closed' || period?['status'] == 'completed') {
        counts = await VotingService.getVoteCounts(
          poolId: widget.poolId,
          roundNumber: widget.roundNumber,
        );
      }

      if (mounted) {
        setState(() {
          _votingPeriod = period;
          _userVote = userVote;
          _votingStats = stats;
          _voteCounts = counts;
          _selectedCandidateId = userVote?['candidate_id'];
          _showResults = period?['status'] == 'closed' || period?['status'] == 'completed';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading voting data: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitVote() async {
    if (_selectedCandidateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a candidate')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await VotingService.castVote(
        poolId: widget.poolId,
        roundNumber: widget.roundNumber,
        candidateId: _selectedCandidateId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadVotingData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting vote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Vote for Winner'),
        backgroundColor: const Color(0xFFF9F9F9),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_showResults) {
      return _buildResults();
    }

    final isOpen = _votingPeriod?['status'] == 'open';
    final endsAt = _votingPeriod?['ends_at'] as String?;
    final endTime = endsAt != null ? DateTime.parse(endsAt) : null;
    final hasEnded = endTime != null && DateTime.now().isAfter(endTime);

    if (!isOpen || hasEnded) {
      return _buildClosedVoting();
    }

    return _buildVotingInterface();
  }

  Widget _buildVotingInterface() {
    final stats = _votingStats ?? {};
    final votesCast = stats['votes_cast'] ?? 0;
    final totalVoters = stats['total_voters'] ?? 1;
    final participationRate = stats['participation_rate'] ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voting Stats Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Round ${widget.roundNumber} Voting',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'OPEN',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Votes Cast',
                        '$votesCast/$totalVoters',
                        Icons.how_to_vote,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Participation',
                        '${participationRate.toStringAsFixed(0)}%',
                        Icons.people,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Your Vote Status
          if (_userVote != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _lightPrimaryColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: _primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'You voted for:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          _userVote!['candidate']?['full_name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedCandidateId = null),
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Instructions
          Text(
            _userVote == null ? 'Select a candidate to vote for:' : 'Change your vote:',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Candidate List
          ...widget.eligibleMembers.map((member) {
            final memberId = member['user_id'] as String;
            final profile = member['profiles'] as Map<String, dynamic>?;
            final name = profile != null
                ? '${profile['first_name']} ${profile['last_name']}'
                : 'Unknown Member';
            final isSelected = _selectedCandidateId == memberId;

            return GestureDetector(
              onTap: () => setState(() => _selectedCandidateId = memberId),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? _lightPrimaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _primaryColor : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isSelected
                          ? _primaryColor
                          : Colors.grey.shade300,
                      child: Text(
                        name[0],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? _primaryColor : Colors.black87,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: _primaryColor),
                  ],
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitVote,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _userVote == null ? 'Submit Vote' : 'Update Vote',
                      style: const TextStyle(fontSize: 18),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildClosedVoting() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_clock, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text(
              'Voting Period Closed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The voting period for Round ${widget.roundNumber} has ended.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: _primaryColor,
              ),
              child: const Text('Back to Pool'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Voting Results',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          if (_voteCounts.isEmpty)
            const Center(
              child: Text('No votes were cast'),
            )
          else
            ..._voteCounts.asMap().entries.map((entry) {
              final index = entry.key;
              final result = entry.value;
              final name = result['candidate_name'] as String;
              final votes = result['vote_count'] as int;
              final totalVotes = _voteCounts.fold<int>(
                0,
                (sum, item) => sum + (item['vote_count'] as int),
              );
              final percentage = totalVotes > 0 ? (votes / totalVotes * 100) : 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: index == 0 ? _lightPrimaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: index == 0 ? _primaryColor : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (index == 0)
                          Icon(Icons.emoji_events, color: _primaryColor),
                        if (index == 0) const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: index == 0 ? _primaryColor : Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          '$votes ${votes == 1 ? 'vote' : 'votes'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          index == 0 ? _primaryColor : Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _primaryColor,
              ),
              child: const Text('Back to Pool'),
            ),
          ),
        ],
      ),
    );
  }
}
