import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/models/avatar_package_models.dart';
import '../../game/providers/avatar_package_providers.dart';
import '../../game/providers/riverpod_providers.dart';  // ✅ FIXED: Removed hide statement
import '../../ui_components/depth_card_3d/depth_card.dart';
import '../../ui_components/depth_card_3d/theme_editor/depth_card_theme_selector.dart';
import '../../core/services/settings/app_settings.dart';
import '../../game/utils/avatar_asset_loader.dart';

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
    // ✅ FIXED: Get cache from provider
    final cache = ref.read(appCacheServiceProvider);

    // ✅ FIXED: Pass cache parameter to both methods
    final loadedImages = await AvatarAssetLoader.loadImageAvatars(
        cache: ref.read(appCacheServiceProvider)
    );
    final loaded3D = await AvatarAssetLoader.loadThreeDAvatars(cache: cache);

    if (mounted) {
      setState(() {
        imageAvatars = loadedImages;
        threeDAvatars = loaded3D;
      });
    }
  }

  void _selectAvatar(String path, {bool is3D = false}) {
    final controller = ref.read(profileAvatarControllerProvider.notifier);
    controller.selectAvatarFromAsset(path);
    Navigator.pop(context);
  }

  /// ** Dynamically loading Avatar Images
  Widget _buildImageAvatarTab() {
    if (imageAvatars.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No image avatars available',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

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
            backgroundImage: imagePath.startsWith('assets/')
                ? AssetImage(imagePath) as ImageProvider
                : FileImage(File(imagePath)),
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
              const Text(
                "Choose Theme",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
          child: threeDAvatars.isEmpty
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.threed_rotation, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No 3D avatars available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
              : GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
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
          const _AvatarPackagesTab(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _AvatarPackagesTab extends ConsumerWidget {
  const _AvatarPackagesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installedAsync = ref.watch(installedAvatarPackagesProvider);
    final serverAsync = ref.watch(serverAvatarPackagesProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text(
          'Installed Packages',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        installedAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Text(
                'No packages installed yet.',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              );
            }

            return Column(
              children: items.map((install) {
                return _PackageCardInstalled(
                  install: install,
                  onUninstall: () async {
                    final svc = ref.read(avatarPackageServiceProvider);
                    await svc.uninstall(install);

                    // Refresh UI
                    ref.invalidate(installedAvatarPackagesProvider);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Uninstalled "${install.meta.name}".')),
                      );
                    }
                  },
                );
              }).toList(),
            );
          },
          loading: () => const _ThinLoader(),
          error: (e, _) => _ErrorLine('Failed to load installed packages: $e'),
        ),

        const SizedBox(height: 22),

        const Text(
          'Server Packages',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Text(
          'Download image-only packs for now. 3D/DepthCard support can be added later.',
          style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        serverAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Text(
                'No server packages yet (or backend not connected).',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              );
            }

            return Column(
              children: items.map((meta) {
                return _PackageCardServer(
                  meta: meta,
                  onInstall: () async {
                    final svc = ref.read(avatarPackageServiceProvider);

                    // Optimistic UX: show immediate feedback
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloading "${meta.name}"...')),
                      );
                    }

                    try {
                      await svc.downloadAndInstall(meta);
                      ref.invalidate(installedAvatarPackagesProvider);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Installed "${meta.name}".')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Install failed: $e')),
                        );
                      }
                    }
                  },
                );
              }).toList(),
            );
          },
          loading: () => const _ThinLoader(),
          error: (e, _) => _ErrorLine('Failed to load server packages: $e'),
        ),
      ],
    );
  }
}

class _PackageCardInstalled extends StatelessWidget {
  final AvatarPackageInstall install;
  final VoidCallback onUninstall;

  const _PackageCardInstalled({
    required this.install,
    required this.onUninstall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_rounded, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  install.meta.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'v${install.meta.version} • Installed',
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onUninstall,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withOpacity(0.25)),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
  }
}

class _PackageCardServer extends ConsumerWidget {
  final AvatarPackageMetadata meta;
  final Future<void> Function() onInstall;

  const _PackageCardServer({
    required this.meta,
    required this.onInstall,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool>(
      future: ref.read(avatarPackageServiceProvider).isInstalled(meta),
      builder: (context, snap) {
        final installed = snap.data == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_download_rounded, color: Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v${meta.version}${meta.sizeBytes == null ? '' : ' • ${(meta.sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB'}',
                      style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: installed ? null : () async => onInstall(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: installed ? Colors.white.withOpacity(0.10) : Colors.amber.withOpacity(0.95),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(installed ? 'Installed' : 'Download'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThinLoader extends StatelessWidget {
  const _ThinLoader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LinearProgressIndicator(
        minHeight: 3,
        backgroundColor: Colors.white.withOpacity(0.10),
        color: Colors.amberAccent,
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  final String text;
  const _ErrorLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: Colors.redAccent.withOpacity(0.9), fontWeight: FontWeight.w700),
    );
  }
}
