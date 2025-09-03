import 'package:flutter/material.dart';
import '../models/confetti_settings.dart';

class ConfettiSaveButton extends StatelessWidget {
  final ConfettiSettings settings;
  final VoidCallback onSave;

  const ConfettiSaveButton({
    super.key,
    required this.settings,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: onSave,
        child: Text("Save & Apply"),
    );
  }
}