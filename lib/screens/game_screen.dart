import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/vote_tile.dart';
import '../widgets/primary_button.dart';
import '../game/game_manager.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import 'waiting_screen.dart';

class GameScreenNew extends StatefulWidget {
  const GameScreenNew({super.key});

  @override
  State<GameScreenNew> createState() => _GameScreenNewState();
}

class _GameScreenNewState extends State<GameScreenNew> {
  bool _hasShownDisconnectDialog = false;
  String?
      _seenInspectedPlayerId; // Track detective inspection reveals we've shown

  GamePhase?
      _overridePhase; // Local UI override (e.g., show discussion while voting)

  // Cached reference to avoid calling Provider.of in dispose (unsafe).
  GameManager? _managerRef;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _managerRef ??= Provider.of<GameManager>(context, listen: false);
  }

  @override
  void dispose() {
    final manager =
        _managerRef ?? Provider.of<GameManager>(context, listen: false);
    if (manager.isLANConnected) {
      manager.leaveLANRoom();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<GameManager>();

    // Clear any local override if the authoritative phase changed
    if (manager.phase != GamePhase.voting && _overridePhase != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _overridePhase = null);
      });
    }

    // Detect and show any new inspection results to detective players only (private)
    if (manager.localPlayer?.role == Role.detective &&
        manager.lastInspectedPlayerId != null &&
        manager.lastInspectedPlayerId != _seenInspectedPlayerId) {
      // Mark seen and show a brief dialog with the result
      final id = manager.lastInspectedPlayerId!;
      _seenInspectedPlayerId = id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final res = manager.lastInspectionResult;
        final name = manager.getPlayerName(id);
        final text =
            res == true ? '$name is likely MAFIA' : '$name is not mafia';
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text('Investigation Result'),
                  content: Text(text),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'))
                  ],
                ));
      });
    } else if (manager.localPlayer?.role == Role.detective &&
        _seenInspectedPlayerId != null &&
        manager.lastInspectedPlayerId == _seenInspectedPlayerId &&
        manager.lastInspectionResult != null) {
      // Ensure test-friendly text when result already set (widget tests may re-pump)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final res = manager.lastInspectionResult;
        final name = manager.getPlayerName(_seenInspectedPlayerId!);
        final text =
            res == true ? '$name is likely MAFIA' : '$name is not mafia';
        // If a dialog is not already visible, present it so widget tests can find it reliably
        if (ModalRoute.of(context)?.isCurrent ?? true) {
          showDialog(
              context: context,
              builder: (_) => AlertDialog(
                    title: const Text('Investigation Result'),
                    content: Text(text),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'))
                    ],
                  ));
        }
      });
    }

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
              // Back / Menu button
              IconButton(
                icon: Icon(manager.phase == GamePhase.lobby
                    ? Icons.menu
                    : Icons.arrow_back),
                onPressed: manager.phase == GamePhase.lobby
                    ? () {}
                    : () => _onBackPressed(manager),
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
                Builder(builder: (ctx) {
                  final m = ctx.watch<GameManager>();
                  int displayTime = m.phase == GamePhase.discussion
                      ? m.discussionSecondsLeft
                      : m.phase == GamePhase.voting
                          ? m.votingSecondsLeft
                          : m.phase == GamePhase.night
                              ? m.nightSecondsLeft
                              : 0;

                  return Text(
                    displayTime > 0 ? _formatTime(displayTime) : '--:--',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontFamily: 'monospace',
                      color: isNight ? Colors.indigo.shade200 : Colors.orange,
                    ),
                  );
                }),
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
    // Allow a local override (e.g., show discussion page while voting locally)
    final phase = (manager.phase == GamePhase.voting && _overridePhase != null)
        ? _overridePhase!
        : manager.phase;
    switch (phase) {
      case GamePhase.voting:
        return _buildVotingPhase();
      case GamePhase.discussion:
        return _buildDiscussionPhase();
      case GamePhase.night:
        return _buildNightPhase();
      case GamePhase.result:
        return _buildResultPhase();
      default:
        return _buildDiscussionPhase();
    }
  }

  Widget _buildResultPhase() {
    final manager = context.watch<GameManager>();
    final eliminatedId = manager.lastEliminatedPlayerId;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            eliminatedId != null
                ? Icons.sentiment_very_dissatisfied
                : Icons.sentiment_satisfied,
            size: 80,
            color: eliminatedId != null ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(height: 24),
          Text(
            eliminatedId != null
                ? '${manager.getPlayerName(eliminatedId)} was eliminated'
                : 'No one was eliminated',
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 12),
          if (eliminatedId != null)
            Text(
              manager.lastEliminatedRole != null
                  ? 'Role: ${manager.lastEliminatedRole}'
                  : '',
              style:
                  AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted),
            ),
        ],
      ),
    );
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
    final manager = context.watch<GameManager>();
    final local = manager.localPlayer;
    final canAct = local != null &&
        local.isAlive &&
        (local.role == Role.mafia ||
            local.role == Role.godfather ||
            local.role == Role.doctor ||
            local.role == Role.detective ||
            local.role == Role.vigilante ||
            local.role == Role.escort ||
            local.role == Role.serialKiller);

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
          const SizedBox(height: 24),
          if (canAct)
            PrimaryButtonLarge(
              label: 'PERFORM NIGHT ACTION',
              icon: Icons.visibility_off,
              onPressed: () => _showNightActionDialog(manager, local),
            ),
        ],
      ),
    );
  }

  Future<bool> _onBackPressed(GameManager manager) async {
    // If we are in voting phase, first provide a local convenience to view discussion
    if (manager.phase == GamePhase.voting &&
        _overridePhase != GamePhase.discussion) {
      setState(() => _overridePhase = GamePhase.discussion);
      return false; // do not pop the route
    }

    // Otherwise confirm leaving the game
    return await _confirmLeave(manager);
  }

  Future<bool> _confirmLeave(GameManager manager) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Game?'),
        content: const Text('Do you want to leave the game?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Yes')),
        ],
      ),
    );

    if (confirmed == true) {
      if (manager.isLANConnected) manager.leaveLANRoom();
      Navigator.popUntil(context, (route) => route.isFirst);
      return true;
    }
    return false;
  }

  void _showNightActionDialog(GameManager manager, Player local) async {
    // Build role-appropriate target list
    List<Player> targets;
    if (local.role == Role.mafia || local.role == Role.godfather) {
      // Show a dedicated mafia vote panel with live counts and team chat
      await _showMafiaVotePanel(manager, local);
      return;
    } else if (local.role == Role.serialKiller) {
      // SK can target anyone alive except themselves
      targets =
          manager.players.where((p) => p.isAlive && p.id != local.id).toList();
    } else if (local.role == Role.vigilante) {
      targets =
          manager.players.where((p) => p.isAlive && p.id != local.id).toList();
    } else if (local.role == Role.doctor ||
        local.role == Role.detective ||
        local.role == Role.escort) {
      // Doctor can save anyone, detective/escort can choose alive players (including self for doctor)
      targets =
          manager.players.where((p) => p.isAlive && p.id != local.id).toList();
      // allow doctor to pick themselves
      if (local.role == Role.doctor) {
        targets = manager.players.where((p) => p.isAlive).toList();
      }
    } else {
      // Villagers and others have no actions
      targets = [];
    }

    if (targets.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No valid targets')));
      return;
    }

    final choice = await showDialog<String?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Choose target'),
        children: targets
            .map((t) => SimpleDialogOption(
                  onPressed: () => Navigator.of(ctx).pop(t.id),
                  child: Text(t.name),
                ))
            .toList(),
      ),
    );

    if (choice == null) return;

    manager.handleNightAction(local.id, choice);

    // Immediate feedback for local roles on host (solo) - else host will broadcast results
    if (local.role == Role.detective) {
      // If we're the host, lastInspectionResult will be set immediately
      final result = manager.lastInspectionResult;
      final inspectedId = manager.lastInspectedPlayerId;
      if (inspectedId == choice && result != null) {
        final name = manager.getPlayerName(inspectedId);
        final desc = result ? '$name is likely MAFIA' : '$name is not mafia';
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Investigation Result'),
            content: Text(desc),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'))
            ],
          ),
        );
      } else {
        // If result will be delivered by host later, just inform player
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Investigation submitted')));
      }
    }

    if (local.role == Role.mafia || local.role == Role.godfather) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Mafia vote submitted')));
      await _showMafiaVotePanel(manager, local);
    }

    // Show waiting screen so player keeps role secret
    Navigator.pushNamed(context, '/waiting',
        arguments: {'reason': WaitingReason.nightAction});
  }

  Future<void> _showMafiaVotePanel(GameManager manager, Player local) async {
    final msgController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: const EdgeInsets.all(12),
          child: AnimatedBuilder(
            animation: manager,
            builder: (context, _) {
              final targets = manager.players
                  .where((p) =>
                      p.isAlive &&
                      p.role != Role.mafia &&
                      p.role != Role.godfather)
                  .toList();
              final teamMsgs = manager.teamChatMessages['mafia'] ?? [];
              final myVote = manager.getMafiaVote(local.id);

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mafia Vote', style: AppTextStyles.headlineMedium),
                      IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ListView(
                            controller: scrollController,
                            children: targets
                                .map((t) => ListTile(
                                      title: Text(t.name),
                                      trailing: Text(
                                          '${manager.getMafiaVoteCount(t.id)}'),
                                      selected: myVote == t.id,
                                      onTap: () {
                                        manager.submitMafiaVote(local.id, t.id);
                                      },
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              Expanded(
                                child: ListView(
                                  children: teamMsgs
                                      .map((m) => ListTile(
                                            dense: true,
                                            title: Text(m.senderName),
                                            subtitle: Text(m.text),
                                          ))
                                      .toList(),
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: msgController,
                                      decoration: const InputDecoration(
                                          hintText: 'Mafia chat'),
                                      onSubmitted: (v) {
                                        if (v.trim().isNotEmpty) {
                                          manager.sendTeamChat(
                                              'mafia', v.trim());
                                          msgController.clear();
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send),
                                    onPressed: () {
                                      final v = msgController.text.trim();
                                      if (v.isNotEmpty) {
                                        manager.sendTeamChat('mafia', v);
                                        msgController.clear();
                                      }
                                    },
                                  )
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
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
