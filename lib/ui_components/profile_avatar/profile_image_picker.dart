import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImagePicker extends StatelessWidget {
  final ValueChanged<File> onImageSelected;
  final bool fullscreen;

  const ProfileImagePicker({
    super.key,
    required this.onImageSelected,
    this.fullscreen = false,
  });

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (!context.mounted) return; // Safe usage check

    if (picked != null) {
      onImageSelected(File(picked.path));
      Navigator.of(context).pop(); // Close dialog/fullscreen after selection
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Choose Profile Picture", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.image),
            label: const Text("From Gallery"),
            onPressed: () => _pickImage(context),
          ),
        ],
      ),
    );

    return fullscreen
        ? Scaffold(
      appBar: AppBar(title: const Text("Change Profile Picture")),
      body: content,
    )
        : Dialog(child: Padding(padding: const EdgeInsets.all(16), child: content));
  }
}
