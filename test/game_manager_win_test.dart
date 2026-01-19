import 'package:flutter_test/flutter_test.dart';
import 'package:Omerta/game/game_manager.dart';
import 'package:Omerta/models/player.dart';
import 'package:Omerta/models/game_state.dart';

void main() {
  group('Win condition tests', () {
    test('Town win triggers gameOver and result phase', () {
      final gm = GameManager();
      gm.players = [
        Player(id: 'p1', name: 'A', role: Role.villager, isBot: false),
        Player(id: 'p2', name: 'B', role: Role.villager, isBot: false),
      ];

      // Ensure no mafia or serial killer alive
      gm.checkWinCondition();

      expect(gm.gameOver, isTrue);
      expect(gm.winningTeam, equals('villagers'));
      expect(gm.phase, equals(GamePhase.result));
    });

    test('Mafia win triggers gameOver and result phase', () {
      final gm = GameManager();
      gm.players = [
        Player(id: 'm1', name: 'M', role: Role.mafia, isBot: false),
        Player(id: 'p1', name: 'A', role: Role.villager, isBot: false),
      ];

      // With 1 mafia and 1 other, mafia >= others -> mafia win
      gm.checkWinCondition();

      expect(gm.gameOver, isTrue);
      expect(gm.winningTeam, equals('mafia'));
      expect(gm.phase, equals(GamePhase.result));
    });
  });
}
