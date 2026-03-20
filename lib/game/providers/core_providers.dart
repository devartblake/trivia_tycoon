/// Infrastructure providers — networking, auth chain, storage.
///
/// Everything else in the providers layer depends on this file.
/// Do NOT import other provider files here.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_tycoon/core/manager/log_manager.dart';

import '../../core/bootstrap/app_init.dart';
import '../../core/env.dart';
import '../../core/manager/login_manager.dart';
import '../../core/manager/service_manager.dart';
import '../../core/navigation/app_router.dart';
import '../../core/networking/http_client.dart';
import '../../core/networking/tycoon_api_client.dart';
import '../../core/networking/ws_client.dart';
import '../../core/services/analytics/config_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_api_client.dart';
import '../../core/services/auth_http_client.dart';
import '../../core/services/auth_token_store.dart';
import '../../core/services/auth_service.dart' as core_auth;
import '../../core/services/device_id_service.dart';
import '../../core/services/settings/general_key_value_storage_service.dart';
import '../../core/services/storage/app_cache_service.dart';
import '../../core/services/storage/secure_storage.dart';

// ---------------------------------------------------------------------------
// Global infrastructure
// ---------------------------------------------------------------------------

final configServiceProvider =
Provider<ConfigService>((ref) => ConfigService.instance);

/// Must be overridden in ProviderScope after [AppInit] completes.
final serviceManagerProvider = Provider<ServiceManager>((ref) {
  throw UnimplementedError(
    'serviceManagerProvider must be overridden in ProviderScope in AppLauncher',
  );
});

final routerProvider = FutureProvider<GoRouter>((ref) async {
  return await AppRouter.router();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final config = ref.watch(configServiceProvider);
  return ApiService(baseUrl: config.apiBaseUrl);
});

final globalWsClientProvider = Provider<WsClient?>((ref) {
  return AppInit.wsClient;
});

final wsConnectionStatusProvider = StateProvider<bool>((ref) {
  return AppInit.isWebSocketConnected;
});

// ---------------------------------------------------------------------------
// Storage
// ---------------------------------------------------------------------------

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final generalKeyValueStorageProvider =
Provider<GeneralKeyValueStorageService>((ref) {
  return GeneralKeyValueStorageService();
});

final appCacheServiceProvider = Provider<AppCacheService>((ref) {
  return ref.read(serviceManagerProvider).appCacheService;
});

// ---------------------------------------------------------------------------
// Auth chain
// ---------------------------------------------------------------------------

final authTokenBoxProvider = Provider<Box>((ref) {
  if (!Hive.isBoxOpen('auth_tokens')) {
    throw StateError(
        'auth_tokens box must be opened in app_init.dart before creating providers');
  }
  return Hive.box('auth_tokens');
});

final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
  final box = ref.watch(authTokenBoxProvider);
  return AuthTokenStore(box);
});

final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DeviceIdService(secureStorage);
});

final authApiClientProvider = Provider<AuthApiClient>((ref) {
  return AuthApiClient(
    http.Client(),
    apiBaseUrl: EnvConfig.apiBaseUrl,
    deviceId: ref.watch(deviceIdServiceProvider),
  );
});

// FIX: was Provider<core_auth.AuthService> / core_auth.AuthService(...)
// The class in core/services/auth_service.dart is BackendAuthService, not AuthService.
final coreAuthServiceProvider = Provider<core_auth.BackendAuthService>((ref) {
  return core_auth.BackendAuthService(
    deviceId: ref.watch(deviceIdServiceProvider),
    tokenStore: ref.watch(authTokenStoreProvider),
    api: ref.watch(authApiClientProvider),
  );
});

final authHttpClientProvider = Provider<AuthHttpClient>((ref) {
  return AuthHttpClient(
    ref.watch(coreAuthServiceProvider),
    ref.watch(authTokenStoreProvider),
    autoRefresh: true,
    onTokenRefreshed: () {
      LogManager.debug('[Auth] ✅ Token auto-refreshed');
    },
    onRefreshFailed: (error) {
      LogManager.debug('[Auth] ❌ Refresh failed: $error');
    },
  );
});

final httpClientProvider = Provider<HttpClient>((ref) {
  return HttpClient(
    authClient: ref.watch(authHttpClientProvider),
    baseUrl: EnvConfig.apiBaseUrl,
  );
});

final tycoonApiClientProvider = Provider<TycoonApiClient>((ref) {
  return TycoonApiClient(
    httpClient: ref.watch(httpClientProvider),
  );
});

final wsClientProvider = Provider<WsClient>((ref) {
  return WsClient(
    url: EnvConfig.apiWsBaseUrl,
    onMessage: (message) {
      LogManager.debug('[WS] Message: ${message.op}');
    },
    onStateChange: (state) {
      LogManager.debug('[WS] State: $state');
    },
    onError: (error) {
      LogManager.debug('[WS] Error: $error');
    },
  );
});

final loginManagerProvider = Provider<LoginManager>((ref) {
  final serviceManager = ref.read(serviceManagerProvider);
  return LoginManager(
    authService: ref.watch(coreAuthServiceProvider),
    tokenStore: ref.watch(authTokenStoreProvider),
    deviceIdService: ref.watch(deviceIdServiceProvider),
    profileService: serviceManager.playerProfileService,
    onboardingService: serviceManager.onboardingSettingsService,
    secureStorage: ref.watch(secureStorageProvider),
  );
});