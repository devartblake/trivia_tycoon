import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum for Timeline ranges
enum TimelineRange { last7Days, last14Days, last30Days, last90Days }

/// Provider to hold currently selected timeline range
final timelineFilterProvider = StateProvider<TimelineRange>((ref) {
  return TimelineRange.last7Days; // Default to 7d
});
