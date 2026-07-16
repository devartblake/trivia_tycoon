# API Endpoints Verification Guide

This guide helps verify that all API endpoints in your Flutter app are correctly configured for the target environment (development, staging, production).

---

## Quick Verification

### Before Building

1. **Check Environment File**
   ```bash
   # For production
   cat assets/config/.env.prod
   
   # Should show:
   # API_BASE_URL=https://api.synaptixplay.com
   # (NOT localhost, 10.0.2.2, or 127.0.0.1)
   ```

2. **Validate Configuration**
   ```bash
   dart scripts/validate_release_build.dart
   ```

3. **Check EnvConfig**
   ```dart
   // lib/core/env.dart loads from .env.prod in release mode
   // Debug mode uses .env.local (for local development)
   ```

---

## API Endpoint Checklist

### Authentication Endpoints

- [ ] **Login**
  - Endpoint: `/api/v1/auth/login`
  - URL: `https://api.synaptixplay.com/api/v1/auth/login`
  - Method: POST
  - **Production Check**: Verify HTTPS, not HTTP

- [ ] **Signup**
  - Endpoint: `/api/v1/auth/signup`
  - URL: `https://api.synaptixplay.com/api/v1/auth/signup`
  - Method: POST

- [ ] **Token Refresh**
  - Endpoint: `/api/v1/auth/refresh`
  - URL: `https://api.synaptixplay.com/api/v1/auth/refresh`
  - Method: POST
  - **Production Check**: Requires valid JWT

- [ ] **Logout**
  - Endpoint: `/api/v1/auth/logout`
  - URL: `https://api.synaptixplay.com/api/v1/auth/logout`
  - Method: POST

### User Endpoints

- [ ] **Get Current User**
  - Endpoint: `/api/v1/users/me`
  - URL: `https://api.synaptixplay.com/api/v1/users/me`
  - Method: GET

- [ ] **Get User Wallet**
  - Endpoint: `/api/v1/users/me/wallet`
  - URL: `https://api.synaptixplay.com/api/v1/users/me/wallet`
  - Method: GET

- [ ] **Update User Profile**
  - Endpoint: `/api/v1/users/me`
  - URL: `https://api.synaptixplay.com/api/v1/users/me`
  - Method: PATCH

### Quiz/Match Endpoints

- [ ] **Get Questions**
  - Endpoint: `/api/v1/questions/set`
  - URL: `https://api.synaptixplay.com/api/v1/questions/set`
  - Method: GET

- [ ] **Start Match**
  - Endpoint: `/api/v1/matches/start`
  - URL: `https://api.synaptixplay.com/api/v1/matches/start`
  - Method: POST

- [ ] **Submit Match Results**
  - Endpoint: `/api/v1/matches/submit`
  - URL: `https://api.synaptixplay.com/api/v1/matches/submit`
  - Method: POST

### Leaderboard/Social Endpoints

- [ ] **Get Leaderboard**
  - Endpoint: `/api/v1/leaderboard`
  - URL: `https://api.synaptixplay.com/api/v1/leaderboard`
  - Method: GET

- [ ] **Get Friends**
  - Endpoint: `/api/v1/social/friends`
  - URL: `https://api.synaptixplay.com/api/v1/social/friends`
  - Method: GET

### WebSocket/SignalR Endpoints

- [ ] **WebSocket Base**
  - Endpoint: `/ws`
  - URL: `wss://api.synaptixplay.com/ws`
  - Protocol: WebSocket over HTTPS

- [ ] **Match Hub**
  - Endpoint: `/ws/match`
  - URL: `wss://api.synaptixplay.com/ws/match`
  - Hub: SignalR

- [ ] **Presence Hub**
  - Endpoint: `/ws/presence`
  - URL: `wss://api.synaptixplay.com/ws/presence`
  - Hub: SignalR

- [ ] **Notify Hub**
  - Endpoint: `/ws/notify`
  - URL: `wss://api.synaptixplay.com/ws/notify`
  - Hub: SignalR

---

## Runtime Verification

### Test on Device

```dart
// You can add this temporarily to test (remove before production)
print('API Base URL: ${EnvConfig.apiBaseUrl}');
print('WebSocket URL: ${EnvConfig.apiWsBaseUrl}');
print('Match Hub: ${EnvConfig.matchHubUrl}');
```

### Check Network Tab (Web)

1. Open Chrome DevTools (F12)
2. Go to "Network" tab
3. Perform login action
4. Check that requests go to:
   - `https://api.synaptixplay.com/api/v1/...` (NOT localhost)
5. Check WebSocket connections show `wss://` (NOT `ws://`)

### Check Network Monitor (Android)

1. Install Android Studio Network Monitor
2. Run app with `flutter run --release`
3. Check real-time network requests
4. Verify all API calls go to production host

