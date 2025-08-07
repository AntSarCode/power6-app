import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/badge.dart' as userbadge;
import '../services/api_response.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BadgeService {
  static Future<ApiResponse<List<userbadge.Badge>>> fetchUserBadges(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://your.api.endpoint/api/dashboard/badges'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final badges = jsonList.map((json) => userbadge.Badge.fromJson(json)).toList();
        return ApiResponse.success(badges);
      } else {
        return ApiResponse.failure('Failed to fetch badges: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.failure('Error: $e');
    }
  }
}

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  late Future<List<userbadge.Badge>> _badges;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  void _loadBadges() async {
    final token = context.read<AppState>().accessToken ?? '';
    final response = await BadgeService.fetchUserBadges(token);
    if (response.isSuccess && response.data != null) {
      setState(() {
        _badges = Future.value(response.data);
      });
    } else {
      setState(() {
        _badges = Future.error(response.error ?? 'Failed to load badges');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🏅 Your Badges')),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: FutureBuilder<List<userbadge.Badge>>(
                future: _badges,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No badges earned yet.'));
                  }

                  return Wrap(
                    spacing: 16.0,
                    runSpacing: 16.0,
                    children: snapshot.data!.map((badge) {
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                            ),
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
    );
  }
}
