# Step-by-Step Backend Integration Guide

## 🎯 Goal
Connect your login screen to the backend server using proper token management.

---

## Current Status: ❌ NOT Connected

Your app has `LoginManager` with proper backend integration, but **it's not being used**. Instead, the login screen uses old `authOps` which uses broken `apiService`.

---

## Implementation Steps

### Step 1: Update auth_providers.dart (5 minutes)

**File:** `lib/game/providers/auth_providers.dart`

**Replace the entire file** with `auth_providers_FIXED.dart`

**Key changes:**
- Line 38-42: `loginWithPassword()` now calls `loginManager.login()`
- Line 47-62: `signup()` now calls `loginManager.signup()`
- Line 67-85: `logout()` now calls `loginManager.logout()`

---

### Step 2: Update login_screen.dart (10 minutes)

**File:** `lib/screens/login_screen.dart`

**Update the `_handleLogin()` method:**

Replace lines 131-260 with the code from `login_screen_handleLogin_COMPLETE.dart`

**What's being removed:**
- `_applyBackendSession()` method (lines 237-249)
- `_extractRole()` method (lines 251-260)
- Complex backend response handling (lines 164-186)

**What's being simplified:**
```dart
// OLD (broken):
final response = await authOps.loginWithPassword(email, password);
await _applyBackendSession(response, authService);

// NEW (works):
await authOps.loginWithPassword(email, password);
// LoginManager handles everything internally!
```

---

### Step 3: Verify Riverpod Providers (Already Done)

**File:** `lib/game/providers/riverpod_providers.dart`

You should have already updated this with the new auth providers. Verify you have:

```dart
final authTokenBoxProvider = Provider<Box>((ref) { ... });
final authTokenStoreProvider = Provider<AuthTokenStore>((ref) { ... });
final deviceIdServiceProvider = Provider<DeviceIdService>((ref) { ... });
final coreAuthServiceProvider = Provider<core_auth.AuthService>((ref) { ... });
final loginManagerProvider = Provider<LoginManager>((ref) { ... });
```

---

### Step 4: Verify app_init.dart (Already Done)

**File:** `lib/core/init/app_init.dart`

Verify you have the fixed version with:

```dart
final authTokenBox = await Hive.openBox('auth_tokens');
final secureStorage = SecureStorage();
final deviceIdService = DeviceIdService(secureStorage);
final tokenStore = AuthTokenStore(authTokenBox);
final authService = AuthService(...);
```

---

### Step 5: Test Backend Connection

#### A. Enable Backend Auth

In your app, make sure backend auth is enabled:

```dart
// ConfigService or similar
ConfigService.useBackendAuth = true;
```

#### B. Set Backend URL

In your `env.dart` or config:

```dart
class EnvConfig {
  static const String apiBaseUrl = 'http://YOUR_BACKEND_IP:5000';
}
```

For local testing:
- **Android emulator:** `http://10.0.2.2:5000`
- **iOS simulator:** `http://localhost:5000`
- **Physical device:** `http://YOUR_COMPUTER_IP:5000`

#### C. Test Signup

```dart
// In login screen, toggle to signup mode
_isSignUpMode = true;

// Fill form
_emailController.text = 'test@example.com';
_passwordController.text = 'TestPass123';

// Click signup button
await _handleLogin();

// Check console for device ID
// ✅ DeviceId ready: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

#### D. Verify Tokens Stored

```dart
// After successful signup/login
final tokenStore = ref.read(authTokenStoreProvider);
final session = tokenStore.load();

print('Has tokens: ${session.hasTokens}');
print('Access token present: ${session.accessToken.isNotEmpty}');
print('Refresh token present: ${session.refreshToken.isNotEmpty}');
print('User ID: ${session.userId}');
```

---

## Backend Requirements

Your backend needs these endpoints:

### 1. POST /auth/signup
```json
Request:
{
  "email": "user@example.com",
  "password": "SecurePass123",
  "deviceId": "uuid-here",
  "username": "Player1",
  "country": "US"
}

Response:
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

### 2. POST /auth/login
```json
Request:
{
  "email": "user@example.com",
  "password": "SecurePass123",
  "deviceId": "uuid-here"
}

Response:
{
  "accessToken": "jwt...",
  "refreshToken": "base64...",
  "expiresIn": 900,
  "userId": "guid",
  "user": { ... }
}
```

---

## File Checklist

Update these files in order:

- [ ] `lib/game/providers/auth_providers.dart` → Use `auth_providers_FIXED.dart`
- [ ] `lib/screens/login_screen.dart` → Update `_handleLogin()` method
- [ ] Test backend connection
- [ ] Verify token storage in Hive

---

## Verification Steps

### 1. Check Device ID
```dart
final deviceId = await ref.read(deviceIdServiceProvider).getOrCreate();
print('Device ID: $deviceId');
// Should print a UUID
```

### 2. Check Backend URL
```dart
final apiClient = ref.read(authApiClientProvider);
print('API URL: ${apiClient.apiBaseUrl}');
// Should print your backend URL
```

### 3. Test Signup
- Open app
- Switch to signup mode
- Enter: test@example.com / TestPass123
- Click signup
- Check console for success/error

### 4. Check Token Storage
```dart
// Open Hive inspector or check programmatically
final box = await Hive.openBox('auth_tokens');
print('Access token: ${box.get('auth_access_token')}');
print('Refresh token: ${box.get('auth_refresh_token')}');
```

### 5. Test App Restart
- Close app completely
- Reopen app
- Should stay logged in (tokens persisted)

### 6. Test Logout
- Click logout
- Tokens should be cleared
- Should redirect to login screen

---

## Common Issues & Solutions

### Issue 1: "auth_tokens box must be opened"
**Fix:** Ensure `app_init.dart` has:
```dart
final authTokenBox = await Hive.openBox('auth_tokens');
```

### Issue 2: "No such method: loginWithPassword"
**Fix:** Update `auth_providers.dart` with new version

### Issue 3: "Connection refused"
**Fix:** Check backend URL:
- Emulator: Use `10.0.2.2` instead of `localhost`
- Physical device: Use computer's IP address

### Issue 4: "signup() is not defined for type 'AuthService'"
**Fix:** Add signup method to `core/services/auth_service.dart`

### Issue 5: Backend returns 404
**Fix:** Verify backend has `/auth/signup` and `/auth/login` endpoints

---

## Success Indicators

✅ Console shows: `DeviceId ready: [uuid]`  
✅ Console shows: `[AppInit] Critical initialization complete`  
✅ Signup/login completes without errors  
✅ Hive contains `auth_access_token` and `auth_refresh_token`  
✅ App restart keeps user logged in  
✅ Logout clears tokens and redirects to login  

---

## Next Steps After Integration

Once basic auth works:

1. **Automatic Token Refresh** - Add interceptor to refresh expired tokens
2. **Error Handling** - Display user-friendly error messages
3. **Loading States** - Show proper loading indicators
4. **Session Management** - Handle multiple devices, logout all
5. **Password Reset** - Implement forgot password flow

---

## Timeline

- **Step 1 (auth_providers):** 5 minutes
- **Step 2 (login_screen):** 10 minutes
- **Step 3 (Testing):** 15 minutes
- **Total:** ~30 minutes

After this, your login screen will be **fully wired to the backend** with proper token management! 🎉
