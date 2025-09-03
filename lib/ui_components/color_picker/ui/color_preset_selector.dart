import 'package:flutter/material.dart';
import '../presets/color_presets.dart';

class ColorPresetSelector extends StatelessWidget {
  final Function(Color) onColorSelected;

  const ColorPresetSelector({super.key, required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ColorPresets.defaultColors.map((color) {
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 50,
              height: 50,
              margin: EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26, width: 2),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
