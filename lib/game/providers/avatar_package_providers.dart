import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';

import '../../core/services/storage/app_cache_service.dart';
import '../models/avatar_package_models.dart';
import '../services/avatar_package_service.dart';

final appCacheServiceProvider = Provider<AppCacheService>((ref) {
  return ref.read(serviceManagerProvider).appCacheService;
});

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
