import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/settings/multi_profile_service.dart';
import '../../../../game/providers/multi_profile_providers.dart';
import '../dialogs/manage_profile_dialog.dart';

/// Netflix-style profile switcher section
class ProfileSwitcher extends ConsumerWidget {
  const ProfileSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileManager = ref.watch(profileManagerProvider);
    final profiles = profileManager.profiles;
    final activeProfile = profileManager.activeProfile;

    // Don't show if only one profile
    if (profiles.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 8),
          _buildProfileList(context, ref, profiles, activeProfile),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Switch Profile',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => const DrawerManageProfilesDialog(),
              );
            },
            child: const Icon(
              Icons.manage_accounts_rounded,
              size: 20,
              color: Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileList(
    BuildContext context,
    WidgetRef ref,
    List<ProfileData> profiles,
    ProfileData? activeProfile,
  ) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: profiles.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final profile = profiles[index];
          final isActive = profile.id == activeProfile?.id;
          return _ProfileChip(
            profile: profile,
            isActive: isActive,
            onTap: () async {
              if (!isActive) {
                // Use profileManagerProvider which handles state updates
                await ref
                    .read(profileManagerProvider.notifier)
                    .switchProfile(profile.id);
              }
            },
          );
        },
      ),
    );
  }
}

/// Individual profile chip widget
class _ProfileChip extends StatelessWidget {
  final ProfileData profile;
  final bool isActive;
  final VoidCallback onTap;

  const _ProfileChip({
    required this.profile,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                )
              : null,
          color: isActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : const Color(0xFF64748B).withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.2)
                    : const Color(0xFF6366F1).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  profile.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : const Color(0xFF6366F1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile.name,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.white : const Color(0xFF64748B),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
