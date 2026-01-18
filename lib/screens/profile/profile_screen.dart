import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/screens/profile/widgets/shimmer_avatar.dart';
import '../../core/services/settings/multi_profile_service.dart';
import '../../game/providers/multi_profile_providers.dart';
import '../../game/services/educational_stats_service.dart';
import '../../ui_components/depth_card_3d/depth_card.dart';
import '../../game/providers/riverpod_providers.dart';
import '../../screens/profile/widgets/animated_state_box.dart';
import '../../ui_components/profile_avatar/profile_image_picker_dialog.dart';
import 'enhanced/enhanced_profile_screen.dart';
import 'enhanced/sheets/edit_profile_bottom_sheet.dart';
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

  void _showEditNameBottomSheet(BuildContext context, ProfileData? currentProfile) {
    if (currentProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active profile found'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // Use the new EditProfileBottomSheet
    EditProfileBottomSheet.show(context, currentProfile);
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        fillColor: Colors.white.withOpacity(0.15),
        filled: true,
        counterStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      ),
      maxLength: maxLength,
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _buildOutlinedButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.5), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required String label,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF40E0D0), Color(0xFF00CED1)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF40E0D0).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
              const Color(0xFF6A5ACD).withOpacity(0.8),
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
                    _buildTopAppBar(activeProfile),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            _buildGameProfileCard(activeProfile),
                            const SizedBox(height: 20),
                            _buildTabSection(),
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
              color: Colors.white.withOpacity(0.1),
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
              color: Colors.white.withOpacity(0.7),
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
              color: Colors.white.withOpacity(0.1),
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
                color: Colors.red.withOpacity(0.2),
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
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            _buildGradientButton(
              onPressed: () => ref.refresh(activeProfileProvider),
              label: 'Retry',
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedStatsSection(ProfileData activeProfile) {
    return Consumer(
      builder: (context, ref, child) {
        final educationalStatsAsync = ref.watch(educationalStatsProvider);
        final profileStats = ref.watch(activeProfileStatsProvider);

        return educationalStatsAsync.when(
          data: (stats) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: AnimatedStatBox(
                  label: 'Quizzes',
                  value: profileStats['totalQuizzes'] ?? stats.totalQuizzes,
                  gradientColors: const [Color(0xFF40E0D0), Color(0xFF00CED1)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedStatBox(
                  label: 'Correct',
                  value: profileStats['correctAnswers'] ?? stats.correctAnswers,
                  gradientColors: const [Color(0xFF26de81), Color(0xFF20bf6b)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedStatBox(
                  label: 'Streak',
                  value: profileStats['currentStreak'] ?? stats.currentStreak,
                  gradientColors: const [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                ),
              ),
            ],
          ),
          loading: () => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: AnimatedStatBox(
                  label: 'Quizzes',
                  value: profileStats['totalQuizzes'] ?? 0,
                  gradientColors: const [Color(0xFF40E0D0), Color(0xFF00CED1)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedStatBox(
                  label: 'Correct',
                  value: profileStats['correctAnswers'] ?? 0,
                  gradientColors: const [Color(0xFF26de81), Color(0xFF20bf6b)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedStatBox(
                  label: 'Streak',
                  value: profileStats['currentStreak'] ?? 0,
                  gradientColors: const [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                ),
              ),
            ],
          ),
          error: (error, stack) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: AnimatedStatBox(
                  label: 'Quizzes',
                  value: profileStats['totalQuizzes'] ?? 0,
                  gradientColors: const [Color(0xFF40E0D0), Color(0xFF00CED1)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedStatBox(
                  label: 'Correct',
                  value: profileStats['correctAnswers'] ?? 0,
                  gradientColors: const [Color(0xFF26de81), Color(0xFF20bf6b)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedStatBox(
                  label: 'Streak',
                  value: profileStats['currentStreak'] ?? 0,
                  gradientColors: const [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopAppBar(ProfileData activeProfile) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '${activeProfile.name}\'s Profile',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    elevation: 8,
                    onSelected: (value) {
                      switch (value) {
                        case 'switch':
                          context.push('/profile-selection');
                          break;
                        case 'theme':
                          context.push('/gradient-editor');
                          break;
                        case 'settings':
                          context.push('/user-settings');
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      _buildPopupMenuItem(
                        value: 'switch',
                        icon: Icons.switch_account_rounded,
                        label: 'Switch Profile',
                      ),
                      _buildPopupMenuItem(
                        value: 'theme',
                        icon: Icons.palette_rounded,
                        label: 'Customize Theme',
                      ),
                      _buildPopupMenuItem(
                        value: 'settings',
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem({
    required String value,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6A5ACD)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameProfileCard(ProfileData activeProfile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/backgrounds/geometry_background.jpg',
                fit: BoxFit.cover,
              ),
            ),

            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8A2BE2).withOpacity(0.92),
                      const Color(0xFF9370DB).withOpacity(0.88),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // Top Action Buttons
            Positioned(
              top: 20,
              left: 20,
              child: _buildGlassButton(
                icon: Icons.restore_rounded,
                tooltip: 'Reset Avatar',
                onPressed: () async {
                  await ref.read(profileAvatarControllerProvider.notifier).resetAvatar();
                },
              ),
            ),

            Positioned(
              top: 20,
              right: 20,
              child: Row(
                children: [
                  if (_isAdmin) ...[
                    _buildGlassButton(
                      icon: _adminModeEnabled ? Icons.toggle_on : Icons.toggle_off_outlined,
                      tooltip: _adminModeEnabled ? 'Disable Admin' : 'Enable Admin',
                      onPressed: () => _toggleAdminMode(!_adminModeEnabled),
                      iconColor: _adminModeEnabled ? const Color(0xFF10B981) : Colors.white70,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFBBF24),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Level ${activeProfile.level}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  SizedBox(
                    height: 240,
                    child: _buildCharacterSection(activeProfile),
                  ),
                  const SizedBox(height: 24),
                  _buildUserNameSection(activeProfile),
                  const SizedBox(height: 24),
                  _buildAnimatedStatsSection(activeProfile),
                  const SizedBox(height: 24),
                  _buildEducationalProgress(activeProfile),
                  const SizedBox(height: 24),
                  _buildFriendsButton(),
                  const SizedBox(height: 16),
                  _buildStudyGroupSection(activeProfile),
                  const SizedBox(height: 20),
                  _buildBottomActions(),
                  const SizedBox(height: 16),
                  _buildDeveloperActions(activeProfile),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color iconColor = Colors.white70,
  }) {
    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/friends'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF40E0D0), Color(0xFF00CED1)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF40E0D0).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Friends',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterSection(ProfileData activeProfile) {
    return Consumer(
      builder: (context, ref, _) {
        final controller = ref.watch(profileAvatarControllerProvider);

        return Hero(
          tag: 'profile-avatar-character',
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipOval(
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: _buildAvatarDisplay(controller, activeProfile),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        showProfileImagePickerDialog(context, controller);
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF40E0D0), Color(0xFF00CED1)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF40E0D0).withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarDisplay(dynamic controller, ProfileData activeProfile) {
    final imageFile = controller.imageFile;
    final avatarPath = controller.avatarPath ?? activeProfile.avatar;

    Widget avatarPreview;

    if (controller.imageFile == null &&
        controller.avatarPath == null &&
        activeProfile.avatar == null) {
      avatarPreview = ShimmerAvatar(
        avatarPath: '',
        status: AvatarStatus.online,
        isLoading: true,
        radius: 120,
        badgeType: activeProfile.isPremium
            ? AvatarBadgeType.premium
            : AvatarBadgeType.level,
        badgeText: 'L${activeProfile.level}',
        showStatusIndicator: false,
      );
    } else if (imageFile != null) {
      avatarPreview = Image.file(
        imageFile,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (avatarPath != null &&
        (avatarPath.endsWith('.png') || avatarPath.endsWith('.jpg'))) {
      avatarPreview = Image.asset(
        avatarPath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (avatarPath != null &&
        (avatarPath.endsWith('.glb') || avatarPath.endsWith('.obj'))) {
      avatarPreview = DepthCard3D(
        config: DepthCardConfig(
          modelAssetPath: avatarPath,
          theme: controller.depthCardTheme,
          text: '',
          width: double.infinity,
          height: double.infinity,
          parallaxDepth: 0.2,
          borderRadius: 150,
          backgroundImage: const AssetImage(
            'assets/images/backgrounds/geometry_background.jpg',
          ),
          onTap: () {},
          overlayActions: [],
        ),
      );
    } else if (activeProfile.avatar != null) {
      avatarPreview = Image.asset(
        activeProfile.avatar!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      avatarPreview = Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF40E0D0),
              const Color(0xFF00CED1),
            ],
          ),
        ),
        child: Center(
          child: Text(
            activeProfile.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return avatarPreview;
  }

  Widget _buildUserNameSection(ProfileData activeProfile) {
    final favoriteSubject = activeProfile.preferences['favoriteSubject'] ?? 'Learning';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                activeProfile.name,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showEditNameBottomSheet(context, activeProfile),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildInfoChip(
              icon: Icons.school_rounded,
              label: activeProfile.ageGroup?.toUpperCase() ?? 'Student',
            ),
            if (activeProfile.country != null)
              _buildInfoChip(
                icon: Icons.location_on_rounded,
                label: activeProfile.country!,
              ),
            _buildInfoChip(
              icon: Icons.favorite_rounded,
              label: 'Loves $favoriteSubject',
              color: const Color(0xFFFF6B6B),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color ?? Colors.white.withOpacity(0.9),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationalProgress(ProfileData activeProfile) {
    return Consumer(
      builder: (context, ref, child) {
        final educationalStatsAsync = ref.watch(educationalStatsProvider);

        return educationalStatsAsync.when(
          data: (stats) => _buildProgressContent(activeProfile),
          loading: () => _buildProgressContent(activeProfile),
          error: (error, stack) => _buildProgressContent(activeProfile),
        );
      },
    );
  }

  Widget _buildProgressContent(ProfileData activeProfile) {
    final progress = (activeProfile.currentXP / activeProfile.maxXP).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Learning Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF40E0D0), Color(0xFF00CED1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${activeProfile.currentXP} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 10,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF40E0D0), Color(0xFF00CED1)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Level in ${activeProfile.maxXP - activeProfile.currentXP} XP',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudyGroupSection(ProfileData activeProfile) {
    final teamName = activeProfile.preferences['teamName'] ?? 'Solo Learner';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.group_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Study Group',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  teamName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  _buildTeamMemberAvatar('assets/images/avatars/avatar-5.png'),
                  Transform.translate(
                    offset: const Offset(-8, 0),
                    child: _buildTeamMemberAvatar('assets/images/avatars/avatar-5.png'),
                  ),
                  Transform.translate(
                    offset: const Offset(-16, 0),
                    child: _buildTeamMemberAvatar('assets/images/avatars/avatar-5.png'),
                  ),
                  if (activeProfile.isPremium) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFBBF24).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberAvatar(String avatarPath) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ShimmerAvatar(
        avatarPath: avatarPath,
        status: AvatarStatus.online,
        isLoading: false,
        radius: 16,
        showStatusIndicator: false,
      ),
    );
  }

  Widget _buildBottomActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Recent Quizzes',
            icon: Icons.quiz_rounded,
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            label: 'Study Chat',
            icon: Icons.chat_bubble_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF40E0D0), Color(0xFF00CED1)],
            ),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloperActions(ProfileData activeProfile) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EnhancedProfileScreen(
                    userId: 'current_user_id',
                    currentUserId: 'current_user_id',
                    isOwnProfile: true,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'View Enhanced Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isAdmin) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: _adminModeEnabled
                  ? const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              )
                  : LinearGradient(
                colors: [
                  Colors.grey.shade700,
                  Colors.grey.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (_adminModeEnabled
                      ? const Color(0xFF10B981)
                      : Colors.grey.shade700)
                      .withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _adminModeEnabled
                        ? Icons.admin_panel_settings_rounded
                        : Icons.security_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _adminModeEnabled ? 'All features unlocked' : 'Standard access',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _adminModeEnabled,
                  onChanged: _toggleAdminMode,
                  activeColor: Colors.white,
                  activeTrackColor: Colors.white.withOpacity(0.3),
                  inactiveThumbColor: Colors.white70,
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6A5ACD),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: const Color(0xFF6A5ACD),
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(
              icon: Icon(Icons.grid_view_rounded, size: 22),
              text: 'Collection',
            ),
            Tab(
              icon: Icon(Icons.bar_chart_rounded, size: 22),
              text: 'Stats',
            ),
            Tab(
              icon: Icon(Icons.emoji_events_rounded, size: 22),
              text: 'Awards',
            ),
            Tab(
              icon: Icon(Icons.create_rounded, size: 22),
              text: 'Created',
            ),
          ],
        ),
      ),
    );
  }
}