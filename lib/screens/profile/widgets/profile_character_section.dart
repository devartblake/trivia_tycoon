import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/settings/multi_profile_service.dart';
import '../../../game/controllers/profile_avatar_controller.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../../../ui_components/depth_card_3d/depth_card.dart';
import '../../../ui_components/profile_avatar/profile_image_picker_dialog.dart';
import './shimmer_avatar.dart';

/// Circular avatar hero widget with edit button overlay.
class ProfileCharacterSection extends ConsumerWidget {
  const ProfileCharacterSection({super.key, required this.profile});

  final ProfileData profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(profileAvatarControllerProvider);

    return Hero(
      tag: 'profile-avatar-character',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipOval(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: _buildAvatarDisplay(controller),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      showProfileImagePickerDialog(context, controller),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF40E0D0), Color(0xFF00CED1)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF40E0D0).withValues(alpha: 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarDisplay(ProfileAvatarController controller) {
    final imageFile = controller.imageFile;
    final avatarPath = controller.avatarPath ?? profile.avatar;

    if (imageFile == null &&
        controller.avatarPath == null &&
        profile.avatar == null) {
      return ShimmerAvatar(
        avatarPath: '',
        status: AvatarStatus.online,
        isLoading: true,
        radius: 120,
        badgeType:
            profile.isPremium ? AvatarBadgeType.premium : AvatarBadgeType.level,
        badgeText: 'L${profile.level}',
        showStatusIndicator: false,
      );
    } else if (imageFile != null) {
      return Image.file(
        imageFile,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (avatarPath != null &&
        (avatarPath.endsWith('.png') || avatarPath.endsWith('.jpg'))) {
      return Image.asset(
        avatarPath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (avatarPath != null &&
        (avatarPath.endsWith('.glb') || avatarPath.endsWith('.obj'))) {
      return DepthCard3D(
        config: DepthCardConfig(
          modelAssetPath: avatarPath,
          theme: controller.depthCardTheme,
          text: '',
          width: double.infinity,
          height: double.infinity,
          parallaxDepth: 0.2,
          borderRadius: 150,
          backgroundImage: const AssetImage(
            'assets/images/backgrounds/geometry_background.jpg',
          ),
          onTap: () {},
          overlayActions: [],
        ),
      );
    } else if (profile.avatar != null) {
      return Image.asset(
        profile.avatar!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF40E0D0), Color(0xFF00CED1)],
          ),
        ),
        child: Center(
          child: Text(
            profile.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }
}
