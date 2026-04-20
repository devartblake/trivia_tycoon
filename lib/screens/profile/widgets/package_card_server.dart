import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/models/avatar_package_models.dart';
import '../../../game/providers/avatar_package_providers.dart';

class PackageCardServer extends ConsumerWidget {
  final AvatarPackageMetadata meta;
  final Future<void> Function() onInstall;

  const PackageCardServer({
    super.key,
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: installed
                  ? [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.03),
                    ]
                  : [
                      const Color(0xFF6366F1).withValues(alpha: 0.15),
                      const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: installed
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFF6366F1).withValues(alpha: 0.3),
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
                          const Color(0xFF6366F1).withValues(alpha: 0.2),
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
                        gradient: installed
                            ? LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.15),
                                  Colors.white.withValues(alpha: 0.08),
                                ],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: installed
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                        boxShadow: installed
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(0xFF6366F1)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Icon(
                        installed
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_download_rounded,
                        color: Colors.white,
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
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'v${meta.version}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (meta.sizeBytes != null) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.circle,
                                  size: 4,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${(meta.sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: installed ? null : () async => onInstall(),
                      icon: Icon(
                        installed
                            ? Icons.check_rounded
                            : Icons.download_rounded,
                        size: 18,
                      ),
                      label: Text(installed ? 'Installed' : 'Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: installed
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFF6366F1),
                        foregroundColor:
                            installed ? Colors.white54 : Colors.white,
                        elevation: installed ? 0 : 3,
                        shadowColor: installed
                            ? Colors.transparent
                            : const Color(0xFF6366F1).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
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
