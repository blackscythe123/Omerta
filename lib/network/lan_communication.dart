// LAN-based P2P implementation using UDP broadcast for discovery and TCP for game communication
// This replaces nearby_connections with standard socket-based networking

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

import '../models/game_state.dart';
import 'game_communication.dart';

/// Room information broadcast over UDP
class RoomInfo {
  final String hostId;
  final String hostName;
  final String roomName;
  final String hostIp;
  final int hostPort;
  final int playerCount;
  final int maxPlayers;
  final bool inProgress;
  final bool isPrivate; // Whether the room requires a PIN to join

  RoomInfo({
    required this.hostId,
    required this.hostName,
    required this.roomName,
    required this.hostIp,
    required this.hostPort,
    required this.playerCount,
    this.maxPlayers = 10,
    this.inProgress = false,
    this.isPrivate = false,
  });

  /// Create a copy with updated fields
  RoomInfo copyWith({
    String? hostId,
    String? hostName,
    String? roomName,
    String? hostIp,
    int? hostPort,
    int? playerCount,
    int? maxPlayers,
    bool? inProgress,
    bool? isPrivate,
  }) {
    return RoomInfo(
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      roomName: roomName ?? this.roomName,
      hostIp: hostIp ?? this.hostIp,
      hostPort: hostPort ?? this.hostPort,
      playerCount: playerCount ?? this.playerCount,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      inProgress: inProgress ?? this.inProgress,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }

  /// Note: PIN is NOT included in JSON - it stays on host only
  Map<String, dynamic> toJson() => {
        'hostId': hostId,
        'hostName': hostName,
        'roomName': roomName,
        'hostIp': hostIp,
        'hostPort': hostPort,
        'playerCount': playerCount,
        'maxPlayers': maxPlayers,
        'inProgress': inProgress,
        'isPrivate': isPrivate,
      };

  factory RoomInfo.fromJson(Map<String, dynamic> json) => RoomInfo(
        hostId: json['hostId'] ?? '',
        hostName: json['hostName'] ?? 'Unknown',
        roomName: json['roomName'] ?? 'Room',
        hostIp: json['hostIp'] ?? '',
        hostPort: json['hostPort'] ?? 41235,
        playerCount: json['playerCount'] ?? 0,
        maxPlayers: json['maxPlayers'] ?? 10,
        inProgress: json['inProgress'] ?? false,
        isPrivate: json['isPrivate'] ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RoomInfo && hostId == other.hostId;

  @override
  int get hashCode => hostId.hashCode;
}

/// LAN Communication using UDP broadcast for discovery and TCP for game data
class LANCommunication implements GameCommunication {
  static const int udpBroadcastPort = 41234;
  static const int tcpPort = 41235;
  static const Duration broadcastInterval = Duration(seconds: 2);
  static const Duration roomTimeout = Duration(seconds: 6);
  static const String messageDelimiter = '\n';

  // UDP for room discovery
  RawDatagramSocket? _udpSocket;
  Timer? _broadcastTimer;
  Timer? _cleanupTimer;

  // TCP for game communication
  ServerSocket? _tcpServer;
  final Map<String, Socket> _clients = {};
  Socket? _hostSocket;

  // Callbacks
  Function(GameState)? _onGameState;
  Function(Map<String, dynamic>)? _onAction;
  Function(RoomInfo)? onRoomDiscovered;
  Function(String playerId, String playerName)? onPlayerJoined;
  Function(String playerId)? onPlayerLeft;
  Function()? onDisconnectedFromHost;
  Function(String reason)? onJoinRejected;

  // State
  final bool isHost;
  String? hostId;
  String? localPlayerId;
  String? localPlayerName;
  RoomInfo? _currentRoom;
  final Map<String, RoomInfo> _discoveredRooms = {};
  final Map<String, DateTime> _roomLastSeen = {};
  bool _isConnected = false;

  // Private room PIN (stored only on host, never broadcast)
  String? _roomPin;

  // Message buffer for TCP
  final Map<Socket, String> _socketBuffers = {};

  LANCommunication({required this.isHost});

  bool get isConnected => _isConnected;
  List<RoomInfo> get discoveredRooms => _discoveredRooms.values.toList();
  RoomInfo? get currentRoom => _currentRoom;

  // ============ LOCAL IP HELPER ============

  Future<String?> getLocalIp() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            // Prefer 192.168.x.x addresses
            if (addr.address.startsWith('192.168.')) {
              return addr.address;
            }
          }
        }
      }
      // Fallback to any non-loopback IPv4
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('[LAN] Error getting local IP: $e');
    }
    return null;
  }

  /// Check if LAN networking is supported on this platform
  static bool get isSupported => !kIsWeb;

  // ============ HOST FUNCTIONS ============

  /// Start hosting a room
  /// [isPrivate] - if true, requires PIN to join
  /// [pin] - 4-digit PIN for private rooms (stored locally, never broadcast)
  Future<bool> startHosting(
    String roomName,
    String playerName,
    String playerId, {
    bool isPrivate = false,
    String? pin,
  }) async {
    if (!isHost) return false;
    if (kIsWeb) {
      print('[LAN] Web platform does not support socket-based networking');
      return false;
    }

    hostId = playerId;
    localPlayerId = playerId;
    localPlayerName = playerName;
    _roomPin = isPrivate ? pin : null;

    try {
      // Start TCP server first
      _tcpServer = await ServerSocket.bind(InternetAddress.anyIPv4, tcpPort);
      print('[LAN] TCP server started on port $tcpPort');

      _tcpServer!.listen(
        _handleClientConnection,
        onError: (e) => print('[LAN] TCP server error: $e'),
      );

      // Get local IP
      final localIp = await getLocalIp();
      if (localIp == null) {
        print('[LAN] Failed to get local IP');
        await stopHosting();
        return false;
      }

      _currentRoom = RoomInfo(
        hostId: playerId,
        hostName: playerName,
        roomName: roomName,
        hostIp: localIp,
        hostPort: tcpPort,
        playerCount: 1,
        isPrivate: isPrivate,
      );

      // Start UDP broadcast
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _udpSocket!.broadcastEnabled = true;
      _startBroadcasting();

      _isConnected = true;
      print(
          '[LAN] Hosting started: ${_currentRoom!.roomName} at $localIp:$tcpPort (private: $isPrivate)');
      return true;
    } catch (e) {
      print('[LAN] Error starting host: $e');
      await stopHosting();
      return false;
    }
  }

  /// Get the room PIN (for QR code generation by host only)
  String? get roomPin => _roomPin;

  /// Check if current room is private
  bool get isRoomPrivate => _currentRoom?.isPrivate ?? false;

  void _startBroadcasting() {
    _broadcastTimer?.cancel();
    _broadcastTimer = Timer.periodic(broadcastInterval, (_) {
      _broadcastRoom();
    });
    // Also broadcast immediately
    _broadcastRoom();
  }

  void _broadcastRoom() {
    if (_currentRoom == null || _udpSocket == null) return;

    try {
      final data = utf8.encode(jsonEncode({
        'type': 'room_broadcast',
        'room': _currentRoom!.toJson(),
      }));

      // Broadcast to multiple addresses for better compatibility
      final broadcastAddresses = [
        '255.255.255.255', // Global broadcast
        _getSubnetBroadcast(
            _currentRoom!.hostIp), // Subnet broadcast (e.g., 192.168.1.255)
      ];

      for (final addr in broadcastAddresses) {
        if (addr.isNotEmpty) {
          try {
            _udpSocket!.send(
              Uint8List.fromList(data),
              InternetAddress(addr),
              udpBroadcastPort,
            );
          } catch (_) {}
        }
      }
    } catch (e) {
      print('[LAN] Broadcast error: $e');
    }
  }

  /// Get subnet broadcast address (e.g., 192.168.1.100 -> 192.168.1.255)
  String _getSubnetBroadcast(String ip) {
    try {
      final parts = ip.split('.');
      if (parts.length == 4) {
        return '${parts[0]}.${parts[1]}.${parts[2]}.255';
      }
    } catch (_) {}
    return '';
  }

  void updateRoomInfo({int? playerCount, bool? inProgress}) {
    if (_currentRoom != null) {
      _currentRoom = _currentRoom!.copyWith(
        playerCount: playerCount,
        inProgress: inProgress,
      );
    }
  }

  void _handleClientConnection(Socket socket) {
    final address = '${socket.remoteAddress.address}:${socket.remotePort}';
    print('[LAN] Client connecting from $address');

    _socketBuffers[socket] = '';

    socket.listen(
      (data) => _handleClientData(socket, data),
      onDone: () => _handleClientDisconnect(socket),
      onError: (e) {
        print('[LAN] Client socket error: $e');
        _handleClientDisconnect(socket);
      },
    );
  }

  void _handleClientData(Socket socket, Uint8List data) {
    _socketBuffers[socket] = (_socketBuffers[socket] ?? '') + utf8.decode(data);

    while (_socketBuffers[socket]!.contains(messageDelimiter)) {
      final index = _socketBuffers[socket]!.indexOf(messageDelimiter);
      final messageStr = _socketBuffers[socket]!.substring(0, index);
      _socketBuffers[socket] = _socketBuffers[socket]!.substring(index + 1);

      try {
        final message = jsonDecode(messageStr) as Map<String, dynamic>;
        _handleClientMessage(socket, message);
      } catch (e) {
        print('[LAN] Error parsing client message: $e');
      }
    }
  }

  void _handleClientMessage(Socket socket, Map<String, dynamic> message) {
    final type = message['type'] as String?;

    switch (type) {
      case 'join_request':
        final playerId = message['playerId'] as String;
        final playerName = message['playerName'] as String;
        final providedPin = message['pin'] as String?;

        // Check if game in progress
        if (_currentRoom?.inProgress == true) {
          _sendToSocket(socket, {
            'type': 'join_rejected',
            'reason': 'Game already in progress',
          });
          socket.close();
          return;
        }

        // Check player limit
        if (_clients.length >= (_currentRoom?.maxPlayers ?? 10) - 1) {
          _sendToSocket(socket, {
            'type': 'join_rejected',
            'reason': 'Room is full',
          });
          socket.close();
          return;
        }

        // Validate PIN for private rooms
        if (_currentRoom?.isPrivate == true && _roomPin != null) {
          if (providedPin == null || providedPin != _roomPin) {
            _sendToSocket(socket, {
              'type': 'join_rejected',
              'reason': 'Invalid PIN',
            });
            socket.close();
            return;
          }
        }

        // Accept the player
        _clients[playerId] = socket;
        print('[LAN] Player joined: $playerName ($playerId)');

        // Send acceptance
        _sendToSocket(socket, {
          'type': 'join_accepted',
          'playerId': playerId,
        });

        // Notify callback
        onPlayerJoined?.call(playerId, playerName);
        break;

      case 'action':
        _onAction?.call(message['data'] as Map<String, dynamic>);
        break;

      case 'ping':
        _sendToSocket(socket, {'type': 'pong'});
        break;

      default:
        print('[LAN] Unknown message type from client: $type');
    }
  }

  void _handleClientDisconnect(Socket socket) {
    _socketBuffers.remove(socket);

    // Find which player this socket belongs to
    String? disconnectedPlayerId;
    _clients.forEach((playerId, clientSocket) {
      if (clientSocket == socket) {
        disconnectedPlayerId = playerId;
      }
    });

    if (disconnectedPlayerId != null) {
      _clients.remove(disconnectedPlayerId);
      print('[LAN] Player disconnected: $disconnectedPlayerId');
      onPlayerLeft?.call(disconnectedPlayerId!);
    }

    try {
      socket.close();
    } catch (_) {}
  }

  void sendToClient(String playerId, Map<String, dynamic> message) {
    final socket = _clients[playerId];
    if (socket != null) {
      _sendToSocket(socket, message);
    }
  }

  void broadcastToClients(Map<String, dynamic> message, {String? excludeId}) {
    for (final entry in _clients.entries) {
      if (entry.key != excludeId) {
        _sendToSocket(entry.value, message);
      }
    }
  }

  void kickClient(String playerId) {
    final socket = _clients[playerId];
    if (socket != null) {
      _sendToSocket(socket, {
        'type': 'kicked',
        'reason': 'You have been kicked by the host',
      });
      socket.close();
      _clients.remove(playerId);
      onPlayerLeft?.call(playerId);
    }
  }

  Future<void> stopHosting() async {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;

    for (final socket in _clients.values) {
      try {
        _sendToSocket(socket, {'type': 'room_closed'});
        socket.close();
      } catch (_) {}
    }
    _clients.clear();
    _socketBuffers.clear();

    await _tcpServer?.close();
    _tcpServer = null;

    _udpSocket?.close();
    _udpSocket = null;

    _currentRoom = null;
    _isConnected = false;
    print('[LAN] Hosting stopped');
  }

  // ============ CLIENT FUNCTIONS ============

  Future<void> startDiscovery() async {
    if (isHost) return;
    if (kIsWeb) {
      print('[LAN] Web platform does not support socket-based networking');
      return;
    }

    try {
      // Note: reusePort is not supported on Windows, only use reuseAddress
      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        udpBroadcastPort,
        reuseAddress: true,
        // reusePort: true, // Not supported on Windows
      );
      _udpSocket!.broadcastEnabled = true;

      print('[LAN] Discovery started on port $udpBroadcastPort');

      _udpSocket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpSocket!.receive();
          if (datagram != null) {
            _handleDiscoveryPacket(datagram);
          }
        }
      });

      // Start cleanup timer for stale rooms
      _cleanupTimer?.cancel();
      _cleanupTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _cleanupStaleRooms();
      });
    } catch (e) {
      print('[LAN] Error starting discovery: $e');
    }
  }

  void _handleDiscoveryPacket(Datagram datagram) {
    try {
      final message =
          jsonDecode(utf8.decode(datagram.data)) as Map<String, dynamic>;

      if (message['type'] == 'room_broadcast') {
        final room = RoomInfo.fromJson(message['room'] as Map<String, dynamic>);

        final isNew = !_discoveredRooms.containsKey(room.hostId);
        _discoveredRooms[room.hostId] = room;
        _roomLastSeen[room.hostId] = DateTime.now();

        if (isNew || _discoveredRooms[room.hostId] != room) {
          onRoomDiscovered?.call(room);
        }
      }
    } catch (e) {
      print('[LAN] Error parsing discovery packet: $e');
    }
  }

  void _cleanupStaleRooms() {
    final now = DateTime.now();
    final staleIds = <String>[];

    _roomLastSeen.forEach((hostId, lastSeen) {
      if (now.difference(lastSeen) > roomTimeout) {
        staleIds.add(hostId);
      }
    });

    for (final id in staleIds) {
      _discoveredRooms.remove(id);
      _roomLastSeen.remove(id);
    }
  }

  void stopDiscovery() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    if (!isHost) {
      _udpSocket?.close();
      _udpSocket = null;
    }

    _discoveredRooms.clear();
    _roomLastSeen.clear();
    print('[LAN] Discovery stopped');
  }

  /// Join a room by IP address directly (fallback when UDP discovery fails)
  /// [pin] is required for private rooms
  Future<bool> joinByIp(String ip, String playerId, String playerName,
      {int port = tcpPort, String? pin, bool isPrivate = false}) async {
    if (isHost) return false;

    // Create a temporary RoomInfo for direct connection
    final room = RoomInfo(
      hostId: 'direct-$ip',
      hostName: 'Host',
      roomName: 'Room',
      hostIp: ip,
      hostPort: port,
      playerCount: 1,
      isPrivate: isPrivate,
    );

    return joinRoom(room, playerId, playerName, pin: pin);
  }

  /// Join a discovered room
  /// [pin] is required for private rooms
  Future<bool> joinRoom(RoomInfo room, String playerId, String playerName,
      {String? pin}) async {
    if (isHost) return false;

    localPlayerId = playerId;
    localPlayerName = playerName;
    hostId = room.hostId;

    try {
      print('[LAN] Connecting to ${room.hostIp}:${room.hostPort}');

      _hostSocket = await Socket.connect(
        room.hostIp,
        room.hostPort,
        timeout: const Duration(seconds: 5),
      );

      _socketBuffers[_hostSocket!] = '';

      _hostSocket!.listen(
        (data) => _handleHostData(data),
        onDone: _handleHostDisconnect,
        onError: (e) {
          print('[LAN] Host connection error: $e');
          _handleHostDisconnect();
        },
      );

      // Send join request (include PIN for private rooms)
      final joinRequest = <String, dynamic>{
        'type': 'join_request',
        'playerId': playerId,
        'playerName': playerName,
      };
      if (pin != null && pin.isNotEmpty) {
        joinRequest['pin'] = pin;
      }
      _sendToSocket(_hostSocket!, joinRequest);

      // Wait for acceptance (with timeout)
      final completer = Completer<bool>();
      Timer? timeout;

      void cleanup() {
        timeout?.cancel();
        onJoinRejected = null;
      }

      timeout = Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          cleanup();
          completer.complete(false);
        }
      });

      // Temporarily override callback to capture result
      final originalCallback = onJoinRejected;
      onJoinRejected = (reason) {
        cleanup();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        originalCallback?.call(reason);
      };

      // Check for join accepted in message handler
      _isConnected = true;
      _currentRoom = room;

      return true;
    } catch (e) {
      print('[LAN] Error joining room: $e');
      _hostSocket?.close();
      _hostSocket = null;
      return false;
    }
  }

  void _handleHostData(Uint8List data) {
    if (_hostSocket == null) return;

    _socketBuffers[_hostSocket!] =
        (_socketBuffers[_hostSocket!] ?? '') + utf8.decode(data);

    while (_socketBuffers[_hostSocket!]!.contains(messageDelimiter)) {
      final index = _socketBuffers[_hostSocket!]!.indexOf(messageDelimiter);
      final messageStr = _socketBuffers[_hostSocket!]!.substring(0, index);
      _socketBuffers[_hostSocket!] =
          _socketBuffers[_hostSocket!]!.substring(index + 1);

      try {
        final message = jsonDecode(messageStr) as Map<String, dynamic>;
        _handleHostMessage(message);
      } catch (e) {
        print('[LAN] Error parsing host message: $e');
      }
    }
  }

  void _handleHostMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;

    switch (type) {
      case 'join_accepted':
        print('[LAN] Join accepted');
        _isConnected = true;
        break;

      case 'join_rejected':
        final reason = message['reason'] as String? ?? 'Unknown reason';
        print('[LAN] Join rejected: $reason');
        _isConnected = false;
        onJoinRejected?.call(reason);
        break;

      case 'state':
        final stateData = message['data'] as Map<String, dynamic>;
        final state = GameState.fromJson(stateData);
        _onGameState?.call(state);
        break;

      case 'kicked':
        final reason = message['reason'] as String? ?? 'Kicked by host';
        print('[LAN] Kicked: $reason');
        _isConnected = false;
        onDisconnectedFromHost?.call();
        break;

      case 'room_closed':
        print('[LAN] Room closed by host');
        _isConnected = false;
        onDisconnectedFromHost?.call();
        break;

      case 'pong':
        // Heartbeat response
        break;

      default:
        print('[LAN] Unknown message type from host: $type');
    }
  }

  void _handleHostDisconnect() {
    print('[LAN] Disconnected from host');
    _socketBuffers.remove(_hostSocket);
    _hostSocket = null;
    _isConnected = false;
    onDisconnectedFromHost?.call();
  }

  Future<void> leaveRoom() async {
    _hostSocket?.close();
    _hostSocket = null;
    _socketBuffers.clear();
    _currentRoom = null;
    _isConnected = false;
    stopDiscovery();
    print('[LAN] Left room');
  }

  // ============ GAME COMMUNICATION INTERFACE ============

  @override
  Future<void> sendGameState(GameState state) async {
    if (!isHost) return;

    final message = {
      'type': 'state',
      'data': state.toJson(),
    };

    broadcastToClients(message);
  }

  @override
  Future<void> sendAction(Map<String, dynamic> action) async {
    if (isHost) {
      // Host handles actions locally
      _onAction?.call(action);
    } else if (_hostSocket != null) {
      _sendToSocket(_hostSocket!, {
        'type': 'action',
        'data': action,
      });
    }
  }

  @override
  void onGameStateReceived(Function(GameState) callback) {
    _onGameState = callback;
  }

  @override
  void onActionReceived(Function(Map<String, dynamic>) callback) {
    _onAction = callback;
  }

  // ============ HELPER ============

  void _sendToSocket(Socket socket, Map<String, dynamic> message) {
    try {
      socket.write(jsonEncode(message) + messageDelimiter);
    } catch (e) {
      print('[LAN] Error sending to socket: $e');
    }
  }

  Future<void> dispose() async {
    if (isHost) {
      await stopHosting();
    } else {
      await leaveRoom();
    }
    _cleanupTimer?.cancel();
  }
}
