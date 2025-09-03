import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/utils/theme_utils.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../../profile/widgets/shimmer_avatar.dart';

class UserGreetingAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String userName;
  final String ageGroup;

  const UserGreetingAppBar({
    super.key,
    required this.userName,
    required this.ageGroup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarController = ref.watch(profileAvatarControllerProvider);
    final avatarPath = avatarController.effectiveAvatarPath;
    final isOnline = true; // You can make this dynamic if needed

    final accentColor = ThemeUtils.getAccentColor(ageGroup);

    return AppBar(
      backgroundColor: accentColor,
      title: Row(
        children: [
          ShimmerAvatar(
            avatarPath: avatarPath,
            radius: 20,
            isOnline: isOnline,
            isLoading: false, // You can toggle this based on app loading state
          ),
          const SizedBox(width: 10),
          Text('Hello, $userName!', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => context.push('/settings'),
        ),
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () => context.push('/alerts'),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
