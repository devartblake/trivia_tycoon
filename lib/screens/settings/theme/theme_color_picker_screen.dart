import 'package:flutter/material.dart';
import '../../../ui_components/color_picker/color_picker.dart';

class ThemeColorPickerScreen extends StatefulWidget {
  const ThemeColorPickerScreen({super.key});

  @override
  State<ThemeColorPickerScreen> createState() => _ThemeColorPickerScreenState();
}

class _ThemeColorPickerScreenState extends State<ThemeColorPickerScreen> {
  Color selectedColor = Colors.blue;
  final List<Color> recentColors = [];

  void _openColorPicker() async {
    final result = await ColorPicker.showColorPickerDialog(context, initialColor: selectedColor);
    if (result != null) {
      setState(() {
        selectedColor = result;
        if (!recentColors.contains(result)) {
          recentColors.insert(0, result);
          if (recentColors.length > 6) recentColors.removeLast();
        }
      });
    }
  }

  String _getColorHex(Color color) => '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

  String _getColorName(Color color) {
    final hex = _getColorHex(color);
    const names = {
      "#FF0000FF": "Blue",
      "#FF00FF00": "Green",
      "#FFFF0000": "Red",
      "#FFFFFFFF": "White",
      "#FF000000": "Black",
      "#FFFFFF00": "Yellow",
    };
    return names[hex] ?? "Custom Color";
  }

  @override
  Widget build(BuildContext context) {
    final colorHex = _getColorHex(selectedColor);
    final colorName = _getColorName(selectedColor);

    return Scaffold(
      appBar: AppBar(title: const Text("🎨 Pick a Color")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _openColorPicker,
                icon: const Icon(Icons.palette),
                label: const Text("Open Color Picker"),
              ),
              const SizedBox(height: 20),

              // 🔵 Live Preview
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: selectedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                colorName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                colorHex,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () => Navigator.pop(context, selectedColor),
                child: const Text("✅ Apply Color"),
              ),
              const SizedBox(height: 24),

              // ⏱️ Recent History
              if (recentColors.isNotEmpty) ...[
                const Text("Recent Colors"),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: recentColors.map((c) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = c),
                      child: CircleAvatar(
                        backgroundColor: c,
                        radius: 18,
                        child: selectedColor == c
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
