# Method Call Fixes for LoginManager

## Three Errors Found

### ❌ Error 1: `secureStorage.setBool('isLoggedIn', false)`
**Location:** LoginManager line 90 (logout method)

**Problem:**
```dart
await secureStorage.setBool('isLoggedIn', false); // ← Method doesn't exist!
```

**Your SecureStorage class has:**
```dart
Future<void> setLoggedIn(bool value) async {
  final box = await Hive.openBox('app');
  await box.put(_boxName, value);
}
```

**Fix:**
```dart
await secureStorage.setLoggedIn(false); // ← Use setLoggedIn() instead
```

---

### ❌ Error 2: `secureStorage.getBool('isLoggedIn')`
**Location:** LoginManager line 152 (isLoggedIn method)

**Problem:**
```dart
return await secureStorage.getBool('isLoggedIn') ?? false; // ← Method doesn't exist!
```

**Your SecureStorage class has:**
```dart
Future<bool> isLoggedIn() async {
  final box = await Hive.openBox('app');
  return box.get(_boxName, defaultValue: false);
}
```

**Fix:**
```dart
return await secureStorage.isLoggedIn(); // ← Use isLoggedIn() instead
```

---

### ❌ Error 3: `profileService.saveUserId(session.userId!)`
**Location:** LoginManager line 121 (_applyBackendSession method)

**Problem:**
```dart
await profileService.saveUserId(session.userId!); // ← Method doesn't exist!
```

**Your PlayerProfileService doesn't have a `saveUserId()` method.**

**Fix Option A (Quick):**
Store in SecureStorage instead:
```dart
await secureStorage.setSecret('user_id', session.userId!);
```

**Fix Option B (Better):**
Add `saveUserId()` method to PlayerProfileService (see `PlayerProfileService_ENHANCED.dart`)

---

## Side-by-Side Comparison

### OLD (Broken)
```dart
// Line 90 - Logout
await secureStorage.setBool('isLoggedIn', false); // ❌ No setBool() method
await secureStorage.removeSecret('user_email');

// Line 121 - Save user ID
await profileService.saveUserId(session.userId!); // ❌ No saveUserId() method

// Line 152 - Check login
return await secureStorage.getBool('isLoggedIn') ?? false; // ❌ No getBool() method
```

### NEW (Fixed)
```dart
// Line 90 - Logout
await secureStorage.setLoggedIn(false); // ✅ Correct method
await secureStorage.removeSecret('user_email');

// Line 121 - Save user ID
await secureStorage.setSecret('user_id', session.userId!); // ✅ Works with existing method

// Line 152 - Check login
return await secureStorage.isLoggedIn(); // ✅ Correct method
```

---

## Why These Errors Happened

The original code I provided assumed generic methods like:
- `setBool(key, value)` - Generic key-value setter
- `getBool(key)` - Generic key-value getter
- `saveUserId(id)` - Profile service method

But your actual classes use more specific methods:
- `setLoggedIn(bool)` - Dedicated method for login state
- `isLoggedIn()` - Dedicated method to check login
- `setSecret(key, value)` - Generic secret storage

---

## What to Do

### Option 1: Quick Fix (Recommended)
Replace your `login_manager.dart` with `LoginManager_CORRECTED.dart`

**Changes:**
- Line 90: `setBool` → `setLoggedIn`
- Line 121: `saveUserId` → `setSecret('user_id', ...)`
- Line 152: `getBool` → `isLoggedIn`

### Option 2: Add saveUserId Method
1. Replace `player_profile_service.dart` with `PlayerProfileService_ENHANCED.dart`
2. Replace `login_manager.dart` with a version that uses `profileService.saveUserId()`

---

## Complete Fixed Code (Option 1)

### logout() method
```dart
Future<void> logout(BuildContext context) async {
  if (ConfigService.useBackendAuth) {
    await authService.logout();
  } else {
    await secureStorage.setLoggedIn(false);     // ← FIXED
    await secureStorage.removeSecret('user_email');
  }
  
  await profileService.clearProfile();
  
  if (context.mounted) {
    context.go('/auth');
  }
}
```

### _applyBackendSession() method
```dart
Future<void> _applyBackendSession(String email, AuthSession session) async {
  await secureStorage.setLoggedIn(true);
  await secureStorage.setSecret('user_email', email);
  
  final username = email.split('@')[0];
  await profileService.savePlayerName(username);
  
  // Save user ID in SecureStorage instead
  if (session.userId != null && session.userId!.isNotEmpty) {
    await secureStorage.setSecret('user_id', session.userId!); // ← FIXED
  }
  
  await profileService.saveUserRole("player");
  await profileService.saveUserRoles(["player"]);
}
```

### isLoggedIn() method
```dart
Future<bool> isLoggedIn() async {
  if (ConfigService.useBackendAuth) {
    final session = tokenStore.load();
    return session.hasTokens;
  }
  
  return await secureStorage.isLoggedIn(); // ← FIXED
}
```

---

## Testing After Fix

```dart
// Test logout
await loginManager.logout(context);
final stillLoggedIn = await secureStorage.isLoggedIn();
print('Still logged in: $stillLoggedIn'); // Should be false

// Test login state check
final isLoggedIn = await loginManager.isLoggedIn();
print('Is logged in: $isLoggedIn'); // Should match token store

// Test user ID storage
await secureStorage.setSecret('user_id', 'test-user-123');
final userId = await secureStorage.getSecret('user_id');
print('User ID: $userId'); // Should be 'test-user-123'
```

---

## If You Want saveUserId() in ProfileService

Use `PlayerProfileService_ENHANCED.dart` which adds:

```dart
/// Saves the backend user ID
Future<void> saveUserId(String userId) async {
  final box = await _getBox();
  await box.put(_userIdKey, userId);
}

/// Retrieves the backend user ID
Future<String?> getUserId() async {
  final box = await _getBox();
  return box.get(_userIdKey);
}
```

Then in LoginManager you can use:
```dart
await profileService.saveUserId(session.userId!);
```

---

## Summary

| Error | Wrong Method | Correct Method |
|-------|--------------|----------------|
| 1. Logout | `setBool('isLoggedIn', false)` | `setLoggedIn(false)` |
| 2. Check login | `getBool('isLoggedIn')` | `isLoggedIn()` |
| 3. Save user ID | `saveUserId(id)` | `setSecret('user_id', id)` |

All three are now fixed in `LoginManager_CORRECTED.dart`!
