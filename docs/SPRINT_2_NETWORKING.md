# SPRINT 2: Complete Networking Layer
## HTTP Client + WebSocket + API Integration (1 hour)

---

## 🎯 Goal
Implement production-ready networking with:
- ✅ HTTP wrapper around AuthHttpClient
- ✅ WebSocket client with reconnection
- ✅ Message reliability (ACK/retry)
- ✅ Enhanced API client

**Prerequisites:**
- Sprint 1 complete (AuthHttpClient + error messages)
- Backend running (for testing)

---

## 📁 Files to Create/Update

### New Files (Copy these):
1. `lib/core/networkting/http_client.dart` - HTTP wrapper
2. `lib/core/networkting/ws_client.dart` - WebSocket client
3. `lib/core/networkting/ws_reliability.dart` - Reliability layer
4. `lib/core/networkting/tycoon_api_client.dart` - Enhanced API client

### Dependencies to Add:
```yaml
# pubspec.yaml
dependencies:
  web_socket_channel: ^2.4.0
  uuid: ^4.0.0
```

Run:
```bash
flutter pub get
```

---

## Step 1: Copy Networking Files (10 minutes)

### 1.1: HTTP Client
```bash
cp http_client.dart lib/core/networkting/http_client.dart
```

**What it does:**
- Wraps AuthHttpClient for convenience
- Provides JSON helpers (getJson, postJson, etc.)
- Automatic error handling
- Type-safe responses

### 1.2: WebSocket Client
```bash
cp ws_client.dart lib/core/networkting/ws_client.dart
```

**What it does:**
- Auto-reconnection with exponential backoff
- Connection state management
- Heartbeat/ping-pong
- Message streaming

### 1.3: WebSocket Reliability
```bash
cp ws_reliability.dart lib/core/networkting/ws_reliability.dart
```

**What it does:**
- Message acknowledgments
- Automatic retries
- Duplicate detection
- Sequence tracking

### 1.4: Enhanced API Client
```bash
cp tycoon_api_client_enhanced.dart lib/core/networkting/tycoon_api_client.dart
```

**What it does:**
- High-level API methods
- Quiz, leaderboard, profile, matches
- Store, achievements, analytics
- Type-safe responses

---

## Step 2: Add Providers (15 minutes)

### File: `lib/game/providers/riverpod_providers.dart`

**Add these imports:**
```dart
import '../../core/networkting/http_client.dart';
import '../../core/networkting/ws_client.dart';
import '../../core/networkting/tycoon_api_client.dart';
```

**Add these providers (after authHttpClientProvider):**

```dart
/// Provides HttpClient wrapper
final httpClientProvider = Provider<HttpClient>((ref) {
  return HttpClient(
    authClient: ref.watch(authHttpClientProvider),
    baseUrl: EnvConfig.apiBaseUrl,
  );
});

/// Provides TycoonApiClient
final tycoonApiClientProvider = Provider<TycoonApiClient>((ref) {
  return TycoonApiClient(
    httpClient: ref.watch(httpClientProvider),
  );
});

/// Provides WebSocket client
final wsClientProvider = Provider<WsClient>((ref) {
  return WsClient(
    url: EnvConfig.apiWsBaseUrl,
    onMessage: (message) {
      debugPrint('[WS] Message: ${message.op}');
    },
    onStateChange: (state) {
      debugPrint('[WS] State: $state');
    },
    onError: (error) {
      debugPrint('[WS] Error: $error');
    },
  );
});
```

---

## Step 3: Usage Examples (10 minutes)

### 3.1: Using HttpClient

