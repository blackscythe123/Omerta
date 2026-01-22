import 'package:flutter_test/flutter_test.dart';
import 'package:Omerta/game/game_manager.dart';
import 'package:Omerta/models/player.dart';
import 'package:Omerta/models/game_state.dart';

void main() {
  // Ensure bindings (used by HapticFeedback in GameManager._onPhaseStarted)
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Night resolution - vigilante and mafia interactions', () {
    
    test('mafia and vigilante kills both applied when different targets', () {
      final gm = GameManager();

      gm.players = [
        Player(id: 'm1', name: 'M1', role: Role.mafia, isBot: false),
        Player(id: 'm2', name: 'M2', role: Role.mafia, isBot: false),
        Player(
            id: 'v',
            name: 'Vig',
            role: Role.vigilante,
            isBot: false,
            bullets: 1),
        Player(id: 'd', name: 'Doc', role: Role.doctor, isBot: false),
        Player(id: 't1', name: 'T1', role: Role.villager, isBot: false),
        Player(id: 't2', name: 'T2', role: Role.villager, isBot: false),
      ];

      gm.phase = GamePhase.night;

      // Mafia consensus kills t1
      gm.submitMafiaVote('m1', 't1');
      gm.submitMafiaVote('m2', 't1');

      // Vigilante kills t2
      gm.handleNightAction('v', 't2');

      // Advance phase to trigger resolution
      gm.advancePhase();

      final t1 = gm.players.firstWhere((p) => p.id == 't1');
      final t2 = gm.players.firstWhere((p) => p.id == 't2');

      expect(t1.isAlive, isFalse, reason: 'Mafia kill should eliminate t1');
      expect(t2.isAlive, isFalse, reason: 'Vigilante kill should eliminate t2');
    });

    test('mafia and vigilante same target saved by doctor results in no death',
        () {
      final gm = GameManager();

      gm.players = [
        Player(id: 'm1', name: 'M1', role: Role.mafia, isBot: false),
        Player(id: 'm2', name: 'M2', role: Role.mafia, isBot: false),
        Player(
            id: 'v',
            name: 'Vig',
            role: Role.vigilante,
            isBot: false,
            bullets: 1),
        Player(id: 'd', name: 'Doc', role: Role.doctor, isBot: false),
        Player(id: 't', name: 'Target', role: Role.villager, isBot: false),
      ];

      gm.phase = GamePhase.night;

      // Both target the same player
      gm.submitMafiaVote('m1', 't');
      gm.submitMafiaVote('m2', 't');
      gm.handleNightAction('v', 't');

      // Doctor saves target
      gm.handleNightAction('d', 't');

      gm.advancePhase();

      final t = gm.players.firstWhere((p) => p.id == 't');
      expect(t.isAlive, isTrue, reason: 'Saved target should remain alive');
    });
  });
}
