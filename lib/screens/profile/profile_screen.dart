import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/screens/profile/widgets/shimmer_avatar.dart';
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

  final String userName = "Maria Elliott";
  final String location = "Albany, New York";
  final String avatarImage = 'assets/images/avatars/default-avatar.jpg'; // Replace as needed

  final int purchased = 120;
  final int wished = 271;
  final int likes = 12000;

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
        content: const Text('✅ Admin Mode Enabled'),
        showCloseIcon: true,
        behavior: SnackBarBehavior.floating,
        clipBehavior: Clip.none, // disables clipping issues
        margin: const EdgeInsets.all(12),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: accentColor,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (_isAdmin)
            Row(
              children: [
                Tooltip(
                  message: _adminModeEnabled ? 'Disable Admin Mode' : 'Enable Admin Mode',
                  child: IconButton(
                    icon: Icon(
                      _adminModeEnabled ? Icons.toggle_on : Icons.toggle_off,
                      color: _adminModeEnabled ? Colors.green : Colors.grey,
                      size: 32,
                    ),
                    onPressed: () => _toggleAdminMode(!_adminModeEnabled),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.palette),
            tooltip: 'Customize 3D Theme',
            onPressed: () => context.push('/gradient-editor'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'User Settings',
            onPressed: () => context.push('/user-settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProfileHeader(theme),
          const SizedBox(height: 10),
          TabBar(
            controller: _tabController,
            indicatorColor: accentColor,
            tabs: const [
              Tooltip(
                message: 'Collection', child: Tab(icon: Icon(Icons.grid_view)),
              ),
              Tooltip(
                message: 'Statistics', child: Tab(icon: Icon(Icons.bar_chart)),
              ),
              Tooltip(
                message: 'Achievements', child: Tab(icon: Icon(Icons.emoji_events)),
              ),
              Tooltip(
                message: 'Created Questions', child: Tab(icon: Icon(Icons.create)),
              ),
            ],
          ),
          Expanded(
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
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    final accentColor = theme.colorScheme.primary;

    return Consumer(
      builder: (context, ref, _) {
        final controller = ref.watch(profileAvatarControllerProvider);
        final imageFile = controller.imageFile;
        final avatarPath = controller.avatarPath;

        Widget avatarPreview;

        if (controller.imageFile == null && controller.avatarPath == null) {
          Hero(
            tag: 'profile-avatar',
            child: avatarPreview = ShimmerAvatar(
                avatarPath: '',
                isOnline: true,
                isLoading: true,
              ),
            );
        } else if (imageFile != null) {
          avatarPreview = CircleAvatar(
            radius: 45,
            backgroundImage: FileImage(imageFile),
          );
        } else if (avatarPath != null && (avatarPath.endsWith('.png') || avatarPath.endsWith('.jpg'))) {
          avatarPreview = CircleAvatar(
            radius: 45,
            backgroundImage: AssetImage(avatarPath),
          );
        } else if (avatarPath != null && (avatarPath.endsWith('.glb') || avatarPath.endsWith('.obj'))) {
          avatarPreview = SizedBox(
            width: 100,
            height: 100,
            child: DepthCard3D(
              config: DepthCardConfig(
                modelAssetPath: avatarPath,
                theme: controller.depthCardTheme,
                text: '',
                width: 100,
                height: 100,
                parallaxDepth: 0.2,
                borderRadius: 50,
                backgroundImage: const AssetImage('assets/images/backgrounds/3d_placeholder.jpg'),
                onTap: () {},
                overlayActions: [],
              ),
            ),
          );
        } else {
          avatarPreview = const CircleAvatar(
            radius: 45,
            backgroundImage: AssetImage('assets/images/avatars/default-avatar.jpg'),
          );
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentColor.withOpacity(0.85), accentColor.withOpacity(0.6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              Stack(
                children: [
                  avatarPreview,
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        showProfileImagePickerDialog(context, controller);
                      },
                      child: const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.edit, size: 16, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.restore, color: Colors.white60),
                label: const Text("Reset Avatar", style: TextStyle(color: Colors.white60),),
                onPressed: () async {
                  await ref.read(profileAvatarControllerProvider.notifier).resetAvatar();
                },
              ),
              Text(userName, style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
              Text(location, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  AnimatedStatBox(label: 'Purchased', value: purchased, gradientColors: [Colors.blue, Colors.yellow]),
                  AnimatedStatBox(label: 'Wished', value: wished, gradientColors: [Colors.orange, Colors.red]),
                  AnimatedStatBox(label: 'Likes', value: likes, gradientColors: [Colors.green, Colors.teal]),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Drawer _buildFancyDrawer(Color accentColor) {
    return Drawer(
      child: Container(
        color: accentColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text("Maria Elliott"),
              accountEmail: Text("maria@example.com"),
              currentAccountPicture: Hero(
                tag: 'profile-avatar',
                child: ShimmerAvatar(
                  avatarPath: '',
                  isOnline: true,
                  isLoading: false,
                ),
              ),
              decoration: BoxDecoration(color: Colors.transparent),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text('Home', style: TextStyle(color: Colors.white)),
              onTap: () => context.push('/'),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text('Profile', style: TextStyle(color: Colors.white)),
              onTap: () => context.push('/profile'),
            ),
            ExpansionTile(
              collapsedIconColor: Colors.white,
              iconColor: Colors.white,
              leading: const Icon(Icons.menu, color: Colors.white),
              title: const Text('More Options', style: TextStyle(color: Colors.white)),
              children: [
                ListTile(
                  leading: const Icon(Icons.people, color: Colors.white),
                  title: const Text('Friends', style: TextStyle(color: Colors.white)),
                  onTap: () => context.push('/friends'),
                ),
                ListTile(
                  leading: const Icon(Icons.tune, color: Colors.white),
                  title: const Text('Preferences', style: TextStyle(color: Colors.white)),
                  onTap: () => context.push('/preferences'),
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: Colors.white),
                  title: const Text('Help', style: TextStyle(color: Colors.white)),
                  onTap: () => context.push('/help'),
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Logout', style: TextStyle(color: Colors.white)),
              onTap: () {
                // Implement logout
              },
            ),
          ],
        ),
      ),
    );
  }
}
