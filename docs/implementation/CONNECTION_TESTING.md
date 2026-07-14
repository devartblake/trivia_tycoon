# Connection Testing Guide

This guide explains how to verify backend API connectivity across different platforms and environments.

## Overview

Connection testing ensures the app can reach the backend API and perform essential operations. Tests cover:
- Network connectivity
- DNS resolution
- TLS/SSL certificate validation
- gRPC connections
- WebSocket connections
- API health checks

## Prerequisites

- Flutter SDK installed
- Backend API running
- Network access to backend host
- (Optional) Network debugging tools: curl, netcat, tcpdump

## Quick Connection Verification

### 1. Check API Health Endpoint

```bash
# Verify API is running and responding
curl -v https://api.example.com/healthz

# Expected response: 200 OK
# Example output:
# < HTTP/2 200
# < content-type: application/json
# {"status":"healthy","timestamp":"2024-06-22T10:00:00Z"}
```

### 2. Test DNS Resolution

```bash
# Verify DNS can resolve the API domain
nslookup api.example.com
# or
dig api.example.com

# Expected: Resolves to your API IP address
```

### 3. Test Network Connectivity

```bash
# Ping API host
ping api.example.com

# Check port accessibility
nc -zv api.example.com 443  # HTTPS
nc -zv api.example.com 5001 # gRPC

# Expected: Connection successful or "succeeded"
```

## Testing on Android Emulator

### Setup Local Backend

1. **Start backend on host machine**:
   ```bash
   dotnet run -c Release --urls "http://+:5000;grpc://+:5001"
   ```

2. **Verify host machine IP** (from emulator perspective):
   - Android emulator uses `10.0.2.2` to reach host machine
   - EnvConfig automatically uses this address

3. **Run debug build**:
   ```bash
   flutter run -d emulator-5554 --dart-define=ENV_FILE=.env.local
   ```

4. **Watch logs for connection**:
   ```bash
   flutter logs | grep -i "env\|health\|connection"
   ```

### Expected Log Output

```
[EnvConfig] API Base: http://10.0.2.2:5000
[EnvConfig] API Health: http://10.0.2.2:5000/healthz
[EnvConfig] WebSocket: ws://10.0.2.2:5000/ws
[EnvConfig] gRPC: 10.0.2.2:5001 (no TLS)
✓ Health check passed
✓ Connected to backend
```

### Troubleshooting Android Emulator

**Problem**: Connection refused on localhost:5000

**Solution**:
```bash
# Verify host is reachable from emulator
adb shell ping 10.0.2.2

# Check if backend is listening on all interfaces
netstat -tlnp | grep 5000

# If not listening on 0.0.0.0, restart backend with:
dotnet run -c Release --urls "http://+:5000"  # The + means all interfaces
```

## Testing on iOS Simulator

### Setup Local Backend

iOS Simulator runs on the same machine as the backend, so use `localhost`:

1. **Create `.env.ios` for simulator**:
   ```env
   API_BASE_URL=http://localhost:5000
   API_WS_BASE_URL=http://localhost:5000/ws
   ```

2. **Run simulator build**:
   ```bash
   flutter run -d iPhone-14 --dart-define=ENV_FILE=.env.ios
   ```

### Known iOS Issues

**Problem**: "Network connection refused"

**Solution**:
```bash
# Verify backend is listening on localhost
lsof -i :5000

# If not found, backend isn't running
# Restart backend: dotnet run
```

**Problem**: WebSocket connection times out

**Solution**:
```bash
# Test WebSocket directly
curl -i -N -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  http://localhost:5000/ws

# Should return 101 Switching Protocols
```

## Testing on Physical Devices

### Setup for LAN Testing

For testing on real Android/iOS devices on your local network:

1. **Find your machine's IP**:
   ```bash
   # macOS/Linux
   ifconfig | grep "inet " | grep -v 127.0.0.1

   # Windows
   ipconfig | findstr "IPv4"
   ```
   Example: `192.168.1.100`

2. **Create `.env.lan`**:
   ```env
   API_BASE_URL=http://192.168.1.100:5000
   API_WS_BASE_URL=http://192.168.1.100:5000/ws
   ```

3. **Ensure backend listens on all interfaces**:
   ```bash
   dotnet run -c Release --urls "http://+:5000"
   ```

4. **Verify connectivity from device**:
   ```bash
   # From device terminal/adb
   adb shell ping 192.168.1.100
   adb shell curl -v http://192.168.1.100:5000/healthz
   ```

5. **Run on physical device**:
   ```bash
   flutter run -d device-id --dart-define=ENV_FILE=.env.lan
   ```

### Network Issues Checklist

- [ ] Firewall allows port 5000 (and 5001 for gRPC)
- [ ] Backend listens on `0.0.0.0` not just `127.0.0.1`
- [ ] Device and machine are on same WiFi network
- [ ] No VPN blocking local network access
- [ ] Correct IP address used (not localhost or 127.0.0.1)

## Testing on Web

### Local Web Testing

```bash
# Run web build against local backend
flutter run -d chrome --dart-define=ENV_FILE=.env.local

# EnvConfig automatically rewrites:
# 10.0.2.2 → localhost
# So http://10.0.2.2:5000 becomes http://localhost:5000
```

### CORS Issues (Common for Web)

If you see CORS errors in browser console:

1. **Verify backend CORS configuration**:
   ```csharp
   // In Startup.cs or Program.cs
   services.AddCors(options => options.AddPolicy("AllowLocalhost",
     builder => builder
       .WithOrigins("http://localhost:3000", "http://localhost:5000")
       .AllowAnyMethod()
       .AllowAnyHeader()
       .AllowCredentials()
   ));
   ```

