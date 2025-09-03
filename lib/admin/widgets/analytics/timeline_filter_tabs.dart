import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/timeline_filter_provider.dart';

class TimelineFilterTabs extends ConsumerWidget {
  const TimelineFilterTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRange = ref.watch(timelineFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<TimelineRange>(
        segments: const [
          ButtonSegment(
            value: TimelineRange.last7Days,
            label: Text('7D'),
          ),
          ButtonSegment(
            value: TimelineRange.last14Days,
            label: Text('14D')
          ),
          ButtonSegment(
            value: TimelineRange.last30Days,
            label: Text('30D'),
          ),
          ButtonSegment(
            value: TimelineRange.last90Days,
            label: Text('90D'),
          ),
        ],
        selected: {currentRange},
        onSelectionChanged: (newSelection) {
          ref.read(timelineFilterProvider.notifier).state = newSelection.first;
        },
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(Colors.blueAccent.withOpacity(0.2)),
          padding: MaterialStatePropertyAll(const EdgeInsets.symmetric(horizontal: 8)),
        ),
      ),
    );
  }
}