**In any screen/service:**
```dart
class QuizScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiClient = ref.read(tycoonApiClientProvider);
    
    return FutureBuilder(
      future: apiClient.getQuizQuestions(
        amount: 10,
        category: 'Science',
        difficulty: 'medium',
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final questions = snapshot.data!;
          return QuizWidget(questions: questions);
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

### 3.2: Using WebSocket

**Connect on app start:**
```dart
class _HomeScreenState extends ConsumerStatefulWidget {
  @override
  void initState() {
    super.initState();
    
    // Connect to WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wsClient = ref.read(wsClientProvider);
      wsClient.connect();
    });
  }
  
  @override
  void dispose() {
    ref.read(wsClientProvider).disconnect();
    super.dispose();
  }
}
```

**Listen to messages:**
```dart
class MatchScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wsClient = ref.watch(wsClientProvider);
    
    return StreamBuilder<WsEnvelope>(
      stream: wsClient.messageStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final message = snapshot.data!;
          
          if (message.op == 'match.update') {
            // Handle match update
            return MatchUpdateWidget(data: message.data);
          }
        }
        
        return MatchWaitingWidget();
      },
    );
  }
}
```

**Send messages:**
```dart
void submitAnswer(String answer) {
  final wsClient = ref.read(wsClientProvider);
  
  wsClient.send(
    WsEnvelope(
      op: 'match.answer',
      ts: DateTime.now().millisecondsSinceEpoch,
      data: {
        'matchId': currentMatchId,
        'answer': answer,
      },
    ),
    requireAck: true, // Will retry if not acknowledged
  );
}
```

### 3.3: Using TycoonApiClient

**Leaderboard:**
```dart
final apiClient = ref.read(tycoonApiClientProvider);

// Get global leaderboard
final leaderboard = await apiClient.getLeaderboard(
  limit: 100,
  category: 'Science',
);

// Get user rank
final userRank = await apiClient.getUserRank(userId);
```

**Quiz submission:**
```dart
final result = await apiClient.submitQuizResults(
  quizId: 'quiz-123',
  answers: answersData,
  score: 8,
  totalQuestions: 10,
);
```

**Store purchase:**
```dart
final purchase = await apiClient.purchaseItem(
  userId: userId,
  itemId: 'powerup-hint',
  quantity: 5,
);
```

---

## Step 4: Replace Old ApiService (15 minutes)

### File: `lib/core/services/api_service.dart`

If you have an existing ApiService using Dio, you can either:

**Option A: Keep Both** (Recommended for gradual migration)
- Old ApiService for existing code
- New TycoonApiClient for new features

**Option B: Replace Completely**

Find usages of old ApiService:
```bash
grep -r "ApiService" lib/
```

Replace with TycoonApiClient:
```dart
// Before
final apiService = ref.read(apiServiceProvider);
final questions = await apiService.fetchQuestions(amount: 10);

// After
final apiClient = ref.read(tycoonApiClientProvider);
final questions = await apiClient.getQuizQuestions(amount: 10);
```

---

## Step 5: WebSocket Integration (15 minutes)

### 5.1: Match System Integration

**Create match service:**
```dart
class MatchService {
  final WsClient wsClient;
  final TycoonApiClient apiClient;
  
  MatchService(this.wsClient, this.apiClient);
  
  Future<void> joinMatch(String matchId) async {
    // HTTP: Join match
    await apiClient.joinMatch(
      matchId: matchId,
      userId: currentUserId,
    );
    
    // WebSocket: Subscribe to match updates
    wsClient.send(WsEnvelope(
      op: 'match.join',
      ts: DateTime.now().millisecondsSinceEpoch,
      data: {'matchId': matchId},
    ));
  }
  
