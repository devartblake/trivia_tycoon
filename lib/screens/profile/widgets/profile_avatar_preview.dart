import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui_components/depth_card_3d/depth_card.dart';
import '../../../game/providers/riverpod_providers.dart';

class ProfileAvatarPreview extends ConsumerWidget {
  final double size;

  const ProfileAvatarPreview({super.key, this.size = 90});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(profileAvatarControllerProvider);

    final path = controller.avatarPath;
    final is3D = path != null && (path.endsWith('glb') || path.endsWith('.obj'));

    if (is3D) {
      return DepthCard3D(
        config: DepthCardConfig(
          modelAssetPath: path!,
          text: '',
          width: size,
          height: size,
          borderRadius: size / 2,
          parallaxDepth: 0.05,
          theme: controller.depthCardTheme,
          backgroundImage: const AssetImage('assets/images/backgrounds/3d_placeholder.jpg'),
          onTap: () {}, // Optional interaction
        ),
      );
    } else if (path != null && path.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: FileImage(File(path)),
      );
    } else {
      return CircleAvatar(
        radius: size / 2,
        child: const Icon(Icons.person),
      );
    }
  }
}
