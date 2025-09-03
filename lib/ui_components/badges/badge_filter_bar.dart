import 'package:flutter/material.dart';

class BadgeFilterBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const BadgeFilterBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: categories.map((cat) {
        return ChoiceChip(
          label: Text(cat),
          selected: cat == selected,
          onSelected: (_) => onSelected(cat),
        );
      }).toList(),
    );
  }
}