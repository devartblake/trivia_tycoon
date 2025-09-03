import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../game/controllers/profile_avatar_controller.dart';

Future<void> showProfileImagePickerDialog(
    BuildContext context,
    ProfileAvatarController controller,
    ) {
  return showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text("Update Profile Image"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await controller.pickImage(ImageSource.camera);
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text("Take Photo"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await controller.pickImage(ImageSource.gallery);
              },
              icon: const Icon(Icons.photo_library),
              label: const Text("Choose from Gallery"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push('/avatar-selection'); // Requires GoRouter
              },
              icon: const Icon(Icons.image_search),
              label: const Text("Choose Avatar"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        ),
      );
    },
  );
}
