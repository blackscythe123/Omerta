// GameManager (The Brain) - owns all game state and logic
// UI only calls methods here and reacts to state changes.

import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';

import 'package:flutter/foundation.dart';

import '../models/player.dart';
import '../models/game_state.dart';
import '../network/game_communication.dart';
import '../network/lan_communication.dart';
import 'game_rules.dart';
import 'bot_controller.dart';

class GameManager extends ChangeNotifier {
  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC STATE (Exposed to UI)
  // ═══════════════════════════════════════════════════════════════════════════

  GameMode mode = GameMode.soloBots;
  GamePhase phase = GamePhase.lobby;
  List<Player> players = [];
  Map<String, int> votes = {}; // targetId -> vote count
  Map<String, String> playerVotes =
      {}; // voterId -> targetId (who voted for whom)

  // Game configuration
  GameConfig gameConfig = GameConfig.forPlayerCount(7);
  int currentDay = 1;

  // Mafia night voting - all mafia vote on who to kill
  Map<String, String> mafiaNightVotes = {}; // mafiaPlayerId -> targetId
  String? mafiaConsensusTarget; // The agreed upon target

  // Result tracking
  String? lastEliminatedPlayerId;
  String? lastEliminatedRole;
  String? moderatorId; // The ID of the assigned moderator
  String? nightKillTargetId; // Who was targeted at night
  bool? nightKillSaved; // Was the kill saved by doctor?

  // Detective inspection result (only visible to detective)
  String? lastInspectedPlayerId;
  bool? lastInspectionResult; // true = mafia, false = not mafia

  // Game outcome
  bool gameOver = false;
  String? winningTeam; // "mafia" or "villagers"

  // Vote history for bot AI
  List<Map<String, String>> voteHistory = [];

  // Local player info
  String? localPlayerId;

  // Discussion timer
  int discussionSecondsLeft = 0;

  // Voting & night timers (seconds left)
  int votingSecondsLeft = 0;
  int nightSecondsLeft = 0;

  // Configurable durations (can be set from Settings)
  int discussionDuration = 90; // seconds
  int votingDuration = 30; // seconds
  int nightDuration = 30; // seconds

  // Haptics preference (set from settings)
  bool hapticsEnabled = true;

  // Chat system for Solo Mode
  List<ChatMessage> chatMessages = [];

  // Lobby chat messages (for LAN multiplayer)
  List<ChatMessage> lobbyChatMessages = [];

  // Team (private) chat messages keyed by team name
  final Map<String, List<ChatMessage>> teamChatMessages = {};

  // Host disconnect info for UI navigation
  String? disconnectReason;
  bool wasDisconnected = false;

  // Countdown state
  bool isCountingDown = false;
  int countdownValue = 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════════════════

  final Set<String> _lastRoundVoters = {};
  String? _nightPendingKill; // Mafia kill
  String? _nightSavedId;
  String? _nightVigilanteTarget;
  String? _nightSerialKillerTarget;
  final Map<String, String> _nightEscortBlocks = {}; // Escort -> Target
  final Set<String> _nightActionsCompleted = {}; // Track who has acted

  GameCommunication? _comm;
  bool _isHost = true;
  BotController? _bot;
  Timer? _phaseTimer;
  Timer? _countdownTimer;
  DateTime? _nightStartTime;
  static const int _minNightDurationSec =
      6; // minimum seconds for night to last

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTRUCTOR
  // ═══════════════════════════════════════════════════════════════════════════

  GameManager();

  bool get isHost => _isHost;

  // ═══════════════════════════════════════════════════════════════════════════
  // MODE SETUP
  // ═══════════════════════════════════════════════════════════════════════════

  void setMode(GameMode newMode,
      {GameCommunication? comm, bool isHost = true}) {
    mode = newMode;
    _comm = comm;
    _isHost = isHost;
    _resetGame();
    notifyListeners();
  }

