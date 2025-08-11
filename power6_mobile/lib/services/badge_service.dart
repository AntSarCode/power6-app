import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/badge.dart' as userbadge;
import 'api_response.dart';

/// BadgeService: fetches badges from the backend and never throws.
class BadgeService {
  static const String _baseUrl = 'https://power6-backend.onrender.com';
  static const Duration _timeout = Duration(seconds: 15);

  /// Safe GET helper that accepts absolute or relative paths.
  static Future<ApiResponse<dynamic>> _get(String path, {String? token}) async {
    try {
      final uri = Uri.parse(
        path.startsWith('http') ? path : '$_baseUrl${path.startsWith('/') ? path : '/$path'}',
      );

      final res = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      if (res.statusCode == 204 || res.body.isEmpty) {
        return ApiResponse.success(null);
      }

      if (res.statusCode >= 200 && res.statusCode < 300) {
        try {
          return ApiResponse.success(jsonDecode(res.body));
        } catch (_) {
          return ApiResponse.success(null); // non-JSON success
        }
      }

      return ApiResponse.failure('Request failed (${res.statusCode})');
    } on TimeoutException {
      return ApiResponse.failure('Network timeout. Please try again.');
    } catch (e) {
      return ApiResponse.failure('Network error: $e');
    }
  }

  /// Returns user's badges. Empty list if not logged in or none found.
  static Future<ApiResponse<List<userbadge.Badge>>> fetchUserBadges(String token) async {
    if (token.isEmpty) {
      return ApiResponse.success(<userbadge.Badge>[]); // don't hit network without auth
    }

    final resp = await _get('/api/dashboard/badges', token: token);
    if (!resp.isSuccess) {
      return ApiResponse.failure(resp.error ?? 'Unable to load badges');
    }

    final data = resp.data;
    final raw = data == null
        ? <dynamic>[]
        : (data is Map && data['badges'] is List)
            ? (data['badges'] as List)
            : (data is List)
                ? data
                : <dynamic>[];

    final list = raw
        .whereType<Map<String, dynamic>>()
        .map((j) => userbadge.Badge.fromJson(j))
        .toList();

    return ApiResponse.success(list);
  }
}