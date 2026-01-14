import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game/game_manager.dart';
import '../../models/game_state.dart';
import '../../models/player.dart';
import 'widgets/day_night_transition.dart';
import 'widgets/phase_header.dart';
import 'widgets/player_tile.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String? _selectedTargetId;
  GamePhase? _lastPhase;
  bool _isTransitioning = false;
  final TextEditingController _chatController = TextEditingController();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<GameManager>();

    if (_lastPhase != null && _lastPhase != manager.phase) {
      // Trigger transition for specific phase changes
      if ((_lastPhase == GamePhase.night &&
              manager.phase == GamePhase.discussion) ||
          (_lastPhase == GamePhase.result &&
              manager.phase == GamePhase.night)) {
        if (!_isTransitioning) {
          _isTransitioning = true;
          // We'll show the transition in the Stack below
        }
      }
    }
    _lastPhase = manager.phase;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const PhaseHeader(),
                Expanded(
                  child: _buildPhaseUI(context, manager),
                ),
              ],
            ),
            if (_isTransitioning)
              DayNightTransition(
                phase: manager.phase,
                day: manager.currentDay,
                onFinish: () {
                  setState(() {
                    _isTransitioning = false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseUI(BuildContext context, GameManager manager) {
    final localPlayer = manager.localPlayer;
    if (localPlayer?.role == Role.moderator) {
      return _buildModeratorDashboard(context, manager);
    }

    switch (manager.phase) {
      case GamePhase.night:
        return _buildNightPhase(context, manager);
      case GamePhase.mafiaVoting:
        return _buildNightPhase(context, manager); // Same UI for now
      case GamePhase.discussion:
        return _buildDiscussionPhase(context, manager);
      case GamePhase.voting:
        return _buildVotingPhase(context, manager);
      case GamePhase.result:
        return _buildResultPhase(context, manager);
      default:
        return const Center(child: Text('Loading...'));
    }
  }

  // ════════════════════ Night Phase ════════════════════
  Widget _buildNightPhase(BuildContext context, GameManager manager) {
    final localPlayer = manager.localPlayer;
    if (localPlayer == null || !localPlayer.isAlive) {
      return const Center(child: Text('You are dead. Spectating...'));
    }

    // Check if player is mafia or godfather - show special mafia voting UI
    if (localPlayer.role == Role.mafia || localPlayer.role == Role.godfather) {
      return _buildMafiaNightPhase(context, manager, localPlayer);
    }

    // Non-mafia night phase
    if (manager.hasCompletedNightAction()) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Waiting for other players...',
                style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    // Villagers just wait
    if (localPlayer.role == Role.villager) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nightlight_round, size: 64, color: Colors.indigo),
            SizedBox(height: 16),
            Text('The night is dark...', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Wait for the morning.',
                style: TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
      );
    }

    final targets =
        manager.alivePlayers.where((p) => p.id != localPlayer.id).toList();

    String instruction = 'Choose someone for your night action.';
    if (localPlayer.role == Role.detective)
      instruction = 'Choose someone to investigate.';
    if (localPlayer.role == Role.doctor)
      instruction = 'Choose someone to protect.';
    if (localPlayer.role == Role.vigilante) {
      instruction =
          'Choose someone to shoot. Bullets left: ${localPlayer.bullets}';
      if (localPlayer.bullets == 0) {
        return const Center(
            child: Text('You are out of ammunition. Waiting for morning...',
                textAlign: TextAlign.center));
      }
    }
    if (localPlayer.role == Role.serialKiller)
      instruction = 'Choose someone to eliminate.';
    if (localPlayer.role == Role.escort)
      instruction = 'Choose someone to block.';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(instruction,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.amberAccent)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: targets.length,
            itemBuilder: (context, index) {
              final player = targets[index];
              return PlayerTile(
                player: player,
                isSelectable: true,
                isSelected: _selectedTargetId == player.id,
                onNightAction: () {
                  setState(() {
                    _selectedTargetId = player.id;
                  });
                },
              );
            },
          ),
        ),
        if (_selectedTargetId != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                manager.handleNightAction(localPlayer.id, _selectedTargetId!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Action confirmed.'),
                      duration: Duration(seconds: 2)),
                );
                setState(() {
                  _selectedTargetId = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    localPlayer.role == Role.vigilante ? Colors.red : null,
              ),
              child: Text(localPlayer.role == Role.vigilante
                  ? 'FIRE!'
                  : 'Confirm Action'),
            ),
          ),
      ],
    );
  }

  // ════════════════════ Mafia Night Phase ════════════════════
  Widget _buildMafiaNightPhase(
      BuildContext context, GameManager manager, Player localPlayer) {
    final aliveMafia = manager.aliveMafia();
    final targets = manager.aliveNonMafia();
    final hasVoted = manager.hasMafiaVoted(localPlayer.id);
    final myVote = manager.getMafiaVote(localPlayer.id);

    return Column(
      children: [
        // Show mafia team
        Card(
          margin: const EdgeInsets.all(16),
          color: Colors.red.shade900.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Your Team',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: aliveMafia.map((m) {
                    final isMe = m.id == localPlayer.id;
                    final theirVote = manager.getMafiaVote(m.id);
                    return Chip(
                      avatar: Icon(
                        isMe ? Icons.person : Icons.smart_toy,
                        size: 16,
                        color: theirVote != null ? Colors.green : Colors.white,
                      ),
                      label: Text(
                        isMe ? 'You' : m.name,
                        style: TextStyle(
                          color:
                              theirVote != null ? Colors.green : Colors.white,
                        ),
                      ),
                      backgroundColor: theirVote != null
                          ? Colors.green.shade900.withOpacity(0.5)
                          : Colors.grey.shade800,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        // Show voting status
        if (hasVoted)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              color: Colors.green.shade900.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'You voted for ${manager.getPlayerName(myVote)}',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 8),

        // Target list with vote counts
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: targets.length,
            itemBuilder: (context, index) {
              final target = targets[index];
              final voteCount = manager.getMafiaVoteCount(target.id);
              final isSelected = _selectedTargetId == target.id;
              final isMyVote = myVote == target.id;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: isMyVote
                    ? Colors.red.shade800.withOpacity(0.4)
                    : isSelected
                        ? Colors.red.shade900.withOpacity(0.3)
                        : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: target.isBot
                        ? Colors.grey.shade700
                        : Colors.blue.shade700,
                    child: Icon(
                      target.isBot ? Icons.smart_toy : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    target.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (voteCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '$voteCount ${voteCount == 1 ? 'vote' : 'votes'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      if (!hasVoted) ...[
                        const SizedBox(width: 8),
                        Radio<String>(
                          value: target.id,
                          groupValue: _selectedTargetId,
                          onChanged: (value) {
                            setState(() {
                              _selectedTargetId = value;
                            });
                          },
                          activeColor: Colors.red,
                        ),
                      ],
                    ],
                  ),
                  onTap: hasVoted
                      ? null
                      : () {
                          setState(() {
                            _selectedTargetId = target.id;
                          });
                        },
                ),
              );
            },
          ),
        ),

        // Vote button
        if (!hasVoted && _selectedTargetId != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                manager.submitMafiaVote(localPlayer.id, _selectedTargetId!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'You voted to eliminate ${manager.getPlayerName(_selectedTargetId)}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
                setState(() {
                  _selectedTargetId = null;
                });
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.how_to_vote),
                  SizedBox(width: 8),
                  Text('Cast Vote',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

        // Waiting message after voting
        if (hasVoted)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Waiting for team consensus...',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
      ],
    );
  }

  // ════════════════════ Discussion Phase ════════════════════
  Widget _buildDiscussionPhase(BuildContext context, GameManager manager) {
    if (manager.isOfflineMode) {
      return Column(
        children: [
          if (manager.nightKillTargetId != null) _buildNightResult(manager),
          const Spacer(),
          const Icon(Icons.people_outline, size: 80, color: Colors.orange),
          const SizedBox(height: 24),
          const Text(
            'FIELD TALK ACTIVE',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          const Text(
            'Talk to your friends in real life!\nCoordinate, bluff, and detect.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Text(
              '${manager.discussionSecondsLeft}s REMAINING',
              style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5),
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Text(
              'CLOSE YOUR EYES DURING TRANSITIONS',
              style: TextStyle(
                  color: Colors.white24,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 2),
            ),
          ),
        ],
      );
    }

    // Solo Mode Chat UI
    return Column(
      children: [
        if (manager.nightKillTargetId != null) _buildNightResult(manager),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: ListView.builder(
              reverse: false, // Newest at bottom
              itemCount: manager.chatMessages.length,
              itemBuilder: (context, index) {
                final msg = manager.chatMessages[index];
                final isMe = msg.senderId == manager.localPlayerId;
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.redAccent.withOpacity(0.15)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      border: Border.all(
                          color: isMe
                              ? Colors.redAccent.withOpacity(0.1)
                              : Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.senderName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: isMe ? Colors.redAccent : Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(msg.text,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Chat Input
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: 'SHARE YOUR INTEL...',
                    hintStyle: const TextStyle(
                        color: Colors.white24, fontSize: 12, letterSpacing: 1),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      manager.sendChatMessage(
                          manager.localPlayerId!, val.trim());
                      _chatController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.black, size: 20),
                  onPressed: () {
                    if (_chatController.text.trim().isNotEmpty) {
                      manager.sendChatMessage(
                          manager.localPlayerId!, _chatController.text.trim());
                      _chatController.clear();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNightResult(GameManager manager) {
    final targetName = manager.getPlayerName(manager.nightKillTargetId);
    final isMe = manager.nightKillTargetId == manager.localPlayerId;
    final saved = manager.nightKillSaved ?? false;

    String message;
    if (saved) {
      message = isMe
          ? 'You were attacked but saved by the Doctor!'
          : '$targetName was attacked but saved by the Doctor!';
    } else {
      message = isMe
          ? 'You were eliminated during the night.'
          : '$targetName was eliminated during the night.';
    }

    return Card(
      color: saved ? Colors.green.shade900 : Colors.red.shade900,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(message,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  // ════════════════════ Voting Phase ════════════════════
  Widget _buildVotingPhase(BuildContext context, GameManager manager) {
    final localPlayer = manager.localPlayer;
    if (localPlayer == null || !localPlayer.isAlive) {
      return const Center(child: Text('You are dead. Spectating...'));
    }

    if (manager.hasUserVoted(localPlayer.id)) {
      final votedFor =
          manager.getPlayerName(manager.getUserVote(localPlayer.id));
      return Center(
        child: Text('You voted for $votedFor. Waiting for others...',
            style: const TextStyle(fontSize: 16)),
      );
    }

    return ListView.builder(
      itemCount: manager.alivePlayers.length,
      itemBuilder: (context, index) {
        final player = manager.alivePlayers[index];
        if (player.id == localPlayer.id)
          return const SizedBox.shrink(); // Can't vote for self

        return PlayerTile(
          player: player,
          onVote: () {
            manager.castVote(localPlayer.id, player.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('You voted for ${player.name}.')),
            );
          },
        );
      },
    );
  }

  // ════════════════════ Result Phase ════════════════════
  Widget _buildResultPhase(BuildContext context, GameManager manager) {
    Widget resultMessage;

    if (manager.gameOver) {
      resultMessage = Text(
        '${manager.winningTeam?.toUpperCase()} WIN!',
        style: const TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber),
      );
    } else if (manager.lastEliminatedPlayerId != null) {
      final victimName = manager.getPlayerName(manager.lastEliminatedPlayerId);
      final victimRole = manager.lastEliminatedRole ?? 'Unknown';
      resultMessage = RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(fontSize: 18, color: Colors.white),
          children: [
            TextSpan(text: '$victimName was eliminated. Their role was '),
            TextSpan(
              text: victimRole,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      );
    } else {
      resultMessage = const Text(
        'No one was eliminated. The town is safe... for now.',
        style: TextStyle(fontSize: 18, color: Colors.greenAccent),
        textAlign: TextAlign.center,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: resultMessage,
            ),
          ),
          const SizedBox(height: 24),
          Text('Remaining Players:',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: manager.alivePlayers.length,
              itemBuilder: (context, index) {
                return PlayerTile(player: manager.alivePlayers[index]);
              },
            ),
          ),
          const SizedBox(height: 16),
          if (!manager.gameOver)
            ElevatedButton(
              onPressed: () {
                manager.advancePhase();
                setState(() {
                  _selectedTargetId = null;
                });
              },
              child: const Text('Next Round'),
            ),
          if (manager.gameOver)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Back to Home'),
            ),
        ],
      ),
    );
  }

  Widget _buildModeratorDashboard(BuildContext context, GameManager manager) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'MODERATOR CONTROL PANEL - ${manager.phase.name.toUpperCase()}',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.redAccent),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: manager.players.length,
              itemBuilder: (context, index) {
                final player = manager.players[index];
                if (player.role == Role.moderator)
                  return const SizedBox.shrink();

                return Card(
                  color: player.isAlive
                      ? Colors.white.withOpacity(0.05)
                      : Colors.red.withOpacity(0.1),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(player.role),
                      child: Text(player.name.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(player.name,
                        style: TextStyle(
                          decoration: player.isAlive
                              ? null
                              : TextDecoration.lineThrough,
                          color: player.isAlive ? Colors.white : Colors.white24,
                        )),
                    subtitle: Text(player.role.name.toUpperCase(),
                        style: TextStyle(color: _getRoleColor(player.role))),
                    trailing: player.isAlive
                        ? const Icon(Icons.favorite,
                            color: Colors.green, size: 16)
                        : const Icon(Icons.heart_broken,
                            color: Colors.red, size: 16),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildActionSummary(manager),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () => manager.advancePhase(),
            child: const Text('MANUAL PHASE ADVANCE',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSummary(GameManager manager) {
    // Show summary of what's happening this phase
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'As Moderator, you guide the narrative. Ensure players are ready before advancing.',
              style: TextStyle(color: Colors.amber, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(Role role) {
    switch (role) {
      case Role.mafia:
      case Role.godfather:
        return Colors.red;
      case Role.doctor:
        return Colors.green;
      case Role.detective:
        return Colors.blue;
      case Role.vigilante:
        return Colors.orange;
      case Role.serialKiller:
        return Colors.purple;
      case Role.escort:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
