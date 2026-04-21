import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/store/avatar_asset_service.dart';
import '../../../game/models/avatar_package_models.dart';
import '../../../game/providers/avatar_package_providers.dart';
import '../../../game/providers/riverpod_providers.dart';

class TryNowWidget extends ConsumerStatefulWidget {
  final String modelPath;
  final String title;

  /// When set, enables the full purchase/install/equip flow.
  /// Should be the avatar SKU (e.g. "avatar:cartoon-hero:v1").
  final String? avatarId;

  const TryNowWidget({
    super.key,
    required this.modelPath,
    this.title = 'Try Now',
    this.avatarId,
  });

  @override
  ConsumerState<TryNowWidget> createState() => _TryNowWidgetState();
}

class _TryNowWidgetState extends ConsumerState<TryNowWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;
  bool _isBuying = false;
  bool _isInstalling = false;
  double _installProgress = 0.0;
  final Flutter3DController _viewer3D = Flutter3DController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // State helpers
  // ---------------------------------------------------------------------------

  AvatarPackageInstall? _findInstall(List<AvatarPackageInstall> installed) {
    if (widget.avatarId == null) return null;
    try {
      return installed.firstWhere((i) => i.meta.id == widget.avatarId);
    } catch (_) {
      return null;
    }
  }

  AvatarPackageMetadata? _findMeta(List<AvatarPackageMetadata> server) {
    if (widget.avatarId == null) return null;
    try {
      return server.firstWhere((m) => m.id == widget.avatarId);
    } catch (_) {
      return null;
    }
  }

  String _glbPath(AvatarPackageInstall install) {
    final sep = install.installDir.endsWith('/') ? '' : '/';
    return '${install.installDir}${sep}models/avatar.glb';
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _handleBuy(AvatarPackageMetadata meta) async {
    HapticFeedback.mediumImpact();
    setState(() => _isBuying = true);
    try {
      final playerId = await ref.read(currentUserIdProvider.future);
      final response = await ref.read(storeServiceProvider).purchaseAvatar(
            playerId: playerId,
            avatarId: meta.id,
          );
      final newBalance = (response['newBalance'] as num?)?.toInt();
      if (newBalance != null) {
        await ref.read(coinBalanceProvider.notifier).set(newBalance);
      }
      ref.invalidate(serverAvatarPackagesProvider);
      if (!mounted) return;
      _showSnack('${meta.name} purchased! Tap Install to download.', const Color(0xFF10B981));
    } on ApiRequestException catch (e) {
      if (!mounted) return;
      _showSnack(e.message, const Color(0xFFEF4444));
    } catch (_) {
      if (!mounted) return;
      _showSnack('Purchase failed. Please try again.', const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  Future<void> _handleInstall(AvatarPackageMetadata meta) async {
    HapticFeedback.lightImpact();
    setState(() {
      _isInstalling = true;
      _installProgress = 0.0;
    });
    try {
      final asset =
          await ref.read(avatarAssetServiceProvider).getAvatarAsset(meta.id);

      final enriched = AvatarPackageMetadata(
        id: meta.id,
        name: meta.name,
        version: meta.version,
        thumbnailUrl: asset.thumbnailUrl ?? meta.thumbnailUrl,
        archiveUrl: asset.presignedUrl,
        sha256: asset.sha256,
        render: meta.render,
      );

      setState(() => _installProgress = 0.1);
      await ref.read(avatarPackageServiceProvider).downloadAndInstall(enriched);
      ref.invalidate(installedAvatarPackagesProvider);

      if (!mounted) return;
      _showSnack('${meta.name} installed! Tap Equip to use it.', const Color(0xFF10B981));
    } catch (e) {
      LogManager.debug('Avatar install failed: $e');
      if (!mounted) return;
      _showSnack('Download failed. Please try again.', const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _isInstalling = false);
    }
  }

  void _handleEquip() {
    HapticFeedback.lightImpact();
    context.push('/avatar-select');
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (widget.avatarId == null) {
      return _buildPlaceholder();
    }

    final serverAsync = ref.watch(serverAvatarPackagesProvider);
    final installedAsync = ref.watch(installedAvatarPackagesProvider);

    final meta = serverAsync.maybeWhen(
      data: _findMeta,
      orElse: () => null,
    );
    final install = installedAsync.maybeWhen(
      data: _findInstall,
      orElse: () => null,
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(meta),
          const SizedBox(height: 8),
          _buildViewerCard(install, meta),
          const SizedBox(height: 12),
          _buildActionBar(install, meta),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(AvatarPackageMetadata? meta) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.threed_rotation, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta?.name ?? widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Text(
                  'Interactive 3D experience',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF10B981), size: 14),
                SizedBox(width: 4),
                Text(
                  'NEW',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Viewer card — 3D when installed, thumbnail when owned, lock overlay otherwise
  // ---------------------------------------------------------------------------

  Widget _buildViewerCard(AvatarPackageInstall? install, AvatarPackageMetadata? meta) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _animationController.reverse();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _animationController.forward();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _animationController.forward();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, _) => Transform.scale(
          scale: _isPressed ? _scaleAnimation.value : 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 250,
              width: double.infinity,
              child: _buildViewerContent(install, meta),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewerContent(AvatarPackageInstall? install, AvatarPackageMetadata? meta) {
    // Installed — render the local GLB file
    if (install != null) {
      final glb = _glbPath(install);
      return Flutter3DViewer(
        controller: _viewer3D,
        src: glb,
        progressBarColor: const Color(0xFF6366F1),
        onProgress: (_) {},
        onLoad: (_) {},
      );
    }

    // Owned but not installed — show thumbnail
    final thumb = meta?.thumbnailUrl;
    if (thumb != null && thumb.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(thumb, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildGradientPlaceholder()),
          Container(
            alignment: Alignment.center,
            color: Colors.black.withValues(alpha: 0.3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.download_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                Text(
                  'Tap Install to download',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Not owned — gradient placeholder with lock
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildGradientPlaceholder(),
        if (meta != null)
          Container(
            alignment: Alignment.center,
            color: Colors.black.withValues(alpha: 0.2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                const Text(
                  'Purchase to unlock',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGradientPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.threed_rotation, color: Colors.white, size: 64),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action bar — Buy / Install / Equip
  // ---------------------------------------------------------------------------

  Widget _buildActionBar(AvatarPackageInstall? install, AvatarPackageMetadata? meta) {
    if (_isInstalling) {
      return _buildProgressBar();
    }

    Widget button;
    if (install != null) {
      button = _buildButton(
        label: 'Equip',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF10B981),
        onTap: _handleEquip,
        loading: false,
      );
    } else if (meta != null) {
      // Determine owned state: server list refreshes after purchase,
      // so treat meta.archiveUrl != null as "owned but not installed" signal.
      // In practice the server returns owned=true on the catalog item after purchase.
      final serverAsync = ref.watch(serverAvatarPackagesProvider);
      final isOwned = serverAsync.maybeWhen(
        data: (list) {
          try {
            final m = list.firstWhere((x) => x.id == widget.avatarId);
            return m.archiveUrl != null || (meta.archiveUrl != null);
          } catch (_) {
            return false;
          }
        },
        orElse: () => false,
      );

      if (isOwned) {
        button = _buildButton(
          label: 'Install',
          icon: Icons.download_rounded,
          color: const Color(0xFF6366F1),
          onTap: () => _handleInstall(meta),
          loading: false,
        );
      } else {
        button = _buildButton(
          label: _isBuying ? '' : 'Buy — ${_formatPrice(meta)}',
          icon: Icons.shopping_cart_outlined,
          color: const Color(0xFF6366F1),
          onTap: () => _handleBuy(meta),
          loading: _isBuying,
        );
      }
    } else {
      button = const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF64748B).withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  install != null
                      ? 'Your avatar is ready'
                      : 'Ready to customize?',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  install != null
                      ? 'Select it from your profile'
                      : 'Purchase and install your 3D avatar',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          button,
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool loading,
  }) {
    return ElevatedButton.icon(
      onPressed: loading ? null : onTap,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon, size: 16),
      label: loading ? const SizedBox.shrink() : Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Downloading avatar…',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _installProgress > 0 ? _installProgress : null,
            backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  String _formatPrice(AvatarPackageMetadata meta) {
    // Price info lives in StoreItemModel; meta only carries id/name/thumbnail.
    // Show generic label until StoreItemModel is unified with AvatarPackageMetadata.
    return 'Coins';
  }

  // ---------------------------------------------------------------------------
  // Fallback placeholder (no avatarId provided)
  // ---------------------------------------------------------------------------

  Widget _buildPlaceholder() {
    LogManager.debug('Building TryNowWidget placeholder for: ${widget.modelPath}');
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.threed_rotation, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Text(
                          'Interactive 3D experience',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTapDown: (_) {
                setState(() => _isPressed = true);
                _animationController.reverse();
              },
              onTapUp: (_) {
                setState(() => _isPressed = false);
                _animationController.forward();
                _handleInteraction();
              },
              onTapCancel: () {
                setState(() => _isPressed = false);
                _animationController.forward();
              },
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, _) => Transform.scale(
                  scale: _isPressed ? _scaleAnimation.value : 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _buildGradientPlaceholder(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleInteraction() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.threed_rotation, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Interacting with ${widget.title}'),
          ],
        ),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
