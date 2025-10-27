import '../env.dart';

class ApiConstants {
  static const String baseUrl = Env.apiBase;

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