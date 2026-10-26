import 'package:flutter_test/flutter_test.dart';
import 'package:booster_tcg/main.dart';

void main() {
  testWidgets('App basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BoosterApp());
    expect(find.byType(BoosterApp), findsOneWidget);
  });
}