2. **Check browser console** (DevTools → Console):
   ```
   Access to XMLHttpRequest at 'http://localhost:5000/api/...'
   from origin 'http://localhost:3000' has been blocked by CORS policy
   ```

3. **Test with curl** (CORS doesn't apply):
   ```bash
   curl -i -X GET http://localhost:5000/api/v1/player/profile
   ```

## Testing WebSocket Connections

### Test WebSocket Manually

```bash
# Using wscat (install: npm install -g wscat)
wscat -c ws://localhost:5000/ws

# Or using curl
curl -i -N -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  http://localhost:5000/ws

# Expected: 101 Switching Protocols
```

### Monitor WebSocket Traffic

```bash
# Using tcpdump (requires sudo)
sudo tcpdump -i lo -n 'tcp port 5000'

# Using Wireshark GUI (better visualization)
# Filter: tcp.port == 5000
```

## Testing gRPC Connections

### Test gRPC Connection

```bash
# Using grpcurl (install: go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest)
grpcurl -plaintext localhost:5001 list

# If running with TLS:
grpcurl localhost:5001 list
# (grpcurl uses system cert store by default)
```

### Common gRPC Issues

**Problem**: "connection refused"

**Solution**:
```bash
# Verify gRPC port is listening
netstat -tlnp | grep 5001

# If not found, backend isn't listening on gRPC port
# Restart with both ports: --urls "http://+:5000;grpc://+:5001"
```

**Problem**: "TLS handshake failure"

**Solution**:
```bash
# For local development, disable TLS
export GRPC_USE_TLS=false

# For production, verify certificate
openssl s_client -connect api.example.com:5001
```

## Testing API Endpoints

### Test Authentication

```bash
# Get auth token
curl -X POST http://localhost:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"password"}'

# Expected response:
# {"token":"eyJhbGc...","expiresIn":3600}
```

### Test Player Profile

```bash
# Get player profile (requires valid token)
curl -X GET http://localhost:5000/api/v1/player/profile \
  -H "Authorization: Bearer YOUR_TOKEN"

# Expected response:
# {"id":"...","name":"...","level":1,...}
```

### Test Quiz Endpoint

```bash
# Start a quiz
curl -X POST http://localhost:5000/api/v1/quiz/start \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"category":"general","difficulty":"medium"}'

# Expected response:
# {"quizId":"...","questions":[...],"timeLimit":30}
```

## Automated Connection Tests

Create `test/connection_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:synaptix/core/env.dart';

void main() {
  group('Backend Connection Tests', () {
    setUpAll(() async {
      await EnvConfig.load();
    });

    test('API health endpoint responds', () async {
      final response = await http.get(
        Uri.parse(EnvConfig.apiHealthUrl),
      ).timeout(const Duration(seconds: 10));

      expect(response.statusCode, 200);
      expect(response.body, contains('healthy'));
    });

    test('WebSocket endpoint is accessible', () async {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(EnvConfig.apiWsBaseUrl));
      request.headers['Connection'] = 'Upgrade';
      request.headers['Upgrade'] = 'websocket';

      final response = await client.send(request)
          .timeout(const Duration(seconds: 10));

      expect(response.statusCode, anyOf([101, 200])); // 101 for WebSocket upgrade or 200
      client.close();
    });

    test('gRPC host is reachable', () async {
      // This test verifies DNS resolution
      final host = EnvConfig.grpcHost;
      expect(host, isNotEmpty);
      expect(host, isNotEqual('localhost')); // Should be actual host
    });
  });
}
```

Run tests:

```bash
flutter test test/connection_test.dart
```

## Performance Testing

### Measure Response Times

```bash
# Time an API call
time curl -s http://localhost:5000/api/v1/player/profile \
  -H "Authorization: Bearer TOKEN" > /dev/null

# Expected: < 500ms for local backend

# For production
time curl -s https://api.synaptixplay.com/api/v1/player/profile \
  -H "Authorization: Bearer TOKEN" > /dev/null

# Expected: < 2000ms over internet
```

### Load Testing

```bash
# Using Apache Bench (macOS/Linux)
ab -c 10 -n 100 http://localhost:5000/healthz

# Using hey (more flexible)
hey -c 10 -n 100 http://localhost:5000/healthz

# Results should show request/second and latency distribution
```

## Debugging Connection Issues

### Enable Verbose Logging

```bash
flutter run -v  # Verbose mode

# Filter for network logs
flutter logs -v | grep -i "http\|network\|socket"
```

### Proxy Traffic for Inspection

Use Charles Proxy or Fiddler:

1. **Install proxy** (Charles for macOS/Linux)
2. **Configure device to use proxy**:
   - Android: Settings → WiFi → Advanced → Proxy
   - iOS: Settings → WiFi → HTTP Proxy
3. **Monitor traffic** in proxy dashboard

### Test with Different Environments

```bash
# Test against staging
flutter run --dart-define=ENV_FILE=assets/config/.env.staging

# Test against production
flutter run --dart-define=ENV_FILE=assets/config/.env.prod
```

## Connection Testing Checklist

Before releasing:

- [ ] API health endpoint responds
- [ ] WebSocket connection establishes
- [ ] gRPC channel connects (with/without TLS as configured)
- [ ] Authentication works end-to-end
- [ ] Player profile loads correctly
- [ ] Quiz data retrieval works
- [ ] Network errors are handled gracefully
- [ ] Timeout handling works (simulate with tc command)
- [ ] Offline mode handles errors appropriately

## Related Documentation

- `ENV_SETUP.md` - Environment configuration
- `BUILD_AND_DEPLOY.md` - Build and deployment
- `lib/core/env.dart` - EnvConfig implementation
- `lib/core/services/api_service.dart` - API client
