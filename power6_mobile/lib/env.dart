import 'package:flutter/foundation.dart';

class Env {
  static const String prodBase = String.fromEnvironment('BASE_URL',
      defaultValue: 'https://power6-backend.onrender.com');
  static const String devBase  = 'http://127.0.0.1:8000';

  static String get apiBase => kReleaseMode ? prodBase : devBase;
}
