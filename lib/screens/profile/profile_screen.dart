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
import 'tabs/collection_tab.dart';
import 'tabs/statistics_tab.dart';
import 'tabs/achievements_tab.dart';
import 'tabs/created_questions_tab.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _adminModeEnabled = false;
  bool _isAdmin = false;

  @override
  void initState() {
    _tabController = TabController(length: 4, vsync: this);
    _loadAdminStatus();
    super.initState();
  }

  Future<void> _loadAdminStatus() async {
    final serviceManager = ref.read(serviceManagerProvider);
    final isAdmin = await serviceManager.adminSettingsService.isAdminUser();
    final adminMode = await serviceManager.adminSettingsService.isAdminMode();

    setState(() {
      _isAdmin = isAdmin;
      _adminModeEnabled = adminMode;
    });
  }

  Future<void> _toggleAdminMode(bool enabled) async {
    final serviceManager = ref.read(serviceManagerProvider);
    await serviceManager.adminSettingsService.setAdminMode(enabled);
    setState(() => _adminModeEnabled = enabled);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Admin Mode Enabled'),
        showCloseIcon: true,
        behavior: SnackBarBehavior.floating,
        clipBehavior: Clip.none,
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void _showEditNameBottomSheet(BuildContext context, ProfileData? currentProfile) {
    final TextEditingController nameController = TextEditingController(
        text: currentProfile?.name ?? 'Guest');
    final TextEditingController locationController = TextEditingController(
        text: currentProfile?.country ?? '');
    final TextEditingController gradeController = TextEditingController(
        text: currentProfile?.ageGroup ?? '');
    final TextEditingController teamController = TextEditingController(
        text: currentProfile?.preferences['teamName'] ?? 'Study Squad');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF6A5ACD),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  fillColor: Colors.white.withOpacity(0.1),
                  filled: true,
                ),
                maxLength: 30,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Location',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  fillColor: Colors.white.withOpacity(0.1),
                  filled: true,
                  prefixIcon: Icon(Icons.location_on, color: Colors.white.withOpacity(0.7)),
                ),
                maxLength: 50,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: gradeController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Current Grade',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  fillColor: Colors.white.withOpacity(0.1),
                  filled: true,
                  prefixIcon: Icon(Icons.school, color: Colors.white.withOpacity(0.7)),
                ),
                maxLength: 20,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: teamController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Study Group/Team Name',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  fillColor: Colors.white.withOpacity(0.1),
                  filled: true,
                  prefixIcon: Icon(Icons.group, color: Colors.white.withOpacity(0.7)),
                ),
                maxLength: 30,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isNotEmpty && currentProfile != null) {
                          final multiProfileService = ref.read(multiProfileServiceProvider);

                          final success = await multiProfileService.updateProfile(
                            currentProfile.id,
                            name: nameController.text.trim(),
                            country: locationController.text.trim().isNotEmpty
                                ? locationController.text.trim()
                                : null,
                            ageGroup: gradeController.text.trim().isNotEmpty
                                ? gradeController.text.trim()
                                : null,
                            preferences: {
                              ...currentProfile.preferences,
                              'teamName': teamController.text.trim(),
                            },
                          );

                          if (mounted) {
                            Navigator.pop(context);
                            ref.read(profileManagerProvider.notifier).refreshProfiles();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? 'Profile updated successfully!'
                                    : 'Failed to update profile'),
                                backgroundColor: success
                                    ? const Color(0xFF40E0D0)
                                    : Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF40E0D0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeProfileStateProvider);

    if (activeProfile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF6A5ACD),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF6A5ACD),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(activeProfile),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildGameProfileCard(activeProfile),
                    const SizedBox(height: 16),
                    _buildTabSection(),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 400,
                      child: TabBarView(
                        controller: _tabController,
                        children: const [
                          CollectionTab(),
                          StatisticsTab(),
                          AchievementsTab(),
                          CreatedQuestionsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
              AnimatedStatBox(
                label: 'Quizzes',
                value: profileStats['totalQuizzes'] ?? stats.totalQuizzes,
                gradientColors: const [Color(0xFF40E0D0), Color(0xFF00CED1)],
              ),
              AnimatedStatBox(
                label: 'Correct',
                value: profileStats['correctAnswers'] ?? stats.correctAnswers,
                gradientColors: const [Color(0xFF26de81), Color(0xFF20bf6b)],
              ),
              AnimatedStatBox(
                label: 'Streak',
                value: profileStats['currentStreak'] ?? stats.currentStreak,
                gradientColors: const [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
              ),
            ],
          ),
          loading: () => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AnimatedStatBox(
                label: 'Quizzes',
                value: profileStats['totalQuizzes'] ?? 0,
                gradientColors: const [Color(0xFF40E0D0), Color(0xFF00CED1)],
              ),
              AnimatedStatBox(
                label: 'Correct',
                value: profileStats['correctAnswers'] ?? 0,
                gradientColors: const [Color(0xFF26de81), Color(0xFF20bf6b)],
              ),
              AnimatedStatBox(
                label: 'Streak',
                value: profileStats['currentStreak'] ?? 0,
                gradientColors: const [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
              ),
            ],
          ),
          error: (error, stack) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AnimatedStatBox(
                label: 'Quizzes',
                value: profileStats['totalQuizzes'] ?? 0,
                gradientColors: const [Color(0xFF40E0D0), Color(0xFF00CED1)],
              ),
              AnimatedStatBox(
                label: 'Correct',
                value: profileStats['correctAnswers'] ?? 0,
                gradientColors: const [Color(0xFF26de81), Color(0xFF20bf6b)],
              ),
              AnimatedStatBox(
                label: 'Streak',
                value: profileStats['currentStreak'] ?? 0,
                gradientColors: const [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopAppBar(ProfileData activeProfile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6A5ACD).withOpacity(0.9),
            const Color(0xFF483D8B).withOpacity(0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '${activeProfile.name}\'s Profile',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
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
                  const PopupMenuItem(
                    value: 'switch',
                    child: Row(
                      children: [
                        Icon(Icons.switch_account),
                        SizedBox(width: 8),
                        Text('Switch Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'theme',
                    child: Row(
                      children: [
                        Icon(Icons.palette),
                        SizedBox(width: 8),
                        Text('Customize 3D Theme'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings),
                        SizedBox(width: 8),
                        Text('User Settings'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameProfileCard(ProfileData activeProfile) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/backgrounds/geometry_background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8A2BE2).withOpacity(0.85),
              const Color(0xFF9370DB).withOpacity(0.80),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Tooltip(
                  message: 'Reset Avatar',
                  child: IconButton(
                    icon: const Icon(Icons.restore, color: Colors.white70, size: 20),
                    onPressed: () async {
                      await ref.read(profileAvatarControllerProvider.notifier).resetAvatar();
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Row(
                children: [
                  if (_isAdmin)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Tooltip(
                        message: _adminModeEnabled ? 'Disable Admin Mode' : 'Enable Admin Mode',
                        child: IconButton(
                          icon: Icon(
                            _adminModeEnabled ? Icons.toggle_on : Icons.toggle_off,
                            color: _adminModeEnabled ? Colors.greenAccent : Colors.white70,
                            size: 24,
                          ),
                          onPressed: () => _toggleAdminMode(!_adminModeEnabled),
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Level ${activeProfile.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  SizedBox(
                    height: 250,
                    child: _buildCharacterSection(activeProfile),
                  ),
                  const SizedBox(height: 20),
                  _buildUserNameSection(activeProfile),
                  const SizedBox(height: 24),
                  _buildAnimatedStatsSection(activeProfile),
                  const SizedBox(height: 20),
                  _buildEducationalProgress(activeProfile),
                  const SizedBox(height: 30),
                  _buildStudyGroupSection(activeProfile),
                  const SizedBox(height: 20),
                  _buildBottomActions(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
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
              color: Colors.black.withOpacity(0.6),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
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
                  bottom: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      showProfileImagePickerDialog(context, controller);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.black87,
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

    if (controller.imageFile == null && controller.avatarPath == null && activeProfile.avatar == null) {
      avatarPreview = ShimmerAvatar(
        avatarPath: '',
        isOnline: true,
        isLoading: true,
        radius: 125,
      );
    } else if (imageFile != null) {
      avatarPreview = Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: FileImage(imageFile),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (avatarPath != null && (avatarPath.endsWith('.png') || avatarPath.endsWith('.jpg'))) {
      avatarPreview = Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: AssetImage(avatarPath),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (avatarPath != null && (avatarPath.endsWith('.glb') || avatarPath.endsWith('.obj'))) {
      avatarPreview = DepthCard3D(
        config: DepthCardConfig(
          modelAssetPath: avatarPath,
          theme: controller.depthCardTheme,
          text: '',
          width: double.infinity,
          height: double.infinity,
          parallaxDepth: 0.2,
          borderRadius: 150,
          backgroundImage: const AssetImage('assets/images/backgrounds/geometry_background.jpg'),
          onTap: () {},
          overlayActions: [],
        ),
      );
    } else if (activeProfile.avatar != null) {
      avatarPreview = Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: AssetImage(activeProfile.avatar!),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      avatarPreview = Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Center(
          child: Text(
            activeProfile.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A5ACD),
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
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showEditNameBottomSheet(context, activeProfile),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              color: Colors.white.withOpacity(0.7),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              activeProfile.ageGroup?.toUpperCase() ?? 'Student',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (activeProfile.country != null) ...[
              const SizedBox(width: 12),
              Icon(
                Icons.location_on,
                color: Colors.white.withOpacity(0.7),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                activeProfile.country!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              color: Colors.white.withOpacity(0.7),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'Loves $favoriteSubject',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEducationalProgress(ProfileData activeProfile) {
    return Consumer(
      builder: (context, ref, child) {
        final xp = ref.watch(profileAwareXPProvider.notifier).state;
        final educationalStatsAsync = ref.watch(educationalStatsProvider);

        return educationalStatsAsync.when(
          data: (stats) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Learning Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${activeProfile.currentXP} XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: (activeProfile.currentXP / activeProfile.maxXP).clamp(0.0, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF40E0D0), Color(0xFF00CED1)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Next Level: ${activeProfile.maxXP - activeProfile.currentXP} XP to go',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Learning Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${activeProfile.currentXP} XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          error: (error, stack) => Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Learning Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${activeProfile.currentXP} XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudyGroupSection(ProfileData activeProfile) {
    final teamName = activeProfile.preferences['teamName'] ?? 'Solo Learner';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Study Group',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                teamName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _buildTeamMemberAvatar('assets/images/avatars/avatar-5.png'),
                  Transform.translate(
                    offset: const Offset(-6, 0),
                    child: _buildTeamMemberAvatar('assets/images/avatars/avatar-5.png'),
                  ),
                  Transform.translate(
                    offset: const Offset(-12, 0),
                    child: _buildTeamMemberAvatar('assets/images/avatars/avatar-5.png'),
                  ),
                  if (activeProfile.isPremium) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 12,
        backgroundImage: AssetImage(avatarPath),
        onBackgroundImageError: (exception, stackTrace) {},
        child: avatarPath.contains('member')
            ? null
            : const CircleAvatar(
          radius: 12,
          backgroundImage: AssetImage('assets/images/avatars/avatar-5.png'),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Recent Quiz Results',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF40E0D0), Color(0xFF00CED1)],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF40E0D0).withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            'Study Chat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF6A5ACD),
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: const Color(0xFF6A5ACD),
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        tabs: const [
          Tab(icon: Icon(Icons.grid_view, size: 22), text: 'Collection'),
          Tab(icon: Icon(Icons.bar_chart, size: 22), text: 'Statistics'),
          Tab(icon: Icon(Icons.emoji_events, size: 22), text: 'Achievements'),
          Tab(icon: Icon(Icons.create, size: 22), text: 'Questions'),
        ],
      ),
    );
  }
}