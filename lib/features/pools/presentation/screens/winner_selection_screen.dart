import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/winner_service.dart';
import '../../../../core/services/voting_service.dart';

class WinnerSelectionScreen extends ConsumerStatefulWidget {
  final String poolId;

  const WinnerSelectionScreen({
    super.key,
    required this.poolId,
  });

  @override
  ConsumerState<WinnerSelectionScreen> createState() => _WinnerSelectionScreenState();
}

enum DrawState { preDraw, liveDraw, completed, voting }
enum SelectionMethod { random, sequential, voting }

class Member {
  final String id;
  final String name;
  final bool hasWon;
  final DateTime? joinDate;

  Member({
    required this.id,
    required this.name,
    this.hasWon = false,
    this.joinDate,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final name = profile != null 
        ? '${profile['first_name']} ${profile['last_name']}'
        : 'Unknown Member';
    
    final joinDateStr = json['join_date'] as String?;
    final joinDate = joinDateStr != null ? DateTime.parse(joinDateStr) : null;
    
    return Member(
      id: json['user_id'],
      name: name,
      hasWon: json['has_won'] ?? false,
      joinDate: joinDate,
    );
  }
}

class _WinnerSelectionScreenState extends ConsumerState<WinnerSelectionScreen> {
  // Theme colors
  final Color _primaryColor = const Color(0xFFF97A53);
  final Color _lightPrimaryColor = const Color(0xFFFFF2EF);
  final Color _scaffoldBgColor = const Color(0xFFF9F9F9);

  // State
  DrawState _currentState = DrawState.preDraw;
  SelectionMethod _selectionMethod = SelectionMethod.random;
  String _currentName = "Waiting...";
  String _winnerName = "";
  double _winningAmount = 0;
  Timer? _timer;
  List<Member> _allMembers = [];
  bool _isLoading = true;

  // Pool data
  Map<String, dynamic>? _poolData;
  bool _canDraw = false;
  String _drawRestrictionReason = '';
  int _currentRound = 1;
  int _winnersNeededForRound = 1;
  int _winnersSelectedForRound = 0;

  // Voting data
  Map<String, dynamic>? _votingPeriod;
  Map<String, dynamic>? _votingStats;

  List<Member> get _eligibleMembers => _allMembers.where((m) => !m.hasWon).toList();
  List<Member> get _pastWinners => _allMembers.where((m) => m.hasWon).toList();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      
      // 1. Fetch Members (sorted by join_date for sequential)
      final membersResponse = await supabase
          .from('pool_members')
          .select('*, profiles(first_name, last_name)')
          .eq('pool_id', widget.poolId)
          .eq('status', 'active')
          .order('join_date', ascending: true);

      final allMembers = (membersResponse as List)
          .map((data) => Member.fromJson(data))
          .toList();

      // 2. Fetch Pool Details & History
      final poolResponse = await supabase
          .from('pools')
          .select('rules, total_rounds, max_members, contribution_amount, start_date')
          .eq('pool_id', widget.poolId)
          .single();
      
      final historyResponse = await supabase
          .from('winner_history')
          .select('round_number')
          .eq('pool_id', widget.poolId);
      
      // 3. Determine Selection Method
      final rules = poolResponse['rules'] as Map<String, dynamic>? ?? {};
      final methodStr = rules['winner_selection_method'] as String? ?? 'Random Draw';
      SelectionMethod method;
      switch (methodStr) {
        case 'Sequential Rotation':
          method = SelectionMethod.sequential;
          break;
        case 'Member Voting':
          method = SelectionMethod.voting;
          break;
        default:
          method = SelectionMethod.random;
      }

      // 4. Calculate Current Round & Winners Needed
      final totalRounds = poolResponse['total_rounds'] as int;
      final startMonth = rules['start_month'] as int? ?? 1;
      final startDateStr = poolResponse['start_date'] as String;
      final startDate = DateTime.parse(startDateStr);
      
      final now = DateTime.now();
      int monthsPassed = (now.year - startDate.year) * 12 + now.month - startDate.month;
      if (now.day < startDate.day) monthsPassed--;
      final int maxAllowedRoundByDate = monthsPassed + 1;

