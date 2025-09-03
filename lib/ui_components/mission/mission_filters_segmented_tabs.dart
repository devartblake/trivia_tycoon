import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/providers/mission_filters_provider.dart';

class MissionFiltersSegmentedTabs extends ConsumerWidget {
  const MissionFiltersSegmentedTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(missionFiltersProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          _buildTabRow(
            label: "User Type",
            options: const ["All", "Admin", "Premium", "Guest"],
            selected: filter.userType,
            onSelect: (val) => ref.read(missionFiltersProvider.notifier).updateUserType(val),
          ),
          const SizedBox(height: 12),
          _buildTabRow(
            label: "Timeframe",
            options: const ["Daily", "Weekly", "Monthly"],
            selected: filter.timeframe,
            onSelect: (val) => ref.read(missionFiltersProvider.notifier).updateTimeframe(val),
          ),
        ],
      ),
    );
  }

  Widget _buildTabRow({
    required String label,
    required List<String> options,
    required String selected,
    required void Function(String) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: options.map((e) => ButtonSegment(value: e, label: Text(e))).toList(),
          selected: {selected},
          onSelectionChanged: (values) => onSelect(values.first),
        ),
      ],
    );
  }
}
