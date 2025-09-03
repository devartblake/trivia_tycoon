import 'package:flutter/material.dart';

class BadgeCategoryTabs extends StatelessWidget {
  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const BadgeCategoryTabs({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      onTap: onChanged,
      tabs: tabs.map((tab) => Tab(text: tab)).toList(),
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Theme.of(context).colorScheme.primary,
    );
  }
}