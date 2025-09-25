import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/screens/profile/widgets/shimmer_avatar.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../../profile/widgets/theme_drawer.dart';

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
      'icon': Icons.quiz_rounded,
      'title': 'Play Quiz',
      'route': '/quiz',
      'gradient': const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
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
      'icon': Icons.card_giftcard_rounded,
      'title': 'Rewards',
      'route': '/rewards',
      'gradient': const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
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
      'icon': Icons.group_rounded,
      'title': 'Friends',
      'route': '/friends',
      'color': const Color(0xFF6366F1),
    },
    {
      'icon': Icons.settings_suggest_rounded,
      'title': 'Preferences',
      'route': '/preferences',
      'color': const Color(0xFF10B981),
    },
    {
      'icon': Icons.help_outline_rounded,
      'title': 'Help & Feedback',
      'route': '/help',
      'color': const Color(0xFFF59E0B),
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

    // Initialize item controllers
    final totalItems = _menuItems.length + _moreItems.length + _bottomItems.length;
    _itemControllers = List.generate(
      totalItems,
          (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 50)),
        vsync: this,
      ),
    );

    // Start animations
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
          child: _buildDrawerContent(path),
        )
            : _buildDrawerContent(path),
      ),
    );
  }

  Widget _buildDrawerContent(String avatarPath) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(avatarPath)),
        SliverToBoxAdapter(child: _buildMainMenu()),
        SliverToBoxAdapter(child: _buildMoreSection()),
        SliverToBoxAdapter(child: _buildBottomSection()),
        SliverToBoxAdapter(child: _buildLogoutSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildHeader(String avatarPath) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
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
              Hero(
                tag: 'profile-avatar',
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 3,
                    ),
                  ),
                  child: ShimmerAvatar(
                    avatarPath: avatarPath,
                    radius: 32,
                    isOnline: true,
                    isLoading: false,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'john.doe@example.com',
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
            child: const Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Trivia Master',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                Text(
                  'Level 12',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          onTap: () => context.push(item['route']),
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
      builder: (BuildContext context) {
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
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close drawer
                // Add actual logout logic here
              },
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
      },
    );
  }
}
