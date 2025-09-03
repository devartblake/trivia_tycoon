import 'package:flutter/material.dart';
import '../../color_picker/color_picker.dart';

class ConfettiColorPicker extends StatefulWidget {
  final List<Color> selectedColors;
  final ValueChanged<List<Color>> onColorsChanged;

  const ConfettiColorPicker({
    super.key,
    required this.selectedColors,
    required this.onColorsChanged,
  });

  @override
  _ConfettiColorPickerState createState() => _ConfettiColorPickerState();
}

class _ConfettiColorPickerState extends State<ConfettiColorPicker> {
  List<Color> _colors = [];

  @override
  void initState() {
    super.initState();
    _colors = List.from(widget.selectedColors);
  }

  void _pickColor() async {
    Color? selectedColor = await ColorPicker.showColorPickerDialog(context, initialColor: Colors.blue);

    if (selectedColor != null && !_colors.contains(selectedColor)) {
      setState(() {
        _colors.add(selectedColor);
      });
      widget.onColorsChanged(_colors);
    }
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
        const Text("Confetti Colors", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _colors.map((color) {
            return Chip(
              label: const Text(''),
              backgroundColor: color,
              avatar: CircleAvatar(backgroundColor: color),
              onDeleted: () => _removeColor(color),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _pickColor,
          child: const Text("Add Color"),
        ),
      ],
    );
  }
}
