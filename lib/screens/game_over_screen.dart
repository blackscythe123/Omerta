import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../game/game_manager.dart';

enum WinningTeam { mafia, town, serialKiller }

class GameOverScreen extends StatelessWidget {
  final WinningTeam winner;
  final String? playerRole;
  final bool didWin;

  const GameOverScreen({
    super.key,
    this.winner = WinningTeam.town,
    this.playerRole,
    this.didWin = true,
  });

  Color get _winnerColor {
    switch (winner) {
      case WinningTeam.mafia:
        return AppColors.mafia;
      case WinningTeam.serialKiller:
        return Colors.purple;
      case WinningTeam.town:
      default:
        return AppColors.town;
    }
  }

  IconData get _winnerIcon {
    switch (winner) {
      case WinningTeam.mafia:
        return Icons.person_off;
      case WinningTeam.serialKiller:
        return Icons.warning_amber;
      case WinningTeam.town:
      default:
        return Icons.groups;
    }
  }

  String get _winnerTitle {
    switch (winner) {
      case WinningTeam.mafia:
        return 'MAFIA WINS';
      case WinningTeam.serialKiller:
        return 'SERIAL KILLER WINS';
      case WinningTeam.town:
      default:
        return 'TOWN WINS';
    }
  }

  String get _winnerSubtitle {
    switch (winner) {
      case WinningTeam.mafia:
        return 'The syndicate has taken over the city';
      case WinningTeam.serialKiller:
        return 'Only the killer remains standing';
      case WinningTeam.town:
      default:
        return 'The innocent have prevailed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.3),
            radius: 1.5,
            colors: [
              _winnerColor.withOpacity(0.2),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: _winnerColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: _winnerColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: _winnerColor.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    _winnerIcon,
                    size: 64,
                    color: _winnerColor,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'GAME OVER',
                  style: AppTextStyles.labelSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  _winnerTitle,
                  style: AppTextStyles.displayMedium.copyWith(
                    color: _winnerColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _winnerSubtitle,
                  style: AppTextStyles.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'YOUR RESULT',
                        style: AppTextStyles.labelSmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            didWin ? Icons.emoji_events : Icons.close,
                            size: 32,
                            color:
                                didWin ? AppColors.secondary : AppColors.error,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            didWin ? 'VICTORY' : 'DEFEAT',
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: didWin
                                  ? AppColors.secondary
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      if (playerRole != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'You were the $playerRole',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                PrimaryButtonLarge(
                  label: 'PLAY AGAIN',
                  icon: Icons.replay,
                  onPressed: () {
                    final manager =
                        Provider.of<GameManager>(context, listen: false);
                    // If connected via LAN, try to restart in-place
                    if (manager.isLANConnected) {
                      if (manager.isHost) {
                        // Preserve hosting when we navigate back to the lobby for a restart
                        manager.preserveRoomForNextDispose();
                        manager.restartGame();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/lobby',
                          (route) => false,
                          arguments: {
                            'name': manager.localPlayer?.name ?? 'Player',
                            'isHost': true,
                            'roomName': manager.currentRoom?.roomName,
                          },
                        );
                      } else {
                        manager.requestRestart();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/lobby',
                          (route) => false,
                          arguments: {
                            'name': manager.localPlayer?.name ?? 'Player',
                            'isHost': false,
                            'roomName': manager.currentRoom?.roomName,
                          },
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Requested restart from host')));
                      }
                    } else {
                      // Offline: just restart locally and go to lobby
                      manager.restartGame();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/lobby',
                        (route) => false,
                        arguments: {
                          'name': manager.localPlayer?.name ?? 'Player',
                          'isHost': true,
                          'roomName': null,
                        },
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    final manager =
                        Provider.of<GameManager>(context, listen: false);
                    if (manager.isLANConnected) manager.leaveLANRoom();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  },
                  child: const Text('Back to Home'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
