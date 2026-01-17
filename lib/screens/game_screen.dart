import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/vote_tile.dart';
import '../widgets/primary_button.dart';
import '../game/game_manager.dart';

enum GamePhaseType { day, night, voting, discussion }

class GameScreenNew extends StatefulWidget {
  const GameScreenNew({super.key});

  @override
  State<GameScreenNew> createState() => _GameScreenNewState();
}

class _GameScreenNewState extends State<GameScreenNew> {
  GamePhaseType _phase = GamePhaseType.discussion;
  int _day = 1;
  int _timeRemaining = 90;
  String? _selectedVote;
  bool _hasShownDisconnectDialog = false;
  final List<_PlayerVote> _players = [
    _PlayerVote('Alex', 2, false),
    _PlayerVote('Jordan', 0, false),
    _PlayerVote('Sam', 1, false),
    _PlayerVote('Riley', 0, true),
    _PlayerVote('Casey', 3, false),
  ];

  bool get _hasVoted => _selectedVote != null;

  void _showDisconnectDialog(GameManager manager) {
    if (_hasShownDisconnectDialog) return;
    _hasShownDisconnectDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 12),
            const Text('GAME ENDED'),
          ],
        ),
        content: Text(
          manager.disconnectReason ?? 'Host disconnected. The game has ended.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              manager.clearDisconnectState();
              manager.leaveLANRoom();
              Navigator.of(ctx).pop();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<GameManager>();

    // Handle host disconnect during game
    if (manager.wasDisconnected && !manager.isHost) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasShownDisconnectDialog) {
          _showDisconnectDialog(manager);
        }
      });
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _phase == GamePhaseType.night
                ? [
                    Colors.indigo.shade900.withOpacity(0.3),
                    AppColors.background,
                  ]
                : [
                    Colors.orange.withOpacity(0.1),
                    AppColors.background,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildPhaseContent()),
              if (_phase == GamePhaseType.voting) _buildVotingFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isNight = _phase == GamePhaseType.night;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {},
              ),
              Column(
                children: [
                  Text(
                    'DAY $_day',
                    style: AppTextStyles.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPhaseName(),
                    style: AppTextStyles.headlineMedium,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.people_outline),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isNight
                  ? Colors.indigo.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isNight
                    ? Colors.indigo.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isNight ? Icons.nightlight_round : Icons.wb_sunny,
                  size: 18,
                  color: isNight ? Colors.indigo.shade200 : Colors.orange,
                ),
                const SizedBox(width: 12),
                Text(
                  _formatTime(_timeRemaining),
                  style: AppTextStyles.titleMedium.copyWith(
                    fontFamily: 'monospace',
                    color: isNight ? Colors.indigo.shade200 : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPhaseName() {
    switch (_phase) {
      case GamePhaseType.night:
        return 'NIGHT';
      case GamePhaseType.discussion:
        return 'DISCUSSION';
      case GamePhaseType.voting:
        return 'VOTING';
      case GamePhaseType.day:
      default:
        return 'DAY';
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case GamePhaseType.voting:
        return _buildVotingPhase();
      case GamePhaseType.discussion:
        return _buildDiscussionPhase();
      case GamePhaseType.night:
        return _buildNightPhase();
      default:
        return _buildDiscussionPhase();
    }
  }

  Widget _buildDiscussionPhase() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              const Icon(Icons.forum, size: 48, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'DISCUSSION TIME',
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Talk with other players. Share suspicions, defend yourself, or bluff.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Last Night',
                style: AppTextStyles.labelSmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.dangerous,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Riley was eliminated',
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.error),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButtonLarge(
                label: 'PROCEED TO VOTE',
                icon: Icons.how_to_vote,
                onPressed: () => setState(() => _phase = GamePhaseType.voting),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVotingPhase() {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _players.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final player = _players[index];
        return VoteTile(
          playerName: player.name,
          voteCount: player.votes,
          isSelected: _selectedVote == player.name,
          isEliminated: player.eliminated,
          onVote: () {
            setState(() {
              _selectedVote = player.name;
            });
          },
        );
      },
    );
  }

  Widget _buildNightPhase() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.nightlight_round,
            size: 80,
            color: Colors.indigo,
          ),
          const SizedBox(height: 32),
          Text(
            'NIGHT FALLS',
            style: AppTextStyles.displayMedium.copyWith(
              color: Colors.indigo.shade200,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Close your eyes and wait...',
            style: AppTextStyles.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildVotingFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Column(
        children: [
          if (_hasVoted)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Voting for $_selectedVote',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          PrimaryButtonLarge(
            label: _hasVoted ? 'CONFIRM VOTE' : 'SELECT A PLAYER',
            icon: _hasVoted ? Icons.check : Icons.how_to_vote,
            onPressed: _hasVoted
                ? () => Navigator.pushNamed(context, '/waiting')
                : null,
          ),
        ],
      ),
    );
  }
}

class _PlayerVote {
  final String name;
  final int votes;
  final bool eliminated;

  _PlayerVote(this.name, this.votes, this.eliminated);
}
