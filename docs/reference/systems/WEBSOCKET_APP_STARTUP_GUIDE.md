# WEBSOCKET APP STARTUP INTEGRATION
## Add WebSocket to app_init.dart

---

## 🎯 Goal

Add WebSocket connection to app startup so it's available throughout the app lifecycle.

**What we'll do:**
1. Initialize WebSocket in `app_init.dart`
2. Connect after user login
3. Manage lifecycle (pause/resume)
4. Handle reconnection automatically

---

## 📁 STEP 1: Update app_init.dart (15 minutes)

### File: `lib/core/bootstrap/app_init.dart`

**Add these imports** at the top:

```dart
// Add with other imports
import '../networking/ws_client.dart';
import '../networking/http_client.dart';
import '../networking/tycoon_api_client.dart';
import '../services/auth_http_client.dart';
```

**Add WebSocket static variables** after line 31:

```dart
class AppInit {
  static bool _backgroundServicesReady = false;
  static SpinAnalyticsTracker? _spinAnalyticsTracker;
  static SpinAnalyticsTracker? get spinAnalyticsTracker => _spinAnalyticsTracker;
  
  // ✅ ADD THESE - WebSocket management
  static WsClient? _wsClient;
  static WsClient? get wsClient => _wsClient;
  static bool _wsConnected = false;
```

**Add WebSocket initialization method** (add after `initialize` method, around line 84):

```dart
  /// Initialize WebSocket connection
  /// Should be called after user login
  static Future<void> initializeWebSocket(AuthTokenStore tokenStore) async {
    try {
      debugPrint('[AppInit] Initializing WebSocket...');
      
      // Get auth token
      final session = tokenStore.load();
      if (!session.hasTokens) {
        debugPrint('[AppInit] No auth token, skipping WebSocket');
        return;
      }
      
      // Determine WebSocket URL based on environment
      final wsUrl = EnvConfig.apiWsBaseUrl;
      
      // Create WebSocket client
      _wsClient = WsClient(
        url: wsUrl,
        onMessage: (message) {
          debugPrint('[WS] ← ${message.op}');
          // Messages will be handled by specific services
        },
        onStateChange: (state) {
          debugPrint('[WS] State: $state');
          _wsConnected = (state == WsState.connected);
        },
        onError: (error) {
          debugPrint('[WS] Error: $error');
        },
      );
      
      // Connect
      await _wsClient!.connect();
      debugPrint('[AppInit] WebSocket initialized');
      
    } catch (e) {
      debugPrint('[AppInit] WebSocket initialization failed: $e');
    }
  }
  
  /// Disconnect WebSocket
  static Future<void> disconnectWebSocket() async {
    if (_wsClient != null) {
      debugPrint('[AppInit] Disconnecting WebSocket...');
      await _wsClient!.disconnect();
      _wsClient = null;
      _wsConnected = false;
    }
  }
  
  /// Reconnect WebSocket (for app resume)
  static Future<void> reconnectWebSocket() async {
    if (_wsClient != null && !_wsConnected) {
      debugPrint('[AppInit] Reconnecting WebSocket...');
      await _wsClient!.reconnect();
    }
  }
  
  /// Check if WebSocket is connected
  static bool get isWebSocketConnected => _wsConnected;
```

**Update `_initializeUserSession`** (around line 171) to connect WebSocket after login:

```dart
  static Future<void> _initializeUserSession(ServiceManager serviceManager, ProviderContainer? container) async {
    try {
      final isLoggedIn = await serviceManager.authService.isLoggedIn();
      if (container != null) {
        container.read(isLoggedInSyncProvider.notifier).state = isLoggedIn;
      }
      
      if (isLoggedIn) {
        await _loadUserProfile(serviceManager, container);
        
        // ✅ ADD THIS - Initialize WebSocket after login
        final authService = serviceManager.authService;
        if (authService is AuthService) {
          await initializeWebSocket(authService.tokenStore);
        }
      }
    } catch (e) {
      debugPrint('[AppInit] Session check failed: $e');
    }
  }
```

---

## 📁 STEP 2: Update app_launcher.dart (10 minutes)

### File: `lib/core/bootstrap/app_launcher.dart`

**Update `didChangeAppLifecycleState`** (around line 49) to manage WebSocket:

