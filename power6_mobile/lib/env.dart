class Env {
  /// Compile-time define with a production-safe default.
  /// IMPORTANT: If your FastAPI routers are mounted with prefix "/api",
  /// keep the default including "/api". Otherwise, remove it.
  static const String apiBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://power6-backend.onrender.com/api',
  );
}
