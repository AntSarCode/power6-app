import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';

class LogoutPill extends StatelessWidget {
  final bool compact;

  const LogoutPill({super.key, this.compact = false});

  const LogoutPill.compact({super.key}) : compact = true;

  Future<void> _doLogout(BuildContext context) async {
    await AuthService().logout();

    await context.read<AppState>().logout();

    // Route back to login and clear back stack
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return TextButton.icon(
        onPressed: () => _doLogout(context),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Logout'),
      );
    }

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
