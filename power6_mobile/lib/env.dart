class Env {
  /// Single source of truth for API base.
  /// Override with --dart-define=API_BASE_URL=...
  static const String base = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://power6-backend.onrender.com',
  );

  static String get apiBase => base;
}
