# WEBSOCKET MESSAGE PROTOCOL
## Standard Format for All Real-Time Features

---

## 📋 MESSAGE FORMAT

All WebSocket messages use the `WsEnvelope` format:

```dart
{
  "op": "operation_name",      // Operation type
  "ts": 1234567890,            // Timestamp (milliseconds)
  "seq": 42,                   // Optional: sequence number
  "data": {                    // Optional: operation data
    "key": "value"
  }
}
```

---

## 🎯 OPERATION TYPES

### System Operations
- `hello` - Server welcome message
- `ping` - Keep-alive from client
- `pong` - Keep-alive response from server
- `ack` - Acknowledgment
- `error` - Error message

### Presence Operations
- `presence.update` - User presence changed
- `presence.subscribe` - Subscribe to user presence
- `presence.unsubscribe` - Unsubscribe from user presence
- `presence.bulk` - Bulk presence update

### Leaderboard Operations
- `leaderboard.update` - Rank/score changed
- `leaderboard.subscribe` - Subscribe to leaderboard
- `leaderboard.unsubscribe` - Unsubscribe
- `leaderboard.snapshot` - Full leaderboard data

### Chat Operations
- `chat.message` - New message
- `chat.typing` - User typing
- `chat.read` - Message read receipt
- `chat.join` - Join chat room
- `chat.leave` - Leave chat room
- `chat.history` - Message history

---

## 📤 CLIENT → SERVER MESSAGES

### 1. Subscribe to Presence
```json
{
  "op": "presence.subscribe",
  "ts": 1234567890,
  "data": {
    "userIds": ["user1", "user2", "user3"]
  }
}
```

### 2. Update My Presence
```json
{
  "op": "presence.update",
  "ts": 1234567890,
  "data": {
    "status": "online",
    "activity": "Playing Quiz",
    "gameActivity": {
      "gameType": "quiz",
      "gameMode": "solo",
      "score": 100
    }
  }
}
```

### 3. Subscribe to Leaderboard
```json
{
  "op": "leaderboard.subscribe",
  "ts": 1234567890,
  "data": {
    "type": "global",
    "category": "all"
  }
}
```

### 4. Send Chat Message
```json
{
  "op": "chat.message",
  "ts": 1234567890,
  "data": {
    "chatId": "group_123",
    "message": "Hello everyone!",
    "type": "text"
  }
}
```

### 5. Join Chat Room
```json
{
  "op": "chat.join",
  "ts": 1234567890,
  "data": {
    "chatId": "group_123"
  }
}
```

### 6. Typing Indicator
```json
{
  "op": "chat.typing",
  "ts": 1234567890,
  "data": {
    "chatId": "group_123",
    "isTyping": true
  }
}
```

---

## 📥 SERVER → CLIENT MESSAGES

### 1. Hello (Connection Established)
```json
{
  "op": "hello",
  "ts": 1234567890,
  "data": {
    "userId": "user123",
    "serverVersion": "1.0.0"
  }
}
```

### 2. Presence Update
```json
{
  "op": "presence.update",
  "ts": 1234567890,
  "data": {
    "userId": "user456",
    "status": "online",
    "activity": "In Match",
    "lastSeen": "2024-02-21T10:30:00Z"
  }
}
```

### 3. Bulk Presence (Initial Load)
```json
{
  "op": "presence.bulk",
  "ts": 1234567890,
  "data": {
    "presences": [
      {
        "userId": "user1",
        "status": "online",
        "activity": "Playing Quiz"
      },
      {
        "userId": "user2",
        "status": "offline",
        "lastSeen": "2024-02-21T09:00:00Z"
      }
    ]
  }
}
```

### 4. Leaderboard Update
```json
{
  "op": "leaderboard.update",
  "ts": 1234567890,
  "data": {
    "userId": "user123",
    "rank": 5,
    "oldRank": 7,
    "score": 1500,
    "change": 50
  }
}
```

### 5. Leaderboard Snapshot (Initial Load)
```json
{
  "op": "leaderboard.snapshot",
  "ts": 1234567890,
  "data": {
    "type": "global",
    "entries": [
      {
        "rank": 1,
        "userId": "user1",
        "username": "ProPlayer",
        "score": 5000,
        "avatar": "url"
      },
      {
        "rank": 2,
        "userId": "user2",
        "username": "QuizMaster",
        "score": 4800,
        "avatar": "url"
      }
    ]
  }
}
```

### 6. Chat Message
```json
{
  "op": "chat.message",
  "ts": 1234567890,
  "seq": 42,
  "data": {
    "chatId": "group_123",
    "messageId": "msg_456",
    "senderId": "user789",
    "senderName": "Alice",
    "message": "Hello everyone!",
    "type": "text",
    "timestamp": "2024-02-21T10:30:00Z"
  }
}
```

### 7. User Typing
```json
{
  "op": "chat.typing",
  "ts": 1234567890,
  "data": {
    "chatId": "group_123",
    "userId": "user456",
    "username": "Bob",
    "isTyping": true
  }
}
```

### 8. Read Receipt
```json
{
  "op": "chat.read",
  "ts": 1234567890,
  "data": {
    "chatId": "group_123",
    "userId": "user456",
    "messageId": "msg_456",
    "readAt": "2024-02-21T10:31:00Z"
  }
}
```

### 9. Error Message
```json
{
  "op": "error",
  "ts": 1234567890,
  "data": {
    "code": "UNAUTHORIZED",
    "message": "Invalid auth token",
    "details": {}
  }
}
```

---

## 🔄 MESSAGE FLOW EXAMPLES

### Example 1: User Comes Online

**1. Client connects:**
```json
// Server → Client
{
  "op": "hello",
  "ts": 1234567890,
  "data": {
    "userId": "user123",
    "sessionId": "session_abc"
  }
}
```