  void _resetGame() {
    phase = GamePhase.lobby;
    players = [];
    votes = {};
    playerVotes = {};
    mafiaNightVotes = {};
    mafiaConsensusTarget = null;
    lastEliminatedPlayerId = null;
    lastEliminatedRole = null;
    nightKillTargetId = null;
    nightKillSaved = null;
    lastInspectedPlayerId = null;
    lastInspectionResult = null;
    gameOver = false;
    winningTeam = null;
    _nightPendingKill = null;
    _nightSavedId = null;
    _nightVigilanteTarget = null;
    _nightSerialKillerTarget = null;
    _nightEscortBlocks.clear();
    _nightActionsCompleted.clear();
    _lastRoundVoters.clear();
    _phaseTimer?.cancel();
    _countdownTimer?.cancel();
    _phaseTimer = null;
    _countdownTimer = null;
    discussionSecondsLeft = 0;
    voteHistory.clear();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOBBY MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Set the player count configuration
  void setPlayerCount(int count) {
    gameConfig = GameConfig.forPlayerCount(count).copyWith(
      isModeratorMode: gameConfig.isModeratorMode,
    );
    notifyListeners();
  }

  void setModeratorMode(bool val) {
    gameConfig = gameConfig.copyWith(isModeratorMode: val);
    if (!val) moderatorId = null;
    notifyListeners();
  }

  void assignModerator(String? playerId) {
    moderatorId = playerId;
    // Enable moderator mode if someone is assigned
    gameConfig = gameConfig.copyWith(isModeratorMode: playerId != null);
    notifyListeners();
  }

  /// Get current game config
  GameConfig get currentConfig => gameConfig;

  /// Initialize players for solo mode (Includes Bots)
  void initializeSoloGame({int? playerCount}) {
    _isHost = true;
    _resetGame();
    final count = playerCount ?? gameConfig.playerCount;
    gameConfig = GameConfig.forPlayerCount(count);
    final botCount = count - 1; // 1 human player

    final rng = Random();
    final List<Player> roster = [];

    // Add human player
    roster.add(Player(
      id: 'local_player',
      name: 'You',
      role: Role.villager, // Will be reassigned
      isBot: false,
    ));

    // Add bots
    final names = [
      'Alice',
      'Bob',
      'Cara',
      'Dan',
      'Eve',
      'Finn',
      'Gina',
      'Hank',
      'Ivy',
      'Jack',
      'Luna'
    ];
    final personalities = BotPersonality.values;
    for (var i = 0; i < botCount && i < names.length; i++) {
      roster.add(Player(
        id: 'bot_$i',
        name: names[i],
        role: Role.villager, // Will be reassigned
        isBot: true,
        personality: personalities[rng.nextInt(personalities.length)],
        isReady: true, // bots should start ready in solo games
      ));
    }

    players = roster;
    localPlayerId = 'local_player';
    notifyListeners();
  }

  /// Initialize for Offline P2P (No Bots)
  void initializeOfflineGame(String playerName, {required bool host}) {
    _resetGame();
    _isHost = host;
    // In P2P, we start with just the host. Others join via network.
    if (isHost) {
      players = [
        Player(
          id: 'host',
          name: playerName,
          role: Role.villager,
          isBot: false,
        )
      ];
      localPlayerId = 'host';
    } else {
      // Joining player starts with an empty list or waits for state
      players = [
        Player(
          id: 'player_${Random().nextInt(1000)}',
          name: playerName,
          role: Role.villager,
          isBot: false,
        )
      ];
      localPlayerId = players.first.id;
    }
    notifyListeners();
  }

  /// Add a remote player (used by host in P2P)
  void addRemotePlayer(String id, String name) {
    if (players.any((p) => p.id == id)) return;
    players.add(Player(
      id: id,
      name: name,
      role: Role.villager,
      isBot: false,
    ));
    notifyListeners();
    _broadcastState();
  }

  /// Get the local player
  Player? get localPlayer {
    if (localPlayerId == null) return null;
    return players.cast<Player?>().firstWhere(
          (p) => p?.id == localPlayerId,
          orElse: () => null,
        );
  }

  /// Check if we have enough players and all are ready to start
  bool get canStartGame {
    // Minimum players required to start is 6 (avoid unbalanced 5-player setups)
    if (players.length < 6) return false;
    // Check if all non-host players are ready
    return players.every((p) => p.isReady);
  }

  /// Check if all players are ready (for UI display)
  bool get allPlayersReady => players.every((p) => p.isReady);

  /// Get count of ready players
  int get readyPlayerCount => players.where((p) => p.isReady).length;

  /// Set local player ready state (client only)
  void setLocalPlayerReady(bool isReady) {
    if (_isHost) return; // Host is always ready

    final playerIndex = players.indexWhere((p) => p.id == localPlayerId);
    if (playerIndex >= 0) {
      players[playerIndex] = players[playerIndex].copyWith(isReady: isReady);
      _lanComm?.sendReadyState(isReady);
      notifyListeners();
    }
  }

  /// Send lobby chat message
  void sendLobbyChatMessage(String message) {
    if (message.trim().isEmpty) return;

    final player = localPlayer;
    if (player == null) return;

    final chatMsg = ChatMessage(
      senderId: player.id,
      senderName: player.name,
      text: message.trim(),
      timestamp: DateTime.now(),
    );

    lobbyChatMessages.add(chatMsg);

    if (_isHost) {
      // Host broadcasts to all clients
      _lanComm?.broadcastChatMessage(player.id, player.name, message.trim());
    } else {
      // Client sends to host
      _lanComm?.sendChatMessage(message.trim(), player.name);
    }

    notifyListeners();
  }

  /// Clear disconnect state (called when navigating away from error)
  void clearDisconnectState() {
    wasDisconnected = false;
    disconnectReason = null;
    notifyListeners();
  }

  /// Kick a player from the room (host only)
  void kickPlayer(String playerId) {
    if (!_isHost || playerId == localPlayerId) return;

    // Remove player from list
    players.removeWhere((p) => p.id == playerId);

    // Kick via network
    _lanComm?.kickClient(playerId);

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME START
  // ═══════════════════════════════════════════════════════════════════════════

  void startGame() {
    if (!canStartGame) return;

    _assignRoles();
    phase = GamePhase.night;
    _nightStartTime = DateTime.now();
    nightSecondsLeft = nightDuration;
    _nightPendingKill = null;
    _nightSavedId = null;
    _nightVigilanteTarget = null;
    _nightSerialKillerTarget = null;
    _nightEscortBlocks.clear();
    _nightActionsCompleted.clear();

    // Initialize bot controller if there are bots in the game (works for solo and LAN with bots)
    if (players.any((p) => p.isBot)) {
      _bot = BotController(this);
      _bot!.onNightPhase();
    }

    // Start night timer
    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (nightSecondsLeft > 0) {
        nightSecondsLeft--;
        if (_isHost)
          _lanComm?.broadcastPhaseCountdown(
              GamePhase.night.name, nightSecondsLeft);
        notifyListeners();
      } else {
        timer.cancel();
        if (phase == GamePhase.night) advancePhase();
      }
    });

    _broadcastState();
    _onPhaseStarted();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NIGHT ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Handle night action from a player
  void handleNightAction(String actorId, String targetId) {
    print(
        '[GameManager] handleNightAction called: actor=$actorId target=$targetId phase=$phase');
    if (phase != GamePhase.night) {
      print('[GameManager] handleNightAction blocked: not in night phase');
      return;
    }

    final actor = _findPlayer(actorId);
    if (actor == null) {
      print('[GameManager] handleNightAction blocked: actor not found');
      return;
    }
    if (!actor.isAlive) {
      print('[GameManager] handleNightAction blocked: actor is dead');
      return;
    }

    // Prevent duplicate actions within same night
    if (_nightActionsCompleted.contains(actorId)) {
      print(
          '[GameManager] handleNightAction ignored: actor already acted this night');
      return;
    }

    switch (actor.role) {
      case Role.mafia:
      case Role.godfather:
        // Mafia/Godfather votes are collected together
        submitMafiaVote(actorId, targetId);
        return;

      case Role.doctor:
        _nightSavedId = targetId;
        _nightActionsCompleted.add(actorId);
        break;

      case Role.detective:
        final target = _findPlayer(targetId);
        if (target != null) {
          lastInspectedPlayerId = targetId;
          // Godfather appears as innocent
          lastInspectionResult =
              target.role == Role.mafia || target.role == Role.godfather;
          if (target.role == Role.godfather) lastInspectionResult = false;
        }
        _nightActionsCompleted.add(actorId);
        break;

      case Role.vigilante:
        if (actor.bullets > 0) {
          _nightVigilanteTarget = targetId;
          actor.bullets--;
        }
        _nightActionsCompleted.add(actorId);
        break;

      case Role.serialKiller:
        _nightSerialKillerTarget = targetId;
        _nightActionsCompleted.add(actorId);
        break;

      case Role.escort:
        _nightEscortBlocks[actorId] = targetId;
        _nightActionsCompleted.add(actorId);
        break;

      case Role.moderator:
      case Role.villager:
        break;
    }

    // If client, send action to host
    if (!_isHost && _comm != null) {
      print(
          '[GameManager] sending nightAction to host: actor=$actorId target=$targetId');
      _comm!.sendAction({
        'type': 'nightAction',
        'actorId': actorId,
        'targetId': targetId,
      });
    }

    _broadcastState();
    notifyListeners();

    // Check if all special roles have acted
    _checkNightComplete();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAFIA VOTING SYSTEM
  // ═══════════════════════════════════════════════════════════════════════════

  /// Submit a mafia vote for who to kill
  void submitMafiaVote(String mafiaId, String targetId) {
    print(
        '[GameManager] submitMafiaVote: mafia=$mafiaId target=$targetId phase=$phase');
    if (phase != GamePhase.night) {
      print('[GameManager] submitMafiaVote blocked: not in night phase');
      return;
    }

    final mafia = _findPlayer(mafiaId);
    if (mafia == null ||
        !mafia.isAlive ||
        (mafia.role != Role.mafia && mafia.role != Role.godfather)) {
      print('[GameManager] submitMafiaVote blocked: invalid mafia actor');
      return;
    }

    mafiaNightVotes[mafiaId] = targetId;
    _nightActionsCompleted.add(mafiaId);

    print('[GameManager] mafiaNightVotes: ${mafiaNightVotes}');

    // Check for mafia consensus
    _checkMafiaConsensus();

    _broadcastState();
    notifyListeners();

    // Check if all night actions complete
    _checkNightComplete();
  }

  /// Check if mafia has reached consensus on target
  void _checkMafiaConsensus() {
    final aliveMafiaList = aliveMafia();
    if (aliveMafiaList.isEmpty) return;

    // Count votes for each target
    final voteCounts = <String, int>{};
    for (final vote in mafiaNightVotes.values) {
      voteCounts[vote] = (voteCounts[vote] ?? 0) + 1;
    }

    print('[GameManager] _checkMafiaConsensus votes=$voteCounts');

    // Find target with majority or most votes
    if (voteCounts.isEmpty) {
      mafiaConsensusTarget = null;
      return;
    }

    // Get the target with most votes
    final maxVotes = voteCounts.values.fold<int>(0, (a, b) => a > b ? a : b);
    final topTargets = voteCounts.entries
        .where((e) => e.value == maxVotes)
        .map((e) => e.key)
        .toList();

    // If all living mafia have voted and there's a clear winner (or tie with all votes)
    final allMafiaVoted =
        aliveMafiaList.every((m) => mafiaNightVotes.containsKey(m.id));
    if (allMafiaVoted && topTargets.isNotEmpty) {
      // Pick the first one (could randomize ties)
      mafiaConsensusTarget = topTargets.first;
      _nightPendingKill = mafiaConsensusTarget;
      print('[GameManager] Mafia consensus reached: $_nightPendingKill');
    } else {
      print(
          '[GameManager] No consensus yet: allMafiaVoted=$allMafiaVoted topTargets=$topTargets');
    }
  }

  /// Get current mafia votes for UI display
  Map<String, String> getMafiaVotes() => Map.from(mafiaNightVotes);

  /// Get vote count for a target from mafia
  int getMafiaVoteCount(String targetId) {
    return mafiaNightVotes.values.where((t) => t == targetId).length;
  }

  /// Check if a specific mafia has voted
  bool hasMafiaVoted(String mafiaId) {
    return mafiaNightVotes.containsKey(mafiaId);
  }

  /// Get who a specific mafia voted for
  String? getMafiaVote(String mafiaId) {
    return mafiaNightVotes[mafiaId];
  }

  /// Check if local player has completed their night action
  bool hasCompletedNightAction() {
    if (localPlayerId == null) return true;
    final local = localPlayer;
    if (local == null || !local.isAlive) return true;
    if (local.role == Role.villager) return true; // Villagers don't act
    return _nightActionsCompleted.contains(localPlayerId);
  }

  /// Client-side request to ask host to restart the match (will be ignored on host)
  void requestRestart() {
    if (_isHost) return;
    if (_comm != null) {
      _comm!.sendAction({'type': 'request_restart', 'playerId': localPlayerId});
    }
  }

  /// Host-side restart the match, keeping players & room settings but returning to lobby
  void restartGame() {
    // Clear game-specific state but keep players and current room
    gameOver = false;
    winningTeam = null;
    phase = GamePhase.lobby;

    // Reset day counter
    currentDay = 1;

    // Clear voting/night state
    votes.clear();
    playerVotes.clear();
    mafiaNightVotes.clear();
    mafiaConsensusTarget = null;
    lastEliminatedPlayerId = null;
    lastEliminatedRole = null;
    nightKillTargetId = null;
    nightKillSaved = null;
    lastInspectedPlayerId = null;
    lastInspectionResult = null;
    _nightPendingKill = null;
    _nightSavedId = null;
    _nightVigilanteTarget = null;
    _nightSerialKillerTarget = null;
    _nightEscortBlocks.clear();
    _nightActionsCompleted.clear();
    _lastRoundVoters.clear();
    _phaseTimer?.cancel();
    _countdownTimer?.cancel();
    _phaseTimer = null;
    _countdownTimer = null;

    // Players are returned to not-ready state (they may re-ready in lobby)
    players =
        players.map((p) => p.copyWith(isReady: false, isAlive: true)).toList();

    // If host, mark room as not in progress and notify clients
    if (_isHost && _lanComm != null) {
      _lanComm!.updateRoomInfo(inProgress: false);
      _broadcastState();
    }

    notifyListeners();
  }

  void _checkNightComplete() {
    // Check if all alive special roles have acted
    final specialRoles =
        players.where((p) => p.isAlive && p.role != Role.villager);

    final allActed =
        specialRoles.every((p) => _nightActionsCompleted.contains(p.id));

    final minElapsed = _nightStartTime != null &&
        DateTime.now().difference(_nightStartTime!).inSeconds >=
            _minNightDurationSec;

    // Advance when either everyone has acted or minimum night duration passed
    if (allActed || minElapsed) {
      // Auto-advance to discussion after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (phase == GamePhase.night) {
          advancePhase();
        }
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VOTING
  // ═══════════════════════════════════════════════════════════════════════════

  void castVote(String voterId, String targetId) {
    print(
        '[GameManager] castVote called: voter=$voterId target=$targetId phase=$phase');
    if (phase != GamePhase.voting) {
      print('[GameManager] castVote blocked: not in voting phase');
      return;
    }

    final voter = _findPlayer(voterId);
    if (voter == null) {
      print('[GameManager] castVote blocked: voter not found');
      return;
    }
    if (!voter.isAlive) {
      print('[GameManager] castVote blocked: voter is dead');
      return;
    }

    // Remove prior vote by this voter
    final priorTarget = playerVotes[voterId];
    if (priorTarget != null) {
      final count = votes[priorTarget] ?? 0;
      votes[priorTarget] = (count - 1).clamp(0, 999);
      if (votes[priorTarget] == 0) votes.remove(priorTarget);
    }

    // Cast new vote
    playerVotes[voterId] = targetId;
    votes[targetId] = (votes[targetId] ?? 0) + 1;
    _lastRoundVoters.add(voterId);

    // If client, send to host
    if (!_isHost && _comm != null) {
      _comm!.sendAction({
        'type': 'vote',
        'voterId': voterId,
        'targetId': targetId,
      });
    }

    _broadcastState();
    notifyListeners();

    // Check if all alive players have voted
    _checkVotingComplete();
  }

  /// Check if a user has voted
  bool hasUserVoted(String voterId) {
    return playerVotes.containsKey(voterId);
  }

  /// Get who a user voted for
  String? getUserVote(String voterId) {
    return playerVotes[voterId];
  }

  /// Get vote count for a player
  int getVoteCount(String playerId) {
    return votes[playerId] ?? 0;
  }

  void _checkVotingComplete() {
    final alivePlayers = players.where((p) => p.isAlive).toList();
    final allVoted = alivePlayers.every((p) => playerVotes.containsKey(p.id));

    if (allVoted) {
      // Auto-advance to results after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (phase == GamePhase.voting) {
          advancePhase();
        }
      });
    }
  }

