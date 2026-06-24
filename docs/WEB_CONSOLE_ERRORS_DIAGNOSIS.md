# Web Console Errors Diagnosis & Solutions

## Issues Identified

### 🔴 Issue 1: Malformed API URLs (CRITICAL)

**Pattern in console:**
```
api.synaptixplay.com.i/v1/auth/refresh ❌
api.synaptixplay.com.ad92-f13ed9ce6d80/home ❌
api.synaptixplay.com.nt/rewards/status ❌
```

**Expected:**
```
https://api.synaptixplay.com/v1/auth/refresh ✅
https://api.synaptixplay.com/home ✅
https://api.synaptixplay.com/rewards/status ✅
```

**Root Cause Analysis:**
The URLs are **missing the `https://` scheme** and have **corrupted domain names** with garbage characters. Investigation shows:

1. **Code Investigation Results:**
   - ✅ `lib/core/env.dart:46` - `apiV1BaseUrl` correctly constructed as `'$apiBaseUrl/api/v1'`
   - ✅ `lib/core/manager/service_manager.dart:210` - ApiService initialized with `apiV1BaseUrl` from EnvConfig
   - ✅ `.env.prod` correctly sets `API_BASE_URL=https://api.synaptixplay.com`
   - ✅ `lib/core/networking/http_client.dart:20-22` - URI construction looks correct: `Uri.parse('$baseUrl$path')`

2. **Likely Root Causes (Web Platform Specific):**
   - **Flutter web environment variables**: May not load .env.prod correctly. Web builds might be using fallback value from line 332 of env.dart (`_releaseApiBaseUrlFallback = 'https://api.synaptixplay.com'`)
   - **URL serialization in browser**: Browser network tab may truncate or mangle the display of URLs
   - **Dio baseUrl handling on web**: Web implementation of Dio may behave differently than mobile
   - **Possible web-specific path prefix issue**: The garbage characters (.i, .ad92-, .nt) suggest UUID fragments or cache busters being appended somewhere in the web runtime

### 🔴 Issue 2: Duplicated Asset Paths (CRITICAL)

**Pattern in console:**
```
assets/assets/images/rewards/silver.png ❌
assets/assets/images/rewards/bronze.png ❌
```

**Expected:**
```
assets/images/rewards/silver.png ✅
```

**Root Cause:**
The asset path is being prefixed with "assets/" twice. This likely happens in:
- Image asset loading code
- AssetResolver configuration
- Web build process

### 🔴 Issue 3: Auth Failures (401/400 errors)

Multiple auth refresh endpoints returning 401/400:
- The malformed URLs prevent proper authentication
- Once URLs are fixed, auth should work

---

## How to Diagnose Further

### Step 1: Check Dio Configuration

**File:** `lib/core/services/api_service.dart`

Look for:
```dart
// Check if baseUrl is properly formatted
Dio(BaseOptions(
  baseUrl: baseUrl,  // Should be: https://api.synaptixplay.com
  ...
))
```

**Question:** Is the baseUrl ending with a `/`?
- If yes, remove it (Dio handles path joining)
- If no, keep it as is

### Step 2: Check URL Path Construction

Search for places where URLs are built:

```bash
# Find all URL construction patterns
grep -r "baseUrl.*\+" lib/core/services/
grep -r "'/v1/" lib/
grep -r "\$baseUrl" lib/
```

Look for:
```dart
// BAD - double slash or missing slash issues
url = "$baseUrl" + "/v1/auth"  // Could create baseUrl/v1 or baseUrl//v1
url = baseUrl + path            // Missing slash between them

// GOOD
url = "$baseUrl/v1/auth"        // Explicit path
url = Uri.parse(baseUrl).resolve(path).toString()  // Proper URL handling
```

### Step 3: Check Asset Path Construction

**File:** `lib/core/services/asset_resolver.dart` and image loading code

Look for:
```dart
// BAD - double assets prefix
final path = "assets/" + "assets/images/...";

// GOOD
final path = "assets/images/...";
```

### Step 4: Check Web Build Configuration

**File:** `web/index.html`

Verify:
```html
<!-- Check base href is correct -->
<base href="$FLUTTER_BASE_HREF">

<!-- Check asset paths in manifest -->
<link rel="manifest" href="manifest.json">
```

---

## Solutions