**2. Client updates presence:**
```json
// Client → Server
{
  "op": "presence.update",
  "ts": 1234567890,
  "data": {
    "status": "online"
  }
}
```

**3. Server broadcasts to friends:**
```json
// Server → Friends
{
  "op": "presence.update",
  "ts": 1234567891,
  "data": {
    "userId": "user123",
    "status": "online",
    "activity": null
  }
}
```

---

### Example 2: Chat Conversation

**1. User joins chat:**
```json
// Client → Server
{
  "op": "chat.join",
  "ts": 1234567890,
  "data": {
    "chatId": "group_123"
  }
}
```

**2. Server sends history:**
```json
// Server → Client
{
  "op": "chat.history",
  "ts": 1234567891,
  "data": {
    "chatId": "group_123",
    "messages": [
      {
        "messageId": "msg_1",
        "senderId": "user456",
        "message": "Hello!",
        "timestamp": "2024-02-21T10:00:00Z"
      }
    ]
  }
}
```

**3. User sends message:**
```json
// Client → Server
{
  "op": "chat.message",
  "ts": 1234567892,
  "data": {
    "chatId": "group_123",
    "message": "Hi there!",
    "type": "text"
  }
}
```

**4. Server broadcasts to all members:**
```json
// Server → All Members
{
  "op": "chat.message",
  "ts": 1234567893,
  "seq": 42,
  "data": {
    "chatId": "group_123",
    "messageId": "msg_2",
    "senderId": "user123",
    "senderName": "Alice",
    "message": "Hi there!",
    "type": "text",
    "timestamp": "2024-02-21T10:30:00Z"
  }
}
```

**5. User starts typing:**
```json
// Client → Server
{
  "op": "chat.typing",
  "ts": 1234567894,
  "data": {
    "chatId": "group_123",
    "isTyping": true
  }
}
```

**6. Server broadcasts typing:**
```json
// Server → Other Members
{
  "op": "chat.typing",
  "ts": 1234567895,
  "data": {
    "chatId": "group_123",
    "userId": "user123",
    "username": "Alice",
    "isTyping": true
  }
}
```

---

### Example 3: Leaderboard Update

**1. Client subscribes:**
```json
// Client → Server
{
  "op": "leaderboard.subscribe",
  "ts": 1234567890,
  "data": {
    "type": "global"
  }
}
```

**2. Server sends snapshot:**
```json
// Server → Client
{
  "op": "leaderboard.snapshot",
  "ts": 1234567891,
  "data": {
    "type": "global",
    "entries": [...]
  }
}
```

**3. Someone's rank changes:**
```json
// Server → All Subscribers
{
  "op": "leaderboard.update",
  "ts": 1234567900,
  "data": {
    "userId": "user456",
    "rank": 3,
    "oldRank": 5,
    "score": 2500,
    "change": 100
  }
}
```

---

## 🎯 IMPLEMENTATION GUIDELINES

### Client-Side (Flutter)

**1. Send Message:**
```dart
void sendPresenceUpdate(String status) {
  final wsClient = AppInit.wsClient;
  if (wsClient != null) {
    wsClient.send(WsEnvelope(
      op: 'presence.update',
      ts: DateTime.now().millisecondsSinceEpoch,
      data: {
        'status': status,
      },
    ));
  }
}
```

**2. Receive Messages:**
```dart
wsClient.messageStream.listen((envelope) {
  switch (envelope.op) {
    case 'presence.update':
      _handlePresenceUpdate(envelope.data);
      break;
    case 'chat.message':
      _handleChatMessage(envelope.data);
      break;
    case 'leaderboard.update':
      _handleLeaderboardUpdate(envelope.data);
      break;
  }
});
```

---

### Server-Side (.NET)

**1. Parse Message:**
```csharp
var message = JsonSerializer.Deserialize<WsEnvelope>(receivedText);

switch (message.Op)
{
    case "presence.update":
        await HandlePresenceUpdate(webSocket, message.Data);
        break;
    case "chat.message":
        await HandleChatMessage(webSocket, message.Data);
        break;
}
```

**2. Broadcast Message:**
```csharp
var envelope = new WsEnvelope
{
    Op = "chat.message",
    Ts = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds(),
    Data = new
    {
        chatId = "group_123",
        messageId = "msg_456",
        senderId = userId,
        message = "Hello!"
    }
};

await BroadcastToGroup(groupId, envelope);
```

---

## 📚 DATA TYPES

### PresenceStatus
```typescript
enum PresenceStatus {
  online = "online",
  away = "away",
  busy = "busy",
  inGame = "inGame",
  offline = "offline"
}
```

### MessageType
```typescript
enum MessageType {
  text = "text",
  image = "image",
  system = "system",
  reaction = "reaction"
}
```

### LeaderboardType
```typescript
enum LeaderboardType {
  global = "global",
  friends = "friends",
  weekly = "weekly",
  monthly = "monthly"
}
```

---

## 🔒 SECURITY NOTES

1. **Authentication:** All messages require valid JWT token
2. **Rate Limiting:** Limit messages per user per minute
3. **Validation:** Validate all data before broadcasting
4. **Sanitization:** Sanitize user-generated content
5. **Authorization:** Check user has permission for operation

---

## ⚡ PERFORMANCE TIPS

1. **Batching:** Batch multiple updates into one message
2. **Debouncing:** Debounce rapid updates (typing indicators)
3. **Compression:** Use WebSocket compression for large messages
4. **Selective Broadcasting:** Only send to users who need update
5. **Pagination:** Paginate history/snapshots

---

This protocol ensures consistent, type-safe WebSocket communication across all features! 🚀