      // Group winners by round
      final Map<int, int> winnersByRound = {};
      for (var w in historyResponse) {
        final r = w['round_number'] as int;
        winnersByRound[r] = (winnersByRound[r] ?? 0) + 1;
      }

      int calculatedCurrentRound = 1;
      int needed = 1;
      int selected = 0;
      
      int membersLeft = allMembers.length;
      int roundsLeft = totalRounds;
      
      for (int r = 1; r <= totalRounds; r++) {
        if (roundsLeft == 0) break;
        
        int winnersForThisRound = (membersLeft / roundsLeft).ceil();
        if (winnersForThisRound < 1 && membersLeft > 0) winnersForThisRound = 1;
        
        final actualWinners = winnersByRound[r] ?? 0;
        
        if (actualWinners < winnersForThisRound) {
          calculatedCurrentRound = r;
          needed = winnersForThisRound;
          selected = actualWinners;
          break;
        } else {
          membersLeft -= actualWinners;
          roundsLeft--;
          if (r == totalRounds) calculatedCurrentRound = totalRounds + 1;
        }
      }

      bool canDraw = true;
      String reason = '';

      // Validation checks
      if (calculatedCurrentRound > totalRounds) {
        canDraw = false;
        reason = 'All rounds are completed!';
      } else if (calculatedCurrentRound < startMonth) {
        canDraw = false;
        reason = 'Draws are scheduled to start from Month $startMonth.\nCurrent Round: $calculatedCurrentRound';
      } else if (calculatedCurrentRound > maxAllowedRoundByDate) {
        canDraw = false;
        final nextDrawDate = DateTime(startDate.year, startDate.month + calculatedCurrentRound - 1, startDate.day);
        final dateStr = '${nextDrawDate.day}/${nextDrawDate.month}/${nextDrawDate.year}';
        reason = 'Round $calculatedCurrentRound is locked until $dateStr.\nPlease wait for the next cycle.';
      } else if (selected >= needed) {
        canDraw = false;
        reason = 'Round $calculatedCurrentRound is complete ($selected/$needed winners selected).';
      }

      // 5. Check Payments & Late Fees
      if (canDraw) {
        final roundStartDate = DateTime(startDate.year, startDate.month + calculatedCurrentRound - 1, startDate.day);
        final contributionAmount = (poolResponse['contribution_amount'] as num).toDouble();
        
        final contributionsResponse = await supabase
            .from('transactions')
            .select('user_id, amount')
            .eq('pool_id', widget.poolId)
            .eq('transaction_type', 'contribution')
            .eq('status', 'completed')
            .gte('created_at', roundStartDate.toIso8601String());
            
        final pendingPenaltiesResponse = await supabase
            .from('transactions')
            .select('user_id')
            .eq('pool_id', widget.poolId)
            .eq('transaction_type', 'penalty')
            .eq('status', 'pending');
            
        final pendingPenaltyUserIds = (pendingPenaltiesResponse as List).map((e) => e['user_id'] as String).toSet();
        
        final Map<String, double> paidAmounts = {};
        for (var t in contributionsResponse) {
          final uid = t['user_id'] as String;
          final amt = (t['amount'] as num).toDouble();
          paidAmounts[uid] = (paidAmounts[uid] ?? 0) + amt;
        }
        
        int fullyPaidCount = 0;
        final totalActiveMembers = allMembers.length;
        
        for (final member in allMembers) {
           final paid = paidAmounts[member.id] ?? 0;
           final hasPendingPenalty = pendingPenaltyUserIds.contains(member.id);
           
           if (paid >= contributionAmount && !hasPendingPenalty) {
             fullyPaidCount++;
           }
        }
        
        if (fullyPaidCount < totalActiveMembers) {
          canDraw = false;
          reason = 'Waiting for payments.\n$fullyPaidCount/$totalActiveMembers members have fully paid (including late fees).';
        }
      }

      // 6. For voting method, check voting period
      Map<String, dynamic>? votingPeriod;
      Map<String, dynamic>? votingStats;
      
      if (method == SelectionMethod.voting && canDraw) {
        votingPeriod = await VotingService.getVotingPeriod(
          poolId: widget.poolId,
          roundNumber: calculatedCurrentRound,
        );
        
        if (votingPeriod != null) {
          votingStats = await VotingService.getVotingStats(
            poolId: widget.poolId,
            roundNumber: calculatedCurrentRound,
          );
        }
      }

