import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/app_theme.dart';
import '../widgets/player_card.dart';
import '../widgets/primary_button.dart';
import '../game/game_manager.dart';
import '../models/game_state.dart';
import '../models/player.dart' as models;
import 'role_reveal_screen.dart';

class LobbyScreenNew extends StatefulWidget {
  final String playerName;
  final bool isHost;
  final String? roomName;

  const LobbyScreenNew({
    super.key,
    required this.playerName,
    this.isHost = false,
    this.roomName,
  });

  @override
  State<LobbyScreenNew> createState() => _LobbyScreenNewState();
}

class _LobbyScreenNewState extends State<LobbyScreenNew> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startGame() {
    final manager = context.read<GameManager>();
    manager.startGame();

    // Navigate to role reveal with role
    final localPlayer = manager.localPlayer;
    if (localPlayer != null) {
      final role = _mapRole(localPlayer.role);
      final teammates = localPlayer.role == models.Role.mafia ||
              localPlayer.role == models.Role.godfather
          ? manager
              .aliveMafia()
              .map((p) => p.name)
              .where((n) => n != localPlayer.name)
              .toList()
          : null;

      Navigator.pushReplacementNamed(context, '/role-reveal', arguments: {
        'role': role,
        'teammates': teammates,
      });
    }
  }

  GameRole _mapRole(models.Role role) {
    switch (role) {
      case models.Role.mafia:
        return GameRole.mafia;
      case models.Role.godfather:
        return GameRole.godfather;
      case models.Role.doctor:
        return GameRole.doctor;
      case models.Role.detective:
        return GameRole.detective;
      case models.Role.vigilante:
        return GameRole.vigilante;
      case models.Role.serialKiller:
        return GameRole.serialKiller;
      case models.Role.escort:
        return GameRole.escort;
      default:
        return GameRole.villager;
    }
  }

  void _leaveGame() {
    final manager = context.read<GameManager>();
    manager.leaveLANRoom();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  // Show QR code dialog for sharing host IP
  void _showQrDialog(String ip) {
    final qrKey = GlobalKey();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: qrKey,
              child: SizedBox(
                width: 200,
                height: 200,
                child: BarcodeWidget(
                  barcode: Barcode.qrCode(),
                  data: ip,
                  width: 200,
                  height: 200,
                  color: AppColors.textPrimary,
                  backgroundColor: AppColors.surface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Scan this QR to join: $ip', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('SHARE'),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _shareQr(qrKey, ip);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareQr(GlobalKey key, String ip) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cannot capture QR')));
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/mafia_qr.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Join my Mafia room: $ip');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Share failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<GameManager>();
    final players = manager.players;
    final canStart = manager.canStartGame && widget.isHost;
    final localPlayerId = manager.localPlayerId;

    // Auto-navigate when game starts (for non-host)
    if (manager.phase != GamePhase.lobby && !widget.isHost) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final localPlayer = manager.localPlayer;
          if (localPlayer != null) {
            final role = _mapRole(localPlayer.role);
            final teammates = localPlayer.role == models.Role.mafia ||
                    localPlayer.role == models.Role.godfather
                ? manager
                    .aliveMafia()
                    .map((p) => p.name)
                    .where((n) => n != localPlayer.name)
                    .toList()
                : null;

            Navigator.pushReplacementNamed(context, '/role-reveal', arguments: {
              'role': role,
              'teammates': teammates,
            });
          }
        }
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showLeaveDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.roomName?.toUpperCase() ?? 'LOBBY'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _showLeaveDialog,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.groups,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${players.length} PLAYERS',
                                style: AppTextStyles.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            canStart
                                ? 'Ready to start'
                                : players.length < 5
                                    ? 'Need at least 5 players'
                                    : 'Waiting for host...',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: canStart
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                          if (widget.isHost && manager.hostIp != null) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                    ClipboardData(text: manager.hostIp!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('IP copied to clipboard'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.lan,
                                      size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    'IP: ${manager.hostIp}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.copy,
                                      size: 12, color: AppColors.textMuted),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      if (manager.hostIp != null) {
                                        _showQrDialog(manager.hostIp!);
                                      }
                                    },
                                    icon: const Icon(Icons.qr_code,
                                        size: 18, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: canStart
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            canStart
                                ? Icons.check_circle
                                : Icons.hourglass_empty,
                            size: 16,
                            color: canStart
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            canStart ? 'READY' : 'WAITING',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: canStart
                                  ? AppColors.success
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PLAYERS', style: AppTextStyles.labelSmall),
                    Text(
                      '${players.length}/${10}',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: players.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final isHost =
                        player.id == 'host' || player.id.startsWith('host_');
                    final isYou = player.id == localPlayerId;
                    return PlayerCard(
                      name: player.name,
                      isHost: isHost,
                      isYou: isYou,
                      status: PlayerStatus.ready,
                      onTap: widget.isHost && !isYou
                          ? () => _showKickDialog(player)
                          : null,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: widget.isHost
                    ? PrimaryButtonLarge(
                        label: 'START GAME',
                        icon: Icons.play_arrow,
                        onPressed: canStart ? _startGame : null,
                      )
                    : Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Waiting for host to start...',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLeaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Leave Room?'),
        content: const Text('Are you sure you want to leave this room?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveGame();
            },
            child: Text(
              'Leave',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showKickDialog(models.Player player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Kick ${player.name}?'),
        content: const Text('Remove this player from the room?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<GameManager>().kickLANPlayer(player.id);
            },
            child: Text(
              'Kick',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
