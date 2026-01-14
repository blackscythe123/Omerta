// Game-wide enums and state model used by both modes

import 'player.dart';

enum GameMode {
  offlineP2P,
  soloBots,
}

enum GamePhase {
  lobby,
  night,
  mafiaVoting, // New phase for mafia to vote on kill target
  discussion,
  voting,
  result,
}

/// Configuration for role distribution based on player count
class GameConfig {
  final int playerCount;
  final int mafiaCount;
  final int doctorCount;
  final int detectiveCount;
  final int godfatherCount;
  final int vigilanteCount;
  final int serialKillerCount;
  final int escortCount;
  final bool isModeratorMode;

  const GameConfig({
    required this.playerCount,
    required this.mafiaCount,
    this.doctorCount = 1,
    this.detectiveCount = 1,
    this.godfatherCount = 0,
    this.vigilanteCount = 0,
    this.serialKillerCount = 0,
    this.escortCount = 0,
    this.isModeratorMode = false,
  });

  int get villagerCount {
    int count = playerCount -
        mafiaCount -
        doctorCount -
        detectiveCount -
        godfatherCount -
        vigilanteCount -
        serialKillerCount -
        escortCount;
    return count;
  }

  GameConfig copyWith({
    int? playerCount,
    int? mafiaCount,
    int? doctorCount,
    int? detectiveCount,
    int? godfatherCount,
    int? vigilanteCount,
    int? serialKillerCount,
    int? escortCount,
    bool? isModeratorMode,
  }) {
    return GameConfig(
      playerCount: playerCount ?? this.playerCount,
      mafiaCount: mafiaCount ?? this.mafiaCount,
      doctorCount: doctorCount ?? this.doctorCount,
      detectiveCount: detectiveCount ?? this.detectiveCount,
      godfatherCount: godfatherCount ?? this.godfatherCount,
      vigilanteCount: vigilanteCount ?? this.vigilanteCount,
      serialKillerCount: serialKillerCount ?? this.serialKillerCount,
      escortCount: escortCount ?? this.escortCount,
      isModeratorMode: isModeratorMode ?? this.isModeratorMode,
    );
  }

  /// Get recommended config for a given player count
  static GameConfig forPlayerCount(int count) {
    switch (count) {
      case 6:
        // 6: 2 Mafia (1 GF), 1 Cop, 1 Doctor, 2 Vil
        return const GameConfig(
            playerCount: 6,
            mafiaCount: 1,
            godfatherCount: 1,
            detectiveCount: 1,
            doctorCount: 1);
      case 7:
        // 7: 2 Mafia (1 GF), 1 Cop, 1 Doctor, 3 Vil (1 Vig)
        return const GameConfig(
            playerCount: 7,
            mafiaCount: 1,
            godfatherCount: 1,
            detectiveCount: 1,
            doctorCount: 1,
            vigilanteCount: 1);
      case 8:
        // 8: 2 Mafia (1 GF), 1 Cop, 1 Doctor, 4 Vil (1 Vig)
        return const GameConfig(
            playerCount: 8,
            mafiaCount: 1,
            godfatherCount: 1,
            detectiveCount: 1,
            doctorCount: 1,
            vigilanteCount: 1);
      case 9:
        // 9: 3 Mafia (1 GF), 1 Cop, 1 Doctor, 4 Vil (1 Vig, 1 Escort)
        return const GameConfig(
            playerCount: 9,
            mafiaCount: 2,
            godfatherCount: 1,
            detectiveCount: 1,
            doctorCount: 1,
            vigilanteCount: 1,
            escortCount: 1);
      case 10:
        // 10: 3 Mafia (1 GF), 1 Cop, 1 Doctor, 5 Vil (1 Vig, 1 Escort)
        return const GameConfig(
            playerCount: 10,
            mafiaCount: 2,
            godfatherCount: 1,
            detectiveCount: 1,
            doctorCount: 1,
            vigilanteCount: 1,
            escortCount: 1);
      case 11:
        // 11: 3 Mafia (1 GF), 1 Cop, 1 Doctor, 6 Vil (1 Vig, 1 Escort, 1 SK)
        return const GameConfig(
            playerCount: 11,
            mafiaCount: 2,
            godfatherCount: 1,
            detectiveCount: 1,
            doctorCount: 1,
            vigilanteCount: 1,
            serialKillerCount: 1,
            escortCount: 1);
      case 12:
      default:
        // 12: 4 Mafia (1 GF), 1 Cop, 1 Doctor, 6 Vil (2 Vig, 1 Escort, 1 SK)
        return const GameConfig(
            playerCount: 12,
            mafiaCount: 3,
            godfatherCount: 1,
            detectiveCount: 1,
            doctorCount: 1,
            vigilanteCount: 2,
            serialKillerCount: 1,
            escortCount: 1);
    }
  }

  /// Available player count options
  static const List<int> playerCountOptions = [6, 7, 8, 9, 10, 11, 12];

  @override
  String toString() {
    return 'GameConfig(players: $playerCount, mafia: $mafiaCount, doctor: $doctorCount, detective: $detectiveCount, villagers: $villagerCount)';
  }
}

class GameState {
  final GameMode mode;
  final GamePhase phase;
  final List<Player> players;
  final Map<String, int> votes; // targetId -> count
  final Map<String, String> mafiaNightVotes; // mafiaPlayerId -> targetId

  GameState({
    required this.mode,
    required this.phase,
    required this.players,
    required this.votes,
    this.mafiaNightVotes = const {},
  });

  GameState copyWith({
    GameMode? mode,
    GamePhase? phase,
    List<Player>? players,
    Map<String, int>? votes,
    Map<String, String>? mafiaNightVotes,
  }) {
    return GameState(
      mode: mode ?? this.mode,
      phase: phase ?? this.phase,
      players: players ?? this.players,
      votes: votes ?? this.votes,
      mafiaNightVotes: mafiaNightVotes ?? this.mafiaNightVotes,
    );
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      mode: GameMode.values.firstWhere((m) => m.name == json['mode'] as String),
      phase:
          GamePhase.values.firstWhere((p) => p.name == json['phase'] as String),
      players: (json['players'] as List<dynamic>)
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList(),
      votes: Map<String, int>.from(json['votes'] as Map<dynamic, dynamic>),
      mafiaNightVotes: json['mafiaNightVotes'] != null
          ? Map<String, String>.from(
              json['mafiaNightVotes'] as Map<dynamic, dynamic>)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'phase': phase.name,
      'players': players.map((p) => p.toJson()).toList(),
      'votes': votes,
      'mafiaNightVotes': mafiaNightVotes,
    };
  }
}
