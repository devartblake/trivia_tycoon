# Dependency Injection Changes

## What Changed in LoginManager

### ❌ Old Dependencies (REMOVED)
```dart
final ApiService apiService;  // REMOVED - AuthService replaces this
```

### ✅ New Dependencies (ADDED)
```dart
final AuthService authService;        // Already exists, but now used properly
final AuthTokenStore tokenStore;      // NEW - for token persistence
final DeviceIdService deviceIdService; // NEW - for device identification
```

---

## How to Update Your DI Setup

Find where you create/register `LoginManager` (likely in `main.dart`, a service locator, or provider setup).

### Before (Your Current Code):
```dart
final loginManager = LoginManager(
  authService: authService,
  apiService: apiService,  // ← Using this
  onboardingService: onboardingService,
  secureStorage: secureStorage,
  profileService: profileService,
);
```

### After (Updated Code):
```dart
// 1. Create DeviceIdService (if not already registered)
final deviceIdService = DeviceIdService(secureStorage);

// 2. Create AuthApiClient (if not already registered)
final authApiClient = AuthApiClient(
  http.Client(),
  apiBaseUrl: 'http://YOUR_BACKEND_URL:5000', // ← UPDATE THIS
);

// 3. Get Hive box for auth tokens
final authBox = await Hive.openBox('auth_tokens');
final authTokenStore = AuthTokenStore(authBox);

// 4. Create AuthService (core, for backend)
final authService = AuthService(
  deviceId: deviceIdService,
  tokenStore: authTokenStore,
  api: authApiClient,
);

// 5. Create LoginManager with new dependencies
final loginManager = LoginManager(
  authService: authService,         // Already exists
  tokenStore: authTokenStore,       // NEW
  deviceIdService: deviceIdService, // NEW
  onboardingService: onboardingService,
  secureStorage: secureStorage,
  profileService: profileService,
);
```

---

## Complete Setup Example (main.dart)

```dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_tycoon/core/services/auth_service.dart';
import 'package:trivia_tycoon/core/services/auth_api_client.dart';
import 'package:trivia_tycoon/core/services/auth_token_store.dart';
import 'package:trivia_tycoon/core/services/device_id_service.dart';
import 'package:trivia_tycoon/core/manager/login_manager.dart';
// ... other imports

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Open auth tokens box
  final authBox = await Hive.openBox('auth_tokens');
  
  // Create services
  final secureStorage = SecureStorage();
  final deviceIdService = DeviceIdService(secureStorage);
  final authTokenStore = AuthTokenStore(authBox);
  
  final authApiClient = AuthApiClient(
    http.Client(),
    apiBaseUrl: 'http://localhost:5000', // ← Update for production
  );
  
  final authService = AuthService(
    deviceId: deviceIdService,
    tokenStore: authTokenStore,
    api: authApiClient,
  );
  
  final onboardingService = OnboardingSettingsService(/* ... */);
  final profileService = PlayerProfileService(/* ... */);
  
  final loginManager = LoginManager(
    authService: authService,
    tokenStore: authTokenStore,
    deviceIdService: deviceIdService,
    onboardingService: onboardingService,
    secureStorage: secureStorage,
    profileService: profileService,
  );
  
  runApp(MyApp(loginManager: loginManager));
}
```

---

## If You're Using a Service Locator (GetIt)

```dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupServices() async {
  // Initialize Hive
  await Hive.initFlutter();
  final authBox = await Hive.openBox('auth_tokens');
  
  // Register singletons
  getIt.registerSingleton<SecureStorage>(SecureStorage());
  getIt.registerSingleton<DeviceIdService>(
    DeviceIdService(getIt<SecureStorage>()),
  );
  getIt.registerSingleton<AuthTokenStore>(
    AuthTokenStore(authBox),
  );
  getIt.registerSingleton<AuthApiClient>(
    AuthApiClient(
      http.Client(),
      apiBaseUrl: 'http://localhost:5000',
    ),
  );
  getIt.registerSingleton<AuthService>(
    AuthService(
      deviceId: getIt<DeviceIdService>(),
      tokenStore: getIt<AuthTokenStore>(),
      api: getIt<AuthApiClient>(),
    ),
  );
  
  // ... register other services
  
  getIt.registerSingleton<LoginManager>(
    LoginManager(
      authService: getIt<AuthService>(),
      tokenStore: getIt<AuthTokenStore>(),
      deviceIdService: getIt<DeviceIdService>(),
      onboardingService: getIt<OnboardingSettingsService>(),
      secureStorage: getIt<SecureStorage>(),
      profileService: getIt<PlayerProfileService>(),
    ),
  );
}
```

---

