# Login System Analysis: Current State vs Required Changes

## 🔴 **Critical Finding: NOT Properly Wired for Backend**

Your login system has **THREE separate authentication flows** that are NOT integrated:

---

## Current Authentication Flows

### Flow 1: LoginScreen → AuthOperations (BROKEN)
**File:** `lib/screens/login_screen.dart` (lines 164-186)
**File:** `lib/game/providers/auth_providers.dart`

```dart
// LoginScreen calls:
final authOps = ref.read(authOperationsProvider);
await authOps.loginWithPassword(email, password);  // or signup()

// Which calls:
final response = await apiService.login(email: email, password: password);
await _persistAuthTokenIfPresent(response, secureStorage);  // Only saves 'auth_token'
```

**Problems:**
1. ❌ Uses `apiService.login()` which probably doesn't exist or isn't properly implemented
2. ❌ Only saves one generic `'auth_token'` - doesn't store `accessToken` + `refreshToken` separately
3. ❌ No device ID support
4. ❌ Doesn't use `AuthTokenStore` (Hive) for persistence
5. ❌ Doesn't use `LoginManager` at all

---

### Flow 2: UI Components (login_card.dart) → Callbacks (SEPARATE)
**File:** `lib/ui_components/login/cards/login_card.dart`

```dart
// UI component calls:
error = await auth.onLogin?.call(LoginData(...));
error = await auth.onSignup!(SignupData(...));
```

**This is just the UI layer** - it calls callbacks provided by parent widgets. These callbacks would also need to use `LoginManager`.

---

### Flow 3: LoginManager (CORRECT BUT UNUSED)
**File:** `lib/core/manager/login_manager.dart` (your updated version)

```dart
// Proper backend integration:
await loginManager.login(email, password);  // Uses core AuthService
await loginManager.signup(data);            // Uses core AuthService
```

**This is the correct implementation** but it's **NOT being called** anywhere!

---

## The Problem Chain

```
LoginScreen (UI)
    ↓
authOps.loginWithPassword()
    ↓
apiService.login()  ← WRONG! Should use LoginManager
    ↓
_persistAuthTokenIfPresent()  ← Only saves one token
    ↓
❌ Backend tokens NOT properly stored
```

**Should be:**

```
LoginScreen (UI)
    ↓
loginManager.login()
    ↓
authService.login()  ← Core auth service
    ↓
AuthTokenStore.save()  ← Saves both tokens in Hive
    ↓
✅ Backend properly connected
```

---

## Files That Need Updating

### 1. ❌ `auth_providers.dart` (CRITICAL)
**Location:** `lib/game/providers/auth_providers.dart`

**Current Issues:**
- Line 39: Uses `apiService.login()` instead of `loginManager.login()`
- Line 67: Uses `apiService.signup()` instead of `loginManager.signup()`
- Lines 101-108: `_persistAuthTokenIfPresent()` only saves one token

**Fix:** Replace with calls to `loginManager`

---

### 2. ❌ `login_screen.dart` (CRITICAL)
**Location:** `lib/screens/login_screen.dart`

**Current Issues:**
- Line 155-156: Gets `authOps` and uses it
- Line 166: Calls `authOps.loginWithPassword()` or `authOps.signup()`

**Fix:** Use `loginManager` instead of `authOps`

---

### 3. ✅ UI Components (OK - Callbacks Handle This)
**Location:** `lib/ui_components/login/`

The UI components are fine - they just call callbacks. The callbacks need to be wired to use `LoginManager`.

---

## Backend Connection Status

### ✅ **Ready for Backend:**
- `AuthService` (core) with proper token management
- `AuthApiClient` with `/auth/login`, `/auth/signup` endpoints
- `AuthTokenStore` with Hive persistence
- `DeviceIdService` for device identification
- `LoginManager` with proper integration

### ❌ **NOT Connected:**
- `LoginScreen` doesn't use `LoginManager`
- `authOperationsProvider` uses old `apiService` instead
- Tokens not stored properly (only generic `'auth_token'`)
- No device ID passed to backend

---

## Required Updates

### Priority 1: Update auth_providers.dart
Replace `AuthOperations` class to use `loginManager`:

```dart
class AuthOperations {
  final Ref ref;
  
  AuthOperations(this.ref);
  
  // Use LoginManager instead of ApiService
  Future<void> login(String email, String password) async {
    final loginManager = ref.read(loginManagerProvider);
    await loginManager.login(email, password);
    ref.read(isLoggedInSyncProvider.notifier).state = true;
  }
  
  Future<void> signup(String email, String password, {Map<String, dynamic>? extra}) async {
    final loginManager = ref.read(loginManagerProvider);
    
    final signupData = SignupData(
      name: email,
      password: password,
      additionalSignupData: extra,
    );
    
    await loginManager.signup(signupData);
    ref.read(isLoggedInSyncProvider.notifier).state = true;
  }
}
```

### Priority 2: Update login_screen.dart
Change from using `authOps` to `loginManager`:

```dart
// OLD:
final authOps = ref.read(authOperationsProvider);
await authOps.loginWithPassword(email, password);

// NEW:
final loginManager = ref.read(loginManagerProvider);
await loginManager.login(email, password);
```

---

## Backend Endpoints Expected

Your backend should have these endpoints ready:

- `POST /auth/signup` - Create account + auto-login
- `POST /auth/login` - Login with email/password
- `POST /auth/refresh` - Refresh access token
- `POST /auth/logout` - Revoke refresh token

**Request Format (signup):**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123",
  "deviceId": "uuid-here",
  "username": "Player1",
  "country": "US"
}
```

**Response Format:**
```json
{
  "accessToken": "jwt...",
  "refreshToken": "base64...",
  "expiresIn": 900,
  "userId": "guid",
  "user": {
    "id": "guid",
    "email": "user@example.com",
    "handle": "Player1"
  }
}
```

---

## Testing Checklist

After updating the files:

- [ ] Update `auth_providers.dart` to use `loginManager`
- [ ] Update `login_screen.dart` to use `loginManager`
- [ ] Ensure backend `/auth/signup` and `/auth/login` endpoints exist
- [ ] Test signup flow
- [ ] Check Hive storage for `auth_access_token` and `auth_refresh_token`
- [ ] Test login flow
- [ ] Test app restart (tokens should persist)
- [ ] Test logout (tokens should be cleared)

---

## Summary

**Current Status:** ❌ **NOT properly wired for backend**

**Why:**
1. `LoginScreen` uses `authOps` which uses old `apiService`
2. Tokens not stored properly
3. `LoginManager` exists but is unused

**Solution:**
1. Update `auth_providers.dart` to use `loginManager`
2. Update `login_screen.dart` to use `loginManager`
3. Test complete flow

**After fixes:** ✅ Backend properly integrated
