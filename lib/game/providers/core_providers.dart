/// Infrastructure providers — networking, auth chain, storage.
///
/// Everything else in the providers layer depends on this file.
/// Do NOT import other provider files here.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:synaptix/core/manager/log_manager.dart';

import '../../core/bootstrap/app_init.dart';
import '../../core/env.dart';
import '../../core/manager/login_manager.dart';
import '../../core/manager/service_manager.dart';
import '../../core/navigation/app_router.dart';
import '../../core/networking/http_client.dart';
import '../../core/networking/synaptix_api_client.dart';
import '../../core/networking/encrypted_api_client.dart';
import '../../core/networking/ws_client.dart';
import '../../core/networking/ws_protocol.dart';
import '../../core/services/analytics/config_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_api_client.dart';
import '../../core/services/auth_http_client.dart';
import '../../core/networking/synaptix_api_client_enhanced.dart';
import '../../core/services/auth_token_store.dart';
import '../../core/services/auth_service.dart' as core_auth;
import '../../core/services/device_id_service.dart';
import '../../core/services/audio/audio_asset_service.dart';
import '../../core/services/settings/general_key_value_storage_service.dart';
import '../../core/services/storage/app_cache_service.dart';
import '../../core/services/storage/secure_storage.dart';
import '../../core/security/secure_session_store.dart';

// ---------------------------------------------------------------------------
// Global infrastructure
// ---------------------------------------------------------------------------

final configServiceProvider =
    Provider<ConfigService>((ref) => ConfigService.instance);

/// Must be overridden in ProviderScope after [AppInit] completes.
///
/// The throw below is intentional — it is a design-time safety net that fires
/// only if the provider is accessed before the override is installed in the
/// root ProviderScope. The app launcher installs the override at startup, so
/// this throw is never reached in production.
final serviceManagerProvider = Provider<ServiceManager>((ref) {
  throw UnimplementedError(
    'serviceManagerProvider must be overridden in ProviderScope in AppLauncher',
  );
});

final routerProvider = FutureProvider<GoRouter>((ref) async {
  return await AppRouter.router();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ref.watch(serviceManagerProvider).apiService;
});

final globalWsClientProvider = Provider<WsClient?>((ref) {
  return AppInit.wsClient;
});

final wsConnectionStatusProvider = StateProvider<bool>((ref) {
  return AppInit.isWebSocketConnected;
});

final wsMessageStreamProvider = StreamProvider<WsEnvelope>((ref) {
  final client = ref.watch(globalWsClientProvider);
  return client?.messageStream ?? const Stream.empty();
});

final wsStateStreamProvider = StreamProvider<WsState>((ref) {
  final client = ref.watch(globalWsClientProvider);
  return client?.stateStream ?? const Stream.empty();
});

final encryptedApiClientProvider = Provider<EncryptedApiClient>((ref) {
  return ref.watch(serviceManagerProvider).encryptedApiClient;
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
  final initializedStore = AppInit.tokenStore;
  if (initializedStore != null) {
    return initializedStore;
  }
  final box = ref.watch(authTokenBoxProvider);
  return AuthTokenStore(box);
});

final secureSessionStoreProvider = Provider<SecureSessionStore>((ref) {
  return ref.watch(serviceManagerProvider).secureSessionStore;
});

final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DeviceIdService(secureStorage);
});

final authApiClientProvider = Provider<AuthApiClient>((ref) {
  return AuthApiClient(
    http.Client(),
    apiBaseUrl: EnvConfig.apiV1BaseUrl,
    deviceId: ref.watch(deviceIdServiceProvider),
    secureSessionStore: ref.watch(secureSessionStoreProvider),
  );
});

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
    baseUrl: EnvConfig.apiV1BaseUrl,
  );
});

final synaptixApiClientProvider = Provider<SynaptixApiClient>((ref) {
  return SynaptixApiClient(
    httpClient: ref.watch(httpClientProvider),
    healthCheckUrl: EnvConfig.apiHealthUrl,
  );
});

final wsClientProvider = Provider<WsClient>((ref) {
  final settingsBox = Hive.isBoxOpen('settings') ? Hive.box('settings') : null;
  final playerId = settingsBox?.get('userId')?.toString();
  final baseWsUri = Uri.parse(EnvConfig.apiWsBaseUrl);
  final resolvedWsUrl = (playerId != null && playerId.isNotEmpty)
      ? baseWsUri.replace(
          queryParameters: {
            ...baseWsUri.queryParameters,
            'playerId': playerId,
          },
        ).toString()
      : EnvConfig.apiWsBaseUrl;

  return WsClient(
    url: resolvedWsUrl,
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

final audioAssetServiceProvider = Provider<AudioAssetService>((ref) {
  return AudioAssetService(ref.watch(synaptixApiClientProvider));
});

/// Unified REST + WebSocket client.
/// Connect the WebSocket after login: `ref.read(synaptixApiClientEnhancedProvider).connectWs()`.
final synaptixApiClientEnhancedProvider =
    Provider<SynaptixApiClientEnhanced>((ref) {
  return SynaptixApiClientEnhanced(
    api: ref.watch(apiServiceProvider),
    ws: ref.watch(wsClientProvider),
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
