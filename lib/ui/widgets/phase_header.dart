import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game/game_manager.dart';
import '../../models/game_state.dart';
import '../../models/player.dart';

class PhaseHeader extends StatelessWidget {
  const PhaseHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<GameManager>();
    final phase = manager.phase;

    final phaseData = _getPhaseData(phase, manager);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: phaseData.color.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: phaseData.color.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                phaseData.color.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: phaseData.color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(phaseData.icon,
                            size: 24, color: phaseData.color),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            phaseData.title.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'PHASE ACTIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: phaseData.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (phase == GamePhase.discussion &&
                      manager.discussionSecondsLeft > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${manager.discussionSecondsLeft}S',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              const SizedBox(height: 12),
              Text(
                phaseData.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _PhaseData _getPhaseData(GamePhase phase, GameManager manager) {
    final localPlayer = manager.localPlayer;
    switch (phase) {
      case GamePhase.lobby:
        return _PhaseData(
          icon: Icons.groups,
          title: 'Lobby',
          subtitle: 'Waiting for players to join...',
          color: Colors.grey,
        );
      case GamePhase.night:
        String subtitle = 'The town is asleep. Special roles act now.';
        if (localPlayer != null && localPlayer.isAlive) {
          final role = localPlayer.role;
          if (role == Role.mafia) {
            subtitle = 'Vote with your team to choose a target.';
          } else if (role == Role.doctor) {
            subtitle = 'Choose a player to save.';
          } else if (role == Role.detective) {
            subtitle = 'Choose a player to investigate.';
          } else if (role == Role.villager) {
            subtitle = 'You are a villager. Wait for the morning.';
          }
        }
        return _PhaseData(
          icon: Icons.nightlight_round,
          title: 'Night',
          subtitle: subtitle,
          color: Colors.indigo,
        );
      case GamePhase.mafiaVoting:
        return _PhaseData(
          icon: Icons.how_to_vote,
          title: 'Mafia Voting',
          subtitle: 'The mafia is deciding on a target...',
          color: Colors.deepPurple,
        );
      case GamePhase.discussion:
        return _PhaseData(
          icon: Icons.chat,
          title: 'Discussion',
          subtitle: 'Debate and decide who might be Mafia.',
          color: Colors.orange,
        );
      case GamePhase.voting:
        return _PhaseData(
          icon: Icons.how_to_vote,
          title: 'Voting',
          subtitle: 'Vote to eliminate a player.',
          color: Colors.red,
        );
      case GamePhase.result:
        return _PhaseData(
          icon: Icons.gavel,
          title: 'Result',
          subtitle: 'The verdict is in.',
          color: Colors.amber,
        );
    }
  }
}

class _PhaseData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  _PhaseData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
