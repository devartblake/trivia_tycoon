import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserTypeFilter { all, admin, premium, regular }
enum TimeframeFilter { allTime, daily, weekly, monthly }

final userTypeFilterProvider = StateProvider<UserTypeFilter>((ref) => UserTypeFilter.all);
final timeframeFilterProvider = StateProvider<TimeframeFilter>((ref) => TimeframeFilter.allTime);

class AnalyticsFilterTabs extends ConsumerWidget {
  const AnalyticsFilterTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userType = ref.watch(userTypeFilterProvider);
    final timeframe = ref.watch(timeframeFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text("User Type", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SegmentedButton<UserTypeFilter>(
            segments: const [
              ButtonSegment(value: UserTypeFilter.all, label: Text("All")),
              ButtonSegment(value: UserTypeFilter.admin, label: Text("Admin")),
              ButtonSegment(value: UserTypeFilter.premium, label: Text("Premium")),
              ButtonSegment(value: UserTypeFilter.regular, label: Text("Regular")),
            ],
            selected: <UserTypeFilter>{userType},
            onSelectionChanged: (newSelection) =>
            ref.read(userTypeFilterProvider.notifier).state = newSelection.first,
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text("Timeframe", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SegmentedButton<TimeframeFilter>(
            segments: const [
              ButtonSegment(value: TimeframeFilter.allTime, label: Text("All Time")),
              ButtonSegment(value: TimeframeFilter.daily, label: Text("Daily")),
              ButtonSegment(value: TimeframeFilter.weekly, label: Text("Weekly")),
              ButtonSegment(value: TimeframeFilter.monthly, label: Text("Monthly")),
            ],
            selected: <TimeframeFilter>{timeframe},
            onSelectionChanged: (newSelection) =>
            ref.read(timeframeFilterProvider.notifier).state = newSelection.first,
          ),
        ),
      ],
    );
  }
}
