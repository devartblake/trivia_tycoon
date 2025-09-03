import 'package:flutter/material.dart';

class ColorPreview extends StatelessWidget {
  final Color selectedColor;

  const ColorPreview({super.key, required this.selectedColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: selectedColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black26, width: 2),
      ),
      child: Center(
        child: Text(
          "#${selectedColor.value.toRadixString(16).toUpperCase()}",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(blurRadius: 3, color: Colors.black, offset: Offset(1, 1))
            ],
          ),
        ),
      ),
    );
  }
}
