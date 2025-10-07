import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trivia_tycoon/screens/profile/widgets/shimmer_avatar.dart';
import '../../../core/services/settings/multi_profile_service.dart';
import '../../../game/providers/multi_profile_providers.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../../profile/widgets/theme_drawer.dart';
import '../dialogs/logout_dialog.dart';
import '../dialogs/manage_profile_dialog.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  late List<AnimationController> _itemControllers;
  String? _selectedRoute;

  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.home_rounded,
      'title': 'Home',
      'route': '/',
      'gradient': const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
    },
    {
      'icon': Icons.message_rounded,
      'title': 'Messages',
      'route': '/messages',
      'gradient': const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
    },
    {
      'icon': Icons.quiz_rounded,
      'title': 'Quiz',
      'route': '/quiz',
      'gradient': const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
    },
    {
      'icon': Icons.games_rounded,
      'title': 'Mini Games',
      'route': '/mini-games',
      'gradient': const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]),
    },
    {
      'icon': Icons.psychology_rounded,
      'title': 'Skills',
      'route': '/skills',
      'gradient': const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
    },
    {
      'icon': Icons.gamepad_rounded,
      'title': 'Multiplayer',
      'route': '/multiplayer',
      'gradient': const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
    },
    {
      'icon': Icons.leaderboard_rounded,
      'title': 'Leaderboard',
      'route': '/leaderboard',
      'gradient': const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]),
    },
  ];

  final List<Map<String, dynamic>> _moreItems = [
    {
      'icon': Icons.telegram_rounded,
      'title': 'Missions',
      'route': '/missions',
      'color': const Color(0x9670FF1B),
    },
    {
      'icon': Icons.settings_suggest_rounded,
      'title': 'Preferences',
      'route': '/preferences',
      'color': const Color(0xFF10B981),
    },
  ];

  final List<Map<String, dynamic>> _bottomItems = [
    {
      'icon': Icons.admin_panel_settings_rounded,
      'title': 'Administrator',
      'route': '/admin',
      'color': const Color(0xFFEF4444),
    },
    {
      'icon': Icons.settings_rounded,
      'title': 'Settings',
      'route': '/settings',
      'color': const Color(0xFF64748B),
    },
    {
      'icon': Icons.help_outline_rounded,
      'title': 'Help & Feedback',
      'route': '/help',
      'color': const Color(0xFFF59E0B),
    },
    {
      'icon': Icons.report_rounded,
      'title': 'Report',
      'route': '/report',
      'color': const Color(0xFF8B5CF6),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));

    final totalItems = _menuItems.length + _moreItems.length + _bottomItems.length;
    _itemControllers = List.generate(
      totalItems,
          (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 50)),
        vsync: this,
      ),
    );

    _animationController!.forward();
    for (int i = 0; i < _itemControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 200 + (i * 80)), () {
        if (mounted) _itemControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(profileAvatarControllerProvider);
    final activeProfile = ref.watch(activeProfileStateProvider);
    final path = controller.effectiveAvatarPath;
    _selectedRoute = GoRouterState.of(context).uri.toString();

    return ThemedDrawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8FAFF),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _fadeAnimation != null
            ? FadeTransition(
          opacity: _fadeAnimation!,
          child: _buildDrawerContent(path, activeProfile),
        )
            : _buildDrawerContent(path, activeProfile),
      ),
    );
  }

  Widget _buildDrawerContent(String avatarPath, ProfileData? activeProfile) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(avatarPath, activeProfile)),
        SliverToBoxAdapter(child: _buildProfileSwitcher()),
        SliverToBoxAdapter(child: _buildMainMenu()),
        SliverToBoxAdapter(child: _buildMoreSection()),
        SliverToBoxAdapter(child: _buildBottomSection()),
        SliverToBoxAdapter(child: _buildLogoutSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildHeader(String avatarPath, ProfileData? activeProfile) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFA855F7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 3,
                  ),
                ),
                child: _buildProfileAvatar(activeProfile),
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
                        color: Colors.white.withOpacity(0.8),
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
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
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Level ${activeProfile?.level ?? 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rank',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${activeProfile?.currentXP ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'XP Points',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        activeProfile?.isPremium == true ? Icons.star : Icons.star_border,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeProfile?.isPremium == true ? 'Premium' : 'Free',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(ProfileData? activeProfile) {
    final controller = ref.watch(profileAvatarControllerProvider);

    // If profile is loading/null, show shimmer
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

    // Get the effective avatar path from the controller
    final effectiveAvatarPath = controller.effectiveAvatarPath;
    final imageFile = controller.imageFile;

    // Determine avatar status based on profile activity
    AvatarStatus avatarStatus = AvatarStatus.online;
    AvatarBadgeType badgeType = AvatarBadgeType.none;
    String? badgeText;

    // Set badge based on user level and premium status
    if (activeProfile.isPremium) {
      badgeType = AvatarBadgeType.premium;
    } else if (activeProfile.level > 0) {
      badgeType = AvatarBadgeType.level;
      badgeText = '${activeProfile.level}';
    }

    // If there's a selected image file from camera/gallery
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
              child: _buildAvatarBadge(badgeType, badgeText),
            ),
        ],
      );
    }
    // Use ShimmerAvatar for all other cases
    else {
      return ShimmerAvatar(
        avatarPath: effectiveAvatarPath.isNotEmpty
            ? effectiveAvatarPath
            : (activeProfile.avatar ?? ''),
        status: avatarStatus,
        isLoading: false,
        radius: 32,
        showStatusIndicator: false, // Hide status in drawer header
        borderColor: Colors.transparent, // Container handles border
        borderWidth: 0,
        badgeType: badgeType,
        badgeText: badgeText,
        onTap: () => _showAvatarOptions(context),
        heroTag: 'drawer-profile-avatar',
      );
    }
  }

  Widget _buildAvatarBadge(AvatarBadgeType badgeType, String? badgeText) {
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
            color: badgeColor.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(child: badgeContent),
    );
  }

  void _showAvatarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                _buildAvatarOption(
                  'Camera',
                  Icons.camera_alt,
                      () async {
                    Navigator.pop(context);
                    await ref.read(profileAvatarControllerProvider.notifier).pickImage(ImageSource.camera);
                  },
                ),
                _buildAvatarOption(
                  'Gallery',
                  Icons.photo_library,
                      () async {
                    Navigator.pop(context);
                    await ref.read(profileAvatarControllerProvider.notifier).pickImage(ImageSource.gallery);
                  },
                ),
                _buildAvatarOption(
                  'Reset',
                  Icons.refresh,
                      () async {
                    Navigator.pop(context);
                    await ref.read(profileAvatarControllerProvider.notifier).resetAvatar();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF6366F1), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSwitcher() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF64748B).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.switch_account_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
            title: const Text(
              'Switch Profile',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: const Text(
              'Change to another profile',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF64748B),
              size: 16,
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              context.push('/profile-selection');
            },
          ),

          Divider(
            height: 1,
            color: Colors.grey.shade200,
            indent: 16,
            endIndent: 16,
          ),

          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.manage_accounts_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            title: const Text(
              'Manage Profiles',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: const Text(
              'Add, edit, or delete profiles',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF64748B),
              size: 16,
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _showManageProfilesDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showManageProfilesDialog() {
    showDialog(
      context: context,
      builder: (context) => const DrawerManageProfilesDialog(),
    );
  }

  Widget _buildMainMenu() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _menuItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildMenuItem(item, index);
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item, int index) {
    final isSelected = _selectedRoute == item['route'];

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _itemControllers[index],
        curve: Curves.easeOutBack,
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? item['gradient'] as LinearGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: (item['gradient'] as LinearGradient).colors.first.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              )
            else
              BoxShadow(
                color: const Color(0xFF64748B).withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.2)
                : const Color(0xFF64748B).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.2)
                  : (item['gradient'] as LinearGradient).colors.first.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item['icon'],
              color: isSelected
                  ? Colors.white
                  : (item['gradient'] as LinearGradient).colors.first,
              size: 20,
            ),
          ),
          title: Text(
            item['title'],
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            color: isSelected
                ? Colors.white.withOpacity(0.8)
                : const Color(0xFF64748B).withOpacity(0.5),
            size: 16,
          ),
          onTap: () {
            Navigator.pop(context); // Close drawer
            if (item['route'] == '/') {
              context.go('/');
            } else {
              context.push(item['route']);
            }
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      ),
    );
  }

  Widget _buildMoreSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Text(
              'More Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ..._moreItems.asMap().entries.map((entry) {
            final index = entry.key + _menuItems.length;
            final item = entry.value;
            return _buildSimpleMenuItem(item, index);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: _bottomItems.asMap().entries.map((entry) {
          final index = entry.key + _menuItems.length + _moreItems.length;
          final item = entry.value;
          return _buildSimpleMenuItem(item, index);
        }).toList(),
      ),
    );
  }

  Widget _buildSimpleMenuItem(Map<String, dynamic> item, int index) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _itemControllers[index],
        curve: Curves.easeOutBack,
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF64748B).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (item['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item['icon'],
              color: item['color'] as Color,
              size: 18,
            ),
          ),
          title: Text(
            item['title'],
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            color: const Color(0xFF9CA3AF),
            size: 12,
          ),
          onTap: () {
            Navigator.pop(context); // Close drawer
            context.push(item['route']);
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        ),
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _itemControllers.last,
          curve: Curves.easeOutBack,
        )),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
            onTap: () {
              _showLogoutDialog();
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => const LogoutDialog(),
    );
  }
}