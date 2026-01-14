import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/game_manager.dart';
import '../models/game_state.dart';
import '../network/lan_communication.dart';
import 'how_to_play_screen.dart';
import 'lobby_screen.dart';
import 'player_setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.read<GameManager>();
    const crimson = Color(0xFF9E1B32);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Cinematic Background
          Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1A0505),
                      Colors.black,
                      const Color(0xFF1A0505),
                    ],
                  ),
                ),
              );
            },
          ),
          // Dark Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.8),
                  Colors.black,
                ],
              ),
            ),
          ),
          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.security,
                      size: 80,
                      color: crimson,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Omertà',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 10,
                          ),
                    ),
                    Text(
                      'CITY OF DECEPTION',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: crimson,
                            letterSpacing: 6,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 80),
                    _buildGameModeButton(
                      context,
                      manager: manager,
                      title: 'SOLO OPERATION',
                      subtitle: 'Infiltrate with AI agents',
                      icon: Icons.psychology,
                      mode: GameMode.soloBots,
                      accentColor: crimson,
                    ),
                    const SizedBox(height: 20),
                    _buildGameModeButton(
                      context,
                      manager: manager,
                      title: 'OFFLINE SYNDICATE',
                      subtitle: 'Gather your local crew',
                      icon: Icons.groups_3,
                      mode: GameMode.offlineP2P,
                      accentColor: crimson,
                    ),
                    const SizedBox(height: 48),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.menu_book,
                            color: Colors.white60, size: 18),
                        label: const Text('RULES OF ENGAGEMENT',
                            style: TextStyle(
                                color: Colors.white60,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                fontSize: 12)),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const HowToPlayScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameModeButton(
    BuildContext context, {
    required GameManager manager,
    required String title,
    required String subtitle,
    required IconData icon,
    required GameMode mode,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.03),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          elevation: 0,
        ),
        onPressed: () {
          if (mode == GameMode.soloBots) {
            manager.setMode(mode);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlayerSetupScreen()),
            );
          } else {
            _showP2PDialog(context, manager);
          }
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: accentColor.withOpacity(0.2)),
              ),
              child: Icon(icon, size: 28, color: accentColor),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white38)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: accentColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  void _showP2PDialog(BuildContext context, GameManager manager) {
    const crimson = Color(0xFF9E1B32);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) => Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: crimson.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: crimson.withOpacity(0.1),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_tethering, size: 64, color: crimson),
                const SizedBox(height: 24),
                const Text(
                  'SYNDICATE SETUP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'DESIGNATE A BOSS TO HOST THE NETWORKS. OTHERS SUBMIT TO THE CREW.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      height: 1.6),
                ),
                const SizedBox(height: 40),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: crimson,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 10,
                          shadowColor: crimson.withOpacity(0.4),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          final lan = LANCommunication(isHost: true);
                          manager.setMode(GameMode.offlineP2P,
                              comm: lan, isHost: true);
                          manager.initializeOfflineGame('Boss', host: true);
                          manager.attachReceiver(lan);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const LobbyScreen()),
                          );
                        },
                        child: const Text('BE THE BOSS',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          side: BorderSide(color: crimson.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          final lan = LANCommunication(isHost: false);
                          manager.setMode(GameMode.offlineP2P,
                              comm: lan, isHost: false);
                          manager.initializeOfflineGame('Associate',
                              host: false);
                          manager.attachReceiver(lan);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const LobbyScreen()),
                          );
                        },
                        child: const Text('JOIN CREW',
                            style: TextStyle(
                                color: crimson,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