```dart
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final serviceManager = widget.initialData.$1;

    switch (state) {
      case AppLifecycleState.resumed:
        AppInit.trackAppLifecycle(serviceManager, 'app_resumed');
        _checkSpinStatusOnResume();
        
        // ✅ ADD THIS - Reconnect WebSocket
        AppInit.reconnectWebSocket();
        break;
        
      case AppLifecycleState.paused:
        AppInit.trackAppLifecycle(serviceManager, 'app_paused');
        _flushAnalyticsOnPause();
        
        // ✅ ADD THIS - Disconnect WebSocket to save battery
        AppInit.disconnectWebSocket();
        break;
        
      case AppLifecycleState.inactive:
        AppInit.trackAppLifecycle(serviceManager, 'app_inactive');
        break;
        
      case AppLifecycleState.detached:
        AppInit.trackAppLifecycle(serviceManager, 'app_detached');
        
        // ✅ ADD THIS - Cleanup on app close
        AppInit.disconnectWebSocket();
        break;
        
      case AppLifecycleState.hidden:
        AppInit.trackAppLifecycle(serviceManager, 'app_hidden');
        break;
    }
  }
```

---

## 📁 STEP 3: Update EnvConfig for WebSocket URL (5 minutes)

### File: `lib/core/env.dart`

**Add WebSocket URL** to EnvConfig:

```dart
class EnvConfig {
  static String apiBaseUrl = '';
  static String apiWsBaseUrl = ''; // ✅ ADD THIS
  
  static Future<void> load() async {
    // Existing code...
    apiBaseUrl = dotenv.get('API_BASE_URL', fallback: 'http://localhost:5000');
    
    // ✅ ADD THIS - Derive WebSocket URL from HTTP URL
    // Convert http:// to ws:// and https:// to wss://
    apiWsBaseUrl = apiBaseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://') + '/ws';
    
    debugPrint('[EnvConfig] API Base: $apiBaseUrl');
    debugPrint('[EnvConfig] WebSocket: $apiWsBaseUrl');
  }
}
```

**OR if you have separate WS URL in .env:**

```dart
// In EnvConfig.load()
apiWsBaseUrl = dotenv.get('API_WS_BASE_URL', 
    fallback: apiBaseUrl.replaceFirst('http://', 'ws://') + '/ws');
```

**Update .env file:**
```bash
# .env
API_BASE_URL=http://10.0.2.2:5000
API_WS_BASE_URL=ws://10.0.2.2:5000/ws
```

---

## 📁 STEP 4: Update Login to Connect WebSocket (5 minutes)

### File: `lib/screens/login_screen.dart`

**After successful login** (around line 228), add WebSocket initialization:

```dart
  if (ConfigService.useBackendAuth) {
    if (_isSignUpMode) {
      await authOps.signup(email, password);
    } else {
      await authOps.loginWithPassword(email, password);
    }
    
    // ✅ ADD THIS - Initialize WebSocket after successful login
    final authService = ref.read(authServiceProvider);
    if (authService.secureStorage != null) {
      // Get token store from service manager or provider
      final serviceManager = ref.read(serviceManagerProvider);
      await AppInit.initializeWebSocket(
        serviceManager.authService.tokenStore
      );
    }
  }
```

---

## 📁 STEP 5: Create Global WebSocket Provider (Optional - 5 minutes)

### File: `lib/game/providers/riverpod_providers.dart`

**Add provider** for easy access throughout app:

```dart
/// Global WebSocket client provider
final globalWsClientProvider = Provider<WsClient?>((ref) {
  return AppInit.wsClient;
});

/// WebSocket connection status provider
final wsConnectionStatusProvider = StateProvider<bool>((ref) {
  return AppInit.isWebSocketConnected;
});
```

**Usage in any screen:**
```dart
// Check if connected
final wsConnected = ref.watch(wsConnectionStatusProvider);

// Get client to send messages
final wsClient = ref.read(globalWsClientProvider);
if (wsClient != null) {
  wsClient.send(WsEnvelope(...));
}
```

---

## ✅ VERIFICATION CHECKLIST

After implementation:

### 1. Compile Check
```bash
flutter pub get
flutter analyze
```
**Expected:** No errors ✅

### 2. Run and Check Logs
```bash
flutter run
```

**Look for these logs:**
```
[AppInit] Initializing WebSocket...
[WS] State: connecting
[WS] State: connected
[AppInit] WebSocket initialized
```

### 3. Test Lifecycle
- **App pause:** Should see `[AppInit] Disconnecting WebSocket...`
- **App resume:** Should see `[AppInit] Reconnecting WebSocket...`

