import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:Omerta/game/game_manager.dart';
import 'package:Omerta/screens/game_screen.dart';
import 'package:Omerta/models/player.dart';

void main() {
  testWidgets('Detective sees inspection result dialog when available',
      (WidgetTester tester) async {
    final gm = GameManager();

    // Setup a detective local player and a target
    gm.players = [
      Player(id: 'd1', name: 'Detective', role: Role.detective, isBot: false),
      Player(id: 't1', name: 'Target', role: Role.mafia, isBot: false),
    ];
    gm.localPlayerId = 'd1';

    // Initially no inspection
    await tester.pumpWidget(ChangeNotifierProvider<GameManager>.value(
      value: gm,
      child: const MaterialApp(home: GameScreenNew()),
    ));

    // Now set inspection result
    gm.lastInspectedPlayerId = 't1';
    gm.lastInspectionResult = true;
    gm.notifyListeners();

    // allow post frame callbacks and dialog to appear
    await tester.pumpAndSettle();

    expect(find.text('Investigation Result'), findsOneWidget);
    expect(find.textContaining('Target is likely MAFIA'), findsOneWidget);
  });
}
