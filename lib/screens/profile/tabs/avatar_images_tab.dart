import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../../../game/utils/avatar_asset_loader.dart';
import '../widgets/avatar_image_card.dart';
import '../widgets/empty_state_widget.dart';

class AvatarImagesTab extends ConsumerStatefulWidget {
  const AvatarImagesTab({super.key});

  @override
  ConsumerState<AvatarImagesTab> createState() => _AvatarImagesTabState();
}

class _AvatarImagesTabState extends ConsumerState<AvatarImagesTab> {
  List<String> imageAvatars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvatars();
  }

  Future<void> _loadAvatars() async {
    setState(() => _isLoading = true);

    final cache = ref.read(appCacheServiceProvider);
    final loadedImages = await AvatarAssetLoader.loadImageAvatars(cache: cache);

    if (mounted) {
      setState(() {
        imageAvatars = loadedImages;
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
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
              'Loading avatars...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (imageAvatars.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.image_not_supported_rounded,
        title: 'No Image Avatars',
        message: 'Install avatar packages to get started',
        gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: imageAvatars.length,
      itemBuilder: (context, index) {
        final imagePath = imageAvatars[index];
        return AvatarImageCard(
          imagePath: imagePath,
          onTap: () => _selectAvatar(imagePath),
        );
      },
    );
  }
}