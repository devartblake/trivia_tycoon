import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/providers/multi_profile_providers.dart';
import '../../game/providers/riverpod_providers.dart';
import '../../screens/profile/widgets/profile_game_card.dart';
import '../../screens/profile/widgets/profile_header_bar.dart';
import '../../screens/profile/widgets/profile_tab_bar.dart';
import 'tabs/collection_tab.dart';
import 'tabs/statistics_tab.dart';
import 'tabs/achievements_tab.dart';
import 'tabs/created_questions_tab.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _adminModeEnabled = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    _loadAdminStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminStatus() async {
    final serviceManager = ref.read(serviceManagerProvider);
    final isAdmin = await serviceManager.adminSettingsService.isAdminUser();
    final adminMode = await serviceManager.adminSettingsService.isAdminMode();

    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
        _adminModeEnabled = adminMode;
      });
    }
  }

  Future<void> _toggleAdminMode(bool enabled) async {
    final serviceManager = ref.read(serviceManagerProvider);
    await serviceManager.adminSettingsService.setAdminMode(enabled);
    setState(() => _adminModeEnabled = enabled);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              enabled ? Icons.admin_panel_settings : Icons.security,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text('Admin Mode ${enabled ? "Enabled" : "Disabled"}'),
          ],
        ),
        backgroundColor: enabled
            ? const Color(0xFF10B981)
            : const Color(0xFF6B7280),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeProfileAsync = ref.watch(activeProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF6A5ACD),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6A5ACD),
              const Color(0xFF8B7EC8),
              const Color(0xFF6A5ACD).withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: activeProfileAsync.when(
              data: (activeProfile) {
                if (activeProfile == null) {
                  return _buildEmptyState();
                }

                return Column(
                  children: [
                    ProfileHeaderBar(profile: activeProfile),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            ProfileGameCard(
                              profile: activeProfile,
                              isAdmin: _isAdmin,
                              adminModeEnabled: _adminModeEnabled,
                              onToggleAdmin: _toggleAdminMode,
                            ),
                            const SizedBox(height: 20),
                            ProfileTabBar(controller: _tabController),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 420,
                              child: TabBarView(
                                controller: _tabController,
                                physics: const BouncingScrollPhysics(),
                                children: const [
                                  CollectionTab(),
                                  StatisticsTab(),
                                  AchievementsTab(),
                                  CreatedQuestionsTab(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_off_rounded,
              color: Colors.white,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No active profile found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please create or select a profile',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading profile...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_rounded,
                color: Colors.red,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error loading profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            _buildRetryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF40E0D0), Color(0xFF00CED1)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF40E0D0).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
        child: ElevatedButton.icon(
            onPressed: () => ref.refresh(activeProfileProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
          label: const Text(
            'Retry',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
