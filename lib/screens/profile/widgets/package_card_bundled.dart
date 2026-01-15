import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/models/avatar_package_models.dart';
import '../../../game/providers/avatar_package_providers.dart';

class PackageCardBundled extends ConsumerWidget {
  final AvatarPackageMetadata meta;
  final String assetArchivePath;
  final Future<void> Function() onInstalled;

  const PackageCardBundled({
    super.key,
    required this.meta,
    required this.assetArchivePath,
    required this.onInstalled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool>(
      future: ref.read(avatarPackageServiceProvider).isInstalled(meta),
      builder: (context, snap) {
        final installed = snap.data == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: installed
                  ? [
                Colors.white.withOpacity(0.06),
                Colors.white.withOpacity(0.03),
              ]
                  : [
                const Color(0xFFFBBF24).withOpacity(0.15),
                const Color(0xFFF59E0B).withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: installed
                  ? Colors.white.withOpacity(0.12)
                  : const Color(0xFFFBBF24).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              if (!installed)
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFBBF24).withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: installed
                            ? Colors.white.withOpacity(0.08)
                            : const Color(0xFFFBBF24).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: installed
                              ? Colors.white.withOpacity(0.15)
                              : const Color(0xFFFBBF24).withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: installed
                            ? Colors.white.withOpacity(0.6)
                            : const Color(0xFFFBBF24),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'v${meta.version}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.circle,
                                size: 4,
                                color: Colors.white.withOpacity(0.4),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Bundled',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: installed
                          ? null
                          : () async {
                        final svc =
                        ref.read(avatarPackageServiceProvider);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                              Text('Installing "${meta.name}"...'),
                              backgroundColor: const Color(0xFFFBBF24),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }

                        try {
                          await svc.installBundledAssetArchive(
                            meta: meta,
                            assetArchivePath: assetArchivePath,
                          );

                          await onInstalled();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                Text('Installed "${meta.name}"'),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: installed
                            ? Colors.white.withOpacity(0.1)
                            : const Color(0xFFFBBF24),
                        foregroundColor:
                        installed ? Colors.white54 : const Color(0xFF0A0A0F),
                        elevation: installed ? 0 : 3,
                        shadowColor: installed
                            ? Colors.transparent
                            : const Color(0xFFFBBF24).withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        installed ? 'Installed' : 'Install',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}