import 'package:flutter/material.dart';

class ConfettiColorPicker extends StatefulWidget {
  final List<Color> selectedColors;
  final ValueChanged<List<Color>> onColorsChanged;

  const ConfettiColorPicker({
    super.key,
    required this.selectedColors,
    required this.onColorsChanged,
  });

  @override
  State<ConfettiColorPicker> createState() => _ConfettiColorPickerState();
}

class _ConfettiColorPickerState extends State<ConfettiColorPicker> {
  List<Color> _colors = [];

  final List<Color> _predefinedColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.blue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lime,
    Colors.yellow,
    Colors.orange,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _colors = List.from(widget.selectedColors);
  }

  void _addColor(Color color) {
    if (!_colors.contains(color)) {
      setState(() {
        _colors.add(color);
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
        if (_colors.isNotEmpty) ...[
          const Text(
            'Selected Colors',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _colors.map((color) => _buildSelectedColorChip(color)).toList(),
          ),
          const SizedBox(height: 20),
        ],
        const Text(
          'Available Colors',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _predefinedColors
              .map((color) => _buildColorOption(color))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSelectedColorChip(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _removeColor(color),
            child: const Icon(
              Icons.close,
              size: 16,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    final bool isSelected = _colors.contains(color);

    return GestureDetector(
      onTap: isSelected ? null : () => _addColor(color),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.grey.shade300 : Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              )
            : null,
      ),
    );
  }
}
