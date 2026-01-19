import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/vote_tile.dart';
import '../widgets/primary_button.dart';
import '../game/game_manager.dart';
import '../models/game_state.dart';
import 'waiting_screen.dart';

class GameScreenNew extends StatefulWidget {
  const GameScreenNew({super.key});

  @override
  State<GameScreenNew> createState() => _GameScreenNewState();
}

class _GameScreenNewState extends State<GameScreenNew> {
  int _timeRemaining = 90;
  bool _hasShownDisconnectDialog = false;

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
  void dispose() {
    final manager = context.read<GameManager>();
    if (manager.isLANConnected) {
      manager.leaveLANRoom();
    }
    super.dispose();
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

    return WillPopScope(
      onWillPop: () async {
        final manager = context.read<GameManager>();
        // Disconnect from LAN when leaving the game
        if (manager.isLANConnected) {
          manager.leaveLANRoom();
        }
        return true;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: manager.phase == GamePhase.night
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
                if (manager.phase == GamePhase.voting) _buildVotingFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final manager = context.watch<GameManager>();
    final isNight = manager.phase == GamePhase.night;
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
                    manager.phase == GamePhase.night
                        ? 'NIGHT ${manager.currentDay}'
                        : 'DAY ${manager.currentDay}',
                    style: AppTextStyles.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPhaseName(),
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Builder(builder: (ctx) {
                    final manager = ctx.watch<GameManager>();
                    int? timeLeft;
                    if (manager.phase == GamePhase.discussion)
                      timeLeft = manager.discussionSecondsLeft;
                    if (manager.phase == GamePhase.voting)
                      timeLeft = manager.votingSecondsLeft;
                    if (manager.phase == GamePhase.night)
                      timeLeft = manager.nightSecondsLeft;
                    if (timeLeft != null && timeLeft > 0) {
                      return Text(
                        'Time left: ${_formatTime(timeLeft)}',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textMuted),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
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
    final manager = context.watch<GameManager>();
    switch (manager.phase) {
      case GamePhase.night:
        return 'NIGHT';
      case GamePhase.discussion:
        return 'DISCUSSION';
      case GamePhase.voting:
        return 'VOTING';
      case GamePhase.lobby:
      case GamePhase.result:
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
    final manager = context.watch<GameManager>();
    switch (manager.phase) {
      case GamePhase.voting:
        return _buildVotingPhase();
      case GamePhase.discussion:
        return _buildDiscussionPhase();
      case GamePhase.night:
        return _buildNightPhase();
      default:
        return _buildDiscussionPhase();
    }
  }

  Widget _buildDiscussionPhase() {
    final manager = context.watch<GameManager>();
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
                  color: ((manager.nightKillTargetId != null &&
                              manager.nightKillSaved != true) ||
                          manager.lastEliminatedPlayerId != null)
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: ((manager.nightKillTargetId != null &&
                                  manager.nightKillSaved != true) ||
                              manager.lastEliminatedPlayerId != null)
                          ? AppColors.error.withOpacity(0.3)
                          : AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      ((manager.nightKillTargetId != null &&
                                  manager.nightKillSaved != true) ||
                              manager.lastEliminatedPlayerId != null)
                          ? Icons.dangerous
                          : Icons.info_outline,
                      color: ((manager.nightKillTargetId != null &&
                                  manager.nightKillSaved != true) ||
                              manager.lastEliminatedPlayerId != null)
                          ? AppColors.error
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        manager.nightKillTargetId != null
                            ? (manager.nightKillSaved == true
                                ? '${manager.getPlayerName(manager.nightKillTargetId)} was targeted but saved'
                                : '${manager.getPlayerName(manager.nightKillTargetId)} was eliminated')
                            : (manager.lastEliminatedPlayerId != null
                                ? '${manager.getPlayerName(manager.lastEliminatedPlayerId)} was eliminated'
                                : 'No one was eliminated last night'),
                        style: AppTextStyles.bodyLarge.copyWith(
                            color: ((manager.nightKillTargetId != null &&
                                        manager.nightKillSaved != true) ||
                                    manager.lastEliminatedPlayerId != null)
                                ? AppColors.error
                                : AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButtonLarge(
                label: 'PROCEED TO VOTE',
                icon: Icons.how_to_vote,
                onPressed: () {
                  final manager = context.read<GameManager>();
                  if (manager.isHost) {
                    manager.advancePhase();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Only the host can advance the phase')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVotingPhase() {
    final manager = context.watch<GameManager>();
    final localId = manager.localPlayerId;
    final alivePlayers = manager.players.where((p) => p.isAlive).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: alivePlayers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final player = alivePlayers[index];
        return VoteTile(
          playerName: player.name,
          voteCount: manager.getVoteCount(player.id),
          isSelected: manager.getUserVote(localId ?? '') == player.id,
          isEliminated: !player.isAlive,
          onVote: () {
            if (localId != null && player.id != localId) {
              manager.castVote(localId, player.id);
            }
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
    final manager = context.watch<GameManager>();
    final localId = manager.localPlayerId;
    final selectedId = localId == null ? null : manager.getUserVote(localId);
    final selectedName = selectedId == null
        ? null
        : manager.players.firstWhere((p) => p.id == selectedId).name;

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
          if (selectedName != null)
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
                    'Voting for $selectedName',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          PrimaryButtonLarge(
            label: selectedName != null ? 'CONFIRM VOTE' : 'SELECT A PLAYER',
            icon: selectedName != null ? Icons.check : Icons.how_to_vote,
            onPressed: selectedName != null
                ? () => Navigator.pushNamed(context, '/waiting',
                    arguments: {'reason': WaitingReason.voting})
                : null,
          ),
        ],
      ),
    );
  }
}
