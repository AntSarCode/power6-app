class ApiConstants {
  static const String baseUrl = "http://127.0.0.1:8000";

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
