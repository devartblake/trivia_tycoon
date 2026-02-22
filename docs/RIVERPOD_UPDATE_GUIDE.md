# Riverpod Providers Update for New LoginManager

## What Changed

Your `loginManagerProvider` (lines 130-139) had the wrong dependencies for the new `LoginManager` constructor.

---

## The Problem

### ❌ OLD Provider (Broken)
```dart
final loginManagerProvider = Provider<LoginManager>((ref) {
  final serviceManager = ref.read(serviceManagerProvider);
  return LoginManager(
    authService: serviceManager.authService,  // ← Wrong: UI AuthService
    apiService: serviceManager.apiService,    // ← Removed from LoginManager
    profileService: serviceManager.playerProfileService,
    onboardingService: serviceManager.onboardingSettingsService,
    secureStorage: serviceManager.secureStorage,
  );
});
```

**Issues:**
1. `authService` from ServiceManager is the **UI AuthService** (from `ui_components/login/providers/auth.dart`), not the **Core AuthService** (from `core/services/auth_service.dart`)
2. `apiService` is no longer used by LoginManager
3. Missing `tokenStore` (for Hive token storage)
4. Missing `deviceIdService` (for device identification)

---

## The Solution

### ✅ NEW Providers (Fixed)

**Step 1: Add Core Auth Service Providers**

```dart
// NEW imports at the top
import '../../core/services/auth_service.dart' as core_auth;
import '../../core/services/auth_api_client.dart';
import '../../core/services/auth_token_store.dart';
import '../../core/services/device_id_service.dart';
import '../../core/env.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
```

**Step 2: Create Auth Infrastructure Providers**

```dart
/// Provides the Hive box for auth tokens
final authTokenBoxProvider = Provider<Box>((ref) {
  if (!Hive.isBoxOpen('auth_tokens')) {
    throw StateError('auth_tokens box must be opened in app_init.dart');
  }
  return Hive.box('auth_tokens');
});

/// Provides the AuthTokenStore
final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
  final box = ref.watch(authTokenBoxProvider);
  return AuthTokenStore(box);
});

/// Provides the DeviceIdService
final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DeviceIdService(secureStorage);
});

/// Provides the AuthApiClient
final authApiClientProvider = Provider<AuthApiClient>((ref) {
  return AuthApiClient(
    http.Client(),
    apiBaseUrl: EnvConfig.apiBaseUrl,
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

/// Provides SecureStorage
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});
```

**Step 3: Update LoginManager Provider**

```dart
final loginManagerProvider = Provider<LoginManager>((ref) {
  final serviceManager = ref.read(serviceManagerProvider);
  
  return LoginManager(
    authService: ref.watch(coreAuthServiceProvider),      // ← Core auth
    tokenStore: ref.watch(authTokenStoreProvider),        // ← NEW
    deviceIdService: ref.watch(deviceIdServiceProvider),  // ← NEW
    profileService: serviceManager.playerProfileService,
    onboardingService: serviceManager.onboardingSettingsService,
    secureStorage: ref.watch(secureStorageProvider),      // ← Provider
  );
});
```

---

## What Each Provider Does

| Provider | Purpose | Used By |
|----------|---------|---------|
| `authTokenBoxProvider` | Provides Hive box for tokens | `authTokenStoreProvider` |
| `authTokenStoreProvider` | Manages token storage (Hive) | `coreAuthServiceProvider`, `loginManagerProvider` |
| `deviceIdServiceProvider` | Generates/retrieves device ID | `coreAuthServiceProvider`, `loginManagerProvider` |
| `authApiClientProvider` | HTTP client for auth endpoints | `coreAuthServiceProvider` |
| `coreAuthServiceProvider` | Core backend authentication | `loginManagerProvider` |
| `secureStorageProvider` | Secure key-value storage | `deviceIdServiceProvider`, `loginManagerProvider` |

---

## Dependencies Flow