### Solution 1: Verify Web Build Environment Variables (FIRST)

**File**: `lib/core/env.dart`

**Step 1A**: Check if .env.prod is being loaded for web builds:

```bash
# Run from project root
flutter clean
flutter pub get

# For web build, specify the env file explicitly
flutter build web --dart-define=ENV_FILE=assets/config/.env.prod
```

**Step 1B**: Add logging to debug env config loading:

```dart
// In lib/core/env.dart, after line 354, add:
LogManager.debug('[EnvConfig] 🔍 Final apiV1BaseUrl = $apiV1BaseUrl');
LogManager.debug('[EnvConfig] 🔍 Is web = $kIsWeb');
LogManager.debug('[EnvConfig] 🔍 Is release = $kReleaseMode');
```

Then run web and check console logs for actual URL being used.

### Solution 2: Fix Asset Path Duplication (Web-Specific)

**Investigate**: The double "assets/" prefix suggests Flutter web asset resolver issue.

**Check files**:
- `web/index.html` - verify `<base href>` is correct
- `pubspec.yaml` - verify assets section uses `- assets/` not `- assets/assets/`

**If issue persists**:

```dart
// In any image loading code, use AssetResolver:
import 'package:trivia_tycoon/core/services/asset_resolver.dart';

// Instead of hardcoded paths:
Image.asset('assets/images/rewards/silver.png')

// Use the resolver:
final imagePath = await AssetResolver.instance.resolveAssetPath('images/rewards/silver.png');
Image.asset(imagePath)
```

### Solution 3: Add Explicit Web Platform Configuration

**File**: `lib/core/services/api_service.dart` (around line 92-98)

Add web-specific Dio configuration:

```dart
_dio = dio ??
    Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: EnvConfig.apiConnectTimeout,
      receiveTimeout: EnvConfig.apiReceiveTimeout,
      sendTimeout: kIsWeb ? null : EnvConfig.apiSendTimeout,
    ))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Log URLs for debugging
          if (kDebugMode) {
            LogManager.debug('[API] ${options.method} ${options.url}');
          }
          return handler.next(options);
        },
      ),
    ),
```

### Solution 4: Verify pubspec.yaml Assets Configuration

Ensure these are NOT present in pubspec.yaml:

```yaml
# ❌ WRONG - doubles assets prefix
- assets/assets/

# ✅ CORRECT
- assets/
- assets/config/
```

---

## IMMEDIATE ACTION PLAN (Start Here)

### Step 1: Diagnose API URL Issue (10 minutes)

```bash
# 1. Clear and rebuild for web
flutter clean
rm -rf build/web
flutter pub get

# 2. Build web with explicit env file
flutter build web --dart-define=ENV_FILE=assets/config/.env.prod --debug

# 3. Run web build locally and check console
# Open DevTools → Application → Console tab
# Look for: [EnvConfig] API Base: https://api.synaptixplay.com
```

**Expected console output:**
```
✅ [EnvConfig] API Base: https://api.synaptixplay.com
✅ [EnvConfig] API Health: https://api.synaptixplay.com/healthz
✅ [EnvConfig] WebSocket: wss://api.synaptixplay.com/ws
✅ [API] GET https://api.synaptixplay.com/api/v1/auth/refresh
```

**If you see:**
```
❌ http://10.0.2.2:5000 (debug fallback)
❌ Missing scheme (api.synaptixplay.com)
❌ Corrupted domain (api.synaptixplay.com.i)
```

**Then**: Environment variables are NOT being loaded correctly on web.

### Step 2: Check Asset Path Issue (5 minutes)

```bash
# 1. Verify pubspec.yaml assets configuration
grep -A 5 "flutter:" pubspec.yaml | grep -A 3 "assets:"

# Expected output:
# assets:
#   - assets/
#   - assets/config/

# NOT:
# assets:
#   - assets/assets/

# 2. Check web/index.html
grep "base href" web/index.html

# Should show one of:
# - <base href="/">
# - <base href="$FLUTTER_BASE_HREF">
```

### Step 3: Root Cause Determination

**If .env.prod is NOT loading on web:**
- Copy `assets/config/.env.prod` content to `web/.env` 
- Or modify the web build process to include env file
- Or use the dart-define fallback approach

