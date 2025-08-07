import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/api_service.dart'; // Updated import
import '../models/badge.dart' as model;

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  List<model.Badge> _badges = [];
  bool _loading = true;
  String? _error;
  final _apiService = ApiService(); // Updated instance

  bool hasEliteAccess(String? tier) {
    return tier == 'elite' || tier == 'admin';
  }

  @override
  void initState() {
    super.initState();
    _fetchBadges();
  }

  void _fetchBadges() async {
    final token = context.read<AppState>().accessToken;
    final result = await _apiService.fetchUserBadges(token ?? ""); // Updated call
    if (result.isSuccess) {
      setState(() {
        _badges = result.data!;
        _loading = false;
      });
    } else {
      setState(() {
        _error = result.error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final tier = user?.tier;

    if (!hasEliteAccess(tier)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Badges')),
        body: const Center(
          child: Text("Upgrade to Elite to unlock badges!"),
        ),
      );
    }

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Badges')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Badges')),
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Badges')),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _badges.length,
        itemBuilder: (context, index) {
          final badge = _badges[index];
          final icon = badge.achieved
              ? Icons.emoji_events
              : Icons.lock_outline;

          return ListTile(
            title: Text(badge.title),
            subtitle: Text(badge.description),
            trailing: Icon(icon, color: badge.achieved ? Colors.deepPurple : Colors.grey),
          );
        },
      ),
    );
  }
}