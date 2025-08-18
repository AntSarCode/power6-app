import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/badge.dart' as badge_model;
import 'api_response.dart';

/// Central API base (overridable via --dart-define=API_BASE_URL=...)
const String kApiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://power6-backend.onrender.com',
);

Uri _buildUri(String path) {
  if (path.startsWith('http')) return Uri.parse(path);
  final normalized = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$kApiBase$normalized');
}

Map<String, String> _headers(String? token) => {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

/// API service for Power6 app.
class ApiService {
  static const Duration _timeout = Duration(seconds: 15);

  static String get baseUrl => kApiBase; // for debugging/logging if needed

  Future<ApiResponse<dynamic>> get(String path, {String? token}) async {
    try {
      final uri = _buildUri(path);
      final res = await http.get(uri, headers: _headers(token)).timeout(_timeout);

      if (res.statusCode == 204 || res.body.isEmpty) {
        return ApiResponse.success(null);
      }

      if (res.statusCode >= 200 && res.statusCode < 300) {
        try {
          return ApiResponse.success(jsonDecode(res.body));
        } catch (_) {
          return ApiResponse.success(null);
        }
      }

      return ApiResponse.failure('Request failed (${res.statusCode})');
    } on TimeoutException {
      return ApiResponse.failure('Network timeout. Please try again.');
    } catch (_) {
      return ApiResponse.failure('Network error. Please check connection.');
    }
  }

  /// Convenience POST (kept minimal; expands as needed)
  Future<ApiResponse<dynamic>> post(String path, {String? token, Object? body}) async {
    try {
      final uri = _buildUri(path);
      final res = await http
          .post(uri, headers: _headers(token), body: body == null ? null : jsonEncode(body))
          .timeout(_timeout);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return ApiResponse.success(res.body.isEmpty ? null : jsonDecode(res.body));
      }
      return ApiResponse.failure('Request failed (${res.statusCode})');
    } on TimeoutException {
      return ApiResponse.failure('Network timeout. Please try again.');
    } catch (_) {
      return ApiResponse.failure('Network error. Please check connection.');
    }
  }

  Future<ApiResponse<List<badge_model.Badge>>> fetchUserBadges(String token) async {
    if (token.isEmpty) {
      return ApiResponse.success(<badge_model.Badge>[]);
    }

    final response = await get('/api/dashboard/badges', token: token);
    if (!response.isSuccess) {
      return ApiResponse.failure(response.error ?? 'Unable to load badges');
    }

    final data = response.data;
    final rawList = data == null
        ? <dynamic>[]
        : (data is Map && data['badges'] is List)
            ? (data['badges'] as List)
            : (data is List)
                ? data
                : <dynamic>[];

    final badges = rawList
        .whereType<Map<String, dynamic>>()
        .map((j) => badge_model.Badge.fromJson(j))
        .toList();

    return ApiResponse.success(badges);
  }
}

/// Badge display screen.
class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  Future<List<badge_model.Badge>> _badges = Future.value(<badge_model.Badge>[]);
  String? _softError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _softError = null);
    final token = context.read<AppState>().accessToken ?? '';

    if (token.isEmpty) {
      setState(() => _badges = Future.value(<badge_model.Badge>[]));
      return;
    }

    final result = await ApiService().fetchUserBadges(token);
    if (result.isSuccess) {
      setState(() => _badges = Future.value(result.data ?? <badge_model.Badge>[]));
    } else {
      setState(() {
        _softError = result.error ?? 'Badges currently unavailable.';
        _badges = Future.value(<badge_model.Badge>[]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final isPro = user?.tier == 'pro' || user?.tier == 'elite' || user?.tier == 'admin';

    if (!isPro) {
      return Scaffold(
        appBar: AppBar(title: const Text('Badges')),
        body: const Center(child: Text('Upgrade to Pro to unlock badges!')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('🏅 Your Badges')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: FutureBuilder<List<badge_model.Badge>>(
          future: _badges,
          initialData: const <badge_model.Badge>[],
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = snapshot.data ?? <badge_model.Badge>[];

            if (items.isEmpty) {
              final title = _softError == null ? 'No badges yet.' : 'Badges temporarily unavailable';
              final subtitle = _softError == null
                  ? 'Complete tasks and build streaks to earn achievements.'
                  : _softError!;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(subtitle, textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final b = items[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(b.achieved ? Icons.emoji_events : Icons.lock_outline),
                    title: Text(b.title),
                    subtitle: Text(b.description),
                    trailing: Icon(
                      Icons.check_circle,
                      color: b.achieved ? Colors.teal : Colors.grey,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}