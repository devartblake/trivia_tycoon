# Quick Fix: 3 Line Changes

## Change 1: Line 90 (logout method)

```diff
  Future<void> logout(BuildContext context) async {
    if (ConfigService.useBackendAuth) {
      await authService.logout();
    } else {
-     await secureStorage.setBool('isLoggedIn', false);
+     await secureStorage.setLoggedIn(false);
      await secureStorage.removeSecret('user_email');
    }
```

**Why:** `SecureStorage` has `setLoggedIn(bool)`, not `setBool(key, value)`

---

## Change 2: Line 121 (_applyBackendSession method)

```diff
  Future<void> _applyBackendSession(String email, AuthSession session) async {
    await secureStorage.setLoggedIn(true);
    await secureStorage.setSecret('user_email', email);
    
    final username = email.split('@')[0];
    await profileService.savePlayerName(username);
    
    if (session.userId != null && session.userId!.isNotEmpty) {
-     await profileService.saveUserId(session.userId!);
+     await secureStorage.setSecret('user_id', session.userId!);
    }
```

**Why:** `PlayerProfileService` doesn't have `saveUserId()` method (yet)

---

## Change 3: Line 152 (isLoggedIn method)

```diff
  Future<bool> isLoggedIn() async {
    if (ConfigService.useBackendAuth) {
      final session = tokenStore.load();
      return session.hasTokens;
    }
    
-   return await secureStorage.getBool('isLoggedIn') ?? false;
+   return await secureStorage.isLoggedIn();
  }
```

**Why:** `SecureStorage` has `isLoggedIn()`, not `getBool(key)`

---

## That's It!

Just **three lines changed** in your `LoginManager`:
- Line 90: `setBool` → `setLoggedIn`
- Line 121: `profileService.saveUserId` → `secureStorage.setSecret`
- Line 152: `getBool` → `isLoggedIn`

Use `LoginManager_CORRECTED.dart` and you're done! ✅
