import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:power6_mobile/main.dart';

void main() {
  testWidgets('Power6 starts at login when unauthenticated',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const Power6App());
    await tester.pumpAndSettle();

    expect(find.text('Power6'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
  });
}
