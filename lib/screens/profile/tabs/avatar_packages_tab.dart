import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/models/avatar_package_models.dart';
import '../../../game/providers/avatar_package_providers.dart';
import '../widgets/package_card_bundled.dart';
import '../widgets/package_card_installed.dart';
import '../widgets/package_card_server.dart';
import '../widgets/section_header.dart';

class AvatarPackagesTab extends ConsumerWidget {
  const AvatarPackagesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installedAsync = ref.watch(installedAvatarPackagesProvider);
    final serverAsync = ref.watch(serverAvatarPackagesProvider);

    Future<void> refresh() async {
      ref.invalidate(installedAvatarPackagesProvider);
      ref.invalidate(serverAvatarPackagesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    return RefreshIndicator(
      color: const Color(0xFF6366F1),
      backgroundColor: const Color(0xFF1A1A24),
      onRefresh: refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Bundled Demo Packages Section
          const SectionHeader(
            icon: Icons.inventory_2_rounded,
            title: 'Bundled Packages',
            subtitle: 'Demo packs included with the app (offline)',
            gradient: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          ),
          const SizedBox(height: 16),
          _buildBundledPackages(context, ref),
          const SizedBox(height: 32),

          // Installed Packages Section
          const SectionHeader(
            icon: Icons.folder_rounded,
            title: 'Installed Packages',
            subtitle: 'Manage your downloaded avatar packs',
            gradient: [Color(0xFF10B981), Color(0xFF3B82F6)],
          ),
          const SizedBox(height: 16),
          installedAsync.when(
            data: (items) => _buildInstalledPackages(context, ref, items),
            loading: () => const _LoadingShimmer(),
            error: (e, _) => _ErrorCard('Failed to load installed: $e'),
          ),
          const SizedBox(height: 32),

          // Server Packages Section
          const SectionHeader(
            icon: Icons.cloud_download_rounded,
            title: 'Download Packages',
            subtitle: 'Browse and install new avatar collections',
            gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          const SizedBox(height: 16),
          serverAsync.when(
            data: (items) => _buildServerPackages(context, ref, items),
            loading: () => const _LoadingShimmer(),
            error: (e, _) => _ErrorCard('Failed to load server packages: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildBundledPackages(BuildContext context, WidgetRef ref) {
    final demoMeta = AvatarPackageMetadata(
      id: 'demo_animals',
      name: 'Demo Animals Pack',
      version: '1.0.0',
      thumbnailUrl: null,
      archiveUrl: null,
      sizeBytes: null,
      sha256: null,
      render: const AvatarPackageRenderHints(kind: AvatarPackageType.image),
    );

    const demoAssetPath = 'assets/zip/demo_avatar_package_animals_v1.zip';

    return PackageCardBundled(
      meta: demoMeta,
      assetArchivePath: demoAssetPath,
      onInstalled: () async {
        ref.invalidate(installedAvatarPackagesProvider);
      },
    );
  }

  Widget _buildInstalledPackages(
    BuildContext context,
    WidgetRef ref,
    List<AvatarPackageInstall> items,
  ) {
    if (items.isEmpty) {
      return _EmptyPlaceholder(
        icon: Icons.folder_off_rounded,
        message: 'No packages installed yet',
        color: const Color(0xFF10B981),
      );
    }

    return Column(
      children: items.map((install) {
        return PackageCardInstalled(
          install: install,
          onUninstall: () async {
            final svc = ref.read(avatarPackageServiceProvider);
            await svc.uninstall(install);
            ref.invalidate(installedAvatarPackagesProvider);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Uninstalled "${install.meta.name}"'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildServerPackages(
    BuildContext context,
    WidgetRef ref,
    List<AvatarPackageMetadata> items,
  ) {
    if (items.isEmpty) {
      return _EmptyPlaceholder(
        icon: Icons.cloud_off_rounded,
        message: 'No server packages available\nPull down to refresh',
        color: const Color(0xFF6366F1),
      );
    }

    return Column(
      children: items.map((meta) {
        return PackageCardServer(
          meta: meta,
          onInstall: () async {
            final svc = ref.read(avatarPackageServiceProvider);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloading "${meta.name}"...'),
                  backgroundColor: const Color(0xFF6366F1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }

            try {
              await svc.downloadAndInstall(meta);
              ref.invalidate(installedAvatarPackagesProvider);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Installed "${meta.name}"'),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Install failed: $e'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            }
          },
        );
      }).toList(),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(2, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.02),
                Colors.white.withValues(alpha: 0.05),
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        );
      }),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.redAccent.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _EmptyPlaceholder({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: color.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
