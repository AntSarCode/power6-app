class DateUtils {
  static String formatDate(DateTime date) {
    return "\${date.year}-\${_twoDigits(date.month)}-\${_twoDigits(date.day)}";
  }

  static String formatTime(DateTime time) {
    return "\${_twoDigits(time.hour)}:\${_twoDigits(time.minute)}";
  }

  static String formatDateTime(DateTime dateTime) {
    return "\${formatDate(dateTime)} \${formatTime(dateTime)}";
  }

  static String getDayOfWeek(DateTime date) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[date.weekday - 1];
  }

  static String getMonthName(int month) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[month - 1];
  }

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
