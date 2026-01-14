import 'package:flutter_test/flutter_test.dart';
import 'package:Omerta/main.dart';

void main() {
  testWidgets('Mafia App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MafiaApp());

    // Verify that the splash/home screen shows Omertà.
    expect(find.text('Omertà'), findsOneWidget);
  });
}
