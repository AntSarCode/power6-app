import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../state/app_state.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _deleting = false;
  String? _error;

  Future<void> _deleteAccount() async {
    final app = context.read<AppState>();
    final token = app.accessToken ?? await AuthService.getToken();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      setState(() => _error = 'You must be logged in to delete your account.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your Power6 account, tasks, subscriptions, badges, and related data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _deleting = true;
      _error = null;
    });

    final response = await AuthService().deleteAccount(token);
    if (!mounted) return;

    if (response.isSuccess) {
      await app.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    setState(() {
      _deleting = false;
      _error = response.error ?? 'Account deletion failed.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.user;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person_outline, color: cs.secondary),
              title: Text(user?.username ?? 'Power6 user'),
              subtitle: Text(user?.email ?? 'Signed in'),
            ),
            const Divider(height: 32),
            Text(
              'Account deletion',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Delete your account and remove your tasks, subscription records, badges, and related Power6 data.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _deleting ? null : _deleteAccount,
              icon: _deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_forever_outlined),
              label: Text(_deleting ? 'Deleting...' : 'Delete Account'),
            ),
          ],
        ),
      ),
    );
  }
}
