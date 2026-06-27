# Flutter Frontend Auth Integration Guide

## Overview

Your `LoginManager` currently has critical issues that prevent proper backend authentication:

### Current Problems:
1. ❌ Only stores a generic `'auth_token'` instead of separate `accessToken` + `refreshToken`
2. ❌ No device ID support (backend requires it)
3. ❌ Not using `AuthTokenStore` (Hive-based persistent storage)
4. ❌ No automatic token refresh logic
5. ❌ Mixing two different `AuthService` classes (UI vs Core)

### What We're Fixing:
- ✅ Proper token storage with `AuthTokenStore` (Hive)
- ✅ Device ID management with `DeviceIdService`
- ✅ Separate `accessToken` and `refreshToken`
- ✅ Backend `/auth/signup` endpoint support
- ✅ Clean separation of concerns

---

## Files to Update

### 1. **LoginManager.dart** (Replace Entire File)
**Location:** `lib/core/manager/login_manager.dart`

**Changes:**
- Added `AuthTokenStore` dependency
- Added `DeviceIdService` dependency
- Renamed `authService` → `coreAuthService` (core auth) and `uiAuthService` (UI auth)
- Updated `login()` to use core `AuthService`
- Updated `signup()` to call new backend `/auth/signup` endpoint
- Updated `logout()` to properly clear tokens
- Updated `isLoggedIn()` to check token storage

**Replace with:** `LoginManager_refactored.dart`

---

### 2. **auth_service.dart** (Add signup method)
**Location:** `lib/core/services/auth_service.dart`

**Changes:**
- Added `signup()` method that calls `/auth/signup` endpoint
- Method signature:
  ```dart
  Future<AuthSession> signup({
    required String email,
    required String password,
    String? username,
    String? country,
  })
  ```

**Update with:** `auth_service_updated.dart`

---

### 3. **auth_api_client.dart** (Add signup endpoint)
**Location:** `lib/core/services/auth_api_client.dart`

**Changes:**
- Added `signupPath = '/auth/signup'` constant
- Added `signup()` method that calls the endpoint
- Parses `expiresIn` (seconds) from backend response
- Better error handling for signup conflicts

**Update with:** `auth_api_client_updated.dart`

---

### 4. **device_id_service.dart** (Verify or Create)
**Location:** `lib/core/services/device_id_service.dart`

**If this file doesn't exist, create it:**

```dart
import 'package:uuid/uuid.dart';
import 'storage/secure_storage.dart';

/// Manages a persistent device identifier for auth operations
class DeviceIdService {
  static const _kDeviceId = 'device_id';
  final SecureStorage _storage;

  DeviceIdService(this._storage);

  /// Get existing device ID or create a new one
  Future<String> getOrCreate() async {
    var id = await _storage.getSecret(_kDeviceId);
    
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await _storage.setSecret(_kDeviceId, id);
    }
    
    return id;
  }

  /// Clear device ID (use for testing only)
  Future<void> clear() async {
    await _storage.removeSecret(_kDeviceId);
  }
}
```

**Add to pubspec.yaml:**
```yaml
dependencies:
  uuid: ^4.0.0
```

---

### 5. **Dependency Injection Setup**

Update wherever you're constructing `LoginManager` (likely in a provider or service locator).

**Before:**
```dart
LoginManager(
  authService: authService,
  apiService: apiService,
  onboardingService: onboardingService,
  secureStorage: secureStorage,
  profileService: profileService,
);
```

**After:**
```dart
// Ensure these are registered first:
final deviceIdService = DeviceIdService(secureStorage);
final authApiClient = AuthApiClient(
  http.Client(),
  apiBaseUrl: 'http://localhost:5000', // Your backend URL
);
final authTokenStore = AuthTokenStore(hiveBox); // Your Hive box
final coreAuthService = core_auth.AuthService(
  deviceId: deviceIdService,
  tokenStore: authTokenStore,
  api: authApiClient,
);

// Then create LoginManager:
final loginManager = LoginManager(
  coreAuthService: coreAuthService,
  uiAuthService: uiAuthService, // The one from ui_components/login/providers/auth.dart
  tokenStore: authTokenStore,
  deviceIdService: deviceIdService,
  onboardingService: onboardingService,
  secureStorage: secureStorage,
  profileService: profileService,
);
```

---

## Testing Checklist

### 1. Test Signup Flow

```dart
// In your signup screen or test
final signupData = SignupData(
  name: 'test@example.com',
  password: 'SecurePass123',
  additionalSignupData: {
    'Username': 'TestUser',
    'Country': 'US',
  },
);

await loginManager.signup(signupData);

// Verify tokens are stored
final session = authTokenStore.load();
assert(session.hasTokens);
print('Access Token: ${session.accessToken}');
print('Refresh Token: ${session.refreshToken}');
```

### 2. Test Login Flow

```dart
await loginManager.login('test@example.com', 'SecurePass123');

final session = authTokenStore.load();
assert(session.hasTokens);
```

