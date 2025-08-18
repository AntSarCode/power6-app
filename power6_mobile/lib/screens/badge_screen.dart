import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/badge.dart' as userbadge;
import '../services/badge_service.dart';
import '../utils/access.dart';
import '../widgets/tier_guard.dart';

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  Future<List<userbadge.Badge>> _badges = Future.value(<userbadge.Badge>[]);
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    setState(() {
      _errorMessage = null;
    });

    final token = context.read<AppState>().accessToken ?? '';

    if (token.isEmpty) {
      setState(() => _badges = Future.value(<userbadge.Badge>[]));
      return;
    }

    try {
      final response = await BadgeService.fetchUserBadges(token);
      if (response.isSuccess) {
        setState(() => _badges = Future.value(response.data ?? <userbadge.Badge>[]));
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Unable to load badges right now.';
          _badges = Future.value(<userbadge.Badge>[]);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Badges currently unavailable. Please try again soon.';
        _badges = Future.value(<userbadge.Badge>[]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TierGuard(
      requiredTier: UserTier.elite,
      child: Scaffold(
        appBar: AppBar(title: const Text('🏅 Your Badges')),
        body: LayoutBuilder(
          builder: (context, constraints) => RefreshIndicator(
            onRefresh: _loadBadges,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: FutureBuilder<List<userbadge.Badge>>(
                    future: _badges,
                    initialData: const <userbadge.Badge>[],
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final items = snapshot.data ?? <userbadge.Badge>[];

                      if (items.isEmpty) {
                        final title = _errorMessage == null
                            ? 'No badges earned yet.'
                            : 'Badges temporarily unavailable';
                        final subtitle = _errorMessage == null
                            ? 'Complete tasks and streaks to unlock achievements.'
                            : _errorMessage!;

                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text(subtitle, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _loadBadges, child: const Text('Retry')),
                            ],
                          ),
                        );
                      }

                      return Wrap(
                        spacing: 16.0,
                        runSpacing: 16.0,
                        children: items.map((badge) {
                          final title = badge.title;
                          final description = badge.description;

                          return Container(
                            width: constraints.maxWidth < 400 ? double.infinity : 160,
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.teal.shade50,
                              border: Border.all(color: Colors.teal.shade200),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.emoji_events, size: 40, color: Colors.teal.shade700),
                                const SizedBox(height: 8),
                                Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      fallback: Scaffold(
        appBar: AppBar(title: const Text('🏅 Your Badges')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'This feature is available to Elite users only.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
