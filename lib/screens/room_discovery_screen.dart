import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/room_tile.dart';
import '../game/game_manager.dart';
import '../network/lan_communication.dart';
import 'qr_scanner_screen.dart';

class RoomDiscoveryScreen extends StatefulWidget {
  final String playerName;

  const RoomDiscoveryScreen({super.key, required this.playerName});

  @override
  State<RoomDiscoveryScreen> createState() => _RoomDiscoveryScreenState();
}

class _RoomDiscoveryScreenState extends State<RoomDiscoveryScreen> {
  bool _isSearching = true;
  bool _isJoining = false;
  final _ipController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _pinController.dispose();
    // Stop discovery when leaving screen
    context.read<GameManager>().stopLANDiscovery();
    super.dispose();
  }

  Future<void> _startDiscovery() async {
    final manager = context.read<GameManager>();
    setState(() => _isSearching = true);

    await manager.startLANDiscovery();

    // Keep searching indicator for a bit
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _joinRoom(RoomInfo room, {String? pin}) async {
    if (_isJoining) return;

    final manager = context.read<GameManager>();

    setState(() => _isJoining = true);

    final success =
        await manager.joinLANRoom(room, widget.playerName, pin: pin);

    if (!mounted) return;

    setState(() => _isJoining = false);

    if (success) {
      Navigator.pushNamed(
        context,
        '/lobby',
        arguments: {
          'name': widget.playerName,
          'isHost': false,
          'roomName': room.roomName,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            room.isPrivate
                ? 'Failed to join. Invalid PIN or room no longer available.'
                : 'Failed to join room. It may be full or no longer available.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Show PIN dialog for private rooms
  void _showPinDialog(RoomInfo room) {
    _pinController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Row(
          children: [
            const Icon(Icons.lock, color: AppColors.warning, size: 20),
            const SizedBox(width: 8),
            const Text('Private Room'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the 4-digit PIN to join "${room.roomName}"',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              autofocus: true,
              style: AppTextStyles.headlineLarge.copyWith(
                letterSpacing: 12,
              ),
              decoration: InputDecoration(
                hintText: '• • • •',
                hintStyle: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 8,
                ),
                counterText: '',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              maxLength: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = _pinController.text.trim();
              if (pin.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a 4-digit PIN'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _joinRoom(room, pin: pin);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('JOIN'),
          ),
        ],
      ),
    );
  }

  /// Handle room tap - show PIN dialog for private rooms
  void _onRoomTap(RoomInfo room) {
    if (room.isPrivate) {
      _showPinDialog(room);
    } else {
      _joinRoom(room);
    }
  }

  Future<void> _joinByIp() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an IP address'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Simple IP validation
    final ipRegex = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
    if (!ipRegex.hasMatch(ip)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please enter a valid IP address (e.g., 192.168.1.100)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isJoining) return;

    final manager = context.read<GameManager>();

    setState(() => _isJoining = true);

    final success = await manager.joinLANRoomByIp(ip, widget.playerName);

    if (!mounted) return;

    setState(() => _isJoining = false);

    if (success) {
      Navigator.pushNamed(
        context,
        '/lobby',
        arguments: {
          'name': widget.playerName,
          'isHost': false,
          'roomName': 'Room',
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Failed to connect. Check the IP address and make sure the host is running.'),
          backgroundColor: Color.fromARGB(255, 173, 38, 63),
        ),
      );
    }
  }

  void _showManualJoinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Join by IP Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter the host's IP address shown on their screen:",
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g., 192.168.1.100',
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _joinByIp();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('JOIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<GameManager>();
    final rooms = manager.discoveredRooms;

    // Show unsupported platform message for web
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('FIND ROOM'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.web_asset_off,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 24),
                Text(
                  'LAN Multiplayer Not Supported',
                  style: AppTextStyles.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Web browsers cannot discover or join LAN games due to security restrictions.\n\nPlease use the Android app or Windows desktop app for LAN multiplayer.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('GO BACK'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('FIND ROOM'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startDiscovery,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isSearching ? Icons.radar : Icons.wifi_find,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSearching
                              ? 'SCANNING NETWORK...'
                              : 'DISCOVERY COMPLETE',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: _isSearching
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isSearching
                              ? 'Looking for nearby games'
                              : '${rooms.length} rooms found',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Make sure you\'re on the same WiFi network',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isSearching)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'AVAILABLE ROOMS',
                style: AppTextStyles.labelSmall,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isSearching && rooms.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_find,
                            size: 64,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Searching for rooms...',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : rooms.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.wifi_off,
                                  size: 64,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No rooms found',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _startDiscovery,
                                  child: const Text('Try again'),
                                ),
                              
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: rooms.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final room = rooms[index];
                            return RoomTile(
                              roomName: room.roomName,
                              hostName: room.hostName,
                              playerCount: room.playerCount,
                              maxPlayers: room.maxPlayers,
                              isInProgress: room.inProgress,
                              isPrivate: room.isPrivate,
                              onJoin: room.inProgress
                                  ? null
                                  : () => _onRoomTap(room),
                            );
                          },
                        ),
            ),
            // Manual join area (always visible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(color: AppColors.cardBorder),
                  const SizedBox(height: 16),
                  Text(
                    "Can't find the room? Join manually:",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _showManualJoinDialog,
                    icon: const Icon(Icons.input, size: 18),
                    label: const Text('JOIN BY IP ADDRESS'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (kIsWeb) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('QR scanning not supported on web')));
                        return;
                      }
                      final result = await Navigator.push<String?>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const QRScannerScreen()),
                      );
                      if (result != null && result.isNotEmpty) {
                        String ip = result.trim();
                        int port = 41235;
                        String? pin;
                        bool isPrivate = false;

                        if (ip.contains('|')) {
                          final pipeParts = ip.split('|');
                          ip = pipeParts[0];
                          if (pipeParts.length > 1 && pipeParts[1].isNotEmpty) {
                            pin = pipeParts[1];
                            isPrivate = true;
                          }
                        }

                        if (ip.contains(':')) {
                          final parts = ip.split(':');
                          ip = parts[0];
                          port =
                              int.tryParse(parts.length > 1 ? parts[1] : '') ??
                                  41235;
                        }

                        final manager = context.read<GameManager>();
                        final success = await manager.joinLANRoomByIp(
                          ip,
                          widget.playerName,
                          port: port,
                          pin: pin,
                          isPrivate: isPrivate,
                        );
                        if (success) {
                          Navigator.pushNamed(context, '/lobby', arguments: {
                            'name': widget.playerName,
                            'isHost': false,
                            'roomName': 'Room',
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(isPrivate
                                  ? 'Failed to connect. Invalid PIN or host unavailable.'
                                  : 'Failed to connect to scanned IP')));
                        }
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text('SCAN QR'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            if (_isJoining)
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Joining room...'),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