```
LoginManager
├─ coreAuthServiceProvider
│  ├─ deviceIdServiceProvider
│  │  └─ secureStorageProvider
│  ├─ authTokenStoreProvider
│  │  └─ authTokenBoxProvider
│  └─ authApiClientProvider
├─ tokenStore (from authTokenStoreProvider)
├─ deviceIdService (from deviceIdServiceProvider)
├─ profileService (from serviceManagerProvider)
├─ onboardingService (from serviceManagerProvider)
└─ secureStorage (from secureStorageProvider)
```

---

## Important: Two AuthService Classes

Your app now uses **TWO different AuthService classes**:

### 1. UI AuthService (Old)
**Location:** `lib/ui_components/login/providers/auth.dart`  
**Provider:** `authServiceProvider`  
**Purpose:** UI state management (login mode, email input)  
**Used by:** ServiceManager, UI components

### 2. Core AuthService (New)
**Location:** `lib/core/services/auth_service.dart`  
**Provider:** `coreAuthServiceProvider`  
**Purpose:** Backend token management (login, signup, refresh, logout)  
**Used by:** LoginManager

**Import alias in riverpod_providers.dart:**
```dart
import '../../core/services/auth_service.dart' as core_auth;
```

This prevents name collision!

---

## Files to Update

### 1. riverpod_providers.dart
**Replace lines 1-205** with the new provider setup from `riverpod_providers_UPDATED.dart`

**Keep lines 206-934** unchanged (all other providers)

---

## Testing After Update

```dart
// In a test or debug screen
void testAuthProviders(WidgetRef ref) {
  // Test device ID
  final deviceId = ref.read(deviceIdServiceProvider);
  print('Device ID service: ${deviceId.runtimeType}');
  
  // Test token store
  final tokenStore = ref.read(authTokenStoreProvider);
  final session = tokenStore.load();
  print('Has tokens: ${session.hasTokens}');
  
  // Test core auth service
  final authService = ref.read(coreAuthServiceProvider);
  print('Core auth service: ${authService.runtimeType}');
  
  // Test login manager
  final loginManager = ref.read(loginManagerProvider);
  print('Login manager: ${loginManager.runtimeType}');
}
```

---

## Common Errors After Update

### Error 1: "auth_tokens box must be opened"
**Cause:** Hive box not opened in `app_init.dart` before creating providers

**Fix:** In `app_init.dart`, ensure this line exists:
```dart
final authTokenBox = await Hive.openBox('auth_tokens');
```

### Error 2: "StateError: No box named 'auth_tokens'"
**Cause:** Same as above

**Fix:** Open the box before creating ProviderScope

### Error 3: "The method 'signup' isn't defined"
**Cause:** `auth_service.dart` missing the `signup()` method

**Fix:** Add signup method from `auth_service_updated.dart`

### Error 4: "Import name collision: AuthService"
**Cause:** Two AuthService classes with same name

**Fix:** Already handled with import alias `as core_auth`

---

## Integration with app_init.dart

Your `app_init.dart` already creates the auth services:

```dart
// In app_init.dart lines 48-67
final authTokenBox = await Hive.openBox('auth_tokens');
final secureStorage = SecureStorage();
final deviceIdService = DeviceIdService(secureStorage);
final tokenStore = AuthTokenStore(authTokenBox);
final authApi = AuthApiClient(httpClient, apiBaseUrl: EnvConfig.apiBaseUrl);
final authService = AuthService(...);
```

**These are used for critical initialization.** The Riverpod providers **recreate them** for dependency injection throughout the app. This is intentional - the providers need to be lazy-loaded.

---

## Summary of Changes

| Line | Old | New | Why |
|------|-----|-----|-----|
| 1-100 | Missing core auth imports | Added 5 new imports | Need core auth classes |
| 130-139 | Old loginManagerProvider | Updated with new deps | Match new LoginManager constructor |
| NEW | N/A | 6 new auth providers | Provide auth infrastructure |

---

## Next Steps

1. ✅ Replace lines 1-205 in `riverpod_providers.dart` with updated version
2. ✅ Keep lines 206-934 unchanged
3. ✅ Hot restart (not hot reload)
4. ✅ Test login/signup/logout

The updated providers will now work with your corrected `LoginManager`!
