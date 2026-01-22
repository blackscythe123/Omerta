import 'package:flutter_test/flutter_test.dart';
import 'package:Omerta/game/game_manager.dart';
import 'package:Omerta/models/player.dart';
import 'package:Omerta/models/game_state.dart';

void main() {
  group('Restart behavior', () {
    test('restartGame resets currentDay and returns to lobby', () {
      final gm = GameManager();

      // Simulate mid-game state
      gm.players = [
        Player(id: 'p1', name: 'A', role: Role.villager, isBot: false),
        Player(id: 'm1', name: 'M', role: Role.mafia, isBot: false),
      ];
      gm.phase = GamePhase.result;
      gm.currentDay = 9;
      gm.gameOver = true;
      gm.winningTeam = 'mafia';

      gm.restartGame();

      expect(gm.currentDay, equals(1));
      expect(gm.phase, equals(GamePhase.lobby));
      expect(gm.gameOver, isFalse);
      expect(gm.winningTeam, isNull);
      expect(gm.players.every((p) => p.isReady == false), isTrue);
      expect(gm.players.every((p) => p.isAlive == true), isTrue);
    });
  });
}
