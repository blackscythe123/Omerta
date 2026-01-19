import 'package:flutter_test/flutter_test.dart';
import 'package:Omerta/game/game_manager.dart';
import 'package:Omerta/models/player.dart';
import 'package:Omerta/models/game_state.dart';

void main() {
  group('GameManager unit tests', () {
    test('Bots are ready in solo initialization', () {
      final gm = GameManager();
      gm.initializeSoloGame(playerCount: 6);

      final bots = gm.players.where((p) => p.isBot).toList();
      expect(bots.isNotEmpty, true);
      expect(bots.every((b) => b.isReady), true);
    });

    test('Mafia majority produces consensus and pending kill', () {
      final gm = GameManager();
      // Create simple lobby: 3 players, 2 mafia
      gm.players = [
        Player(id: 'p1', name: 'A', role: Role.mafia, isBot: false),
        Player(id: 'p2', name: 'B', role: Role.mafia, isBot: false),
        Player(id: 'p3', name: 'C', role: Role.villager, isBot: false),
      ];
      gm.phase = GamePhase.night;

      gm.submitMafiaVote('p1', 'p3');
      // No consensus yet (not all mafia have voted)
      expect(gm.mafiaConsensusTarget, isNot('p3'));

      gm.submitMafiaVote('p2', 'p3');
      // Both mafia voted for p3 -> consensus
      expect(gm.mafiaConsensusTarget, equals('p3'));
    });

    test('Detective inspection sets lastInspectedPlayerId and result', () {
      final gm = GameManager();
      // Setup players with one detective and one mafia target
      gm.players = [
        Player(id: 'd1', name: 'Detective', role: Role.detective, isBot: false),
        Player(id: 't1', name: 'Target', role: Role.mafia, isBot: false),
      ];
      gm.localPlayerId = 'd1';
      gm.phase = GamePhase.night;

      gm.handleNightAction('d1', 't1');

      expect(gm.lastInspectedPlayerId, equals('t1'));
      // Godfather appears innocent; mafia should be reported true
      expect(gm.lastInspectionResult, isTrue);
    });
  });
}
