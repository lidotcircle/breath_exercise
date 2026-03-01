import 'package:breath_execise/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app renders main title', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const BreathingApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('呼吸练习'), findsOneWidget);
    expect(find.text('练习'), findsOneWidget);
    expect(find.text('预设'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });
}
