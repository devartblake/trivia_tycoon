# Quick Reference: File Locations & Changes

## Files to Update

### ✅ LoginManager_refactored.dart
**Replace:** `lib/core/manager/login_manager.dart`

**Key Changes:**
- Added `coreAuthService` and `tokenStore` dependencies
- Added `deviceIdService` dependency
- Updated `login()` to properly store tokens via core AuthService
- Updated `signup()` to call backend `/auth/signup` endpoint
- Updated `logout()` to clear tokens from Hive
- Updated `isLoggedIn()` to check token storage

---

### ✅ auth_service_updated.dart
**Update:** `lib/core/services/auth_service.dart`

**Key Changes:**
- Added `signup()` method that calls `/auth/signup` endpoint
- Returns `AuthSession` with both tokens stored

**What to Add:**
```dart
Future<AuthSession> signup({
  required String email,
  required String password,
  String? username,
  String? country,
}) async {
  final deviceId = await _deviceId.getOrCreate();
  final session = await _api.signup(
    email: email,
    password: password,
    deviceId: deviceId,
    username: username,
    country: country,
  );
  await _store.save(session);
  return session;
}
```

---

### ✅ auth_api_client_updated.dart
**Update:** `lib/core/services/auth_api_client.dart`

**Key Changes:**
- Added `signupPath = '/auth/signup'` constant
- Added `signup()` method that makes HTTP POST to `/auth/signup`
- Parses `expiresIn` (seconds) from backend response
- Better error handling for 409 conflicts

**What to Add:**
```dart
static const String signupPath = '/auth/signup';

Future<AuthSession> signup({
  required String email,
  required String password,
  required String deviceId,
  String? username,
  String? country,
}) async {
  final res = await _http.post(
    _u(signupPath),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
      'deviceId': deviceId,
      if (username != null) 'username': username,
      if (country != null) 'country': country,
    }),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    try {
      final errorJson = jsonDecode(res.body) as Map<String, dynamic>;
      final errorMsg = errorJson['error'] ?? errorJson['message'] ?? res.body;
      throw Exception('Signup failed: $errorMsg');
    } catch (_) {
      throw Exception('Signup failed: ${res.statusCode} ${res.body}');
    }
  }

  final json = jsonDecode(res.body) as Map<String, dynamic>;
  return _parseSession(json);
}
```

---

### ✅ device_id_service.dart
**Create:** `lib/core/services/device_id_service.dart`

**If this file doesn't exist, create it from the provided template.**

**Also add to pubspec.yaml:**
```yaml
dependencies:
  uuid: ^4.0.0
```

---

## Dependency Injection Setup

Find where you create/register your services (likely in `main.dart` or a service locator).

**Add these registrations:**

```dart
// 1. Device ID service
final deviceIdService = DeviceIdService(secureStorage);

// 2. Auth API client (if not already registered)
final authApiClient = AuthApiClient(
  http.Client(),
  apiBaseUrl: 'http://your-backend-url:5000', // Update this!
);

// 3. Auth token store (should already exist, but verify)
final authTokenStore = AuthTokenStore(yourHiveBox);

// 4. Core auth service
final coreAuthService = AuthService(
  deviceId: deviceIdService,
  tokenStore: authTokenStore,
  api: authApiClient,
);

// 5. Update LoginManager constructor
final loginManager = LoginManager(
  coreAuthService: coreAuthService,  // NEW
  uiAuthService: uiAuthService,      // Existing
  tokenStore: authTokenStore,        // NEW
  deviceIdService: deviceIdService,  // NEW
  onboardingService: onboardingService,
  secureStorage: secureStorage,
  profileService: profileService,
);
```

---

## Import Aliases (Fix Name Conflicts)

In `login_manager.dart`, use these import aliases to distinguish between the two `AuthService` classes:

```dart
// Core auth service (handles backend tokens)
import 'package:trivia_tycoon/core/services/auth_service.dart' as core_auth;

// UI auth service (handles UI state)
import 'package:trivia_tycoon/ui_components/login/providers/auth.dart' as ui_auth;
```

Then use:
- `core_auth.AuthService` for the token management service
- `ui_auth.AuthService` for the UI state service

---

## Quick Test

After updating all files:

```dart
// 1. Try signup
final data = SignupData(
  name: 'newuser@test.com',
  password: 'SecurePass123',
  additionalSignupData: {'Username': 'NewUser'},
);
await loginManager.signup(data);

// 2. Check tokens are stored
final session = authTokenStore.load();
print('Logged in: ${session.hasTokens}');
print('Access token: ${session.accessToken.substring(0, 20)}...');
print('Refresh token: ${session.refreshToken.substring(0, 20)}...');

// 3. Restart app - tokens should persist
// 4. Try logout
await loginManager.logout(context);
final afterLogout = authTokenStore.load();
print('Still logged in: ${afterLogout.hasTokens}'); // Should be false
```

---

## File Tree (After Changes)

```
lib/
├── core/
│   ├── manager/
│   │   └── login_manager.dart ← REPLACE
│   └── services/
│       ├── auth_service.dart ← UPDATE (add signup method)
│       ├── auth_api_client.dart ← UPDATE (add signup method)
│       ├── auth_token_store.dart ← No changes
│       └── device_id_service.dart ← CREATE (if doesn't exist)
└── ui_components/
    └── login/
        └── providers/
            └── auth.dart ← No changes
```

---

## Checklist

- [ ] Replace `login_manager.dart` with refactored version
- [ ] Add `signup()` method to `auth_service.dart`
- [ ] Add `signup()` method to `auth_api_client.dart`
- [ ] Create `device_id_service.dart` (if doesn't exist)
- [ ] Add `uuid: ^4.0.0` to `pubspec.yaml`
- [ ] Update DI setup (service locator or provider)
- [ ] Add import aliases to avoid name conflicts
- [ ] Run `flutter pub get`
- [ ] Test signup flow
- [ ] Test login flow
- [ ] Test logout flow
- [ ] Test app restart (tokens should persist)

---

## Need Help?

See `FLUTTER_INTEGRATION_GUIDE.md` for:
- Detailed explanation of each change
- Common issues & solutions
- Complete testing instructions
- API response format reference
