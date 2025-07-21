class ApiConstants {
  static const String baseUrl = 'http://localhost:8000'; // or your deployed URL

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String currentUser = '/auth/me';

  static const String tasks = '/tasks';
  static const String taskReview = '/tasks/review';
  static const String taskSubmit = '/tasks/submit';

  static const String streak = '/users/streak';
  static const String badges = '/badges';
}
