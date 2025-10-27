// lib/config/api_constants.dart
class ApiConstants {
  // Include '/api' here if your backend routers are mounted with prefix="/api".
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // If your backend is at /api, set: 'https://power6-backend.onrender.com/api'
    defaultValue: 'https://power6-backend.onrender.com',
  );

  // ---- Auth ----
  static String get login => '/auth/login';
  static String get register => '/auth/register';
  static String get me => '/auth/me';

  // ---- Tasks ----
  static String get tasks => '/tasks';

  static String get streak => '/streak';

  static String get streakRefresh => '/streak/refresh';

  static String taskById(int id) => '/tasks/$id';
}