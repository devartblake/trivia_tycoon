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
    final isOnline = true;
    final theme = _getThemeData();

    return Container(
      decoration: BoxDecoration(
        gradient: theme['gradient'] as LinearGradient,
        boxShadow: [
          BoxShadow(
            color: (theme['shadowColor'] as Color).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: _buildAppBarContent(avatarPath, isOnline, theme),
        ),
      ),
    );
  }

  Widget _buildAppBarContent(String avatarPath, bool isOnline, Map<String, dynamic> theme) {
    return Row(
      children: [
        _buildDrawerButton(),
        const SizedBox(width: 16),
        _buildUserSection(avatarPath, isOnline),
        const Spacer(),
        _buildActionButtons(theme),
      ],
    );
  }

  Widget _buildDrawerButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Builder(
        builder: (context) => IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(
            Icons.menu_rounded,
            color: Colors.white,
            size: 22,
          ),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ),
    );
  }

  Widget _buildUserSection(String avatarPath, bool isOnline) {
    final currentHour = DateTime.now().hour;
    final greeting = _getGreeting(currentHour);
    final greetingIcon = _getGreetingIcon(currentHour);

    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: ShimmerAvatar(
              avatarPath: avatarPath,
              radius: 18,
              isOnline: isOnline,
              isLoading: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      greetingIcon,
                      color: Colors.white.withOpacity(0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        greeting,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.notifications_rounded,
          onPressed: (context) => context.push('/alerts'),
          hasNotification: true,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.settings_rounded,
          onPressed: (context) => context.push('/settings'),
          hasNotification: false,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Function(BuildContext) onPressed,
    bool hasNotification = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => onPressed(context),
              icon: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ),
          if (hasNotification)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  IconData _getGreetingIcon(int hour) {
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_sunny_outlined;
    return Icons.nightlight_round;
  }

  Map<String, dynamic> _getThemeData() {
    switch (ageGroup) {
      case 'kids':
        return {
          'gradient': const LinearGradient(
            colors: [
              Color(0xFFFF6B6B),
              Color(0xFFFF8E53),
              Color(0xFFFF6B9D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': const Color(0xFFFF6B6B),
        };
      case 'teens':
        return {
          'gradient': const LinearGradient(
            colors: [
              Color(0xFF4ECDC4),
              Color(0xFF44A08D),
              Color(0xFF093637),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': const Color(0xFF4ECDC4),
        };
      case 'adults':
        return {
          'gradient': const LinearGradient(
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF6B73FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': const Color(0xFF667eea),
        };
      default:
        return {
          'gradient': const LinearGradient(
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Color(0xFFA855F7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': const Color(0xFF6366F1),
        };
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
