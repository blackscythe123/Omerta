// Core game rules helpers without side effects

import '../models/player.dart';

class GameRules {
  // Return alive players
  static List<Player> alivePlayers(List<Player> players) {
    return players.where((p) => p.isAlive && p.role != Role.moderator).toList();
  }

  // Count how many alive players have the given role
  static int countAliveRole(List<Player> players, Role role) {
    return players.where((p) => p.isAlive && p.role == role).length;
  }

  // Count Mafia (including Godfather)
  static int countAliveMafia(List<Player> players) {
    return players
        .where((p) =>
            p.isAlive && (p.role == Role.mafia || p.role == Role.godfather))
        .length;
  }

  // Townies are non-mafia and non-neutral
  static int countAliveTown(List<Player> players) {
    return players
        .where((p) =>
            p.isAlive &&
            p.role != Role.mafia &&
            p.role != Role.godfather &&
            p.role != Role.serialKiller &&
            p.role != Role.moderator)
        .length;
  }

  // Determine majority target from votes map
  static String? majorityTarget(Map<String, int> votes,
      {bool breakTiesRandom = true}) {
    if (votes.isEmpty) return null;
    final maxCount = votes.values.fold<int>(0, (a, b) => a > b ? a : b);
    final leaders = votes.entries
        .where((e) => e.value == maxCount)
        .map((e) => e.key)
        .toList();
    if (leaders.isEmpty) return null;
    if (leaders.length == 1 || breakTiesRandom) {
      leaders.shuffle();
      return leaders.first;
    }
    return null;
  }

  // Win condition checks
  static bool townWin(List<Player> players) {
    return countAliveMafia(players) == 0 &&
        countAliveRole(players, Role.serialKiller) == 0;
  }

  static bool mafiaWin(List<Player> players) {
    final mafia = countAliveMafia(players);
    final others = alivePlayers(players).length - mafia;
    // Mafia wins if they equal or outnumber others (and SK is dead)
    return mafia >= others &&
        mafia > 0 &&
        countAliveRole(players, Role.serialKiller) == 0;
  }

  static bool serialKillerWin(List<Player> players) {
    final sk = countAliveRole(players, Role.serialKiller);
    final total = alivePlayers(players).length;
    // SK wins if they are one of the last 2 standing
    return sk > 0 && total <= 2;
  }
}
