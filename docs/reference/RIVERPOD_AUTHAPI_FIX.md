# Updated Riverpod Provider for AuthApiClient

## The Issue

`AuthApiClient` now requires `DeviceIdService` in its constructor, but the Riverpod provider wasn't updated.

---

## ❌ OLD Provider (Broken)

```dart
/// Provides the AuthApiClient
final authApiClientProvider = Provider<AuthApiClient>((ref) {
  return AuthApiClient(
    http.Client(),
    apiBaseUrl: EnvConfig.apiBaseUrl,
  );
});
```

**Problem:** Missing `deviceId` parameter

---

## ✅ NEW Provider (Fixed)

```dart
/// Provides the AuthApiClient
final authApiClientProvider = Provider<AuthApiClient>((ref) {
  return AuthApiClient(
    http.Client(),
    apiBaseUrl: EnvConfig.apiBaseUrl,
    deviceId: ref.watch(deviceIdServiceProvider), // ← ADDED
  );
});
```

---

## Complete Updated Section in riverpod_providers.dart

Replace the auth providers section (around lines 130-180) with:

```dart
// --- 🔐 Core Auth Providers ---

/// Provides the Hive box for auth tokens
final authTokenBoxProvider = Provider<Box>((ref) {
  if (!Hive.isBoxOpen('auth_tokens')) {
    throw StateError('auth_tokens box must be opened in app_init.dart before creating providers');
  }
  return Hive.box('auth_tokens');
});

/// Provides the AuthTokenStore
final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
  final box = ref.watch(authTokenBoxProvider);
  return AuthTokenStore(box);
});

/// Provides SecureStorage
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

/// Provides the DeviceIdService
final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DeviceIdService(secureStorage);
});

/// Provides the AuthApiClient (UPDATED with deviceId)
final authApiClientProvider = Provider<AuthApiClient>((ref) {
  return AuthApiClient(
    http.Client(),
    apiBaseUrl: EnvConfig.apiBaseUrl,
    deviceId: ref.watch(deviceIdServiceProvider), // ← ADDED
  );
});

/// Provides the core AuthService (backend token management)
final coreAuthServiceProvider = Provider<core_auth.AuthService>((ref) {
  return core_auth.AuthService(
    deviceId: ref.watch(deviceIdServiceProvider),
    tokenStore: ref.watch(authTokenStoreProvider),
    api: ref.watch(authApiClientProvider),
  );
});

/// Provides the LoginManager with all required dependencies
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

## What Changed

| Provider | Before | After |
|----------|--------|-------|
| `authApiClientProvider` | Missing `deviceId` param | Added `deviceId: ref.watch(deviceIdServiceProvider)` |

---

## Why This Matters

`AuthApiClient` needs `DeviceIdService` to:
1. Get device ID for login/signup requests
2. Include device ID in all backend calls
3. Support per-device refresh tokens
4. Enable "logout this device" vs "logout all devices"

---

## Files to Update

1. **auth_api_client.dart** → Use `auth_api_client_CORRECTED.dart`
2. **riverpod_providers.dart** → Update `authApiClientProvider` as shown above

---

## Quick Fix

In your `riverpod_providers.dart`, find this line:

```dart
final authApiClientProvider = Provider<AuthApiClient>((ref) {
  return AuthApiClient(
    http.Client(),
    apiBaseUrl: EnvConfig.apiBaseUrl,
  );
});
```

Change to:

```dart
final authApiClientProvider = Provider<AuthApiClient>((ref) {
  return AuthApiClient(
    http.Client(),
    apiBaseUrl: EnvConfig.apiBaseUrl,
    deviceId: ref.watch(deviceIdServiceProvider),
  );
});
```

Done! ✅
