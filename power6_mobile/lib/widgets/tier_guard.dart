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
      if (fallback != null) return fallback!;
      return _UpgradePrompt(requiredTier: requiredTier);
    }

    return child;
  }
}

class _UpgradePrompt extends StatelessWidget {
  final UserTier requiredTier;

  const _UpgradePrompt({required this.requiredTier});

  @override
  Widget build(BuildContext context) {
    final label = requiredTier.name.toUpperCase();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                size: 44,
                color: Color(0xFF64FFDA),
              ),
              const SizedBox(height: 14),
              Text(
                '$label feature',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upgrade to access this feature. You can keep using your dashboard, tasks, review, account settings, and subscription options on the free tier.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/upgrade'),
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('Upgrade'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/home'),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Back to Home'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
