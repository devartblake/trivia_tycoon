import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../models/avatar_package_models.dart';
import '../services/avatar_package_service.dart';
import '../../core/services/store/avatar_asset_service.dart';
import '../../core/services/store/avatar_store_remote_source.dart';

final avatarPackageRemoteSourceProvider =
    Provider<AvatarPackageRemoteSource?>((ref) {
  return AvatarStoreRemoteSource(ref.watch(apiServiceProvider));
});

final avatarPackageServiceProvider = Provider<AvatarPackageService>((ref) {
  final cache = ref.watch(appCacheServiceProvider);
  final remote = ref.watch(avatarPackageRemoteSourceProvider);
  return AvatarPackageService(cache, remote: remote);
});

final avatarAssetServiceProvider = Provider<AvatarAssetService>((ref) {
  return AvatarAssetService(ref.watch(synaptixApiClientProvider));
});

final installedAvatarPackagesProvider =
    FutureProvider<List<AvatarPackageInstall>>((ref) async {
  final service = ref.read(avatarPackageServiceProvider);
  return service.loadInstalledPackages();
});

final serverAvatarPackagesProvider =
    FutureProvider<List<AvatarPackageMetadata>>((ref) async {
  final service = ref.read(avatarPackageServiceProvider);
  if (!service.hasRemoteSource) return const [];
  return service.fetchServerPackages();
});
