/// Admin providers — filter state and analytics pipeline.
///
/// Depends only on [core_providers.dart].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/controllers/admin_filter_controller.dart';
import '../../admin/states/admin_filter_state.dart';
import '../../game/analytics/services/analytics_service.dart';
import '../../core/services/event_queue_service.dart';
import 'core_providers.dart';

// ---------------------------------------------------------------------------
// Admin filter
// ---------------------------------------------------------------------------

final adminFilterProvider =
StateNotifierProvider<AdminFilterController, AdminFilterState>(
      (ref) => AdminFilterController(ref),
);

// ---------------------------------------------------------------------------
// Analytics
// ---------------------------------------------------------------------------

final eventQueueServiceProvider = Provider<EventQueueService>((ref) {
  return EventQueueService();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final api = ref.watch(apiServiceProvider);
  final queue = ref.watch(eventQueueServiceProvider);
  return AnalyticsService(api, queue);
});