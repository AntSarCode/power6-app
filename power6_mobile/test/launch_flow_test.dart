import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:power6_mobile/navigation/main_nav.dart';
import 'package:power6_mobile/screens/signup_screen.dart';
import 'package:power6_mobile/services/api_service.dart';
import 'package:power6_mobile/services/auth_service.dart';
import 'package:power6_mobile/state/app_state.dart';

class SignupAuth extends AuthService {
  SignupAuth({this.profileAvailable = true});
  final bool profileAvailable;

  @override
  Future<ApiResponse> register(
          {required String username,
          required String email,
          required String password}) async =>
      ApiResponse.success({'access_token': 'test-token'});

  @override
  Future<ApiResponse> getCurrentUser() async => profileAvailable
      ? ApiResponse.success({
          'user': {
            'id': 1,
            'username': 'member',
            'email': 'member@example.com',
            'tier': 'free'
          }
        })
      : ApiResponse.failure('offline');
}

void main() {
  for (final available in [true, false]) {
    testWidgets('signup hydrates profile before onboarding: $available',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
            home: SignUpScreen(
                authService: SignupAuth(profileAvailable: available)),
            routes: {
              '/onboarding': (_) =>
                  const Scaffold(body: Text('Onboarding ready'))
            }),
      ));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'member');
      await tester.enterText(fields.at(1), 'member@example.com');
      await tester.enterText(fields.at(2), 'Password123!');
      await tester.enterText(fields.at(3), 'Password123!');
      await tester.ensureVisible(find.text('Sign up'));
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();
      if (available) {
        expect(find.text('Onboarding ready'), findsOneWidget);
        expect(state.user?.tier, 'free');
        expect(state.accessToken, 'test-token');
      } else {
        expect(find.text('Onboarding ready'), findsNothing);
        expect(find.text('Account created. Please log in to start planning.'),
            findsOneWidget);
        expect(state.accessToken, isNull);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'hidden paid tabs initialize only on first visit and retain state',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var subscriptionStarts = 0;
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
          home: MainNav(screens: [
        const Text('Dashboard content'),
        const SizedBox(),
        const SizedBox(),
        const SizedBox(),
        const SizedBox(),
        _VisitProbe(onStart: () => subscriptionStarts++),
        const SizedBox(),
      ])),
    ));
    await tester.pumpAndSettle();
    expect(subscriptionStarts, 0);
    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();
    expect(subscriptionStarts, 1);
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();
    expect(subscriptionStarts, 1);
  });
}

class _VisitProbe extends StatefulWidget {
  const _VisitProbe({required this.onStart});
  final VoidCallback onStart;
  @override
  State<_VisitProbe> createState() => _VisitProbeState();
}

class _VisitProbeState extends State<_VisitProbe> {
  @override
  void initState() {
    super.initState();
    widget.onStart();
  }

  @override
  Widget build(BuildContext context) => const Text('Subscription content');
}
