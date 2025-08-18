class ApiConstants {
  /// Overridable at build time with --dart-define=API_BASE_URL=...
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://power6-backend.onrender.com',
  );

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String currentUser = '/auth/me';

  static const String tasks = '/tasks';
  static const String taskReview = '/tasks/review';
  static const String taskSubmit = '/tasks/submit';

  static const String streak = '/users/streak';
  static const String streakRefresh = '/users/streak/refresh';

  static const String badges = '/badges';
}
