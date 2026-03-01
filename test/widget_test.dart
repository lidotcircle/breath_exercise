import 'package:breath_execise/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app renders main title', (tester) async {
    await tester.pumpWidget(const BreathingApp());
    await tester.pumpAndSettle();

    expect(find.text('呼吸练习APP'), findsOneWidget);
    expect(find.text('练习'), findsOneWidget);
    expect(find.text('预设'), findsOneWidget);
  });
}
