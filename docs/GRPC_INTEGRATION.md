# gRPC Integration — Synaptix Flutter Client

**Date:** 2026-06-04  
**Backend service:** `MobileMatchGrpcService` — port 5001 (HTTP/2)  
**Proto:** `protos/mobile.proto`

---

## Quick start

### 1. Install protoc

| Platform | Command |
|----------|---------|
| macOS | `brew install protobuf` |
| Ubuntu | `apt install protobuf-compiler` |
| Windows | `winget install protobuf` or `choco install protoc` |

### 2. Activate Dart plugin

```bash
dart pub global activate protoc_plugin
# Ensure ~/.pub-cache/bin (or %APPDATA%\Pub\Cache\bin on Windows) is on PATH
```

### 3. Generate Dart stubs

```bash
# macOS / Linux
./scripts/generate_proto.sh

# Windows
.\scripts\generate_proto.ps1
```

This writes four files to `lib/core/networking/grpc/generated/`:
- `mobile.pb.dart` — message classes
- `mobile.pbenum.dart` — enum helpers
- `mobile.pbgrpc.dart` — client stub
- `mobile.pbjson.dart` — JSON helpers

**Re-run whenever `protos/mobile.proto` changes.**

---

## Environment configuration

Add to your `.env` file:

```env
# gRPC — backend MobileMatchService
GRPC_HOST=localhost         # hostname (defaults to same host as API_BASE_URL)
GRPC_PORT=5001              # port (default: 5001)
GRPC_USE_TLS=false          # true for staging/prod
```

For Docker (`docker-compose.yml`):
```env
GRPC_HOST=backend-api
GRPC_PORT=5001
GRPC_USE_TLS=false
```

---

## Available RPCs

| Method | Type | Description |
|--------|------|-------------|
| `startMatch(hostPlayerId, mode)` | Unary | Start a match; returns `(matchId, startedAtMs)` |
| `submitMatch(req)` | Unary | Submit results; returns awards |
| `playMatch(actionsStream)` | Bidi stream | Live match session |
| `watchLeaderboard(playerId, mode, windowSize)` | Server stream | Live rank updates |
| `watchMatchmaking(playerId, mode, tierId)` | Server stream | Matchmaking queue |
| `cancelMatchmaking(playerId, ticketId)` | Unary | Cancel queue subscription |

---

## Usage examples

### Start a match

```dart
final grpc = ref.read(grpcMatchServiceProvider);
final (:matchId, :startedAtMs) = await grpc.startMatch(playerId, 'ranked');
```

### Live match session

```dart
final actions = StreamController<PlayerAction>();

// Join the match
actions.add(PlayerAction(join: JoinMatchAction(
  matchId: matchId,
  playerId: playerId,
)));

final events = grpc.playMatch(actions.stream);
await for (final event in events) {
  switch (event.whichEvent()) {
    case MatchEvent_Event.question:
      _onQuestion(event.question);
    case MatchEvent_Event.answerResult:
      _onAnswerResult(event.answerResult);
    case MatchEvent_Event.matchEnd:
      _onMatchEnd(event.matchEnd);
      actions.close();
    default:
      break;
  }
}
```

### Submit an answer

```dart
actions.add(PlayerAction(answer: SubmitAnswerAction(
  matchId: matchId,
  questionId: currentQuestion.questionId,
  selectedOptionId: selectedOptionId,
  answeredAtMs: Int64(DateTime.now().millisecondsSinceEpoch),
)));
```

### Matchmaking queue

```dart
final sub = grpc.watchMatchmaking(
  playerId: playerId,
  mode: 'ranked',
).listen((update) {
  if (update.status == 'Matched') {
    Navigator.of(context).push(...); // go to match lobby
  }
});

// To cancel:
await grpc.cancelMatchmaking(playerId, update.ticketId);
sub.cancel();
```

### Live leaderboard

```dart
final updates = grpc.watchLeaderboard(
  playerId: playerId,
  windowSize: 5,
);

await for (final update in updates) {
  setState(() => _rank = update.playerRank);
}
// Cancel by calling .cancel() on the StreamSubscription.
```

---

## Architecture notes

- **Auth** is injected automatically via `GrpcAuthInterceptor` on the channel — no manual `CallOptions` needed at the call site.
- **Platform support**: Mobile/desktop use `ClientChannel` (native HTTP/2); web uses `GrpcWebClientChannel.xhr` (gRPC-Web). Switching is automatic via `kIsWeb`.
- **TLS**: `GRPC_USE_TLS=false` for local dev (plain HTTP/2). Set to `true` with a valid cert for staging/prod.
- **int64 fields** (`startedAtMs`, `answeredAtMs`, `snapshotAtMs`) use `Int64` from the `fixnum` package — call `.toInt()` to get a Dart `int` when not on web.
- **Relationship to SignalR**: gRPC handles match lifecycle and matchmaking. SignalR continues to handle notifications, DMs, and player presence. Do not move those to gRPC.

---

## Track 3+ planned RPCs

| RPC | Reason deferred |
|-----|----------------|
| `SpectateMatch` (server stream) | Backend spectate service not yet implemented |
| `StreamAnalyticsEvents` (client stream) | REST analytics sufficient; gRPC is an optimisation |
| `GetMatchHistory` (unary) | REST `/matches/{id}` is sufficient |
