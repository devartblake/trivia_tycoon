import 'package:flutter/material.dart';
import '../models/confetti_shape.dart';

class ConfettiShapePicker extends StatefulWidget {
  final List<ConfettiShapeType> availableShapes;
  final List<ConfettiShapeType> selectedShapes;
  final Function(List<ConfettiShapeType>) onShapesChanged;

  const ConfettiShapePicker({
    super.key,
    required this.availableShapes,
    required this.selectedShapes,
    required this.onShapesChanged,
  });

  @override
  State<ConfettiShapePicker> createState() => _ConfettiShapePickerState();
}

class _ConfettiShapePickerState extends State<ConfettiShapePicker> {
  List<ConfettiShapeType> selectedShapes = [];

  @override
  void initState() {
    super.initState();
    selectedShapes = List.from(widget.selectedShapes);
  }

  void _toggleShape(ConfettiShapeType shape) {
    setState(() {
      if (selectedShapes.contains(shape)) {
        selectedShapes.remove(shape);
      } else {
        selectedShapes.add(shape);
      }
    });
    widget.onShapesChanged(selectedShapes);
  }

  String _getShapeName(ConfettiShapeType shape) {
    return shape.toString().split('.').last;
  }

  IconData _getShapeIcon(ConfettiShapeType shape) {
    final name = _getShapeName(shape).toLowerCase();
    switch (name) {
      case 'circle':
        return Icons.circle;
      case 'square':
        return Icons.square;
      case 'triangle':
        return Icons.change_history;
      case 'star':
        return Icons.star;
      default:
        return Icons.shape_line;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.availableShapes.map((shape) {
        final bool isSelected = selectedShapes.contains(shape);
        final String shapeName = _getShapeName(shape);
        final IconData shapeIcon = _getShapeIcon(shape);

        return GestureDetector(
          onTap: () => _toggleShape(shape),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF667EEA).withOpacity(0.1)
                  : const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF667EEA) : const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  shapeIcon,
                  size: 20,
                  color: isSelected ? const Color(0xFF667EEA) : const Color(0xFF718096),
                ),
                const SizedBox(width: 8),
                Text(
                  shapeName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? const Color(0xFF667EEA) : const Color(0xFF4A5568),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}