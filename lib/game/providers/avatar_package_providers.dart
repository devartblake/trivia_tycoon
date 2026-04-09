import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../models/avatar_package_models.dart';
import '../services/avatar_package_service.dart';

/// Provide a remote source later (FastAPI).
/// For now, keep it null (or swap in a mock implementation).
final avatarPackageRemoteSourceProvider = Provider<AvatarPackageRemoteSource?>((ref) {
  return null;
});

/// ----------------------------
/// Service provider
/// ----------------------------

final avatarPackageServiceProvider = Provider<AvatarPackageService>((ref) {
  final cache = ref.watch(appCacheServiceProvider);
  final remote = ref.watch(avatarPackageRemoteSourceProvider);
  return AvatarPackageService(cache, remote: remote);
});

/// ----------------------------
/// Installed (local) packages
/// ----------------------------

final installedAvatarPackagesProvider =
FutureProvider<List<AvatarPackageInstall>>((ref) async {
  final service = ref.read(avatarPackageServiceProvider);
  return service.loadInstalledPackages();
});

/// ----------------------------
/// Server (remote) packages
/// ----------------------------
///
/// This is backend-ready but safe for now.
/// If no backend is wired, it simply returns [].

final serverAvatarPackagesProvider =
FutureProvider<List<AvatarPackageMetadata>>((ref) async {
  final service = ref.read(avatarPackageServiceProvider);

  // If remote source not connected yet, return empty list safely
  if (!service.hasRemoteSource) {
    return const [];
  }

  return service.fetchServerPackages();
});