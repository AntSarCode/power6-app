class Env {
  // Build-time define with a safe default so the app never crashes if it's missing.
  static const String apiBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://power6-backend.onrender.com',
  );
}
