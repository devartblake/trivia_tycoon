import 'package:flutter/material.dart';
import '../core/presets/confetti_presets.dart';
import '../core/confetti_theme.dart';

class ConfettiPresetSelector extends StatelessWidget {
  final Function(ConfettiTheme) onPresetsSelected;

  const ConfettiPresetSelector({super.key, required this.onPresetsSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ConfettiPresets.allPresets.map((preset) {
          return GestureDetector(
            onTap: () => onPresetsSelected(preset),
            child: MouseRegion(
              onEnter: (_) => _onHover(preset, true),
              onExit: (_) => _onHover(preset, false),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              margin: EdgeInsets.symmetric(horizontal: 8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    preset.previewImage,
                    width: 40,
                    height: 40,
                  ),
                  SizedBox(height: 4),
                  Text(
                    preset.name,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _onHover(ConfettiTheme preset, bool isHovered) {
    // Future functionality: Highlight or animate preset
  }
}
