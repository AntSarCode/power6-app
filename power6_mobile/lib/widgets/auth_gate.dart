import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  final Widget child;

  const AuthGate({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isAuthenticated = appState.accessToken != null && appState.accessToken!.isNotEmpty;

    return isAuthenticated ? child : const LoginScreen();
  }
}
