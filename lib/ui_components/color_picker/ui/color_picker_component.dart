import 'package:flutter/material.dart';
import 'color_slider_picker.dart';
import 'color_wheel_picker.dart';

class ColorPickerComponent extends StatefulWidget {
  final List<Color> selectedColors;
  final ValueChanged<List<Color>> onColorsChanged;

  const ColorPickerComponent({
    super.key,
    required this.selectedColors,
    required this.onColorsChanged,
  });

  @override
  _ColorPickerComponentState createState() => _ColorPickerComponentState();
}

class _ColorPickerComponentState extends State<ColorPickerComponent> {
  List<Color> _colors = [];

  @override
  void initState() {
    super.initState();
    _colors = List.from(widget.selectedColors);
  }

  void _pickColor() async {
    Color selectedColor = _colors.isNotEmpty ? _colors.first : Colors.blue;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Pick a color"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// 🎡 Color Wheel Picker
                ColorWheelPicker(
                  initialColor: selectedColor,
                  selectedColor: selectedColor,
                  onColorChanged: (color) {
                    setStateDialog(() => selectedColor = color);
                  },
                  onColorSelected: (color) {
                    setStateDialog(() => selectedColor = color);
                  },
                ),

                const SizedBox(height: 8),

                /// 🎛️ Sliders
                ColorSliderPicker(
                  initialColor: selectedColor,
                  color: selectedColor,
                  onColorChanged: (color) {
                    setStateDialog(() => selectedColor = color);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (!_colors.contains(selectedColor)) {
                      _colors.add(selectedColor);
                    }
                  });
                  widget.onColorsChanged(_colors);
                  Navigator.pop(context);
                },
                child: const Text("Select"),
              ),
            ],
          );
        });
      },
    );
  }

  void _removeColor(Color color) {
    setState(() {
      _colors.remove(color);
    });
    widget.onColorsChanged(_colors);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Selected Colors", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                children: _colors.map((color) {
                  return Chip(
                    backgroundColor: color,
                    avatar: CircleAvatar(backgroundColor: color),
                    onDeleted: () => _removeColor(color),
                    label: const Text(''),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _pickColor,
              child: const Text("Add Color"),
            ),
          ],
        ),
      ],
    );
  }
}
