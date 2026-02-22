# LoginManager: What Changed (Side-by-Side)

## Constructor Changes

### ❌ OLD (Your Current Code)
```dart
LoginManager({
  required this.authService,
  required this.apiService,  // ← REMOVED
  required this.onboardingService,
  required this.secureStorage,
  required this.profileService,
});
```

### ✅ NEW (Updated Code)
```dart
LoginManager({
  required this.authService,
  required this.tokenStore,        // ← NEW
  required this.deviceIdService,   // ← NEW
  required this.onboardingService,
  required this.secureStorage,
  required this.profileService,
});
```

---

## login() Method Changes

### ❌ OLD
```dart
Future<void> login(String email, String password) async {
  if (ConfigService.useBackendAuth) {
    final response = await apiService.login(email: email, password: password);
    await _applyBackendLogin(email, response);
    return;
  }
  await authService.login(email);
  await secureStorage.setLoggedIn(true);
}
```

**Problems:**
- Uses `apiService.login()` which returns a `Map<String, dynamic>`
- Doesn't properly store tokens
- `_applyBackendLogin()` only saves a generic 'auth_token'

### ✅ NEW
```dart
Future<void> login(String email, String password) async {
  if (ConfigService.useBackendAuth) {
    // AuthService.login() returns AuthSession and stores tokens in Hive
    final session = await authService.login(
      email: email,
      password: password,
    );
    
    // Tokens already saved, just update profile
    await _applyBackendSession(email, session);
    return;
  }
  
  // Legacy local-only login
  await _legacyLogin(email);
}
```

**Fixed:**
- Uses `authService.login()` which returns `AuthSession` object
- Tokens automatically stored in Hive by AuthService
- Clean separation of backend vs legacy flow

---

## signup() Method Changes

### ❌ OLD
```dart
Future<void> signup(SignupData data) async {
  final email = data.name;
  final username = data.additionalSignupData?["Username"] ?? 'Player';
  if (ConfigService.useBackendAuth) {
    final response = await apiService.signup(
      email: email!,
      password: data.password ?? '',
      extra: _buildSignupExtras(username, data.additionalSignupData),
    );
    await _applyBackendLogin(email, response);
    await onboardingService.setHasCompletedOnboarding(false);
    return;
  }

  await authService.secureStorage.setUserEmail(email!);
  await profileService.savePlayerName(username);
  await profileService.saveUserRole("player");
  await profileService.saveUserRoles(["player"]);
  await secureStorage.setLoggedIn(true);
  await onboardingService.setHasCompletedOnboarding(false);
}
```

**Problems:**
- `apiService.signup()` doesn't exist
- Doesn't pass username/country to backend properly
- Tokens not stored correctly

### ✅ NEW
```dart
Future<void> signup(SignupData data) async {
  final email = data.name!;
  final username = data.additionalSignupData?["Username"] ?? 'Player';
  final country = data.additionalSignupData?["Country"];
  
  if (ConfigService.useBackendAuth) {
    // AuthService.signup() calls /auth/signup endpoint
    final session = await authService.signup(
      email: email,
      password: data.password ?? '',
      username: username,
      country: country,
    );
    
    // Tokens already saved, just update profile
    await _applyBackendSession(email, session);
    await onboardingService.setHasCompletedOnboarding(false);
    return;
  }

  // Legacy local-only signup
  await _legacySignup(email, username);
}
```

**Fixed:**
- Uses `authService.signup()` which properly calls backend
- Passes username and country as named parameters
- Tokens automatically stored in Hive

---

## logout() Method Changes

### ❌ OLD
```dart
Future<void> logout(BuildContext context) async {
  await authService.logout(context);
  await profileService.clearProfile();
}
```

**Problems:**
- `authService.logout(context)` expects BuildContext but doesn't use backend properly
- Doesn't distinguish between backend vs local logout

### ✅ NEW
```dart
Future<void> logout(BuildContext context) async {
  if (ConfigService.useBackendAuth) {
    // Backend logout - revokes refresh token
    await authService.logout();
  } else {
    // Legacy local logout
    await secureStorage.setBool('isLoggedIn', false);
    await secureStorage.removeSecret('user_email');
  }
  
  // Always clear profile
  await profileService.clearProfile();
  
  // Navigate to login
  if (context.mounted) {
    context.go('/auth');
  }
}
```

**Fixed:**
- Backend logout properly revokes refresh token
- Clear separation of backend vs legacy
- Safer context usage with mounted check

---

## isLoggedIn() Method Changes

### ❌ OLD
```dart
Future<bool> isLoggedIn() async => await authService.isLoggedIn();
```

