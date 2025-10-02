import 'package:flutter/material.dart';
import 'ui/theme.dart';
import 'screens/login_screen.dart';
import 'navigation/main_nav.dart';

class PowerApp extends StatelessWidget {
  const PowerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Power6',
      theme: appTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/': (context) => const MainNav(),
      },
    );
  }
}