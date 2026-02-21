# Login Screen Updates

## Changes Needed in login_screen.dart

Your `login_screen.dart` needs minimal changes. The key is to simplify the login flow by using `LoginManager` which handles all the backend complexity.

---

## Change 1: Remove _applyBackendSession Method

**DELETE lines 237-249:**
```dart
Future<void> _applyBackendSession(
    Map<String, dynamic> response,
    AuthService authService,
) async {
  final role = _extractRole(response);
  final isPremium = response['isPremium'] == true;

  if (role != null) {
    await authService.secureStorage.setSecret('user_role', role);
  }
  await authService.secureStorage
      .setSecret('is_premium', isPremium.toString());
}
```

**Why:** `LoginManager` handles all session management internally.

---

## Change 2: Remove _extractRole Method

**DELETE lines 251-260:**
```dart
String? _extractRole(Map<String, dynamic> response) {
  final roles = response['roles'];
  if (roles is List) {
    return roles.map((role) => role.toString()).toList().first;
  }
  final role = response['role'];
  if (role != null) {
    return role.toString();
  }
  return 'player';
}
```

**Why:** No longer needed - LoginManager handles this.

---

## Change 3: Simplify _handleLogin Method

**REPLACE lines 154-186 with:**

```dart
try {
  final authOps = ref.read(authOperationsProvider);
  final multiProfileService = ref.read(multiProfileServiceProvider);
  final serviceManager = ref.read(serviceManagerProvider);

  if (ConfigService.useBackendAuth) {
    // Backend authentication - LoginManager handles tokens, device ID, and profile
    if (_isSignUpMode) {
      await authOps.signup(email, password);
    } else {
      await authOps.loginWithPassword(email, password);
    }
  } else {
    // Legacy mock authentication
    if (!mockUsers.containsKey(email)) {
      _showErrorSnackBar('User does not exist');
      setState(() => _isLoading = false);
      return;
    }

    final mockUser = mockUsers[email]!;
    if (mockUser.password != password) {
      _showErrorSnackBar('Incorrect password');
      setState(() => _isLoading = false);
      return;
    }
    
    await authOps.login(email);
    final authService = ref.read(authServiceProvider);
    await authService.secureStorage.setSecret('user_role', mockUser.role);
    await authService.secureStorage
        .setSecret('is_premium', mockUser.isPremium.toString());
  }

  // Handle multi-profile logic (same as before)
  final existingProfiles = await multiProfileService.getAllProfiles();
  // ... rest of profile logic unchanged
```

---

## Complete Updated _handleLogin Method

**Replace the entire _handleLogin method (lines 131-235) with:**

```dart
Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  final email = _emailController.text.trim();
  final password = _passwordController.text;

  await Future.delayed(const Duration(milliseconds: 1500));

  try {
    final authOps = ref.read(authOperationsProvider);
    final multiProfileService = ref.read(multiProfileServiceProvider);
    final serviceManager = ref.read(serviceManagerProvider);

    if (ConfigService.useBackendAuth) {
      // Backend authentication - authOps now uses LoginManager internally
      if (_isSignUpMode) {
        await authOps.signup(email, password);
      } else {
        await authOps.loginWithPassword(email, password);
      }
    } else {
      // Legacy mock authentication
      if (!mockUsers.containsKey(email)) {
        _showErrorSnackBar('User does not exist');
        setState(() => _isLoading = false);
        return;
      }

      final mockUser = mockUsers[email]!;
      if (mockUser.password != password) {
        _showErrorSnackBar('Incorrect password');
        setState(() => _isLoading = false);
        return;
      }
      
      await authOps.login(email);
      final authService = ref.read(authServiceProvider);
      await authService.secureStorage.setSecret('user_role', mockUser.role);
      await authService.secureStorage
          .setSecret('is_premium', mockUser.isPremium.toString());
    }

    // Handle multi-profile migration/loading
    final existingProfiles = await multiProfileService.getAllProfiles();

    if (existingProfiles.isNotEmpty) {
      final activeProfile = await multiProfileService.getActiveProfile();

      if (activeProfile != null) {
        ref.read(activeProfileStateProvider.notifier).state = activeProfile;
        ref.read(hasSeenIntroProvider.notifier).state = true;
        ref.read(hasCompletedProfileProvider.notifier).state = true;
      }
    } else {
      final playerProfileService = serviceManager.playerProfileService;
      final existingName = await playerProfileService.getPlayerName();

      if (existingName != 'Player' && existingName.isNotEmpty) {
        final existingAvatar = await playerProfileService.getAvatar();
        final existingCountry = await playerProfileService.getCountry();
        final existingAgeGroup = await playerProfileService.getAgeGroup();

        final migratedProfile = await multiProfileService.createProfile(
          name: existingName,
          avatar: existingAvatar,
          country: existingCountry,
          ageGroup: existingAgeGroup,
        );

        if (migratedProfile != null) {
          await multiProfileService.setActiveProfile(migratedProfile.id);
          ref.read(activeProfileStateProvider.notifier).state = migratedProfile;
          ref.read(hasSeenIntroProvider.notifier).state = true;
          ref.read(hasCompletedProfileProvider.notifier).state = true;
        }
      } else {
        ref.read(hasSeenIntroProvider.notifier).state = false;
        ref.read(hasCompletedProfileProvider.notifier).state = false;
      }
    }

    setState(() => _isLoading = false);

    if (mounted) {
      context.go('/');
    }
  } catch (e) {
    _showErrorSnackBar('Login failed: ${e.toString()}');
    setState(() => _isLoading = false);
  }
}
```

---

## Summary of Changes

| Line Range | Change | Reason |
|------------|--------|--------|
| 154-186 | Simplified backend auth | Use authOps which now calls LoginManager |
| 237-249 | DELETE `_applyBackendSession` | No longer needed |
| 251-260 | DELETE `_extractRole` | No longer needed |

---

## What's Better Now

✅ **Before:** Complex manual token handling, role extraction, backend response parsing  
✅ **After:** Simple `authOps.loginWithPassword(email, password)` - everything handled internally

✅ **Before:** No device ID support  
✅ **After:** Device ID automatically included

✅ **Before:** Only generic 'auth_token' saved  
✅ **After:** Both accessToken + refreshToken properly saved in Hive

✅ **Before:** Manual response parsing  
✅ **After:** LoginManager handles all backend response parsing

---

## Testing After Update

```dart
// Test backend login
ConfigService.useBackendAuth = true;
await loginScreen._handleLogin();

// Verify tokens stored
final tokenStore = ref.read(authTokenStoreProvider);
final session = tokenStore.load();
print('Has tokens: ${session.hasTokens}');
print('Access token: ${session.accessToken.substring(0, 20)}...');
print('Refresh token: ${session.refreshToken.substring(0, 20)}...');

// Verify device ID
final deviceId = await ref.read(deviceIdServiceProvider).getOrCreate();
print('Device ID: $deviceId');
```
