import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage/app_cache_service.dart';
import '../../core/services/settings/app_settings.dart';
import '../../core/services/storage/secure_storage.dart';

final appCacheServiceProvider = Provider<AppCacheService>((ref) {
  return AppCacheService();
});

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});
