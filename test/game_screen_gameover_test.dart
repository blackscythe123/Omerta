import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:Omerta/game/game_manager.dart';
import 'package:Omerta/screens/game_screen.dart';
import 'package:Omerta/screens/game_over_screen.dart';
import 'package:Omerta/models/player.dart';
import 'package:Omerta/models/game_state.dart';

void main() {
  testWidgets('GameScreen navigates to GameOver when gameOver is true',
      (WidgetTester tester) async {
    final gm = GameManager();

    // Setup players: one mafia, one villager
    gm.players = [
      Player(id: 'm1', name: 'M', role: Role.mafia, isBot: false),
      Player(id: 'p1', name: 'A', role: Role.villager, isBot: false),
    ];
    gm.localPlayerId = 'm1';

    // Increase test window size to avoid layout overflow on GameOverScreen
    final binding = tester.binding;
    binding.window.physicalSizeTestValue = const Size(800, 1200);
    binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    // Build app
    await tester.pumpWidget(
      ChangeNotifierProvider<GameManager>.value(
        value: gm,
        child: MaterialApp(
          routes: {
            '/': (ctx) => const SizedBox.shrink(),
            '/game': (ctx) => const GameScreenNew(),
            '/game-over': (ctx) => const GameOverScreen(),
          },
          initialRoute: '/game',
        ),
      ),
    );

    // Simulate game over state
    gm.winningTeam = 'mafia';
    gm.gameOver = true;
    gm.phase = GamePhase.result;

    // Propagate change
    gm.notifyListeners();

    // Allow post-frame navigation
    await tester.pumpAndSettle();

    expect(find.text('GAME OVER'), findsOneWidget);
  });
}
