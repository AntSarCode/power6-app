import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';

class LogoutPill extends StatelessWidget {
  const LogoutPill({super.key});

  Future<void> _doLogout(BuildContext context) async {
    await AuthService().logout();

    context.read<AppState>().logout();

    // Route back to login and clear back stack
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'logout-pill',
      onPressed: () => _doLogout(context),
      label: const Text(
        'Logout',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      icon: const Icon(Icons.logout),
    );
  }
}