**If assets have double prefix:**
- Check if there's a custom asset resolver adding "assets/" prefix
- Search for: `"assets/" + imagePath`
- Update to: `imagePath` (if it already includes assets/)

### Step 4: Implementation Checklist

- [ ] **Verify .env.prod loads on web** - Add logging to env.dart line 335-336
- [ ] **Test actual API URLs in console** - Run: `fetch('https://api.synaptixplay.com/api/v1/auth/refresh')`
- [ ] **Check pubspec.yaml assets** - Ensure no double assets/ prefix
- [ ] **Rebuild and test** - `flutter build web && firebase deploy`
- [ ] **Monitor DevTools Network tab** - Verify correct URLs being requested
- [ ] **Check response codes** - Should be 401 (auth needed), not 400 (bad request)

---

## Testing After Fixes

1. **Auth Endpoints:**
   - Check Network tab in DevTools
   - Verify URLs look like: `https://api.synaptixplay.com/v1/auth/refresh`
   - Should get 200/401 not 400 with malformed URL

2. **Asset Loading:**
   - Check Network tab for image requests
   - Verify paths look like: `assets/images/rewards/silver.png`
   - Should load successfully (200) not 404

3. **Console:**
   - No more "Failed to load resource: the server responded with a status of 4xx" errors
   - No more "Error while trying to load an asset" messages

---

## Troubleshooting Guide

### Symptom: "Cannot GET /api/v1/auth/refresh"

**Likely Cause**: Missing API base URL scheme (http/https)

**Fix**:
1. Verify EnvConfig.apiBaseUrl includes scheme: `https://api.synaptixplay.com`
2. Check .env.prod is being loaded (not using fallback)
3. Add diagnostic logging in env.dart

```dart
// In env.dart after load(), add:
LogManager.debug('Loaded API URL: $_apiBaseUrl');
LogManager.debug('Full apiV1BaseUrl: $apiV1BaseUrl');
```

### Symptom: "Cannot GET /assets/assets/images/..."

**Likely Cause**: Double "assets/" prefix being added

**Fix**:
1. Check pubspec.yaml - remove any `- assets/assets/` entries
2. Search codebase: `grep -r "assets/" lib/ | grep -i image`
3. Ensure asset paths don't have "assets/" prefix added twice

### Symptom: "401 Unauthorized" (Expected) vs "400 Bad Request" (Error)

**What it means**:
- ✅ **401**: Good! URL is correct, just need to authenticate
- ❌ **400**: Bad! Malformed request, usually bad URL

**Action**: If getting 400, the URL format is wrong. Go back to Step 1.

---

## Files to Check

**Critical Path** (check these first):
1. `lib/core/env.dart` (line 46) - apiV1BaseUrl construction
2. `lib/core/manager/service_manager.dart` (line 210) - ApiService initialization
3. `.env.prod` - Verify API_BASE_URL has https scheme
4. `pubspec.yaml` - Check assets configuration

**Supporting Files**:
5. `lib/core/networking/http_client.dart` (line 20-22) - URL parsing
6. `lib/core/services/api_service.dart` (line 92-98) - Dio BaseOptions
7. `web/index.html` - Base href configuration

---

## Expected Outcomes After Fixes

### Before (Current State)
```
❌ Network requests: api.synaptixplay.com.i/v1/auth/refresh (400 Bad Request)
❌ Asset requests: assets/assets/images/rewards/silver.png (404 Not Found)
❌ Console errors: 18 errors, 2 warnings
❌ App functionality: Broken auth, missing images
```

### After (Goal State)
```
✅ Network requests: https://api.synaptixplay.com/api/v1/auth/refresh (401 → 200 with token)
✅ Asset requests: assets/images/rewards/silver.png (200 OK)
✅ Console errors: 0 errors, 0 warnings
✅ App functionality: Full authentication, images load properly
```

---

## Support References

- **Dio Documentation**: https://pub.dev/packages/dio
- **Flutter Web Environment**: https://flutter.dev/docs/development/platform-integration/web
- **Flutter Assets**: https://flutter.dev/docs/development/ui/assets-and-images

---

**Last Updated**: 2026-06-23  
**Priority**: 🔴 CRITICAL - Blocking feature functionality  
**Estimated Fix Time**: 30-60 minutes  
**Complexity**: Medium (requires environment debugging + code review)