  void processVotes() {
    final targetId = GameRules.majorityTarget(votes, breakTiesRandom: true);
    if (targetId != null) {
      final victim = _findPlayer(targetId);
      if (victim != null) {
        victim.isAlive = false;
        lastEliminatedPlayerId = targetId;
        lastEliminatedRole = victim.role.name;
      }
    } else {
      lastEliminatedPlayerId = null;
      lastEliminatedRole = null;
    }

    checkWinCondition();
    _broadcastState();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  void advancePhase() {
    switch (phase) {
      case GamePhase.lobby:
        // Don't auto-advance from lobby
        break;

      case GamePhase.night:
        _resolveNightActions();
        phase = GamePhase.discussion;
        // Start discussion countdown
        _startDiscussionTimer();
        if (players.any((p) => p.isBot)) {
          _bot ??= BotController(this);
          _bot!.onDiscussionPhase();
        }
        _onPhaseStarted();
        break;

      case GamePhase.mafiaVoting:
        // This phase is handled internally, just advance to discussion
        phase = GamePhase.discussion;
        _startDiscussionTimer();
        // Trigger bot chat (if bots present)
        if (players.any((p) => p.isBot)) {
          _bot ??= BotController(this);
          _bot!.onDiscussionPhase();
        }
        _onPhaseStarted();
        break;

      case GamePhase.discussion:
        _phaseTimer?.cancel();
        _countdownTimer?.cancel();
        chatMessages.clear(); // Clear chat for next round
        phase = GamePhase.voting;
        votes.clear();
        playerVotes.clear();
        // Start voting timer
        votingSecondsLeft = votingDuration;
        _phaseTimer?.cancel();
        _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (votingSecondsLeft > 0) {
            votingSecondsLeft--;
            if (_isHost)
              _lanComm?.broadcastPhaseCountdown(
                  GamePhase.voting.name, votingSecondsLeft);
            notifyListeners();
          } else {
            timer.cancel();
            if (phase == GamePhase.voting) advancePhase();
          }
        });
        // Trigger bot voting (if bots present)
        if (players.any((p) => p.isBot)) {
          _bot ??= BotController(this);
          _bot!.onVotingPhase();
        }
        _onPhaseStarted();
        break;

      case GamePhase.voting:
        processVotes();
        phase = GamePhase.result;
        // Let players see the result for a short time before starting the next night
        Timer(const Duration(seconds: 4), () {
          if (phase == GamePhase.result && !gameOver) {
            _startNextRound();
          }
        });
        break;

      case GamePhase.result:
        if (!gameOver) {
          _startNextRound();
        }
        break;
    }

