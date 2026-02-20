import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../../../game/utils/avatar_asset_loader.dart';
import '../../../ui_components/depth_card_3d/depth_card.dart';
import '../../../ui_components/depth_card_3d/theme_editor/depth_card_theme_selector.dart';
import '../widgets/empty_state_widget.dart';

class Avatar3DTab extends ConsumerStatefulWidget {
  final DepthCardTheme selectedTheme;
  final Future<void> Function(DepthCardTheme) onThemeSelected;

  const Avatar3DTab({
    super.key,
    required this.selectedTheme,
    required this.onThemeSelected,
  });

  @override
  ConsumerState<Avatar3DTab> createState() => _Avatar3DTabState();
}

class _Avatar3DTabState extends ConsumerState<Avatar3DTab> {
  List<String> threeDAvatars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvatars();
  }

  Future<void> _loadAvatars() async {
    setState(() => _isLoading = true);

    final cache = ref.read(appCacheServiceProvider);
    final loaded3D = await AvatarAssetLoader.loadThreeDAvatars(cache: cache);

    if (mounted) {
      setState(() {
        threeDAvatars = loaded3D;
        _isLoading = false;
      });
    }
  }

  void _selectAvatar(String path) {
    final controller = ref.read(profileAvatarControllerProvider.notifier);
    controller.selectAvatarFromAsset(path);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildThemeSelector(),
        const SizedBox(height: 20),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildThemeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16), // Reduced from 20 to prevent overflow
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withValues(alpha: 0.2),
            const Color(0xFFEC4899).withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ✅ Prevents vertical overflow
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.palette_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Card Theme',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced from 16 for more compact layout
          DepthCardThemeSelector(
            selectedName: widget.selectedTheme.name,
            onThemeSelected: widget.onThemeSelected,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading 3D avatars...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (threeDAvatars.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.threed_rotation_rounded,
        title: 'No 3D Avatars',
        message: 'Install 3D avatar packages to get started',
        gradient: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: threeDAvatars.length,
      itemBuilder: (context, index) {
        final modelPath = threeDAvatars[index];

        final config = DepthCardConfig(
          modelAssetPath: modelPath,
          text: "Character ${index + 1}",
          onTap: () => _selectAvatar(modelPath),
          theme: widget.selectedTheme,
          width: 200,
          height: 220,
          parallaxDepth: 0.1,
          borderRadius: 20.0,
          backgroundImage:
          const AssetImage('assets/images/logo/appLogo.png'),
          overlayActions: [],
        );

        return DepthCard3D(config: config);
      },
    );
  }
}