      if (mounted) {
        setState(() {
          _allMembers = allMembers;
          _poolData = poolResponse;
          _currentRound = calculatedCurrentRound;
          _winnersNeededForRound = needed;
          _winnersSelectedForRound = selected;
          _canDraw = canDraw;
          _drawRestrictionReason = reason;
          _selectionMethod = method;
          _votingPeriod = votingPeriod;
          _votingStats = votingStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startDraw() async {
    if (!_canDraw) return;

    setState(() => _currentState = DrawState.liveDraw);

    // Start animation for random draw
    if (_selectionMethod == SelectionMethod.random) {
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_eligibleMembers.isNotEmpty) {
          setState(() {
            _currentName = _eligibleMembers[Random().nextInt(_eligibleMembers.length)].name;
          });
        }
      });
    }

    try {
      final supabase = Supabase.instance.client;
      final nextRound = _currentRound;

      // Use WinnerService (it routes to correct RPC based on method)
      await WinnerService.selectWinner(widget.poolId, nextRound);

      // Fetch winner details
      final winnerData = await supabase
          .from('winner_history')
          .select('*, profiles!winner_history_user_id_fkey(first_name, last_name)')
          .eq('pool_id', widget.poolId)
          .eq('round_number', nextRound)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      final winnerProfile = winnerData['profiles'];
      final winnerName = '${winnerProfile['first_name']} ${winnerProfile['last_name']}';
      final winningAmount = (winnerData['amount_won'] as num).toDouble();
      
      _timer?.cancel();
      if (mounted) {
        setState(() {
          _winnerName = winnerName;
          _winningAmount = winningAmount;
          _currentState = DrawState.completed;
          _winnersSelectedForRound++;
        });
      }
    } catch (e) {
      _timer?.cancel();
      if (mounted) {
        setState(() => _currentState = DrawState.preDraw);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting winner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startVotingPeriod() async {
    try {
      await VotingService.startVotingPeriod(
        poolId: widget.poolId,
        roundNumber: _currentRound,
        durationHours: 48,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voting period started! Members can now vote.'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchData(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting voting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _closeVotingPeriod() async {
    try {
      await VotingService.closeVotingPeriod(
        poolId: widget.poolId,
        roundNumber: _currentRound,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voting period closed!'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchData(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error closing voting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToVoting() {
    context.push(
      '/voting/${widget.poolId}/$_currentRound',
      extra: _eligibleMembers.map((m) => {
        'user_id': m.id,
        'profiles': {'first_name': m.name.split(' ').first, 'last_name': m.name.split(' ').last},
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor,
      appBar: AppBar(
        title: const Text('Winner Selection'),
        backgroundColor: _scaffoldBgColor,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentState) {
      case DrawState.preDraw:
        return _buildPreDraw();
      case DrawState.liveDraw:
        return _buildLiveDraw();
      case DrawState.completed:
        return _buildCompleted();
      case DrawState.voting:
        return _buildVotingState();
    }
  }

  Widget _buildPreDraw() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Method Icon
          Icon(
            _selectionMethod == SelectionMethod.voting
                ? Icons.how_to_vote
                : _selectionMethod == SelectionMethod.sequential
                    ? Icons.format_list_numbered
                    : Icons.casino,
            size: 80,
            color: _primaryColor,
          ),
          const SizedBox(height: 32),
          
          // Title
          Text(
            _selectionMethod == SelectionMethod.voting
                ? 'Member Voting'
                : _selectionMethod == SelectionMethod.sequential
                    ? 'Sequential Rotation'
                    : 'Random Draw',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Round Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              'Round $_currentRound • Winner ${_winnersSelectedForRound + 1} of $_winnersNeededForRound',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Restriction Warning
          if (!_canDraw)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade800),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _drawRestrictionReason,
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Method-specific content
          if (_selectionMethod == SelectionMethod.sequential)
            _buildSequentialContent()
          else if (_selectionMethod == SelectionMethod.voting)
            _buildVotingContent()
          else
            _buildRandomContent(),
        ],
      ),
    );
  }

  Widget _buildRandomContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _lightPrimaryColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _primaryColor.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: _primaryColor),
              const SizedBox(width: 12),
              Text(
                '${_eligibleMembers.length} eligible members',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildMembersList(),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_eligibleMembers.isEmpty || !_canDraw) ? null : _startDraw,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: const Text('Start Live Draw', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildSequentialContent() {
    if (_eligibleMembers.isEmpty) {
      return const Center(
        child: Text('No eligible members for sequential rotation'),
      );
    }

    final nextWinner = _eligibleMembers.first;
    final position = _allMembers.indexOf(nextWinner) + 1;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _lightPrimaryColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primaryColor, width: 2),
          ),
          child: Column(
            children: [
              const Text(
                'Next Winner:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 40,
                backgroundColor: _primaryColor,
                child: Text(
                  nextWinner.name[0],
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                nextWinner.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Position #$position in rotation',
                  style: TextStyle(
                    fontSize: 14,
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildMembersList(),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: !_canDraw ? null : _startDraw,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: const Text('Confirm Winner', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildVotingContent() {
    final votingPeriod = _votingPeriod;
    final votingStats = _votingStats;

    if (votingPeriod == null) {
      // No voting period started
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.how_to_vote, size: 48, color: Colors.blue.shade700),
                const SizedBox(height: 16),
                const Text(
                  'Start Voting Period',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Members will have 48 hours to vote for the winner',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildMembersList(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: !_canDraw ? null : _startVotingPeriod,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Text('Start Voting', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      );
    }

    final status = votingPeriod['status'] as String;
    final votesCast = votingStats?['votes_cast'] ?? 0;
    final totalVoters = votingStats?['total_voters'] ?? 1;
    final participationRate = votingStats?['participation_rate'] ?? 0.0;

    if (status == 'open') {
      // Voting in progress
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Voting in Progress',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Votes Cast',
                        '$votesCast/$totalVoters',
                        Icons.how_to_vote,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _navigateToVoting,
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Voting'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: _primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _closeVotingPeriod,
                  icon: const Icon(Icons.lock),
                  label: const Text('Close Voting'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Voting closed, ready to draw
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _lightPrimaryColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryColor),
            ),
            child: Column(
              children: [
                Icon(Icons.lock_clock, size: 48, color: _primaryColor),
                const SizedBox(height: 16),
                const Text(
                  'Voting Closed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$votesCast votes were cast',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _navigateToVoting,
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('View Results'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: _primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _startDraw,
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('Trigger Draw'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.green.shade700, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
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
      ),
    );
  }

  Widget _buildMembersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eligible for This Draw',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _eligibleMembers.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = _eligibleMembers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  child: Text(
                    member.name[0],
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  member.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  Icons.check_circle_outline,
                  color: _primaryColor,
                  size: 20,
                ),
              );
            },
          ),
        ),
        if (_pastWinners.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Past Winners (Excluded)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pastWinners.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = _pastWinners[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    child: Text(
                      member.name[0],
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    member.name,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  subtitle: const Text(
                    'Won previously',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: const Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 20,
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLiveDraw() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Selecting Winner...',
          style: TextStyle(fontSize: 24, color: Colors.grey),
        ),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _lightPrimaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: _primaryColor, width: 4),
          ),
          child: Text(
            _currentName.isNotEmpty ? _currentName.split(' ').first[0] : '?',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _currentName,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCompleted() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ZoomIn(
            child: Icon(Icons.emoji_events, size: 100, color: _primaryColor),
          ),
          const SizedBox(height: 32),
          FadeInUp(
            child: const Text(
              'Congratulations!',
              style: TextStyle(fontSize: 24, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              _winnerName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: Text(
              'You won ₹${_winningAmount.toStringAsFixed(0)}!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _lightPrimaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: _primaryColor),
                  const SizedBox(height: 8),
                  Text(
                    '$_winnerName is now marked as a winner and will be excluded from future draws.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _primaryColor.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          FadeInUp(
            delay: const Duration(milliseconds: 800),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Return to Pool', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingState() {
    return const Center(
      child: Text('Voting State'),
    );
  }
}
