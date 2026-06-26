# Console Noise Reduction & Bug Fixes

This document provides fixes for excessive logging and UI/auth issues.

## Issues Identified

1. **Excessive DEBUG logging** from LifecycleManager and AnalyticsService
2. **Layout error**: Expanded widgets inside Wrap container (invalid in Flutter)
3. **Auth 400 error**: Token refresh returning Bad Request

---

## Fix 1: Reduce Lifecycle Debug Logs

**File**: `lib/core/services/app_lifecycle_manager.dart`

**Issue**: The `LogManager.debug()` calls fire constantly, cluttering the console.

**Solution**: Wrap debug logs in a condition to only log when needed.

**Changes Required**:
```dart
// Before (noisy):
LogManager.debug('[Lifecycle] State changed: $state');

// After (silent in production):
if (kDebugMode && false) {  // Set to true for dev debugging
  LogManager.debug('[Lifecycle] State changed: $state');
}
```

**Implementation**:
1. Add at the top of the file:
```dart
import 'package:flutter/foundation.dart';
```

2. Replace all `LogManager.debug('[Lifecycle]...` calls with:
```dart
_logDebug(String message) {
  // Only log if explicitly enabled for debugging
  const bool enableDebugLogging = false;  // Set to true when debugging
  if (enableDebugLogging) {
    LogManager.debug(message);
  }
}
```

3. Update all calls:
```dart
// Line 47
_logDebug('[Lifecycle] Initialized - graceful shutdown enabled');

// Line 56
_logDebug('[Lifecycle] Disposed');

// Line 61
_logDebug('[Lifecycle] State changed: $state');

// And all other LogManager.debug calls...
```

---

## Fix 2: Reduce Auth API Client Logging

**File**: `lib/core/services/auth_api_client.dart`

**Issue**: Every API call logs request body including tokens and sensitive data.

**Solution**: Only log errors and successful calls, not full request bodies.

**Changes Required**:
```dart
void _logRequest(String method, String path, {dynamic body}) {
  // Only log path, not sensitive body
  if (kDebugMode) {
    LogManager.debug('[$method] $path');
    // Don't log body - it may contain tokens
  }
}

void _logResponse(String method, String path, http.Response res) {
  // Only log status code
  if (!kDebugMode) return;
  
  if (res.statusCode >= 400) {
    // Log errors
    LogManager.error('[$method] $path returned ${res.statusCode}');
  }
  // Don't log successful responses
}
```

---

## Fix 3: Fix Layout Error (Expanded in Wrap)

**File**: `lib/features/synaptix_home/widgets/navigation/synaptix_rail_content.dart`

**Issue** (Lines 53-57):
```dart
Wrap(
  spacing: 16,
  runSpacing: 16,
  children: [
    Expanded(  // ❌ INVALID: Expanded only works in Flex (Row, Column)
      child: Column(...),
    ),
```

**Solution**: Replace `Wrap` with `Row` since Expanded needs a Flex parent.

**Changes**:
```dart
// Before
Wrap(
  spacing: 16,
  runSpacing: 16,
  children: [
    Expanded(child: Column(...)),
    Expanded(child: Column(...)),
  ],
)

// After
Row(
  children: [
    Expanded(
      flex: 1,
      child: Column(...),
    ),
    Expanded(
      flex: 1,
      child: Column(...),
    ),
  ],
)
```

**Full replacement** (lines 53-120 approximately):
```dart
Row(
  children: [
    Expanded(
      flex: 1,
      child: Column(
        children: [
          Text(
            '${home.player.wins}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Wins',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(width: 16),  // Spacing instead of Wrap spacing
    Expanded(
      flex: 1,
      child: Column(
        children: [
          Text(
            '${home.player.streak}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Streak',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
    // ... repeat for other stat columns
  ],
)
```

---

## Fix 4: Fix Auth Token Refresh 400 Error

**File**: `lib/core/services/auth_api_client.dart` (lines 335-382)

**Issue**: Token refresh returning 400 (Bad Request). Backend might not accept both snake_case and camelCase fields.

**Solution**: Send only camelCase fields (matching modern backend expectations).

**Current problematic code** (lines 341-347):
```dart
final payload = {
  'refresh_token': refreshToken,      // Duplicate - remove this
  'refreshToken': refreshToken,
  'device_id': deviceId,              // Duplicate - remove this
  'deviceId': deviceId,
  'device_type': resolvedDeviceType,  // Duplicate - remove this
  'deviceType': resolvedDeviceType,
};
```

**Fixed code**:
```dart
final payload = {
  'refreshToken': refreshToken,        // Modern backend uses camelCase
  'deviceId': deviceId,
  'deviceType': resolvedDeviceType,
};
```

**Why this works**:
- Sending duplicate keys confuses the backend parser
- Modern APIs prefer consistent naming (usually camelCase for JSON)
- Reduces payload size
- Prevents validation errors

---

## Implementation Checklist

- [ ] **Lifecycle Debug Logs**
  - [ ] Add `_logDebug()` method to `app_lifecycle_manager.dart`
  - [ ] Replace all `LogManager.debug()` calls with `_logDebug()`
  - [ ] Set `enableDebugLogging = false` by default
  - [ ] Test: console should be clean

- [ ] **Auth API Logs**
  - [ ] Update `_logRequest()` to not log body
  - [ ] Update `_logResponse()` to only log errors
  - [ ] Remove token logging
  - [ ] Test: sensitive data not logged

- [ ] **Layout Error**
  - [ ] Replace `Wrap` with `Row` in `synaptix_rail_content.dart`
  - [ ] Replace `spacing` with `SizedBox(width: 16)`
  - [ ] Remove `runSpacing` (only needed for Wrap)
  - [ ] Test in browser: no layout errors

- [ ] **Auth 400 Error**
  - [ ] Remove snake_case duplicates from `refresh()` method
  - [ ] Keep only camelCase fields
  - [ ] Test: token refresh works (200 OK)
  - [ ] Verify new token is stored

---

## Testing After Fixes

```bash
# 1. Run development build
flutter run -d chrome

# 2. Open browser DevTools (F12)

# 3. Check console:
# ✅ No [DEBUG] logs flooding console
# ✅ No layout errors
# ✅ No 400 errors on token refresh
# ✅ App loads successfully

# 4. Test flows:
# - Login/logout
# - Background/foreground transitions
# - Token refresh (let app idle for ~55 min or check network tab)
```

---

## Quick Reference

| Issue | File | Line(s) | Fix |
|-------|------|---------|-----|
| Lifecycle logs | `app_lifecycle_manager.dart` | 47-150+ | Add `_logDebug()` wrapper |
| Auth logs | `auth_api_client.dart` | 350, 368 | Simplify `_logRequest()` / `_logResponse()` |
| Layout error | `synaptix_rail_content.dart` | 53-120 | Replace `Wrap` with `Row` |
| 400 error | `auth_api_client.dart` | 341-347 | Remove snake_case duplicates |

---

## Expected Results

After implementing these fixes:

```
✅ Console becomes quiet (only errors/warnings)
✅ No layout error about Expanded in Wrap
✅ Token refresh returns 200 instead of 400
✅ App performs better (less logging overhead)
✅ Production build will be even cleaner
```

---

**Priority Order**:
1. Fix auth 400 error (breaks login flow)
2. Fix layout error (causes UI crash)
3. Reduce logging (improves DX)
