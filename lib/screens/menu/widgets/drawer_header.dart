import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/ui_components/shimmer_avatar/index.dart';
import '../../../../core/services/settings/multi_profile_service.dart';
import '../../../../game/providers/riverpod_providers.dart';
import '../../../game/models/drawer_menu_data.dart';
import '../../../game/utils/drawer_menu_config.dart';
import 'avatar_options_modal.dart';

/// Drawer header with profile avatar and stats
class AppDrawerHeader extends ConsumerWidget {
  final ProfileData? activeProfile;

  const AppDrawerHeader({
    super.key,
    required this.activeProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = activeProfile != null
        ? ProfileStats(
      level: activeProfile!.level,
      currentXP: activeProfile!.currentXP,
      isPremium: activeProfile!.isPremium,
    ) : const ProfileStats(level: 1, currentXP: 0, isPremium: false);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        gradient: DrawerMenuConfig.headerGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileRow(context, ref),
          const SizedBox(height: 20),
          _buildStatsRow(stats),
        ],
      ),
    );
  }

  Widget _buildProfileRow(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 3,
            ),
          ),
          child: _ProfileAvatar(activeProfile: activeProfile),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activeProfile?.name ?? 'Guest',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activeProfile?.country ?? 'Student',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(ProfileStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatColumn(
              'Level ${stats.level}',
              'Rank',
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatColumn(
              '${stats.currentXP}',
              'XP Points',
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: Column(
              children: [
                Icon(
                  stats.isPremium ? Icons.star : Icons.star_border,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  'Premium',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Profile avatar with reactive updates
class _ProfileAvatar extends ConsumerWidget {
  final ProfileData? activeProfile;

  const _ProfileAvatar({required this.activeProfile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(profileAvatarControllerProvider);

    if (activeProfile == null) {
      return ShimmerAvatar(
        avatarPath: '',
        status: AvatarStatus.online,
        isLoading: true,
        radius: 32,
        showStatusIndicator: false,
        borderColor: Colors.transparent,
        borderWidth: 0,
      );
    }

    final effectiveAvatarPath = controller.effectiveAvatarPath;
    final imageFile = controller.imageFile;

    AvatarStatus avatarStatus = AvatarStatus.online;
    AvatarBadgeType badgeType = AvatarBadgeType.none;
    String? badgeText;

    if (activeProfile!.isPremium) {
      badgeType = AvatarBadgeType.premium;
    } else if (activeProfile!.level > 0) {
      badgeType = AvatarBadgeType.level;
      badgeText = '${activeProfile!.level}';
    }

    if (imageFile != null) {
      return Stack(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage: FileImage(imageFile),
          ),
          if (badgeType != AvatarBadgeType.none)
            Positioned(
              top: -2,
              right: -2,
              child: _buildBadge(badgeType, badgeText),
            ),
        ],
      );
    }

    return ShimmerAvatar(
      avatarPath: effectiveAvatarPath.isNotEmpty
          ? effectiveAvatarPath
          : (activeProfile!.avatar ?? ''),
      status: avatarStatus,
      isLoading: false,
      radius: 32,
      showStatusIndicator: false,
      borderColor: Colors.transparent,
      borderWidth: 0,
      badgeType: badgeType,
      badgeText: badgeText,
      onTap: () => _showAvatarOptions(context, ref),
      heroTag: 'drawer-profile-avatar',
      useGradientBorder: false,
      useGlowEffect: false,
    );
  }

  Widget _buildBadge(AvatarBadgeType badgeType, String? badgeText) {
    Color badgeColor;
    Widget badgeContent;

    switch (badgeType) {
      case AvatarBadgeType.premium:
        badgeColor = Colors.amber;
        badgeContent = const Icon(
          Icons.star,
          size: 12,
          color: Colors.white,
        );
        break;
      case AvatarBadgeType.level:
        badgeColor = const Color(0xFF6366F1);
        badgeContent = Text(
          badgeText ?? '',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(child: badgeContent),
    );
  }

  void _showAvatarOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AvatarOptionsModal(ref: ref),
    );
  }
}
