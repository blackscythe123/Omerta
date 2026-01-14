import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game/game_manager.dart';
import '../../models/game_state.dart';
import 'game_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  @override
  void initState() {
    super.initState();
    // Start P2P services if in offline mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final manager = context.read<GameManager>();
      if (manager.mode == GameMode.offlineP2P) {
        manager.startP2P();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<GameManager>();

    // Auto-navigate to GameScreen if the host started the game
    if (manager.phase != GamePhase.lobby) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const GameScreen()),
          );
        }
      });
    }

    final canStart = manager.canStartGame;
    final config = manager.currentConfig;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          manager.mode == GameMode.soloBots ? 'SOLO LOBBY' : 'SYNDICATE LOBBY',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.red.withOpacity(0.05),
              Colors.black,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${manager.players.length} CREW MEMBERS',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      canStart
                          ? 'READY TO INFILTRATE'
                          : manager.isOfflineMode
                              ? (manager.isHost
                                  ? 'WAITING FOR ASSOCIATES...\n(THEY MUST CONNECT TO YOUR HOTSPOT)'
                                  : 'WAITING FOR THE BOSS TO START...')
                              : 'WAITING FOR AT LEAST 5 AGENTS...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            canStart ? Colors.greenAccent : Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Role Config Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRoleChip(Icons.person_off, '${config.mafiaCount}',
                        'MAFIA', Colors.redAccent),
                    _buildRoleChip(Icons.medical_services,
                        '${config.doctorCount}', 'DOCTOR', Colors.greenAccent),
                    _buildRoleChip(Icons.search, '${config.detectiveCount}',
                        'INTEL', Colors.blueAccent),
                    _buildRoleChip(Icons.person, '${config.villagerCount}',
                        'CIVILIANS', Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'MANIFEST:',
                style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 12),
              ),
              const SizedBox(height: 12),

              // Player list
              Expanded(
                child: ListView.builder(
                  itemCount: manager.players.length,
                  itemBuilder: (context, index) {
                    final player = manager.players[index];
                    final isMe = player.id == manager.localPlayerId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.white.withOpacity(0.1)
                            : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isMe
                              ? Colors.redAccent.withOpacity(0.3)
                              : Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: player.isBot
                                ? Colors.grey.shade800
                                : Colors.redAccent.withOpacity(0.2),
                            child: Icon(
                              player.isBot ? Icons.smart_toy : Icons.person,
                              color: player.isBot
                                  ? Colors.white54
                                  : Colors.redAccent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              player.name.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.white : Colors.white70,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          if (isMe)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (manager.currentConfig.isModeratorMode &&
                              player.id == manager.moderatorId) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'MODERATOR',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          if (manager.isHost &&
                              manager.mode == GameMode.offlineP2P) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.gavel,
                                  color: player.id == manager.moderatorId
                                      ? Colors.greenAccent
                                      : Colors.amberAccent,
                                  size: 20),
                              tooltip: player.id == manager.moderatorId
                                  ? 'Unassign Moderator'
                                  : 'Assign as Moderator',
                              onPressed: () => manager.assignModerator(
                                  player.id == manager.moderatorId
                                      ? null
                                      : player.id),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Start button
              const SizedBox(height: 16),
              if (manager.isHost)
                ElevatedButton(
                  onPressed: canStart
                      ? () {
                          manager.startGame();
                          // Host navigates immediately
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => const GameScreen()),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    disabledBackgroundColor: Colors.grey.shade900,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    shadowColor: Colors.redAccent.withOpacity(0.5),
                  ),
                  child: const Text(
                    'EXECUTE MISSION',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  child: const Text(
                    'WAITING FOR MISSION COMMANDER...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(
      IconData icon, String count, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          label,
          style: const TextStyle(
              color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