### 3. Test Token Persistence

```dart
// After signup/login, restart the app
// Tokens should still be there
final session = authTokenStore.load();
print('Still logged in: ${session.hasTokens}');
```

### 4. Test Logout

```dart
await loginManager.logout(context);

final session = authTokenStore.load();
assert(!session.hasTokens);
```

---

## Common Issues & Solutions

### Issue 1: "No such method: 'signup'"
**Cause:** `AuthService` doesn't have the `signup()` method yet  
**Fix:** Update `auth_service.dart` with the new method

### Issue 2: "DeviceIdService not found"
**Cause:** File doesn't exist  
**Fix:** Create `device_id_service.dart` using the template above

### Issue 3: "Type mismatch: authService"
**Cause:** Two different `AuthService` classes with same name  
**Fix:** Use import aliases:
```dart
import 'package:trivia_tycoon/core/services/auth_service.dart' as core_auth;
import 'package:trivia_tycoon/ui_components/login/providers/auth.dart' as ui_auth;
```

### Issue 4: "Email already registered" but it's not
**Cause:** Backend database still has the test user  
**Fix:** Delete from database:
```sql
DELETE FROM users WHERE email = 'test@example.com';
```

### Issue 5: Tokens not persisting after app restart
**Cause:** Hive box not initialized or wrong box  
**Fix:** Ensure Hive is initialized in main():
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final box = await Hive.openBox('auth_tokens');
  // ... rest of init
}
```

---

## API Response Format (What Backend Returns)

### Signup Response (200 OK):
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "base64-random-token...",
  "expiresIn": 900,
  "userId": "guid-string",
  "user": {
    "id": "guid",
    "handle": "TestUser",
    "email": "test@example.com",
    "country": "US",
    "tier": "Bronze",
    "mmr": 1000
  }
}
```

### Login Response (200 OK):
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "base64-random-token...",
  "expiresIn": 900,
  "user": {
    "id": "guid",
    "handle": "TestUser",
    "email": "test@example.com",
    "country": "US",
    "tier": "Bronze",
    "mmr": 1000
  }
}
```

### Error Response (400/409):
```json
{
  "error": "email_already_exists",
  "message": "This email is already registered"
}
```

---

## What Happens Under the Hood

### Signup Flow:
1. User fills signup form → calls `loginManager.signup()`
2. `LoginManager` → calls `coreAuthService.signup()`
3. `AuthService` → gets device ID from `DeviceIdService`
4. `AuthService` → calls `AuthApiClient.signup()`
5. `AuthApiClient` → makes HTTP POST to `/auth/signup`
6. Backend → creates user + returns tokens
7. `AuthApiClient` → parses response into `AuthSession`
8. `AuthService` → saves `AuthSession` to `AuthTokenStore` (Hive)
9. `LoginManager` → updates UI state (logged in)

### Token Storage:
```
AuthTokenStore (Hive)
├─ auth_access_token → "eyJhbGciOi..."
├─ auth_refresh_token → "base64-random..."
├─ auth_expires_at_utc → 1708300800000 (ms)
└─ auth_user_id → "guid-string"
```

---

## Next Steps

### Phase 1: Basic Auth (This PR)
- ✅ Signup working
- ✅ Login working
- ✅ Tokens stored in Hive
- ✅ Device ID persisted

### Phase 2: Token Refresh (Next PR)
- Add automatic token refresh on 401
- Add token expiry checking before API calls
- Handle concurrent refresh requests

### Phase 3: Logout Everywhere (Future)
- Add "logout all devices" feature
- Show active sessions list
- Revoke specific refresh tokens

---

## File Summary

| File | Status | Action |
|------|--------|--------|
| `login_manager.dart` | 🔴 Broken | Replace entire file |
| `auth_service.dart` | 🟡 Incomplete | Add `signup()` method |
| `auth_api_client.dart` | 🟡 Incomplete | Add `signup()` method |
| `device_id_service.dart` | ❓ May not exist | Create if missing |
| `auth_token_store.dart` | ✅ Good | No changes needed |

---

## Testing Commands

After implementing, test the complete flow:

```bash
# 1. Start backend
cd backend
docker compose up

# 2. Run Flutter app
cd flutter
flutter run

# 3. Test signup
# - Fill form with new email
# - Submit
# - Should redirect to home screen

# 4. Verify tokens in Hive
# - Open Hive Inspector or check app data
# - Should see auth_access_token and auth_refresh_token

# 5. Test persistence
# - Force quit app
# - Reopen app
# - Should stay logged in (tokens still there)

# 6. Test logout
# - Tap logout button
# - Tokens should be cleared
# - Should redirect to login screen
```

---

## Questions?

If you hit any issues:
1. Check backend logs: `docker compose logs backend-api --tail=50`
2. Check Flutter console for API errors
3. Verify tokens in Hive storage
4. Test backend directly with Swagger UI

Let me know which issue you encounter!
