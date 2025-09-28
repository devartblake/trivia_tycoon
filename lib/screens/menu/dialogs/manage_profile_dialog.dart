import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/settings/multi_profile_service.dart';
import '../../../game/analytics/managers/profile_analytics_manager.dart';
import '../../../game/providers/multi_profile_providers.dart';
import '../../../core/manager/log_manager.dart';
import 'create_profile_dialog.dart';

class DrawerManageProfilesDialog extends ConsumerWidget {
  const DrawerManageProfilesDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1A1B3D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Manage Profiles',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    _showCreateProfileDialog(context, ref);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: profilesAsync.when(
                data: (profiles) => ListView.builder(
                  shrinkWrap: true,
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    return ProfileManagementTile(profile: profile);
                  },
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (error, stack) => Text(
                  'Error: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xFF6A5ACD)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateProfileDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CreateProfileDialog(
        onProfileCreated: () {
          // Refresh the profiles provider to update the list
          ref.refresh(profilesProvider);
          // Force the dialog to rebuild by invalidating the provider
          ref.invalidate(profilesProvider);
        },
      ),
    );
  }
}

class ProfileManagementTile extends ConsumerWidget {
  final ProfileData profile;

  const ProfileManagementTile({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileStateProvider);
    final isActive = activeProfile?.id == profile.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF6366F1).withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: const Color(0xFF6366F1), width: 2)
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: profile.avatar != null ? AssetImage(profile.avatar!) : null,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: profile.avatar == null
                ? Text(
              profile.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Level ${profile.level} • ${profile.rank}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!isActive)
            TextButton(
              onPressed: () => _switchProfile(context, ref, profile),
              child: const Text(
                'Switch',
                style: TextStyle(color: Color(0xFF6366F1)),
              ),
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.7)),
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                // TODO: Implement edit profile functionality
                  break;
                case 'delete':
                  await _deleteProfile(context, ref, profile, isActive);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              if (!isActive) // Don't allow deleting active profile
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _switchProfile(BuildContext context, WidgetRef ref, ProfileData profile) async {
    final activeProfile = ref.read(activeProfileStateProvider);
    final fromProfileName = activeProfile?.name ?? 'Unknown';

    try {
      final profileManager = ref.read(profileManagerProvider.notifier);
      await profileManager.switchProfile(profile.id);

      // Track analytics safely
      final analyticsManager = ref.read(profileAnalyticsManagerProvider.notifier);
      await analyticsManager.trackProfileSwitch(
        fromProfileId: activeProfile?.id ?? 'unknown',
        toProfileId: profile.id,
        toProfileName: profile.name,
        fromProfileName: fromProfileName,
      );

      // Refresh the profiles to update the UI
      ref.refresh(profilesProvider);
      ref.invalidate(activeProfileStateProvider);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${profile.name}'),
            backgroundColor: const Color(0xFF6366F1),
          ),
        );
      }
    } catch (e) {
      LogManager.logProfileError('switch', e.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error switching profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProfile(BuildContext context, WidgetRef ref, ProfileData profile, bool isActive) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B3D),
        title: const Text('Delete Profile', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${profile.name}"? This action cannot be undone.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final profileManager = ref.read(profileManagerProvider.notifier);
        final success = await profileManager.deleteProfile(profile.id);

        if (success && context.mounted) {
          // Track analytics safely
          final analyticsManager = ref.read(profileAnalyticsManagerProvider.notifier);
          await analyticsManager.trackProfileDeleted(
            profileId: profile.id,
            profileName: profile.name,
          );

          // Refresh the profiles list to reflect the deletion
          ref.refresh(profilesProvider);
          ref.invalidate(profilesProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile "${profile.name}" deleted'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
