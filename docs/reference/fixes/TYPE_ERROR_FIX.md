# Type Casting Error Fix

## The Error

```
type 'BoxImpl<dynamic>' is not a subtype of type 'SecureStorage' in type cast
```

## Root Cause

In your `app_init.dart` line 51, you had:

```dart
final deviceIdService = DeviceIdService(settingsBox as SecureStorage);
```

**This is wrong because:**
- `settingsBox` is a `Box<dynamic>` from Hive (a database container)
- `SecureStorage` is a custom class that wraps Hive operations
- You can't cast one to the other - they're completely different types

---

## The Fix

### ❌ OLD (Line 51-52)
```dart
final deviceIdService = DeviceIdService(settingsBox as SecureStorage); // WRONG!
final tokenStore = AuthTokenStore(settingsBox);
```

### ✅ NEW (Lines 48-59)
```dart
// Open dedicated box for auth tokens
final authTokenBox = await Hive.openBox('auth_tokens');

// Create SecureStorage instance (don't cast!)
final secureStorage = SecureStorage();

// DeviceIdService needs SecureStorage, not a Box
final deviceIdService = DeviceIdService(secureStorage);
final deviceId = await deviceIdService.getOrCreate();

// AuthTokenStore needs a Hive Box
final tokenStore = AuthTokenStore(authTokenBox);
```

---

## Understanding the Types

### Box (from Hive)
```dart
final box = await Hive.openBox('some_name');
// box is Box<dynamic> - a key-value storage container
```

### SecureStorage (your custom class)
```dart
class SecureStorage {
  Future<void> setSecret(String key, String value) async {
    final box = await Hive.openBox('secrets');
    await box.put(key, value);
  }
  // ... opens boxes internally
}
```

**Key difference:** `Box` is a storage container. `SecureStorage` is a service that uses boxes.

---

## What Each Service Needs

| Service | Needs | Why |
|---------|-------|-----|
| `DeviceIdService` | `SecureStorage` | Uses `setSecret()/getSecret()` methods |
| `AuthTokenStore` | `Box` | Directly manages keys in a box |
| `AuthService` | Both services above | Uses them to manage auth |

---

## Complete Fixed Code

Replace your `app_init.dart` with `app_init_fixed.dart`.

**Key changes:**
1. **Line 48:** Open dedicated `auth_tokens` box
2. **Line 53:** Create `SecureStorage()` instance (no casting)
3. **Line 56:** Pass `secureStorage` to `DeviceIdService`
4. **Line 61:** Pass `authTokenBox` to `AuthTokenStore`

---

## Additional Issue: Two AuthService Classes

Your app has TWO different `AuthService` classes:

### 1. UI AuthService (Old)
**Location:** `lib/ui_components/login/providers/auth.dart`
**Purpose:** UI state management (login mode, email input, etc.)
**Used in:** `ServiceManager` (line 215)

### 2. Core AuthService (New)
**Location:** `lib/core/services/auth_service.dart`
**Purpose:** Backend token management (login, signup, refresh, logout)
**Used in:** `app_init.dart` (line 67)

**This causes confusion!** You need to use BOTH, but for different purposes.

---

## Recommended Structure

### app_init.dart (Critical Init)
```dart
// Create CORE AuthService for backend tokens
final authService = AuthService(
  deviceId: deviceIdService,
  tokenStore: tokenStore,
  api: authApi,
);
```

### ServiceManager.initialize() (Line 215)
```dart
// Create UI AuthService for UI state
final uiAuth = AuthService(
  secureStorage: secureStorage,
  generalKey: generalKey,
  playerProfileService: playerProfile,
);
```

### LoginManager
```dart
// Use CORE AuthService for backend
final loginManager = LoginManager(
  authService: coreAuthService,  // ← From app_init
  tokenStore: tokenStore,
  deviceIdService: deviceIdService,
  // ... other services
);
```

---

## Import Aliases to Avoid Confusion

In files that use both AuthService classes:

```dart
// Core auth (backend tokens)
import 'package:trivia_tycoon/core/services/auth_service.dart' as core_auth;

// UI auth (state management)
import 'package:trivia_tycoon/ui_components/login/providers/auth.dart' as ui_auth;

// Then use:
final coreAuth = core_auth.AuthService(...);
final uiAuth = ui_auth.AuthService(...);
```

---

## Testing After Fix

1. **Replace `app_init.dart`** with the fixed version
2. **Hot restart** (not hot reload)
3. **Check console** - should see:
   ```
   ✅ DeviceId ready: some-uuid-here
   [AppInit] Critical initialization complete
   ```
4. **Try signup** - tokens should be saved in Hive

---

## Common Follow-Up Errors

### Error: "signup() is not defined"
**Fix:** Add `signup()` method to `core/services/auth_service.dart` (see `auth_service_updated.dart`)

### Error: "No such method: ensureDeviceId"
**Fix:** This method should exist in `core/services/auth_service.dart`:
```dart
Future<String> ensureDeviceId() => _deviceId.getOrCreate();
```

### Error: "isLoggedIn is not a Future"
**Fix:** In `ServiceManager`, change line 215 to keep UI AuthService but add core AuthService separately

---

## Quick Verification

After applying the fix, run this in your app:

```dart
// In a debug screen or test
final deviceId = await deviceIdService.getOrCreate();
print('Device ID: $deviceId');

final session = tokenStore.load();
print('Has tokens: ${session.hasTokens}');
print('Access token: ${session.accessToken.isEmpty ? "empty" : "present"}');
```

Should print:
```
Device ID: some-uuid-here
Has tokens: false (or true if logged in)
Access token: empty (or present if logged in)
```

---

## Summary

✅ **Fixed:** `SecureStorage` is now created properly (not cast from Box)  
✅ **Fixed:** `DeviceIdService` gets `SecureStorage` instance  
✅ **Fixed:** `AuthTokenStore` gets dedicated `auth_tokens` box  
⚠️ **Still needed:** Distinguish between UI AuthService and Core AuthService  

Use the fixed `app_init.dart` file and you should be good to go!
