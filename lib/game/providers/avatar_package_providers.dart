import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';

import '../models/avatar_package_models.dart';
import '../services/avatar_package_service.dart';

/// Provide a remote source later (FastAPI).
/// For now, keep it null (or swap in a mock implementation).
final avatarPackageRemoteSourceProvider = Provider<AvatarPackageRemoteSource?>((ref) {
  return null;
});

final avatarPackageServiceProvider = Provider<AvatarPackageService>((ref) {
  final cache = ref.watch(appCacheServiceProvider);
  final remote = ref.watch(avatarPackageRemoteSourceProvider);
  return AvatarPackageService(cache, remote: remote);
});

/// Local installs list.
final installedAvatarPackagesProvider = FutureProvider<List<AvatarPackageInstall>>((ref) async {
  final svc = ref.watch(avatarPackageServiceProvider);
  return svc.listInstalled();
});

/// Server list (cached if no remote is wired).
final serverAvatarPackagesProvider = FutureProvider<List<AvatarPackageMetadata>>((ref) async {
  final svc = ref.watch(avatarPackageServiceProvider);
  return svc.fetchServerPackages();
});
