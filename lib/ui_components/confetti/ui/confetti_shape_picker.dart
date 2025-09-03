import 'package:flutter/material.dart';
import '../../confetti/models/confetti_shape.dart';

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
  _ConfettiShapePickerState createState() => _ConfettiShapePickerState();
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
    widget.onShapesChanged(selectedShapes.cast<ConfettiShapeType>());
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: widget.availableShapes.map((shape){
        bool isSelected = selectedShapes.contains(shape);
      return ChoiceChip(
        label: Text(shape as String),
        selected: isSelected,
        onSelected: (_) =>_toggleShape(shape),
      );
      }).toList(),
    );
  }
}