### Check Console Logs (iOS)

1. Run on real iPhone
2. Connect Xcode
3. Check console for any connection warnings
4. Verify no localhost URLs in logs

---

## Environment-Specific URLs

### Development (Local)

```
HTTP API:      http://10.0.2.2:5000 (Android Emulator)
HTTP API:      http://localhost:5000 (Web/Desktop)
WebSocket:     ws://10.0.2.2:5000/ws
```

### Staging

```
HTTPS API:     https://staging-api.synaptixplay.com
WebSocket:     wss://staging-api.synaptixplay.com/ws
Certificate:   Valid staging cert
```

### Production

```
HTTPS API:     https://api.synaptixplay.com
WebSocket:     wss://api.synaptixplay.com/ws
Certificate:   Valid production cert (*.synaptixplay.com)
```

---

## Validation Script

The automated validator checks for:

```dart
// Patterns that trigger warnings:
- 'localhost URL': RegExp(r'http://localhost|localhost:\d+'),
- '10.0.2.2': RegExp(r'10\.0\.2\.2'),
- 'hardcoded IP': RegExp(r'http://\d+\.\d+\.\d+\.\d+'),
```

Run before building:
```bash
dart scripts/validate_release_build.dart
```

---

## Common Issues & Fixes

### Issue: "API Connection Refused"

**Cause**: App trying to reach localhost instead of production

**Fix**:
1. Check `.env.prod` file
2. Verify `API_BASE_URL=https://api.synaptixplay.com`
3. Rebuild with `flutter build <platform> --release`

### Issue: "Invalid Certificate"

**Cause**: Using HTTP instead of HTTPS, or cert mismatch

**Fix**:
1. Ensure all URLs use `https://` and `wss://`
2. Verify cert is valid: `openssl s_client -connect api.synaptixplay.com:443`
3. Check cert expiration date

### Issue: "WebSocket Connection Failed"

**Cause**: Using `ws://` instead of `wss://`, or wrong host

**Fix**:
1. Check `API_WS_BASE_URL` uses `wss://` (secure)
2. Verify hub URLs (match, presence, notify)
3. Check firewall isn't blocking WebSocket

### Issue: "Still seeing localhost in logs"

**Cause**: Debug build using .env.local instead of .env.prod

**Fix**:
1. Use `flutter run --release` instead of debug
2. Or: `flutter build <platform> --release`
3. Verify LogManager suppresses debug logs in release mode

---

## Automated Testing

Create a simple API test to verify endpoints:

```dart
// test/api_endpoints_test.dart
import 'package:synaptix/core/env.dart';

void main() {
  test('Production endpoints are configured', () {
    expect(EnvConfig.apiBaseUrl, 'https://api.synaptixplay.com');
    expect(EnvConfig.apiWsBaseUrl, contains('wss://'));
    expect(EnvConfig.matchHubUrl, contains('api.synaptixplay.com'));
    
    // Ensure no localhost
    expect(EnvConfig.apiBaseUrl, isNot(contains('localhost')));
    expect(EnvConfig.apiBaseUrl, isNot(contains('10.0.2.2')));
  });
  
  test('WebSocket URLs use secure protocol', () {
    expect(EnvConfig.apiWsBaseUrl.startsWith('wss://'), true);
    expect(EnvConfig.matchHubUrl.startsWith('wss://'), true);
  });
}
```

Run test:
```bash
flutter test test/api_endpoints_test.dart
```

---

## Pre-Release API Checklist

- [ ] **DNS Resolution**
  ```bash
  nslookup api.synaptixplay.com
  # Should resolve to correct IP
  ```

- [ ] **SSL Certificate**
  ```bash
  openssl s_client -connect api.synaptixplay.com:443 -showcerts
  # Check: certificate is valid, CN matches domain
  ```

- [ ] **API Health**
  ```bash
  curl -v https://api.synaptixplay.com/healthz
  # Should return 200 OK
  ```

- [ ] **WebSocket Connectivity**
  ```bash
  # Use WebSocket client to test
  # ws://echo.websocket.org (for testing)
  # wss://api.synaptixplay.com/ws (for production)
  ```

- [ ] **CORS Headers** (for Web)
  ```bash
  curl -I https://api.synaptixplay.com
  # Check for proper CORS headers
  ```

---

## Documentation Links

- [Flutter Network Configuration](https://flutter.dev/docs/cookbook/networking)
- [Environment Variables Guide](../lib/core/env.dart)
- [Release Build Checklist](../RELEASE_CHECKLIST.md)
- [Build Validation Script](../scripts/validate_release_build.dart)

---

**Last Updated**: June 26, 2026  
**Version**: 1.0
