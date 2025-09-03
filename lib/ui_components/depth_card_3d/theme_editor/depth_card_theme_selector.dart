import 'package:flutter/material.dart';
import '../models/depth_card_theme.dart';

class DepthCardThemeSelector extends StatelessWidget {
  final Function(DepthCardTheme) onThemeSelected;
  final String? selectedName;

  const DepthCardThemeSelector({
    super.key,
    required this.onThemeSelected,
    this.selectedName,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: DepthCardTheme.presets.map((theme) {
        final isSelected = theme.name == selectedName;
        return GestureDetector(
          onTap: () => onThemeSelected(theme),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.overlayColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.style, color: theme.textColor),
                const SizedBox(height: 8),
                Text(theme.name, style: TextStyle(color: theme.textColor)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
