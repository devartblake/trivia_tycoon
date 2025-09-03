import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui_components/depth_card_3d/depth_card.dart';
import '../../ui_components/depth_card_3d/theme_editor/depth_card_theme_selector.dart';
import '../../core/services/settings/app_settings.dart';
import '../../game/providers/riverpod_providers.dart';
import '../../game/utils/avatar_asset_loader.dart'; // Adjust path if needed

class AvatarSelectionScreen extends ConsumerStatefulWidget {
   const AvatarSelectionScreen({super.key});

  @override
  ConsumerState<AvatarSelectionScreen> createState() => _AvatarChoiceScreenState();
}

class _AvatarChoiceScreenState extends ConsumerState<AvatarSelectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> imageAvatars = [];
  List<String> threeDAvatars = [];
  DepthCardTheme _selectedTheme = DepthCardTheme.presets[0];

  final List<Map<String, String>> avatarPackages = [
    {
      'image': 'assets/images/packages/package1.png',
      'route': '/store?package=starter'
    },
    {
      'image': 'assets/images/packages/package2.png',
      'route': '/store?package=hero'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _loadAvatars();
    AppSettings.getDepthCardTheme().then((name) {
      if (name != null) {
        setState(() {
          _selectedTheme = DepthCardTheme.fromName(name);
        });
      }
    });
  }

  Future<void> _loadAvatars() async {
    final loadedImages = await AvatarAssetLoader.loadImageAvatars();
    final loaded3D = await AvatarAssetLoader.loadThreeDAvatars();
    setState(() {
      imageAvatars = loadedImages;
      threeDAvatars = loaded3D;
    });
  }

  void _selectAvatar(String path, {bool is3D = false}) {
    final controller = ref.read(profileAvatarControllerProvider.notifier);
    controller.selectAvatarFromAsset(path);
    Navigator.pop(context);
  }

  /// ** Dynamically loading Avatar Images
  Widget _buildImageAvatarTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: imageAvatars.length,
      itemBuilder: (context, index) {
        final imagePath = imageAvatars[index];
        return GestureDetector(
          onTap: () => _selectAvatar(imagePath),
          child: CircleAvatar(
            backgroundImage: AssetImage(imagePath),
            radius: 40,
          ),
        );
      },
    );
  }

  /// ** Dynamically load DepthCard 3D Avatars.
  Widget _build3DAvatarTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Choose Theme", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DepthCardThemeSelector(
                selectedName: _selectedTheme.name,
                onThemeSelected: (theme) async {
                  setState(() => _selectedTheme = theme);
                  await AppSettings.setDepthCardTheme(theme.name);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Can adjust if needed
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: threeDAvatars.length,
            itemBuilder: (context, index) {
              final modelPath = threeDAvatars[index];

              final config = DepthCardConfig(
                modelAssetPath: modelPath,
                text: "Character ${index + 1}",
                onTap: () => _selectAvatar(modelPath),
                theme: _selectedTheme,
                width: 200,
                height: 200,
                parallaxDepth: 0.1,
                borderRadius: 30.0,
                backgroundImage: const AssetImage('assets/images/logo/appLogo.png'),
                overlayActions: [],
              );

              return DepthCard3D(config: config);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPackagesTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: avatarPackages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final package = avatarPackages[index];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, package['route']!),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(package['image']!),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text("Package ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Avatar"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.image), text: "Images"),
            Tab(icon: Icon(Icons.threed_rotation), text: "3D"),
            Tab(icon: Icon(Icons.shopping_bag), text: "Packages"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Image Avatars
          _buildImageAvatarTab(),

          // 3D Avatars using DepthCard3D
          _build3DAvatarTab(),

          // Packages (Navigate to Store)
          _buildAvatarPackagesTab(),
        ],
      ),
    );
  }
}
