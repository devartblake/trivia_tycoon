import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../game/providers/riverpod_providers.dart';

/// Modal bottom sheet for avatar selection options
class AvatarOptionsModal extends StatelessWidget {
  final WidgetRef ref;

  const AvatarOptionsModal({
    super.key,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Change Avatar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOption(
                context,
                'Camera',
                Icons.camera_alt,
                    () async {
                  Navigator.pop(context);
                  await ref
                      .read(profileAvatarControllerProvider.notifier)
                      .pickImage(ImageSource.camera);
                },
              ),
              _buildOption(
                context,
                'Gallery',
                Icons.photo_library,
                    () async {
                  Navigator.pop(context);
                  await ref
                      .read(profileAvatarControllerProvider.notifier)
                      .pickImage(ImageSource.gallery);
                },
              ),
              _buildOption(
                context,
                'Reset',
                Icons.refresh,
                    () async {
                  Navigator.pop(context);
                  await ref
                      .read(profileAvatarControllerProvider.notifier)
                      .resetAvatar();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption(
      BuildContext context,
      String label,
      IconData icon,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6366F1), size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