## If You're Using Riverpod

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Device ID service
final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  return DeviceIdService(ref.read(secureStorageProvider));
});

// Auth token store
final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
  // Note: You'll need to initialize Hive and get the box first
  final box = Hive.box('auth_tokens');
  return AuthTokenStore(box);
});

// Auth API client
final authApiClientProvider = Provider<AuthApiClient>((ref) {
  return AuthApiClient(
    http.Client(),
    apiBaseUrl: 'http://localhost:5000',
  );
});

// Core auth service
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    deviceId: ref.read(deviceIdServiceProvider),
    tokenStore: ref.read(authTokenStoreProvider),
    api: ref.read(authApiClientProvider),
  );
});

// Login manager
final loginManagerProvider = Provider<LoginManager>((ref) {
  return LoginManager(
    authService: ref.read(authServiceProvider),
    tokenStore: ref.read(authTokenStoreProvider),
    deviceIdService: ref.read(deviceIdServiceProvider),
    onboardingService: ref.read(onboardingServiceProvider),
    secureStorage: ref.read(secureStorageProvider),
    profileService: ref.read(profileServiceProvider),
  );
});
```

---

## Files You Need (If They Don't Exist)

### 1. device_id_service.dart
**Location:** `lib/core/services/device_id_service.dart`

See the provided `device_id_service.dart` file.

**Add to pubspec.yaml:**
```yaml
dependencies:
  uuid: ^4.0.0
```

### 2. auth_service.dart
**Location:** `lib/core/services/auth_service.dart`

Add the `signup()` method from `auth_service_updated.dart`.

### 3. auth_api_client.dart
**Location:** `lib/core/services/auth_api_client.dart`

Add the `signup()` method from `auth_api_client_updated.dart`.

### 4. auth_token_store.dart
**Location:** `lib/core/services/auth_token_store.dart`

You should already have this. If not, it's the one with:
```dart
class AuthTokenStore {
  final Box _box;
  AuthSession load() { ... }
  Future<void> save(AuthSession session) { ... }
  Future<void> clear() { ... }
}
```

---

## Environment Variables (Optional)

For production, don't hardcode the API URL. Use environment variables:

```dart
// config.dart
class Config {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );
}

// Then in your DI setup:
final authApiClient = AuthApiClient(
  http.Client(),
  apiBaseUrl: Config.apiBaseUrl,
);
```

Run with:
```bash
flutter run --dart-define=API_BASE_URL=https://your-production-api.com
```

---

## Verification Checklist

After updating your DI setup:

- [ ] `DeviceIdService` is registered
- [ ] `AuthTokenStore` is registered (with Hive box)
- [ ] `AuthApiClient` is registered (with correct API URL)
- [ ] `AuthService` is registered (with above 3 dependencies)
- [ ] `LoginManager` is registered (with `authService`, `tokenStore`, `deviceIdService`)
- [ ] `ApiService` dependency is REMOVED from `LoginManager`
- [ ] Add `uuid: ^4.0.0` to pubspec.yaml
- [ ] Run `flutter pub get`

---

## Quick Test

After updating:

```dart
// Get LoginManager from DI
final loginManager = getIt<LoginManager>(); // or ref.read(loginManagerProvider)

// Try signup
final data = SignupData(
  name: 'test@example.com',
  password: 'SecurePass123',
  additionalSignupData: {'Username': 'TestUser'},
);

try {
  await loginManager.signup(data);
  print('✅ Signup successful!');
  
  // Check tokens
  final session = loginManager.tokenStore.load();
  print('Has tokens: ${session.hasTokens}');
  print('Access token: ${session.accessToken.substring(0, 20)}...');
} catch (e) {
  print('❌ Signup failed: $e');
}
```

---

## Common Errors & Solutions

### Error: "DeviceIdService not found"
**Solution:** Add `DeviceIdService` to your DI container

### Error: "AuthTokenStore not found"
**Solution:** Open Hive box and create `AuthTokenStore(box)`

### Error: "signup() is not defined"
**Solution:** Add the `signup()` method to `auth_service.dart` and `auth_api_client.dart`

### Error: "Type 'AuthService' is not a subtype of..."
**Solution:** Make sure you're importing the correct `AuthService` (from `core/services`, not `ui_components`)

---

## Next Steps

1. Update your DI setup with the code above
2. Replace `login_manager.dart` with `LoginManager_FINAL.dart`
3. Add `signup()` methods to `auth_service.dart` and `auth_api_client.dart`
4. Create `device_id_service.dart` if it doesn't exist
5. Run `flutter pub get`
6. Test signup → login → logout → app restart

Once this works, you can move on to automatic token refresh!