**Problems:**
- Relies on `authService.isLoggedIn()` which might check wrong storage
- Doesn't distinguish between backend vs local auth

### ✅ NEW
```dart
Future<bool> isLoggedIn() async {
  if (ConfigService.useBackendAuth) {
    // Check if we have valid tokens in Hive
    final session = tokenStore.load();
    return session.hasTokens;
  }
  
  // Legacy check
  return await secureStorage.getBool('isLoggedIn') ?? false;
}
```

**Fixed:**
- Backend mode checks token storage directly
- Clear separation of concerns

---

## Helper Methods Changes

### ❌ OLD - Multiple Confusing Methods
```dart
Future<void> _applyBackendLogin(String email, Map<String, dynamic> response) async {
  final roles = _extractRoles(response);
  final isPremium = response['isPremium'] == true;
  final userId = response['userId']?.toString() ?? 'guest';

  await authService.login(email, userId: userId, isPremiumUser: isPremium, roles: roles);
  await secureStorage.setLoggedIn(true);
  await _persistAuthTokenIfPresent(response);
}

List<String> _extractRoles(Map<String, dynamic> response) { ... }

Future<void> _persistAuthTokenIfPresent(Map<String, dynamic> response) async {
  final token = response['token'];  // ← WRONG: only saves one token
  if (token is String && token.isNotEmpty) {
    await secureStorage.setSecret('auth_token', token);
  }
}

Map<String, dynamic> _buildSignupExtras(String username, Map<String, dynamic>? additionalData) { ... }
```

**Problems:**
- `_persistAuthTokenIfPresent()` only saves one generic token
- Complex response parsing that AuthService should handle
- `_buildSignupExtras()` no longer needed

### ✅ NEW - One Clean Method
```dart
Future<void> _applyBackendSession(String email, AuthSession session) async {
  // Mark as logged in
  await secureStorage.setLoggedIn(true);
  
  // Save email for profile
  await secureStorage.setSecret('user_email', email);
  
  // Extract username from email
  final username = email.split('@')[0];
  await profileService.savePlayerName(username);
  
  // Save user ID if available
  if (session.userId != null && session.userId!.isNotEmpty) {
    await profileService.saveUserId(session.userId!);
  }
  
  // Set default role
  await profileService.saveUserRole("player");
  await profileService.saveUserRoles(["player"]);
}

// Legacy helpers
Future<void> _legacyLogin(String email) async { ... }
Future<void> _legacySignup(String email, String username) async { ... }
```

**Fixed:**
- No manual token persistence needed (AuthService handles it)
- Simple profile updates only
- Clear separation of legacy vs backend flows

---

## Summary of Key Differences

| Aspect | Old | New |
|--------|-----|-----|
| Token Storage | Generic `'auth_token'` in SecureStorage | Separate `accessToken` + `refreshToken` in Hive |
| Backend Calls | `apiService.login/signup()` | `authService.login/signup()` |
| Device ID | Not used | Required for all backend operations |
| Response Type | `Map<String, dynamic>` | `AuthSession` object |
| Token Persistence | Manual via `_persistAuthTokenIfPresent()` | Automatic via AuthService |
| Dependencies | `apiService` | `authService`, `tokenStore`, `deviceIdService` |
| Signup Method | Doesn't exist in ApiService | Properly implemented in AuthService |

---

## What You Get With These Changes

### ✅ Proper Token Management
- Access token and refresh token stored separately
- Tokens persist across app restarts via Hive
- Ready for automatic token refresh

### ✅ Backend Integration
- Calls `/auth/signup` endpoint correctly
- Proper device identification
- Clean error handling

### ✅ Cleaner Code
- Removed complex token parsing
- AuthService handles all backend communication
- LoginManager only handles business logic

### ✅ Future-Proof
- Ready for automatic token refresh
- Easy to add "logout all devices"
- Supports multi-device sessions

---

## Migration Checklist

1. [ ] Update dependencies in constructor (add tokenStore, deviceIdService)
2. [ ] Replace `apiService.login()` with `authService.login()`
3. [ ] Replace `apiService.signup()` with `authService.signup()`
4. [ ] Update `logout()` to use backend properly
5. [ ] Update `isLoggedIn()` to check token storage
6. [ ] Replace `_applyBackendLogin()` with `_applyBackendSession()`
7. [ ] Remove `_extractRoles()`, `_persistAuthTokenIfPresent()`, `_buildSignupExtras()`
8. [ ] Add `_legacyLogin()` and `_legacySignup()` helpers
9. [ ] Update DI setup to provide new dependencies
10. [ ] Test signup → login → logout → app restart
