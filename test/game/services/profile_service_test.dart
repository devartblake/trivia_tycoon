import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/services/profile_service.dart';
import 'package:trivia_tycoon/game/services/xp_service.dart' hide xpServiceProvider;
import 'package:trivia_tycoon/game/providers/xp_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Runs [body] inside a ProviderScope with a real [Ref], so ProfileService
/// (which accepts a Ref) can be constructed without mocking.
///
/// Returns the result of [body].
Future<T> _withRef<T>(
  Future<T> Function(Ref ref, XPService xpService) body, {
  int startingXP = 0,
}) async {
  final xpService = XPService(startingPlayerXP: startingXP);
  late T result;

  final captureProvider = Provider<void>((ref) {
    // schedule the body after the provider is mounted
    Future.microtask(() async {
      result = await body(ref, xpService);
    });
  });

  final container = ProviderContainer(
    overrides: [xpServiceProvider.overrideWithValue(xpService)],
  );
  addTearDown(container.dispose);
  container.read(captureProvider); // triggers mounting
  await Future.delayed(Duration.zero); // let microtask run
  return result;
}

/// Simpler sync helper: creates a ProfileService using a ProviderContainer-backed
/// approach for tests that only call synchronous methods.
ProfileService _makeSyncService({
  required ProviderContainer container,
  String playerId = 'player-1',
  String displayName = 'Alice',
}) {
  late Ref capturedRef;
  final helperProvider = Provider<void>((ref) {
    capturedRef = ref;
  });
  container.read(helperProvider);
  return ProfileService(
    capturedRef,
    playerId: playerId,
    displayName: displayName,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ProfileService — display name', () {
    test('initializes with provided display name', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final svc = _makeSyncService(container: container, displayName: 'Bob');
      expect(svc.displayName, 'Bob');
    });

    test('setDisplayName updates the name', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final svc =
          _makeSyncService(container: container, displayName: 'Alice');
      svc.setDisplayName('Charlie');
      expect(svc.displayName, 'Charlie');
    });
  });

  group('ProfileService — categories', () {
    late ProviderContainer container;
    late ProfileService svc;

    setUp(() {
      container = ProviderContainer();
      svc = _makeSyncService(container: container);
    });
    tearDown(() => container.dispose());

    test('no categories unlocked by default', () {
      expect(svc.isCategoryUnlocked('science'), isFalse);
    });

    test('unlockCategory makes category accessible', () {
      svc.unlockCategory('science');
      expect(svc.isCategoryUnlocked('science'), isTrue);
    });

    test('unlocking one category does not affect others', () {
      svc.unlockCategory('history');
      expect(svc.isCategoryUnlocked('science'), isFalse);
    });

    test('can unlock multiple categories independently', () {
      svc.unlockCategory('math');
      svc.unlockCategory('geography');
      expect(svc.isCategoryUnlocked('math'), isTrue);
      expect(svc.isCategoryUnlocked('geography'), isTrue);
    });
  });

  group('ProfileService — preferences', () {
    late ProviderContainer container;
    late ProfileService svc;

    setUp(() {
      container = ProviderContainer();
      svc = _makeSyncService(container: container);
    });
    tearDown(() => container.dispose());

    test('getPreference returns null for unknown key', () {
      expect(svc.getPreference<String>('theme'), isNull);
    });

    test('setPreference then getPreference round-trips correctly', () {
      svc.setPreference('theme', 'dark');
      expect(svc.getPreference<String>('theme'), 'dark');
    });

    test('setPreference overwrites existing value', () {
      svc.setPreference('volume', 0.8);
      svc.setPreference('volume', 0.5);
      expect(svc.getPreference<double>('volume'), 0.5);
    });

    test('preferences are independent of each other', () {
      svc.setPreference('a', 1);
      svc.setPreference('b', 2);
      expect(svc.getPreference<int>('a'), 1);
      expect(svc.getPreference<int>('b'), 2);
    });
  });

  group('ProfileService — XP delegation', () {
    test('getPlayerXP delegates to XPService and returns starting value', () {
      final xpService = XPService(startingPlayerXP: 750);
      final container = ProviderContainer(
        overrides: [xpServiceProvider.overrideWithValue(xpService)],
      );
      addTearDown(container.dispose);

      final svc = _makeSyncService(container: container);
      expect(svc.getPlayerXP(), 750);
    });

    test('getPlayerXP reflects XP mutations on the underlying service', () {
      final xpService = XPService();
      final container = ProviderContainer(
        overrides: [xpServiceProvider.overrideWithValue(xpService)],
      );
      addTearDown(container.dispose);

      final svc = _makeSyncService(container: container);
      xpService.addXP(300);
      expect(svc.getPlayerXP(), 300);
    });
  });
}