    _broadcastState();
    notifyListeners();
  }

  bool get isOfflineMode => mode == GameMode.offlineP2P;

  void _startDiscussionTimer() {
    _phaseTimer?.cancel();

    discussionSecondsLeft = discussionDuration;
    // Broadcast initial countdown to clients if host
    if (_isHost)
      _lanComm?.broadcastPhaseCountdown(
          GamePhase.discussion.name, discussionSecondsLeft);

    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (discussionSecondsLeft > 0) {
        discussionSecondsLeft--;
        // Broadcast tick
        if (_isHost)
          _lanComm?.broadcastPhaseCountdown(
              GamePhase.discussion.name, discussionSecondsLeft);
        notifyListeners();
      } else {
        timer.cancel();
        if (phase == GamePhase.discussion) advancePhase();
      }
    });
  }

  void _startNextRound() {
    // Archive the previous round's votes
    if (playerVotes.isNotEmpty) {
      voteHistory.add(Map.from(playerVotes));
    }

    phase = GamePhase.night;
    _nightStartTime = DateTime.now();
    nightSecondsLeft = nightDuration;
    currentDay++;
    votes.clear();
    playerVotes.clear();
    mafiaNightVotes.clear();
    mafiaConsensusTarget = null;
    _lastRoundVoters.clear();
    _nightPendingKill = null;
    _nightSavedId = null;
    _nightVigilanteTarget = null;
    _nightSerialKillerTarget = null;
    _nightEscortBlocks.clear();
    _nightActionsCompleted.clear();
    nightKillTargetId = null;
    nightKillSaved = null;
    lastEliminatedPlayerId = null;
    lastEliminatedRole = null;
    lastInspectedPlayerId = null;
    lastInspectionResult = null;

    // Start night countdown
    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (nightSecondsLeft > 0) {
        nightSecondsLeft--;
        if (_isHost)
          _lanComm?.broadcastPhaseCountdown(
              GamePhase.night.name, nightSecondsLeft);
        notifyListeners();
      } else {
        timer.cancel();
        // Ensure minimum night duration has passed
        if (phase == GamePhase.night) advancePhase();
      }
    });

    if (mode == GameMode.soloBots) {
      _bot ??= BotController(this);
      _bot!.onNightPhase();
    }

    _onPhaseStarted();
    notifyListeners();
  }

  void _resolveNightActions() {
    final killedIds = <String>{};
    final savedId = _nightSavedId;
    final blockedTargets = _nightEscortBlocks.values.toSet();

    // 1. Resolve blocking first
    // If a role is blocked, their action doesn't count.

    // 2. Mafia Kill
    print(
        '[GameManager] _resolveNightActions: pendingKill=$_nightPendingKill savedId=$savedId blockedTargets=$blockedTargets');
    if (_nightPendingKill != null) {
      // Mafia kill only proceeds if the mafia consensus exists and attacker(s) not all blocked
      final mafiaCallerBlocked =
          aliveMafia().every((m) => blockedTargets.contains(m.id));
      if (!mafiaCallerBlocked) {
        if (_nightPendingKill != savedId) {
          killedIds.add(_nightPendingKill!);
          nightKillTargetId = _nightPendingKill;
          nightKillSaved = false;
          print('[GameManager] Mafia kill scheduled: ${_nightPendingKill}');
        } else {
          nightKillSaved = true;
          print('[GameManager] Mafia kill saved by doctor');
        }
      } else {
        print('[GameManager] Mafia kill blocked (all mafia blocked)');
      }
    }

    // 3. Vigilante Kill
    if (_nightVigilanteTarget != null) {
      try {
        final vigilante =
            players.firstWhere((p) => p.role == Role.vigilante && p.isAlive);
        if (!blockedTargets.contains(vigilante.id)) {
          if (_nightVigilanteTarget != savedId) {
            killedIds.add(_nightVigilanteTarget!);
            print(
                '[GameManager] Vigilante kill scheduled: ${_nightVigilanteTarget}');
          } else {
            print('[GameManager] Vigilante kill saved by doctor');
          }
        } else {
          print('[GameManager] Vigilante blocked by escort');
        }
      } catch (_) {
        // no vigilante alive
      }
    }

    // 4. Serial Killer Kill
    if (_nightSerialKillerTarget != null) {
      final sk =
          players.firstWhere((p) => p.role == Role.serialKiller && p.isAlive);
      if (!blockedTargets.contains(sk.id)) {
        // SK usually kills through heals in some variants, but here we'll let doctor save.
        if (_nightSerialKillerTarget != savedId) {
          killedIds.add(_nightSerialKillerTarget!);
        }
      }
    }

    // Apply deaths
    for (final id in killedIds) {
      final victim = _findPlayer(id);
      if (victim != null) {
        victim.isAlive = false;
        print('[GameManager] Player eliminated: ${victim.id} (${victim.name})');
      }
    }

    _nightPendingKill = null;
    _nightSavedId = null;
    _nightVigilanteTarget = null;
    _nightSerialKillerTarget = null;
    _nightEscortBlocks.clear();
    checkWinCondition();
    print(
        '[GameManager] After resolution: alive=${alivePlayers.map((p) => p.id)}');
  }

  String? _findMafiaCaller() {
    // For simplicity, if any mafia is blocked, the consensus might fail?
    // Realsitically, we just check if the "attacker" was blocked.
    // Let's say if ALL alive mafia are blocked, the kill fails.
    final aliveMafia = this.aliveMafia();
    if (aliveMafia.every((m) => _nightEscortBlocks.values.contains(m.id)))
      return "ALL_BLOCKED";
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIN CONDITIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void checkWinCondition() {
    if (GameRules.townWin(players)) {
      gameOver = true;
      winningTeam = 'villagers';
      phase = GamePhase.result;
    } else if (GameRules.mafiaWin(players)) {
      gameOver = true;
      winningTeam = 'mafia';
      phase = GamePhase.result;
    } else if (GameRules.serialKillerWin(players)) {
      gameOver = true;
      winningTeam = 'serial_killer';
      phase = GamePhase.result;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Player? _findPlayer(String id) {
    return players.cast<Player?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
  }

  /// Get player name by ID
  String getPlayerName(String? id) {
    if (id == null) return 'Unknown';
    return _findPlayer(id)?.name ?? 'Unknown';
  }

  /// Get alive players
  List<Player> get alivePlayers => players.where((p) => p.isAlive).toList();

  /// Get alive non-mafia players (for mafia targeting)
  List<Player> aliveNonMafia() {
    return players.where((p) => p.isAlive && p.role != Role.mafia).toList();
  }

  /// Get alive mafia players (including Godfather)
  List<Player> aliveMafia() {
    return players
        .where((p) =>
            p.isAlive && (p.role == Role.mafia || p.role == Role.godfather))
        .toList();
  }

  /// Get players who voted last round (for aggressive bot)
  Set<String> lastRoundVoters() => Set<String>.from(_lastRoundVoters);

  void _assignRoles() {
    final rng = Random();
    final idxs = List<int>.generate(players.length, (i) => i)..shuffle(rng);

    // Use game config for role distribution
    int mafiaAssigned = 0;
    int gfAssigned = 0;
    int doctorAssigned = 0;
    int detectiveAssigned = 0;
    int vigAssigned = 0;
    int skAssigned = 0;
    int escortAssigned = 0;

    for (final i in idxs) {
      final player = players[i];

      // If moderator mode is on, assign the selected moderator
      if (gameConfig.isModeratorMode && player.id == moderatorId) {
        players[i] = players[i].copyWith(role: Role.moderator);
        continue;
      }

      if (mafiaAssigned < gameConfig.mafiaCount) {
        players[i] = players[i].copyWith(role: Role.mafia);
        mafiaAssigned++;
      } else if (gfAssigned < gameConfig.godfatherCount) {
        players[i] = players[i].copyWith(role: Role.godfather);
        gfAssigned++;
      } else if (doctorAssigned < gameConfig.doctorCount) {
        players[i] = players[i].copyWith(role: Role.doctor);
        doctorAssigned++;
      } else if (detectiveAssigned < gameConfig.detectiveCount) {
        players[i] = players[i].copyWith(role: Role.detective);
        detectiveAssigned++;
      } else if (vigAssigned < gameConfig.vigilanteCount) {
        players[i] = players[i].copyWith(role: Role.vigilante, bullets: 2);
        vigAssigned++;
      } else if (skAssigned < gameConfig.serialKillerCount) {
        players[i] = players[i].copyWith(role: Role.serialKiller);
        skAssigned++;
      } else if (escortAssigned < gameConfig.escortCount) {
        players[i] = players[i].copyWith(role: Role.escort);
        escortAssigned++;
      } else {
        players[i] = players[i].copyWith(role: Role.villager);
      }
    }
  }

  void _broadcastState() {
    if (_comm == null || !_isHost) return;
    final state = GameState(
      mode: mode,
      phase: phase,
      players: players,
      votes: votes,
    );
    _comm!.sendGameState(state);
  }

  void _onPhaseStarted() {
    // Haptic alert at phase start (if enabled)
    try {
      if (hapticsEnabled) HapticFeedback.vibrate();
    } catch (_) {}

    // Broadcast initial phase countdown to clients (if host)
    if (_isHost) {
      if (phase == GamePhase.discussion) {
        _lanComm?.broadcastPhaseCountdown(
            GamePhase.discussion.name, discussionSecondsLeft);
      } else if (phase == GamePhase.voting) {
        _lanComm?.broadcastPhaseCountdown(
            GamePhase.voting.name, votingSecondsLeft);
      } else if (phase == GamePhase.night) {
        _lanComm?.broadcastPhaseCountdown(
            GamePhase.night.name, nightSecondsLeft);
      }
    }
  }

  void attachReceiver(GameCommunication comm) {
    _comm = comm;
    comm.onGameStateReceived((incoming) {
      mode = incoming.mode;
      phase = incoming.phase;
      players = incoming.players;
      votes = Map<String, int>.from(incoming.votes);
      notifyListeners();
    });

    comm.onActionReceived((action) {
      if (isHost) {
        _handleIncomingAction(action);
      }
    });

    // If underlying comm supports team chat broadcasts, attach handler
    if (comm is LANCommunication) {
      comm.onTeamChatReceived = (team, senderId, senderName, message) {
        final chatMsg = ChatMessage(
          senderId: senderId,
          senderName: senderName,
          text: message,
          timestamp: DateTime.now(),
        );
        teamChatMessages.putIfAbsent(team, () => []).add(chatMsg);
        notifyListeners();
      };

      // Phase countdowns from host
      comm.onPhaseCountdownReceived = (phaseStr, value) {
        try {
          final p = GamePhase.values.firstWhere((e) => e.name == phaseStr);
          if (p == GamePhase.discussion) {
            discussionSecondsLeft = value;
          } else if (p == GamePhase.voting) {
            votingSecondsLeft = value;
          } else if (p == GamePhase.night) {
            nightSecondsLeft = value;
          }
          notifyListeners();
        } catch (_) {}
      };

      // Room settings updates from host (durations / haptics)
      comm.onRoomSettingsChanged = (discussion, voting, night, haptics) {
        if (discussion != null) setDiscussionDuration(discussion);
        if (voting != null) setVotingDuration(voting);
        if (night != null) setNightDuration(night);
        if (haptics != null) setHapticsEnabled(haptics);
      };
    }

    // If we are a client and just attached, send a join action
    if (!isHost && localPlayer != null) {
      comm.sendAction({
        'type': 'join',
        'id': localPlayerId,
        'name': localPlayer!.name,
      });
    }
  }

  void _handleIncomingAction(Map<String, dynamic> action) {
    final type = action['type'];
    switch (type) {
      case 'join':
        addRemotePlayer(action['id'], action['name']);
        break;
      case 'vote':
        castVote(action['voterId'], action['targetId']);
        break;
      case 'nightAction':
        handleNightAction(action['actorId'], action['targetId']);
        break;
      case 'request_restart':
        // A client asked the host to restart the match
        if (isHost) {
          restartGame();
        }
        break;
    }
  }

  // ===== Settings: durations & haptics =====
  void setDiscussionDuration(int seconds) {
    discussionDuration = seconds;
    // If we're in discussion, update the remaining seconds proportionally
    if (phase == GamePhase.discussion) {
      discussionSecondsLeft = discussionDuration;
      notifyListeners();
    }
  }

  void setVotingDuration(int seconds) {
    votingDuration = seconds;
    if (phase == GamePhase.voting) {
      votingSecondsLeft = votingDuration;
      notifyListeners();
    }
  }

  void setNightDuration(int seconds) {
    nightDuration = seconds;
    if (phase == GamePhase.night) {
      nightSecondsLeft = nightDuration;
      notifyListeners();
    }
  }

  void setHapticsEnabled(bool enabled) {
    hapticsEnabled = enabled;
    notifyListeners();
  }

  void sendChatMessage(String senderId, String text) {
    final sender = _findPlayer(senderId);
    if (sender == null) return;

    chatMessages.add(ChatMessage(
      senderId: senderId,
      senderName: sender.name,
      text: text,
      timestamp: DateTime.now(),
    ));

    _broadcastState();
    notifyListeners();
  }

  Future<void> startP2P() async {
    if (_comm is LANCommunication) {
      final lan = _comm as LANCommunication;
      final local = localPlayer;
      if (local == null) return;

      if (isHost) {
        await lan.startHosting(
            _currentRoomName ?? 'Game Room', local.name, local.id);
      } else {
        await lan.startDiscovery();
      }
    }
  }

  void stopP2P() {
    if (_comm is LANCommunication) {
      (_comm as LANCommunication).dispose();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAN COMMUNICATION METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  LANCommunication? _lanComm;
  final List<RoomInfo> _discoveredRooms = [];
  String? _currentRoomName;

  /// Get discovered rooms
  List<RoomInfo> get discoveredRooms => List.unmodifiable(_discoveredRooms);

  /// Get current room name
  String? get currentRoomName => _currentRoomName;

  /// Check if current room is private
  bool get isRoomPrivate => _lanComm?.isRoomPrivate ?? false;

  /// Get room PIN (for host to share)
  String? get roomPin => _lanComm?.roomPin;

  /// Initialize LAN hosting
  /// [isPrivate] - if true, room requires PIN to join
  /// [pin] - 4-digit PIN for private rooms
  Future<bool> createLANRoom(String playerName, String roomName,
      {bool isPrivate = false, String? pin}) async {
    _resetGame();
    mode = GameMode.offlineP2P;
    _isHost = true;
    _currentRoomName = roomName;

    final playerId = 'host_${DateTime.now().millisecondsSinceEpoch}';
    localPlayerId = playerId;

    // Create local player (host is always ready)
    players = [
      Player(
        id: playerId,
        name: playerName,
        role: Role.villager,
        isBot: false,
        isReady: true, // Host is always ready
      )
    ];

    // Clear disconnect state
    wasDisconnected = false;
    disconnectReason = null;
    lobbyChatMessages.clear();

    // Create LAN communication
    _lanComm = LANCommunication(isHost: true);
    _comm = _lanComm;

    // Set up callbacks
    _lanComm!.onPlayerJoined = (id, name) {
      addRemotePlayer(id, name);
    };

    _lanComm!.onPlayerLeft = (id) {
      players.removeWhere((p) => p.id == id);
      _lanComm!.updateRoomInfo(playerCount: players.length);

      // Cancel countdown if a player leaves
      if (isCountingDown) {
        cancelGameCountdown();
      }

      _broadcastState();
      notifyListeners();
    };

    // Handle ready state changes from clients
    _lanComm!.onPlayerReadyChanged = (playerId, isReady) {
      final playerIndex = players.indexWhere((p) => p.id == playerId);
      if (playerIndex >= 0) {
        players[playerIndex] = players[playerIndex].copyWith(isReady: isReady);
        // Broadcast to all clients
        _lanComm!.broadcastReadyState(playerId, isReady);
        _broadcastState();
        notifyListeners();
      }
    };

    // Handle chat messages from clients
    _lanComm!.onChatMessage = (senderId, senderName, message) {
      final chatMsg = ChatMessage(
        senderId: senderId,
        senderName: senderName,
        text: message,
        timestamp: DateTime.now(),
      );
      lobbyChatMessages.add(chatMsg);
      // Broadcast to all clients
      _lanComm!.broadcastChatMessage(senderId, senderName, message);
      notifyListeners();
    };

    // Handle countdown messages (won't receive as host, but set for consistency)
    _lanComm!.onCountdownReceived = (value) {
      countdownValue = value;
      isCountingDown = value > 0;
      notifyListeners();
    };

    // Handle team chat for host
    _lanComm!.onTeamChatReceived = (team, senderId, senderName, message) {
      final chatMsg = ChatMessage(
        senderId: senderId,
        senderName: senderName,
        text: message,
        timestamp: DateTime.now(),
      );
      teamChatMessages.putIfAbsent(team, () => []).add(chatMsg);
      notifyListeners();
    };

    // Handle game start messages (won't receive as host, but set for consistency)
    _lanComm!.onGameStartReceived = () {
      // Host starts game locally, doesn't receive this
    };

    // Start hosting with privacy settings
    final success = await _lanComm!.startHosting(
      roomName,
      playerName,
      playerId,
      isPrivate: isPrivate,
      pin: pin,
    );
    if (!success) {
      _lanComm = null;
      _comm = null;
      return false;
    }

    // Attach receiver for state sync
    attachReceiver(_lanComm!);

    notifyListeners();
    return true;
  }

  /// Start LAN room discovery
  Future<void> startLANDiscovery() async {
    _discoveredRooms.clear();
    // Defer notifyListeners to avoid calling during build
    Future.microtask(() => notifyListeners());

    // Check if platform supports LAN
    if (!LANCommunication.isSupported) {
      print('[GameManager] LAN not supported on this platform');
      return;
    }

    _lanComm = LANCommunication(isHost: false);
    _lanComm!.onRoomDiscovered = (room) {
      final existingIndex =
          _discoveredRooms.indexWhere((r) => r.hostId == room.hostId);
      if (existingIndex >= 0) {
        _discoveredRooms[existingIndex] = room;
      } else {
        _discoveredRooms.add(room);
      }
      // Defer notifyListeners to avoid calling during build
      Future.microtask(() => notifyListeners());
    };

    // Immediately remove rooms when the host broadcasts a closure
    _lanComm!.onRoomClosed = (hostId) {
      _discoveredRooms.removeWhere((r) => r.hostId == hostId);
      Future.microtask(() => notifyListeners());
    };

    await _lanComm!.startDiscovery();
  }

  /// Stop LAN room discovery
  void stopLANDiscovery() {
    _lanComm?.stopDiscovery();
    _discoveredRooms.clear();
    notifyListeners();
  }

  /// Join a discovered LAN room
  /// [pin] is required for private rooms
  Future<bool> joinLANRoom(RoomInfo room, String playerName,
      {String? pin}) async {
    _resetGame();
    mode = GameMode.offlineP2P;
    _isHost = false;
    _currentRoomName = room.roomName;

    final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}';
    localPlayerId = playerId;

    // Create local player (clients start not ready)
    players = [
      Player(
        id: playerId,
        name: playerName,
        role: Role.villager,
        isBot: false,
        isReady: false, // Clients must explicitly ready up
      )
    ];

    // Clear disconnect state
    wasDisconnected = false;
    disconnectReason = null;
    lobbyChatMessages.clear();

    // Set up LAN communication
    if (_lanComm == null) {
      _lanComm = LANCommunication(isHost: false);
    }
    _comm = _lanComm;

    _lanComm!.onDisconnectedFromHost = (reason) {
      // Handle disconnection with reason
      wasDisconnected = true;
      disconnectReason = reason;

      // Cancel countdown if host disconnects
      if (isCountingDown) {
        cancelGameCountdown();
      }

      notifyListeners();
    };

    _lanComm!.onJoinRejected = (reason) {
      // Could store the reason for UI
      notifyListeners();
    };

    // Handle ready state broadcasts from host
    _lanComm!.onPlayerReadyChanged = (playerId, isReady) {
      final playerIndex = players.indexWhere((p) => p.id == playerId);
      if (playerIndex >= 0) {
        players[playerIndex] = players[playerIndex].copyWith(isReady: isReady);
        notifyListeners();
      }
    };

    // Handle chat broadcasts from host
    _lanComm!.onChatMessage = (senderId, senderName, message) {
      final chatMsg = ChatMessage(
        senderId: senderId,
        senderName: senderName,
        text: message,
        timestamp: DateTime.now(),
      );
      lobbyChatMessages.add(chatMsg);
      notifyListeners();
    };

    // Handle countdown messages from host (clients only)
    _lanComm!.onCountdownReceived = (value) {
      countdownValue = value;
      isCountingDown = value > 0;
      notifyListeners();
    };

    // Handle game start messages from host (clients only)
    _lanComm!.onGameStartReceived = () {
      startGame();
      // Navigation will be handled by lobby screen
    };

    // Attach receiver before joining
    attachReceiver(_lanComm!);

    // Join the room with optional PIN
    final success =
        await _lanComm!.joinRoom(room, playerId, playerName, pin: pin);
    if (!success) {
      _lanComm = null;
      _comm = null;
      return false;
    }

    notifyListeners();
    return true;
  }

  /// Join a LAN room by IP address directly (fallback when discovery fails)
  /// [pin] is required for private rooms
  Future<bool> joinLANRoomByIp(String ip, String playerName,
      {int port = 41235, String? pin, bool isPrivate = false}) async {
    _resetGame();
    mode = GameMode.offlineP2P;
    _isHost = false;
    _currentRoomName = 'Room';

    final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}';
    localPlayerId = playerId;

    // Create local player (clients start not ready)
    players = [
      Player(
        id: playerId,
        name: playerName,
        role: Role.villager,
        isBot: false,
        isReady: false, // Clients must explicitly ready up
      )
    ];

    // Clear disconnect state
    wasDisconnected = false;
    disconnectReason = null;
    lobbyChatMessages.clear();

    // Set up LAN communication
    _lanComm = LANCommunication(isHost: false);
    _comm = _lanComm;

    _lanComm!.onDisconnectedFromHost = (reason) {
      wasDisconnected = true;
      disconnectReason = reason;

      // Cancel countdown if host disconnects
      if (isCountingDown) {
        cancelGameCountdown();
      }

      notifyListeners();
    };

    _lanComm!.onJoinRejected = (reason) {
      notifyListeners();
    };

    // Handle ready state broadcasts from host
    _lanComm!.onPlayerReadyChanged = (playerId, isReady) {
      final playerIndex = players.indexWhere((p) => p.id == playerId);
      if (playerIndex >= 0) {
        players[playerIndex] = players[playerIndex].copyWith(isReady: isReady);
        notifyListeners();
      }
    };

    // Handle chat broadcasts from host
    _lanComm!.onChatMessage = (senderId, senderName, message) {
      final chatMsg = ChatMessage(
        senderId: senderId,
        senderName: senderName,
        text: message,
        timestamp: DateTime.now(),
      );
      lobbyChatMessages.add(chatMsg);
      notifyListeners();
    };

    // Handle countdown messages from host (clients only)
    _lanComm!.onCountdownReceived = (value) {
      countdownValue = value;
      isCountingDown = value > 0;
      notifyListeners();
    };

    // Handle game start messages from host (clients only)
    _lanComm!.onGameStartReceived = () {
      startGame();
      // Navigation will be handled by lobby screen
    };

    attachReceiver(_lanComm!);

    // Join by IP directly with optional PIN
    final success = await _lanComm!.joinByIp(
      ip,
      playerId,
      playerName,
      port: port,
      pin: pin,
      isPrivate: isPrivate,
    );
    if (!success) {
      _lanComm = null;
      _comm = null;
      return false;
    }

    notifyListeners();
    return true;
  }

  bool _preserveRoomOnDispose = false;

  /// Preserve the hosted room when the current UI is disposed (useful for host restart -> lobby navigation).
  void preserveRoomForNextDispose() {
    _preserveRoomOnDispose = true;
  }

  /// Leave LAN room (client)
  Future<void> leaveLANRoom() async {
    if (_lanComm != null) {
      if (_isHost) {
        if (_preserveRoomOnDispose) {
          // Consume the flag and keep hosting active (restart flow).
          _preserveRoomOnDispose = false;
          notifyListeners();
          return;
        } else {
          await _lanComm!.stopHosting();
        }
      } else {
        await _lanComm!.leaveRoom();
      }
      _lanComm = null;
      _comm = null;
    }
    _resetGame();
    notifyListeners();
  }

  /// Kick a player from LAN room (host only)
  void kickLANPlayer(String playerId) {
    if (!_isHost || _lanComm == null) return;

    _lanComm!.kickClient(playerId);
    players.removeWhere((p) => p.id == playerId);
    _lanComm!.updateRoomInfo(playerCount: players.length);
    _broadcastState();
    notifyListeners();
  }

  /// Check if connected to LAN
  bool get isLANConnected => _lanComm?.isConnected ?? false;

  /// Get host IP address (for host only, to show to players)
  String? get hostIp => _lanComm?.currentRoom?.hostIp;

  /// Get host port (for host only, to show to players)
  int? get hostPort => _lanComm?.currentRoom?.hostPort;

  /// Update room settings (host only)
  void updateRoomSettings({
    int? maxPlayers,
    bool? isPrivate,
    String? newPin,
    bool? chatEnabled,
    bool? moderatorMode,
    bool? botsEnabled,
    int? botCount,
    int? discussionDurationSec,
    int? votingDurationSec,
    int? nightDurationSec,
    bool? hapticsEnabled,
  }) {
    if (!_isHost || _lanComm == null) return;

    // Broadcast to clients
    _lanComm!.updateRoomSettings(
      maxPlayers: maxPlayers,
      isPrivate: isPrivate,
      newPin: newPin,
      chatEnabled: chatEnabled,
      moderatorMode: moderatorMode,
      botsEnabled: botsEnabled,
      botCount: botCount,
      discussionDuration: discussionDurationSec,
      votingDuration: votingDurationSec,
      nightDuration: nightDurationSec,
      hapticsEnabled: hapticsEnabled,
    );

    // Apply bot configuration locally for host
    if (botsEnabled != null || botCount != null) {
      final enabled =
          botsEnabled ?? _lanComm!.currentRoom?.botsEnabled ?? false;
      final count = botCount ?? _lanComm!.currentRoom?.botCount ?? 0;
      setRoomBots(enabled: enabled, count: count);
    }

    // Apply durations/haptics locally for host immediately
    if (discussionDurationSec != null)
      setDiscussionDuration(discussionDurationSec);
    if (votingDurationSec != null) setVotingDuration(votingDurationSec);
    if (nightDurationSec != null) setNightDuration(nightDurationSec);
    if (hapticsEnabled != null) setHapticsEnabled(hapticsEnabled);

    notifyListeners();
  }

  /// Get current room info
  RoomInfo? get currentRoom => _lanComm?.currentRoom;

  /// Add or remove bots in the lobby (host only)
  void setRoomBots({required bool enabled, required int count}) {
    if (!_isHost) return;

    // Remove all bots if disabled
    if (!enabled) {
      players.removeWhere((p) => p.isBot);
      _lanComm?.updateRoomInfo(playerCount: players.length);
      _broadcastState();
      notifyListeners();
      return;
    }

    // Compute caps based on max players
    final currentBots = players.where((p) => p.isBot).toList();
    final humanCount = players.where((p) => !p.isBot).length;
    final maxPlayers =
        _lanComm?.currentRoom?.maxPlayers ?? this.gameConfig.playerCount;
    final maxAllowedBots = maxPlayers - humanCount;
    final desiredBotCount = count.clamp(0, maxAllowedBots);
    final delta = desiredBotCount - currentBots.length;

    final rng = Random();
    final names = [
      'Alice',
      'Bob',
      'Cara',
      'Dan',
      'Eve',
      'Finn',
      'Gina',
      'Hank',
      'Ivy',
      'Jack',
      'Luna'
    ];
    final personalities = BotPersonality.values;

    if (delta > 0) {
      for (var i = 0; i < delta; i++) {
        // Pick base name and ensure unique numbering if duplicate
        final baseName = names[rng.nextInt(names.length)];
        final existing =
            players.where((p) => p.name.startsWith(baseName)).toList();
        final suffix = existing.isEmpty ? '' : ' #${existing.length + 1}';
        final name = '$baseName$suffix';
        final id =
            'bot_${DateTime.now().millisecondsSinceEpoch}_${rng.nextInt(9999)}';
        final bot = Player(
          id: id,
          name: name,
          role: Role.villager, // will be reassigned when game starts
          isBot: true,
          personality: personalities[rng.nextInt(personalities.length)],
          isReady: true, // bots are auto-ready in lobby
        );
        players.add(bot);
      }
    } else if (delta < 0) {
      var toRemove = -delta;
      // Remove last added bots
      for (int i = players.length - 1; i >= 0 && toRemove > 0; i--) {
        if (players[i].isBot) {
          players.removeAt(i);
          toRemove--;
        }
      }
    }

    // Ensure bots are ready
    players =
        players.map((p) => p.isBot ? p.copyWith(isReady: true) : p).toList();

    _lanComm?.updateRoomInfo(playerCount: players.length);
    _broadcastState();
    notifyListeners();

    // Let bots send a short lobby greeting if chat is enabled
    if (_lanComm?.currentRoom?.chatEnabled == true) {
      _bot ??= BotController(this);
      final newBots = players.where((p) => p.isBot).toList();
      for (final bot in newBots) {
        // schedule a brief delayed greeting
        Future.delayed(Duration(seconds: Random().nextInt(3) + 1), () {
          _bot?.sendLobbyGreeting(bot);
        });
      }
    }
  }

  /// Host-side method to send a lobby chat message from a bot
  void sendLobbyChatMessageFromBot(String botId, String message) {
    final bot = players
        .cast<Player?>()
        .firstWhere((p) => p?.id == botId, orElse: () => null);
    if (bot == null) return;

    final chatMsg = ChatMessage(
      senderId: bot.id,
      senderName: bot.name,
      text: message,
      timestamp: DateTime.now(),
    );

    lobbyChatMessages.add(chatMsg);
    _lanComm?.broadcastChatMessage(bot.id, bot.name, message);
    notifyListeners();
  }

  /// Start game countdown (host only)
  Future<void> startGameCountdown() async {
    if (!_isHost || !canStartGame || isCountingDown) return;

    isCountingDown = true;
    countdownValue = 5;

    // Set countdown flag on room to prevent joins
    if (_lanComm?.currentRoom != null) {
      _lanComm!.currentRoom!.isCountingDown = true;
    }

    notifyListeners();

    // Broadcast countdown start to all clients
    _lanComm?.broadcastCountdown(countdownValue);

    // Countdown from 5 to 1
    for (int i = 5; i >= 1; i--) {
      if (!isCountingDown) {
        // Countdown was cancelled
        if (_lanComm?.currentRoom != null) {
          _lanComm!.currentRoom!.isCountingDown = false;
        }
        return;
      }

      countdownValue = i;
      notifyListeners();
      _lanComm?.broadcastCountdown(i);

      await Future.delayed(const Duration(seconds: 1));
    }

    // Check again before starting (in case host disconnected during countdown)
    if (!isCountingDown) {
      if (_lanComm?.currentRoom != null) {
        _lanComm!.currentRoom!.isCountingDown = false;
      }
      return;
    }

    // Countdown complete - start the game
    isCountingDown = false;
    countdownValue = 0;
    if (_lanComm?.currentRoom != null) {
      _lanComm!.currentRoom!.isCountingDown = false;
    }
    notifyListeners();

    // Broadcast game start to all clients
    _lanComm?.broadcastGameStart();

    // Start the game
    startGame();

    // Navigate to role reveal will be handled in lobby screen
  }

  /// Cancel game countdown (host only, or on host disconnect)
  void cancelGameCountdown() {
    if (isCountingDown) {
      isCountingDown = false;
      countdownValue = 0;
      if (_lanComm?.currentRoom != null) {
        _lanComm!.currentRoom!.isCountingDown = false;
      }
      notifyListeners();
    }
  }

  /// Send a team/private chat message (e.g., mafia chat)
  void sendTeamChat(String team, String message) {
    final sender = localPlayer;
    if (sender == null) return;

    final chatMsg = ChatMessage(
      senderId: sender.id,
      senderName: sender.name,
      text: message,
      timestamp: DateTime.now(),
    );

    // Store locally
    teamChatMessages.putIfAbsent(team, () => []).add(chatMsg);

    if (_isHost) {
      // Host broadcasts directly to clients
      if (_lanComm is LANCommunication) {
        (_lanComm as LANCommunication)
            .broadcastTeamChat(team, sender.id, sender.name, message);
      }
    } else {
      // Client sends to host
      if (_lanComm is LANCommunication) {
        (_lanComm as LANCommunication)
            .sendTeamChat(team, message, sender.id, sender.name);
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    stopP2P();
    _lanComm?.dispose();
    _phaseTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}

class ChatMessage {
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        senderId: json['senderId'],
        senderName: json['senderName'],
        text: json['text'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}
