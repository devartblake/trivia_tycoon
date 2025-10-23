import 'package:flutter/material.dart';

class SegmentedTabs extends StatelessWidget {
  final int index;
  final List<String> tabs;
  final ValueChanged<int> onChanged;
  const SegmentedTabs({super.key, required this.index, required this.tabs, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        for (var i = 0; i < tabs.length; i++) ButtonSegment(value: i, label: Text(tabs[i])),
      ],
      selected: {index},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
