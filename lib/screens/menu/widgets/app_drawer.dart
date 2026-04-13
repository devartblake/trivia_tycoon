import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/screens/menu/widgets/profile_switcher.dart';
import 'package:trivia_tycoon/screens/menu/widgets/simple_menu_item.dart';
import '../../../core/services/settings/multi_profile_service.dart';
import '../../../core/animations/animation_manager.dart';
import '../../../game/providers/multi_profile_providers.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../../../game/utils/drawer_menu_config.dart';
import '../../profile/widgets/theme_drawer.dart';

// Import all modular components
import '../sections/logout_section.dart';
import 'drawer_header.dart';
import 'gradient_menu_item.dart';

/// Modular App Drawer with modern navigation and profile switching
///
/// Features:
/// - Clean modular architecture (10 files, ~150 lines each)
/// - Reactive avatar updates via ShimmerAvatar
/// - Profile switching capabilities
/// - Animated menu sections
/// - Easy to maintain and extend
class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer>
    with TickerProviderStateMixin {
  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;
  late List<AnimationController> _itemControllers;
  String? _selectedRoute;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Fade animation for entire drawer
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeInOut,
    ));

    // Create staggered animations for all menu items
    final totalItems = DrawerMenuConfig.mainMenuItems.length +
        DrawerMenuConfig.moreMenuItems.length +
        DrawerMenuConfig.bottomMenuItems.length +
        1; // +1 for logout

    _itemControllers = AnimationManager.createStaggeredControllers(
      vsync: this,
      count: totalItems,
    );

    // Start animations
    _fadeController!.forward();
    AnimationManager.startStaggered(
      controllers: _itemControllers,
      mounted: mounted,
    );
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    AnimationManager.disposeControllers(_itemControllers);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers for reactive updates
    ref.watch(profileAvatarControllerProvider);
    final activeProfile = ref.watch(activeProfileStateProvider);
    _selectedRoute = GoRouterState.of(context).uri.toString();

    return ThemedDrawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: DrawerMenuConfig.backgroundGradient,
        ),
        child: _fadeAnimation != null
            ? FadeTransition(
          opacity: _fadeAnimation!,
          child: _buildDrawerContent(activeProfile),
        )
            : _buildDrawerContent(activeProfile),
      ),
    );
  }

  Widget _buildDrawerContent(ProfileData? activeProfile) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header with avatar and stats
        SliverToBoxAdapter(
          child: AppDrawerHeader(activeProfile: activeProfile),
        ),

        // Profile switcher (only shows if multiple profiles)
        const SliverToBoxAdapter(
          child: ProfileSwitcher(),
        ),

        // Main menu items
        SliverToBoxAdapter(
          child: _buildMainMenu(),
        ),

        // More options section
        SliverToBoxAdapter(
          child: _buildMoreSection(),
        ),

        // Bottom section (settings, help, etc.)
        SliverToBoxAdapter(
          child: _buildBottomSection(),
        ),

        // Logout button
        SliverToBoxAdapter(
          child: LogoutSection(
            animationController: _itemControllers.last,
          ),
        ),

        // Bottom spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildMainMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: DrawerMenuConfig.mainMenuItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = _isRouteSelected(item.route);

          return GradientMenuItemWidget(
            item: item,
            isSelected: isSelected,
            animationController: _itemControllers[index],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMoreSection() {
    if (DrawerMenuConfig.moreMenuItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final startIndex = DrawerMenuConfig.mainMenuItems.length;

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
          ...DrawerMenuConfig.moreMenuItems.asMap().entries.map((entry) {
            final index = startIndex + entry.key;
            final item = entry.value;

            return SimpleMenuItemWidget(
              item: item,
              animationController: _itemControllers[index],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    if (DrawerMenuConfig.bottomMenuItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final startIndex = DrawerMenuConfig.mainMenuItems.length +
        DrawerMenuConfig.moreMenuItems.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: DrawerMenuConfig.bottomMenuItems.asMap().entries.map((entry) {
          final index = startIndex + entry.key;
          final item = entry.value;

          return SimpleMenuItemWidget(
            item: item,
            animationController: _itemControllers[index],
          );
        }).toList(),
      ),
    );
  }

  bool _isRouteSelected(String route) {
    return _selectedRoute == route || (_selectedRoute == '/' && route == '/');
  }
}
