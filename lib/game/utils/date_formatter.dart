/// Utility functions for date formatting
class DateFormatter {
  /// Format a DateTime for display in the UI
  /// Shows "Today HH:MM" for same day, otherwise "MM/DD HH:MM"
  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final isSameDay = now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;

    final hours = dateTime.hour.toString().padLeft(2, '0');
    final minutes = dateTime.minute.toString().padLeft(2, '0');
    final time = '$hours:$minutes';

    if (isSameDay) {
      return 'Today $time';
    } else {
      return '${dateTime.month}/${dateTime.day} $time';
    }
  }

  /// Format duration as HH:MM:SS
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Format relative time (e.g., "2 hours ago", "in 3 days")
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    final absDiff = difference.abs();

    if (absDiff.inSeconds < 60) {
      return difference.isNegative ? 'just now' : 'in a moment';
    } else if (absDiff.inMinutes < 60) {
      final mins = absDiff.inMinutes;
      return difference.isNegative
          ? '$mins ${mins == 1 ? 'minute' : 'minutes'} ago'
          : 'in $mins ${mins == 1 ? 'minute' : 'minutes'}';
    } else if (absDiff.inHours < 24) {
      final hours = absDiff.inHours;
      return difference.isNegative
          ? '$hours ${hours == 1 ? 'hour' : 'hours'} ago'
          : 'in $hours ${hours == 1 ? 'hour' : 'hours'}';
    } else {
      final days = absDiff.inDays;
      return difference.isNegative
          ? '$days ${days == 1 ? 'day' : 'days'} ago'
          : 'in $days ${days == 1 ? 'day' : 'days'}';
    }
  }
}
