// lib/config/api_constants.dart
import '../env.dart';

class ApiConstants {
  static const String _fallback = 'https://power6-backend.onrender.com';

  /// Backward-compatible base URL property (no trailing slash).
  static String get baseUrl {
    final raw = (Env.apiBase).trim();
    final b = raw.isEmpty ? _fallback : raw;
    return b.endsWith('/') ? b.substring(0, b.length - 1) : b;
  }

  /// Normalize any endpoint to start with a single leading slash.
  static String normalize(String path) =>
      path.startsWith('/') ? path : '/$path';

  // Named endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static String get me => '/auth/me';

  static const String tasks = '/tasks';
  static String taskById(String id) => '/tasks/$id';

  static const String streak = '/streak';
  static const String streakRefresh = '/streak/refresh';
}