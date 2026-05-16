import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/presence/rich_presence_service.dart';
import 'package:trivia_tycoon/game/models/user_presence_models.dart';

void main() {
  // RichPresenceService is a singleton. setUp re-initializes it to reset
  // currentUserPresence before each test. Tests use distinct userIds so
  // accumulated _userPresences state does not cross-contaminate.
  late RichPresenceService service;

  setUp(() {
    service = RichPresenceService();
    service.initialize(useWebSocket: false);
  });

  test('initialize sets currentUserPresence to non-null online status', () {
    expect(service.currentUserPresence, isNotNull);
    expect(service.currentUserPresence!.status, PresenceStatus.online);
  });

  test('updateCurrentUserPresence reflects new status and activity', () async {
    await service.updateCurrentUserPresence(
      status: PresenceStatus.away,
      activity: 'Reading notes',
    );

    expect(service.currentUserPresence!.status, PresenceStatus.away);
    expect(service.currentUserPresence!.activity, 'Reading notes');
  });

  test('setGameActivity switches to inGame and populates gameActivity',
      () async {
    await service.setGameActivity(
      gameType: 'Quiz',
      gameMode: 'Science',
      gameState: GameState.playing,
    );

    final presence = service.currentUserPresence!;
    expect(presence.status, PresenceStatus.inGame);
    expect(presence.gameActivity, isNotNull);
    expect(presence.gameActivity!.gameType, 'Quiz');
    expect(presence.gameActivity!.gameMode, 'Science');
    expect(presence.gameActivity!.gameState, GameState.playing);
  });

  test('clearGameActivity resets to online with null gameActivity', () async {
    await service.setGameActivity(gameType: 'Quiz');
    await service.clearGameActivity();

    final presence = service.currentUserPresence!;
    expect(presence.status, PresenceStatus.online);
    expect(presence.gameActivity, isNull);
  });

  test('setGameActivity and clearGameActivity both notify listeners', () async {
    int notifyCount = 0;
    void listener() => notifyCount++;
    service.addListener(listener);
    addTearDown(() => service.removeListener(listener));

    await service.setGameActivity(gameType: 'Quiz');
    final afterSet = notifyCount;
    expect(afterSet, greaterThan(0));

    await service.clearGameActivity();
    expect(notifyCount, greaterThan(afterSet));
  });

  test('canUserJoinGame returns true when gameState is lobby', () {
    const uid = 'lobby-player';
    service.updateFriendPresence(
      uid,
      UserPresence(
        userId: uid,
        status: PresenceStatus.inGame,
        lastSeen: DateTime.now(),
        gameActivity: GameActivity(
          gameType: 'Quiz',
          gameState: GameState.lobby,
          startTime: DateTime.now(),
        ),
      ),
    );

    expect(service.canUserJoinGame(uid), isTrue);
  });

  test('canUserJoinGame returns true when gameState is waiting', () {
    const uid = 'waiting-player';
    service.updateFriendPresence(
      uid,
      UserPresence(
        userId: uid,
        status: PresenceStatus.inGame,
        lastSeen: DateTime.now(),
        gameActivity: GameActivity(
          gameType: 'Quiz',
          gameState: GameState.waiting,
          startTime: DateTime.now(),
        ),
      ),
    );

    expect(service.canUserJoinGame(uid), isTrue);
  });

  test('canUserJoinGame returns false when gameState is playing', () {
    const uid = 'playing-player';
    service.updateFriendPresence(
      uid,
      UserPresence(
        userId: uid,
        status: PresenceStatus.inGame,
        lastSeen: DateTime.now(),
        gameActivity: GameActivity(
          gameType: 'Quiz',
          gameState: GameState.playing,
          startTime: DateTime.now(),
        ),
      ),
    );

    expect(service.canUserJoinGame(uid), isFalse);
  });

  test('canUserJoinGame returns false for user with no tracked presence', () {
    expect(service.canUserJoinGame('ghost-user'), isFalse);
  });

  test('watchUserPresence stream emits when updateFriendPresence is called',
      () async {
    const uid = 'stream-user';
    final presence = UserPresence(
      userId: uid,
      status: PresenceStatus.online,
      lastSeen: DateTime.now(),
    );

    final emitted = <UserPresence?>[];
    final sub = service.watchUserPresence(uid).listen(emitted.add);
    addTearDown(sub.cancel);

    service.updateFriendPresence(uid, presence);
    await Future<void>.delayed(Duration.zero);

    expect(emitted, isNotEmpty);
    expect(emitted.last?.userId, uid);
  });

  // Must run last — dispose permanently closes stream controllers on the singleton.
  test('dispose completes without throwing and cancels timers', () {
    expect(() => service.dispose(), returnsNormally);
  });
}