### 4. Test Login Flow
- Login successfully
- Should see WebSocket connect after login
- Check connection status

---

## 🧪 TESTING

### Test 1: Login Flow
```dart
1. Start app (not logged in)
2. Login with valid credentials
3. Check logs for WebSocket connection
```
**Expected:** WebSocket connects after login ✅

### Test 2: Logout Flow
```dart
1. Be logged in with WebSocket connected
2. Logout
3. Check logs for WebSocket disconnect
```
**Expected:** WebSocket disconnects on logout ✅

### Test 3: App Lifecycle
```dart
1. App running, WebSocket connected
2. Put app in background (pause)
3. Resume app
4. Check logs
```
**Expected:** 
- Pause: Disconnect
- Resume: Reconnect ✅

### Test 4: Reconnection
```dart
1. Turn off wifi/mobile data
2. Check logs for connection error
3. Turn back on
4. Check logs for reconnection
```
**Expected:** Auto-reconnects ✅

---

## 📊 MONITORING

### Add Debug Widget (Optional)

Create a debug overlay to monitor WebSocket:

```dart
class WebSocketDebugOverlay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wsConnected = ref.watch(wsConnectionStatusProvider);
    
    return Positioned(
      top: 40,
      right: 10,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: wsConnected ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          wsConnected ? 'WS: Connected' : 'WS: Disconnected',
          style: TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }
}
```

**Add to app in debug mode only:**
```dart
// In app_launcher.dart build method
children: [
  if (child != null) child,
  const PowerUpHUDOverlay(),
  if (!const bool.fromEnvironment('dart.vm.product'))
    const WebSocketDebugOverlay(), // ✅ Debug only
],
```

---

## 🚨 TROUBLESHOOTING

### Issue: "WebSocket won't connect"
**Check:**
1. Backend is running
2. WebSocket URL is correct
3. User is logged in
4. Auth token is valid

**Fix:**
```dart
// Check logs for exact error
debugPrint('[WS] URL: ${EnvConfig.apiWsBaseUrl}');
debugPrint('[WS] Token: ${session.accessToken.substring(0, 10)}...');
```

### Issue: "Connection refused"
**Check .env:**
```bash
# Android emulator
API_WS_BASE_URL=ws://10.0.2.2:5000/ws

# iOS simulator
API_WS_BASE_URL=ws://localhost:5000/ws

# Physical device
API_WS_BASE_URL=ws://YOUR_COMPUTER_IP:5000/ws
```

### Issue: "WebSocket not reconnecting"
**Check:**
```dart
// Make sure auto-reconnect is enabled
_wsClient = WsClient(
  url: wsUrl,
  // ... other params
);
// Default is auto-reconnect: true
```

### Issue: "App crashes on pause"
**Fix:**
```dart
// Make sure null check before disconnect
if (_wsClient != null) {
  await _wsClient!.disconnect();
}
```

---

## 📁 COMPLETE CODE SUMMARY

### Files Modified:
1. `lib/core/bootstrap/app_init.dart` - WebSocket initialization
2. `lib/core/bootstrap/app_launcher.dart` - Lifecycle management
3. `lib/core/env.dart` - WebSocket URL config
4. `lib/screens/login_screen.dart` - Connect on login
5. `lib/game/providers/riverpod_providers.dart` - Global provider

### Files Created:
- None (uses existing Sprint 2 files)

---

## ⏱️ TIME ESTIMATE

- app_init.dart modifications: 15 min
- app_launcher.dart modifications: 10 min  
- env.dart modifications: 5 min
- login_screen.dart modifications: 5 min
- riverpod_providers.dart: 5 min
- Testing: 10 min

**Total: 50 minutes**

---

## ✅ SUCCESS CRITERIA

WebSocket integration complete when:

- [ ] WebSocket connects on login
- [ ] Disconnects on logout
- [ ] Disconnects on app pause
- [ ] Reconnects on app resume
- [ ] Auto-reconnects on connection loss
- [ ] Logs show all events
- [ ] No crashes or errors
- [ ] Global provider accessible

---

## 🎯 NEXT STEPS

After WebSocket is in app startup:

1. **Use in Presence Service** (Quick win - 3 hours)
2. **Use in Group Chat** (High impact - 4 hours)
3. **Use in Leaderboard** (Engagement boost - 2 hours)

**See WEBSOCKET_INTEGRATION_ANALYSIS.md for full roadmap**

---

This gets WebSocket connected and ready to use throughout your app! 🚀
