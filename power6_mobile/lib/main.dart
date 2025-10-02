import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ui/theme.dart';
import 'state/app_state.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/streak_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/power_badge_screen.dart';
import 'screens/subscription_screen.dart' as subs;
import 'navigation/main_nav.dart';

// Services
import 'services/streak_service.dart';

/// Global messenger key so overlays/snackbars can work from anywhere.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Power6App());
}

class Power6App extends StatelessWidget {
  const Power6App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        Provider(create: (_) => StreakService()),
      ],
      child: MaterialApp(
        title: 'Power6',
        theme: appTheme, // unified dark theme from /ui/theme.dart
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: scaffoldMessengerKey,
        home: const _RootGate(),
        routes: {
          '/home': (ctx) => const MainNav(),
          '/login': (ctx) => const LoginScreen(),
          '/signup': (ctx) => const SignUpScreen(),
          '/streak': (ctx) => const StreakScreen(),
          '/timeline': (ctx) => const TimelineScreen(),
          '/badges': (ctx) => const PowerBadgeScreen(),
          '/upgrade': (ctx) => const subs.SubscriptionScreen(),
          '/subscribe': (ctx) => const subs.SubscriptionScreen(),
        },
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      ),
    );
  }
}

/// Decides where to start based on auth state
class _RootGate extends StatefulWidget {
  const _RootGate({Key? key}) : super(key: key);

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      final hasToken = (appState.accessToken ?? '').isNotEmpty;
      if (!mounted) return;
      if (hasToken) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Minimal splash while we decide the start route.
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}