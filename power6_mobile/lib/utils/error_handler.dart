class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error == null) return "An unknown error occurred.";

    if (error is String) return error;

    if (error is Exception) return error.toString();

    try {
      return error.message ?? error.toString();
    } catch (_) {
      return "An unexpected error occurred.";
    }
  }

  static void logError(dynamic error, [StackTrace? stackTrace]) {
    // Replace this with a logging tool if needed (e.g., Sentry, Firebase Crashlytics)
    print("[ERROR] \${getErrorMessage(error)}");
    if (stackTrace != null) {
      print("[STACK TRACE] \$stackTrace");
    }
  }
}