  Stream<WsEnvelope> get matchUpdates {
    return wsClient.messageStream
        .where((msg) => msg.op.startsWith('match.'));
  }
}
```

### 5.2: Presence System

**Track online users:**
```dart
void updatePresence(String status) {
  wsClient.send(WsEnvelope(
    op: 'presence.update',
    ts: DateTime.now().millisecondsSinceEpoch,
    data: {
      'userId': currentUserId,
      'status': status, // 'online', 'away', 'in-match'
    },
  ));
}
```

---

## Step 6: Testing (5 minutes)

### Test HTTP Client

```dart
void testHttpClient() async {
  final http = ref.read(httpClientProvider);
  
  try {
    // Test GET
    final data = await http.getJson('/health');
    print('Health: $data');
    
    // Test POST
    final result = await http.postJson('/test', body: {'key': 'value'});
    print('Result: $result');
    
  } on HttpException catch (e) {
    print('Error: ${e.statusCode} - ${e.message}');
  }
}
```

### Test WebSocket

```dart
void testWebSocket() async {
  final ws = ref.read(wsClientProvider);
  
  // Listen to state
  ws.stateStream.listen((state) {
    print('WS State: $state');
  });
  
  // Listen to messages
  ws.messageStream.listen((message) {
    print('WS Message: ${message.op} - ${message.data}');
  });
  
  // Connect
  await ws.connect();
  
  // Send test message
  ws.send(WsEnvelope(
    op: 'test',
    ts: DateTime.now().millisecondsSinceEpoch,
    data: {'message': 'Hello!'},
  ));
}
```

### Test API Client

```dart
void testApiClient() async {
  final api = ref.read(tycoonApiClientProvider);
  
  try {
    // Health check
    final healthy = await api.healthCheck();
    print('Backend healthy: $healthy');
    
    // Get leaderboard
    final leaderboard = await api.getLeaderboard(limit: 10);
    print('Top 10: ${leaderboard.length} entries');
    
  } catch (e) {
    print('API Error: $e');
  }
}
```

---

## Verification Checklist

- [ ] All dependencies installed
- [ ] All networking files in place
- [ ] Providers added to riverpod_providers.dart
- [ ] No compilation errors
- [ ] `flutter analyze` passes
- [ ] HTTP requests work
- [ ] WebSocket connects
- [ ] Messages send/receive
- [ ] Auto-reconnection works

---

## Expected Results

### HTTP Client
```
✅ GET /health → 200 OK
✅ POST /quiz/submit → Success response
✅ Token auto-refreshed on 401
✅ Friendly error messages on failure
```

### WebSocket
```
✅ Connects to wss://your-backend/ws
✅ Receives messages
✅ Sends messages with ACK
✅ Auto-reconnects on disconnect
✅ Heartbeat keeps connection alive
```

### API Client
```
✅ getQuizQuestions() → Array of questions
✅ submitQuizResults() → Score data
✅ getLeaderboard() → Ranked users
✅ All methods return proper types
```

---

## Common Issues & Solutions

### Issue 1: WebSocket Won't Connect
**Error:** Connection refused  
**Fix:** Check EnvConfig.apiWsBaseUrl is correct
- Android emulator: `ws://10.0.2.2:5000/ws`
- iOS simulator: `ws://localhost:5000/ws`
- Production: `wss://your-domain.com/ws`

### Issue 2: UUID Package Error
**Error:** uuid package not found  
**Fix:** 
```yaml
dependencies:
  uuid: ^4.0.0
```
Then: `flutter pub get`

### Issue 3: Messages Not Acknowledged
**Problem:** Pending messages keep retrying  
**Fix:** Make sure backend sends ACK messages:
```json
{"op": "ack", "ts": 1234567890, "data": {"msgId": "uuid-here"}}
```

### Issue 4: HTTP Timeout
**Problem:** Requests hanging  
**Fix:** Check backend is running and reachable

---

## Files Created in Sprint 2

```
lib/core/networkting/
├── http_client.dart              [NEW] HTTP wrapper
├── ws_client.dart                [NEW] WebSocket with reconnect
├── ws_reliability.dart           [NEW] ACK/retry logic  
└── tycoon_api_client.dart        [UPDATED] Enhanced API

lib/game/providers/
└── riverpod_providers.dart       [UPDATED] New providers

pubspec.yaml                      [UPDATED] Dependencies
```

---

## Performance Tips

### HTTP Client
- Use `getJson()` for single objects
- Use `getJsonList()` for arrays
- Responses are automatically typed

### WebSocket
- Use `requireAck: true` for critical messages
- Use `requireAck: false` for frequent updates
- Messages automatically retry up to 3 times

### API Client
- Methods are type-safe
- Errors throw HttpException
- Wrap in try-catch for error handling

---

## Next Steps

After Sprint 2:
✅ Complete networking layer
✅ HTTP + WebSocket working
✅ Ready for real-time features

**Ready for Sprint 3?**
- Sprint 3: Optional features (tests, analytics, biometric)

**Or ship now?**
Your networking is production-ready! 🚀

---

## Time Breakdown

- Step 1: Copy files (10 min) ⏱️
- Step 2: Add providers (15 min) ⏱️
- Step 3: Usage examples (10 min) ⏱️
- Step 4: Replace old API (15 min) ⏱️
- Step 5: WebSocket integration (15 min) ⏱️
- Step 6: Testing (5 min) ⏱️

**Total:** ~70 minutes 🎯

---

## Success Criteria

Sprint 2 is complete when:

✅ HTTP client making authenticated requests
✅ WebSocket connecting and staying connected
✅ Messages sending with ACK
✅ API client methods working
✅ Auto-reconnection tested
✅ No errors in console
✅ All features functional

**Then you have enterprise-grade networking!** 🌐
