import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/auth_providers.dart';
import '../../../game/providers/multi_profile_providers.dart';

class LogoutDialog extends ConsumerWidget {
  final BuildContext parentContext;

  const LogoutDialog({super.key, required this.parentContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Logout',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async => _performLogout(context, ref),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Logout'),
        ),
      ],
    );
  }

  Future<void> _performLogout(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop(); // Close logout dialog

    // Clear active profile immediately so stale profile data is not shown.
    ref.read(profileManagerProvider.notifier).clearActiveProfile();

    // Use still-mounted screen context for centralized logout + navigation.
    await ref.read(authOperationsProvider).logout(parentContext);
  }
}
