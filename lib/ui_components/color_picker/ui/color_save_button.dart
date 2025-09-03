import 'package:flutter/material.dart';
import '../utils/color_storage.dart';

class ColorSaveButton extends StatelessWidget {
  final Color selectedColor;
  final VoidCallback onSaved;

  const ColorSaveButton({super.key, required this.selectedColor, required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(Icons.save),
      label: Text("Save Color"),
      onPressed: () async {
        await ColorStorage.saveColor(selectedColor);
        onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Color saved!")),
        );
      },
    );
  }
}
