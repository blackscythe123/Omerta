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
import 'widgets/countdown_overlay.dart';
import 'widgets/room_settings_dialog.dart';

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
  final TextEditingController _chatController = TextEditingController();
  bool _hasShownDisconnectDialog = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _startGame() {
    final manager = context.read<GameManager>();

    // Start countdown instead of immediate start
    manager.startGameCountdown();
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

  void _showRoomSettings(BuildContext context, GameManager manager) {
    final room = manager.currentRoom;
    if (room == null) return;

    showDialog(
      context: context,
      builder: (ctx) => RoomSettingsDialog(
        currentMaxPlayers: room.maxPlayers,
        currentIsPrivate: room.isPrivate,
        currentPin: manager.roomPin,
        currentChatEnabled: room.chatEnabled,
        currentModeratorMode: room.moderatorMode,
        currentBotEnabled: room.botsEnabled,
        currentBotCount: room.botCount,
        onSave: (
            {maxPlayers,
            isPrivate,
            newPin,
            chatEnabled,
            moderatorMode,
            botsEnabled,
            botCount}) {
          manager.updateRoomSettings(
            maxPlayers: maxPlayers,
            isPrivate: isPrivate,
            newPin: newPin,
            chatEnabled: chatEnabled,
            moderatorMode: moderatorMode,
            botsEnabled: botsEnabled,
            botCount: botCount,
          );

          // Show confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room settings updated'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

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
            const Text('DISCONNECTED'),
          ],
        ),
        content: Text(
          manager.disconnectReason ?? 'Connection to host was lost.',
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

  // Generate QR data string
  // Format: ip:port|pin (pin only for private rooms)
  String _generateQrData(String ip, int port, String? pin) {
    final baseData = '$ip:$port';
    if (pin != null && pin.isNotEmpty) {
      return '$baseData|$pin';
    }
    return baseData;
  }

  // Show QR code dialog for sharing host IP:PORT
  void _showQrDialog(String ip, int port) {
    final qrKey = GlobalKey();
    final manager = context.read<GameManager>();
    final pin = manager.roomPin;
    final isPrivate = manager.isRoomPrivate;
    final qrData = _generateQrData(ip, port, pin);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPrivate) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, color: AppColors.warning, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'PRIVATE ROOM',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            RepaintBoundary(
              key: qrKey,
              child: SizedBox(
                width: 200,
                height: 200,
                child: BarcodeWidget(
                  barcode: Barcode.qrCode(),
                  data: qrData,
                  width: 200,
                  height: 200,
                  color: AppColors.textPrimary,
                  backgroundColor: AppColors.surface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Scan this QR to join', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text(
              '$ip:$port',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            if (isPrivate && pin != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.key, size: 14, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Text(
                      'PIN: $pin',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.warning,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                    await _shareQr(qrKey, ip, port,
                        pin: pin, isPrivate: isPrivate);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareQr(GlobalKey key, String ip, int port,
      {String? pin, bool isPrivate = false}) async {
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

      final shareText = isPrivate && pin != null
          ? 'Join my Mafia room: $ip:$port (PIN: $pin)'
          : 'Join my Mafia room: $ip:$port';

      await Share.shareXFiles([XFile(file.path)], text: shareText);
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

    // Handle disconnect
    if (manager.wasDisconnected && !widget.isHost) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasShownDisconnectDialog) {
          _showDisconnectDialog(manager);
        }
      });
    }

    // Auto-navigate when game starts
    if (manager.phase != GamePhase.lobby) {
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
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(widget.roomName?.toUpperCase() ?? 'LOBBY'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _showLeaveDialog,
              ),
              actions: [
                // Room settings button (host only)
                if (widget.isHost && manager.mode == GameMode.offlineP2P)
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => _showRoomSettings(context, manager),
                    tooltip: 'Room Settings',
                  ),
              ],
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
                              const SizedBox(height: 4),
                              Text(
                                '${manager.readyPlayerCount}/${players.length} READY',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: manager.allPlayersReady
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                canStart
                                    ? 'Ready to start'
                                    : players.length < 5
                                        ? 'Need at least 5 players'
                                        : manager.allPlayersReady
                                            ? 'Waiting for host...'
                                            : 'Waiting for all to be ready...',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: canStart
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                              if (widget.isHost &&
                                  manager.hostIp != null &&
                                  manager.hostPort != null) ...[
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {
                                    final ipPort =
                                        '${manager.hostIp}:${manager.hostPort}';
                                    Clipboard.setData(
                                        ClipboardData(text: ipPort));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('IP:PORT copied to clipboard'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(Icons.lan,
                                          size: 14, color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'IP: ${manager.hostIp}:${manager.hostPort}',
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              AppTextStyles.labelSmall.copyWith(
                                            color: AppColors.textMuted,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.copy,
                                          size: 12, color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          if (manager.hostIp != null &&
                                              manager.hostPort != null) {
                                            _showQrDialog(manager.hostIp!,
                                                manager.hostPort!);
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
                        Row(
                          children: [
                            Text('PLAYERS', style: AppTextStyles.labelSmall),
                            // Moderator mode badge
                            if (manager.currentRoom?.moderatorMode == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.warning.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.supervisor_account,
                                        size: 10, color: AppColors.warning),
                                    const SizedBox(width: 4),
                                    Text(
                                      'MODERATOR',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.warning,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${players.length}/${manager.currentRoom?.maxPlayers ?? 10}',
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
                        final isHost = player.id == 'host' ||
                            player.id.startsWith('host_');
                        final isYou = player.id == localPlayerId;
                        return PlayerCard(
                          name: player.name,
                          isHost: isHost,
                          isYou: isYou,
                          status: player.isReady
                              ? PlayerStatus.ready
                              : PlayerStatus.waiting,
                          subtitle: player.isBot
                              ? 'BOT'
                              : (player.isReady ? 'READY' : 'NOT READY'),
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
                            label: canStart
                                ? 'START GAME'
                                : players.length < 5
                                    ? 'NEED ${5 - players.length} MORE'
                                    : 'WAITING FOR READY',
                            icon: Icons.play_arrow,
                            onPressed: canStart ? _startGame : null,
                          )
                        : Column(
                            children: [
                              PrimaryButtonLarge(
                                label: manager.localPlayer?.isReady == true
                                    ? 'READY - TAP TO UNREADY'
                                    : 'TAP WHEN READY',
                                icon: manager.localPlayer?.isReady == true
                                    ? Icons.check_circle
                                    : Icons.hourglass_empty,
                                onPressed: () {
                                  final currentPlayer = manager.localPlayer;
                                  if (currentPlayer != null) {
                                    manager.setLocalPlayerReady(
                                        !currentPlayer.isReady);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Waiting for host to start...',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            floatingActionButton: manager.mode == GameMode.offlineP2P
                ? FloatingActionButton(
                    onPressed: () => _showChatPanel(context, manager),
                    backgroundColor: AppColors.primary,
                    child: Stack(
                      children: [
                        const Icon(Icons.chat),
                        if (manager.lobbyChatMessages.isNotEmpty)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : null,
          ),
          // Countdown overlay
          if (manager.isCountingDown)
            CountdownOverlay(
              countdownValue: manager.countdownValue,
            ),
        ],
      ),
    );
  }

  void _showChatPanel(BuildContext context, GameManager manager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChatPanel(
        manager: manager,
        chatController: _chatController,
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
              style:
                  TextStyle(color: const ui.Color.fromARGB(255, 165, 42, 65)),
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
              context.read<GameManager>().kickPlayer(player.id);
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

/// Chat panel widget for lobby chat
class _ChatPanel extends StatefulWidget {
  final GameManager manager;
  final TextEditingController chatController;

  const _ChatPanel({
    required this.manager,
    required this.chatController,
  });

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = widget.chatController.text.trim();
    if (text.isNotEmpty) {
      widget.manager.sendLobbyChatMessage(text);
      widget.chatController.clear();
      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameManager>(
      builder: (context, manager, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.chat, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      'LOBBY CHAT',
                      style: AppTextStyles.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Divider(color: AppColors.cardBorder, height: 1),
              // Messages
              Expanded(
                child: manager.lobbyChatMessages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet.\nSay hello to your crew!',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: manager.lobbyChatMessages.length,
                        itemBuilder: (context, index) {
                          final msg = manager.lobbyChatMessages[index];
                          final isMe = msg.senderId == manager.localPlayerId;
                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppColors.primary.withOpacity(0.2)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Text(
                                      msg.senderName.toUpperCase(),
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  Text(
                                    msg.text,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Input
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.chatController,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                          filled: true,
                          fillColor: AppColors.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sendMessage,
                      icon: Icon(Icons.send, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
