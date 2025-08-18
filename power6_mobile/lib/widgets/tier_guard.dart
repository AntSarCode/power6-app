import 'package:flutter/material.dart';
import '../utils/access.dart';
import '../state/app_state.dart';
import 'package:provider/provider.dart';

class TierGuard extends StatelessWidget {
  final UserTier requiredTier;
  final Widget child;
  final Widget? fallback; // e.g., Upgrade screen teaser

  const TierGuard({
    super.key,
    required this.requiredTier,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.user;

    if (user == null) {
      // not logged in -> to Login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const SizedBox.shrink();
    }

    if (!hasAccess(requiredTier, user.tier)) {
      // insufficient tier -> to Upgrade (or show fallback inline)
      if (fallback != null) return fallback!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/upgrade');
      });
      return const SizedBox.shrink();
    }

    return child;
  }
}
