# Riverpod Providers: Visual Changes

## 1. New Imports (Add at top)

```diff
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
+ import 'package:hive/hive.dart';
+ import 'package:http/http.dart' as http;
  import 'package:trivia_tycoon/core/services/settings/admin_settings_service.dart';
  ...
  
+ // NEW: Core auth imports
+ import '../../core/services/auth_service.dart' as core_auth;
+ import '../../core/services/auth_api_client.dart';
+ import '../../core/services/auth_token_store.dart';
+ import '../../core/services/device_id_service.dart';
+ import '../../core/env.dart';
```

---

## 2. New Auth Providers (Add after apiServiceProvider)

```diff
  final apiServiceProvider = Provider<ApiService>((ref) {
    final config = ref.watch(configServiceProvider);
    return ApiService(baseUrl: config.apiBaseUrl);
  });

+ // --- 🔐 NEW: Core Auth Providers ---
+ 
+ final authTokenBoxProvider = Provider<Box>((ref) {
+   if (!Hive.isBoxOpen('auth_tokens')) {
+     throw StateError('auth_tokens box must be opened in app_init.dart');
+   }
+   return Hive.box('auth_tokens');
+ });
+ 
+ final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
+   final box = ref.watch(authTokenBoxProvider);
+   return AuthTokenStore(box);
+ });
+ 
+ final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
+   final secureStorage = ref.watch(secureStorageProvider);
+   return DeviceIdService(secureStorage);
+ });
+ 
+ final authApiClientProvider = Provider<AuthApiClient>((ref) {
+   return AuthApiClient(
+     http.Client(),
+     apiBaseUrl: EnvConfig.apiBaseUrl,
+   );
+ });
+ 
+ final coreAuthServiceProvider = Provider<core_auth.AuthService>((ref) {
+   return core_auth.AuthService(
+     deviceId: ref.watch(deviceIdServiceProvider),
+     tokenStore: ref.watch(authTokenStoreProvider),
+     api: ref.watch(authApiClientProvider),
+   );
+ });
+ 
+ final secureStorageProvider = Provider<SecureStorage>((ref) {
+   return SecureStorage();
+ });
```

---

## 3. Updated LoginManager Provider

```diff
  final loginManagerProvider = Provider<LoginManager>((ref) {
    final serviceManager = ref.read(serviceManagerProvider);
    return LoginManager(
-     authService: serviceManager.authService,
-     apiService: serviceManager.apiService,
+     authService: ref.watch(coreAuthServiceProvider),
+     tokenStore: ref.watch(authTokenStoreProvider),
+     deviceIdService: ref.watch(deviceIdServiceProvider),
      profileService: serviceManager.playerProfileService,
      onboardingService: serviceManager.onboardingSettingsService,
-     secureStorage: serviceManager.secureStorage,
+     secureStorage: ref.watch(secureStorageProvider),
    );
  });
```

---

## Quick Copy-Paste Guide

### Replace This Section (Lines ~130-139):

**❌ OLD:**
```dart
final loginManagerProvider = Provider<LoginManager>((ref) {
  final serviceManager = ref.read(serviceManagerProvider);
  return LoginManager(
    authService: serviceManager.authService,
    apiService: serviceManager.apiService,
    profileService: serviceManager.playerProfileService,
    onboardingService: serviceManager.onboardingSettingsService,
    secureStorage: serviceManager.secureStorage,
  );
});
```

**✅ NEW:**
```dart
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
```

---

## Complete File Structure

```
riverpod_providers.dart
├─ Imports (lines 1-105)
│  ├─ [existing imports]
│  └─ + NEW: core auth imports
├─ Global Services (lines 106-129)
│  ├─ configServiceProvider
│  ├─ serviceManagerProvider
│  ├─ routerProvider
│  └─ apiServiceProvider
├─ + NEW: Core Auth Providers (lines 130-180)
│  ├─ authTokenBoxProvider
│  ├─ authTokenStoreProvider
│  ├─ deviceIdServiceProvider
│  ├─ authApiClientProvider
│  ├─ coreAuthServiceProvider
│  └─ secureStorageProvider
├─ UPDATED: loginManagerProvider (lines 181-192)
└─ Rest of providers unchanged (lines 193-934)
```

---

## That's It!

Just **3 changes**:
1. Add new imports
2. Add 6 new auth providers
3. Update loginManagerProvider

Then hot restart and test!
