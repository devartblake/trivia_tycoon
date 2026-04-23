import 'package:flutter/material.dart';

const _kIntervals = ['none', 'hourly', 'daily', 'weekly', 'seasonal'];
const _kLabels = {
  'none': 'None',
  'hourly': 'Hourly',
  'daily': 'Daily',
  'weekly': 'Weekly',
  'seasonal': 'Seasonal',
};

/// Segmented button / dropdown for selecting a stock reset interval.
class StockIntervalSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool useDropdown;

  const StockIntervalSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.useDropdown = false,
  });

  @override
  Widget build(BuildContext context) {
    if (useDropdown) return _buildDropdown(context);
    return _buildSegmented(context);
  }

  Widget _buildDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Reset Interval',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: _kIntervals
          .map((i) => DropdownMenuItem(value: i, child: Text(_kLabels[i]!)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSegmented(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reset Interval',
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _kIntervals.map((interval) {
            final selected = value == interval;
            return ChoiceChip(
              label: Text(_kLabels[interval]!),
              selected: selected,
              onSelected: (_) => onChanged(interval == 'none' ? null : interval),
              selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: selected ? const Color(0xFF6366F1) : Colors.grey[700],
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: selected
                    ? const Color(0xFF6366F1)
                    : Colors.grey.shade300,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
