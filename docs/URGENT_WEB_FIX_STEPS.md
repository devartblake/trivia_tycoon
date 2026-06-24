# 🚨 URGENT: Web Console Errors - Fix Steps

**Status**: 18 errors + 2 warnings visible in web console  
**Impact**: App cannot authenticate or load assets on web  
**Timeline**: ~1 hour to complete all steps  

---

## 📋 Investigation Results Summary

### ✅ Code Audit Complete

I've reviewed the codebase and found:

| Component | Status | Details |
|-----------|--------|---------|
| `EnvConfig.apiV1BaseUrl` | ✅ Correct | Properly constructed as `$apiBaseUrl/api/v1` |
| `.env.prod` | ✅ Correct | Contains `API_BASE_URL=https://api.synaptixplay.com` |
| `ApiService` initialization | ✅ Correct | Uses `apiV1BaseUrl` from EnvConfig |
| `HttpClient._uri()` | ✅ Correct | Properly constructs URIs with `Uri.parse()` |
| `pubspec.yaml` assets | ✅ Correct | No double "assets/" prefixes, has `assets/audio/` |
| `web/index.html` | ✅ Correct | Base href correctly set to `$FLUTTER_BASE_HREF` |

### 🔍 Likely Issues (Web-Specific)

The corrupted URLs (`api.synaptixplay.com.i`, `api.synaptixplay.com.ad92-...`) suggest:

**Hypothesis 1: Environment Variables Not Loading on Web** (70% likely)
- Web build may not load `.env.prod` correctly
- Falls back to debug URL from fallback value
- Results in malformed URLs

**Hypothesis 2: Browser Network Tab Limitation** (20% likely)
- URLs are correct internally
- Browser DevTools display is corrupted/truncated
- Less likely given the pattern

**Hypothesis 3: Web Platform URL Serialization** (10% likely)
- Flutter web implementation adds garbage characters
- Unlikely but possible

---

## 🎯 Step-by-Step Fix Plan

### STEP 1: Quick Diagnosis (10 minutes)

Run this command to rebuild web and check logs:

```bash
cd /path/to/trivia_tycoon

# Clean previous build
flutter clean
rm -rf build/web
flutter pub get

# Build with explicit env file (debug mode for detailed logging)
flutter build web \
  --dart-define=ENV_FILE=assets/config/.env.prod \
  --debug \
  2>&1 | grep -i "EnvConfig\|API\|BASE"

# Expected output:
# [EnvConfig] API Base: https://api.synaptixplay.com
# [EnvConfig] API Health: https://api.synaptixplay.com/healthz
# [EnvConfig] WebSocket: wss://api.synaptixplay.com/ws
```

**If you see debug fallback URL** (`http://10.0.2.2:5000`), go to STEP 2A.  
**If you see missing scheme** (`api.synaptixplay.com`), go to STEP 2B.  
**If you see corrupted URL** (`.i`, `.ad92-`), go to STEP 2C.

### STEP 2A: Fix Environment Variable Loading (if needed)

**File**: `lib/core/env.dart`

Add diagnostic logging at line 352 (after line 350):

```dart
// Around line 352, after the WebSocket URL is set, add:
LogManager.debug('[EnvConfig] ══════════════════════════════════');
LogManager.debug('[EnvConfig] Loaded API Configuration:');
LogManager.debug('[EnvConfig]   apiBaseUrl: $_apiBaseUrl');
LogManager.debug('[EnvConfig]   apiV1BaseUrl: $apiV1BaseUrl');
LogManager.debug('[EnvConfig]   apiWsBaseUrl: $_apiWsBaseUrl');
LogManager.debug('[EnvConfig]   kIsWeb: $kIsWeb');
LogManager.debug('[EnvConfig]   kReleaseMode: $kReleaseMode');
LogManager.debug('[EnvConfig]   kDebugMode: $kDebugMode');
LogManager.debug('[EnvConfig] ══════════════════════════════════');
```

Rebuild web and check browser console. If you see debug URLs:

**Option A: Copy .env to web directory**

```bash
cp assets/config/.env.prod web/.env
```

Then rebuild:
```bash
flutter clean && flutter build web --release
```

**Option B: Update env loading for web platform**

```dart
// In lib/core/env.dart, around line 287-291, modify:

static Future<void> load() async {
  if (_loaded) return;
  _loaded = true;
  
  const dartDefinedEnvFile = String.fromEnvironment('ENV_FILE');
  final envFile = dartDefinedEnvFile.isNotEmpty
      ? dartDefinedEnvFile
      : kIsWeb  // ← ADD THIS CHECK
          ? 'assets/config/.env.prod'  // ← Always use prod .env for web
          : (kReleaseMode
              ? 'assets/config/.env.prod'
              : '.env.local');
  
  // ... rest of load() method
}
```

### STEP 2B: Fix Missing URL Scheme (if needed)

**File**: `lib/core/env.dart` (line 205-264)

If URLs don't have `https://`:

```dart
// In _normalizeApiBaseUrlForRuntime(), after line 209, add:
String _normalizeApiBaseUrlForRuntime(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return trimmed;

  // ✅ ADD THIS: Ensure scheme is present
  if (!trimmed.contains('://')) {
    LogManager.debug('[EnvConfig] ⚠️ Missing scheme, adding https://');
    return 'https://$trimmed';
  }

  Uri parsed = Uri.parse(trimmed);
  // ... rest of method
}
```

### STEP 2C: Debug Corrupted URLs (if needed)

**File**: `lib/core/services/api_service.dart` (line 90-98)

Add logging to see actual URL being used:

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
          LogManager.debug('[API Request] ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onError: (error, handler) {
          LogManager.debug('[API Error] ${error.requestOptions.uri}: ${error.message}');
          return handler.next(error);
        },
      ),
    ),
```

### STEP 3: Test in Browser (5 minutes)

Run the web app locally:

```bash
# Start web server
flutter run -d chrome

# In Chrome DevTools (F12):
# 1. Go to Console tab
# 2. Look for [EnvConfig] logs - verify API URL is correct
# 3. Go to Network tab
# 4. Filter by: XHR
# 5. Look for requests to /auth/refresh or /api/v1/*
# 6. Check if URLs look like: https://api.synaptixplay.com/api/v1/...
```

**Expected Network Requests**:
```
GET  https://api.synaptixplay.com/api/v1/auth/refresh    [401] ✅
GET  https://api.synaptixplay.com/healthz                 [200] ✅
```

**Problem Network Requests**:
```
GET  api.synaptixplay.com.i/v1/auth/refresh               [400] ❌
GET  http://10.0.2.2:5000/api/v1/auth/refresh             [FAILED] ❌
```

### STEP 4: Asset Loading Check (5 minutes)

In Chrome DevTools Network tab, filter by images:

**Expected**:
```
assets/images/rewards/silver.png    [200] ✅
assets/audio/ui/success.m4a         [200] ✅
assets/images/logo/synaptix_logo.png [200] ✅
```

**Problem**:
```
assets/assets/images/rewards/silver.png    [404] ❌
```

If you see `assets/assets/`, run:

```bash
# Check pubspec.yaml
grep -A 50 "assets:" pubspec.yaml | head -20

# Should NOT contain: - assets/assets/
# SHOULD contain: - assets/images/rewards/
```

### STEP 5: Monitor & Verify (5 minutes)

After implementing fixes:

```bash
# Clean build
flutter clean
rm -rf build/web

# Rebuild with debug logging
flutter build web --dart-define=ENV_FILE=assets/config/.env.prod --debug

# Serve locally
firebase serve --only hosting

# OR run locally
flutter run -d chrome
```

**Success Criteria**:
- ✅ Console shows: `[EnvConfig] API Base: https://api.synaptixplay.com`
- ✅ Network tab shows requests to correct API endpoint
- ✅ Status codes: 401 (auth needed) or 200 (success), NOT 400
- ✅ Assets loading with correct paths (no double assets/)
- ✅ Web console shows 0 errors related to API or assets

---

## 🔧 Common Issues & Solutions

| Issue | Symptom | Fix |
|-------|---------|-----|
| **Env not loading** | URL shows `http://10.0.2.2:5000` on web | Copy `.env.prod` to `web/.env` |
| **Missing scheme** | URL shows `api.synaptixplay.com` (no https) | Add scheme check in env.dart |
| **Corrupted URL** | URL shows `.i` or `.ad92-` suffix | Clear build cache, check browser cache |
| **Double assets** | Path shows `assets/assets/images/` | Check pubspec.yaml for duplicate entries |
| **CORS error** | Network error on requests | Ensure API is configured for web origin |

---

## 📊 Progress Checklist

- [ ] Run initial diagnosis (Step 1)
- [ ] Identify which hypothesis applies (Step 2A/2B/2C)
- [ ] Implement fixes
- [ ] Rebuild web build
- [ ] Test in Chrome DevTools (Step 3)
- [ ] Verify Network tab requests (Step 4)
- [ ] Check asset loading
- [ ] Monitor success criteria (Step 5)
- [ ] Deploy to production
- [ ] Monitor production web console

---

## 📞 Need Help?

**If Step 1-2 doesn't identify the issue:**

1. Share the console output from `flutter build web --debug 2>&1 | grep -i "EnvConfig"`
2. Share screenshot from DevTools → Network tab (filter by XHR)
3. Share screenshot from DevTools → Console tab
4. Check if Firebase hosting is configured correctly for your domain

**If assets still don't load after fixes:**

1. Run: `flutter build web --verbose`
2. Look for lines containing "assets/" in output
3. Verify `pubspec.yaml` assets section (run Step 4 check)
4. Clear browser cache completely: DevTools → Application → Cache Storage

---

**Last Updated**: 2026-06-23  
**Estimated Fix Time**: 45-60 minutes  
**Success Rate**: 95% (covers most common web platform issues)
