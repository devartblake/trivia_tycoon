import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:synaptix/core/services/auth_token_store.dart';
import 'package:synaptix/core/services/storage/secure_secret_store.dart';

class _MemorySecretStore implements SecretStore {
  final Map<String, String> values = {};

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> get(String key) async => values[key];

  @override
  Future<void> set(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  late Directory tempDir;
  late Box box;
  late AuthTokenStore store;
  late _MemorySecretStore secretStore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('auth_token_store_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('auth_tokens');
    secretStore = _MemorySecretStore();
    store = AuthTokenStore(box, secretStore: secretStore);
    await store.initialize();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // -------------------------------------------------------------------------
  // AuthSession — hasTokens
  // -------------------------------------------------------------------------

  group('AuthSession — hasTokens', () {
    test('true when both tokens are non-empty', () {
      final session = AuthSession(
        accessToken: 'access',
        refreshToken: 'refresh',
      );
      expect(session.hasTokens, isTrue);
    });

    test('false when accessToken is empty', () {
      final session = AuthSession(
        accessToken: '',
        refreshToken: 'refresh',
      );
      expect(session.hasTokens, isFalse);
    });

    test('false when refreshToken is empty', () {
      final session = AuthSession(
        accessToken: 'access',
        refreshToken: '',
      );
      expect(session.hasTokens, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // AuthSession — isExpired
  // -------------------------------------------------------------------------

  group('AuthSession — isExpired', () {
    test('false when expiresAtUtc is null', () {
      final session = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
      );
      expect(session.isExpired, isFalse);
    });

    test('false when expiresAtUtc is in the future', () {
      final session = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      expect(session.isExpired, isFalse);
    });

    test('true when expiresAtUtc is in the past', () {
      final session = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtUtc: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      );
      expect(session.isExpired, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // AuthSession — role / roles
  // -------------------------------------------------------------------------

  group('AuthSession — role getter', () {
    test('returns role from "role" key', () {
      final session = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        metadata: {'role': 'admin'},
      );
      expect(session.role, 'admin');
    });

    test('returns first element from "roles" list', () {
      final session = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        metadata: {
          'roles': ['moderator', 'player']
        },
      );
      expect(session.role, 'moderator');
    });

    test('returns null when no role metadata', () {
      final session = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        metadata: {'other': 'data'},
      );
      expect(session.role, isNull);
    });

    test('returns null when metadata is null', () {
      final session = AuthSession(accessToken: 'a', refreshToken: 'r');
      expect(session.role, isNull);
    });
  });

  group('AuthSession — roles getter', () {
    test('returns list from "roles" key', () {
      final session = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        metadata: {
          'roles': ['admin', 'player']
        },
      );
      expect(session.roles, ['admin', 'player']);
    });

    test('wraps single "role" key in list', () {
      final session = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        metadata: {'role': 'player'},
      );
      expect(session.roles, ['player']);
    });

    test('returns empty list when no role metadata', () {
      final session = AuthSession(accessToken: 'a', refreshToken: 'r');
      expect(session.roles, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // AuthSession — isPremium
  // -------------------------------------------------------------------------

  group('AuthSession — isPremium getter', () {
    test('true from isPremium=true', () {
      final session = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        metadata: {'isPremium': true},
      );
      expect(session.isPremium, isTrue);
    });

    test('false from isPremium=false', () {
      final session = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        metadata: {'isPremium': false},
      );
      expect(session.isPremium, isFalse);
    });

    test('true from subscriptionStatus=active', () {
      final session = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        metadata: {'subscriptionStatus': 'active'},
      );
      expect(session.isPremium, isTrue);
    });

    test('false from subscriptionStatus=expired', () {
      final session = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        metadata: {'subscriptionStatus': 'expired'},
      );
      expect(session.isPremium, isFalse);
    });

    test('false when metadata is null', () {
      final session = AuthSession(accessToken: 'a', refreshToken: 'r');
      expect(session.isPremium, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // AuthSession — tier
  // -------------------------------------------------------------------------

  group('AuthSession — tier getter', () {
    test('returns tier string', () {
      final session = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        metadata: {'tier': 'premium'},
      );
      expect(session.tier, 'premium');
    });

    test('returns null when tier absent', () {
      final session = AuthSession(accessToken: 'a', refreshToken: 'r');
      expect(session.tier, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // AuthSession — copyWith
  // -------------------------------------------------------------------------

  group('AuthSession — copyWith', () {
    test('updates only specified fields', () {
      final original = AuthSession(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
        userId: 'uid-1',
        metadata: {'role': 'player'},
      );
      final updated = original.copyWith(accessToken: 'new-access');

      expect(updated.accessToken, 'new-access');
      expect(updated.refreshToken, 'old-refresh');
      expect(updated.userId, 'uid-1');
      expect(updated.metadata, {'role': 'player'});
    });

    test('all fields can be replaced', () {
      final original = AuthSession(accessToken: 'a', refreshToken: 'r');
      final future = DateTime.now().toUtc().add(const Duration(hours: 1));
      final updated = original.copyWith(
        accessToken: 'new-a',
        refreshToken: 'new-r',
        expiresAtUtc: future,
        userId: 'u-2',
        metadata: {'role': 'admin'},
      );

      expect(updated.accessToken, 'new-a');
      expect(updated.refreshToken, 'new-r');
      expect(updated.expiresAtUtc, future);
      expect(updated.userId, 'u-2');
      expect(updated.metadata, {'role': 'admin'});
    });
  });

  // -------------------------------------------------------------------------
  // AuthSession — toJson / fromJson
  // -------------------------------------------------------------------------

  group('AuthSession — toJson / fromJson round-trip', () {
    test('round-trips basic fields', () {
      final expiry = DateTime.utc(2030, 6, 15, 12, 0, 0); // truncate to seconds
      final session = AuthSession(
        accessToken: 'access-xyz',
        refreshToken: 'refresh-xyz',
        expiresAtUtc: expiry,
        userId: 'user-abc',
        metadata: {'role': 'player', 'isPremium': false},
      );

      final json = session.toJson();
      final restored = AuthSession.fromJson(json);

      expect(restored.accessToken, session.accessToken);
      expect(restored.refreshToken, session.refreshToken);
      expect(restored.expiresAtUtc, session.expiresAtUtc);
      expect(restored.userId, session.userId);
      expect(restored.metadata, session.metadata);
    });

    test('fromJson handles missing optional fields gracefully', () {
      final json = {
        'accessToken': 'a',
        'refreshToken': 'r',
      };
      final session = AuthSession.fromJson(json);
      expect(session.accessToken, 'a');
      expect(session.refreshToken, 'r');
      expect(session.expiresAtUtc, isNull);
      expect(session.userId, isNull);
      expect(session.metadata, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // AuthTokenStore — load empty box
  // -------------------------------------------------------------------------

  group('AuthTokenStore — load empty', () {
    test('returns session with empty tokens on empty box', () {
      final session = store.load();
      expect(session.accessToken, '');
      expect(session.refreshToken, '');
      expect(session.userId, isNull);
      expect(session.expiresAtUtc, isNull);
      expect(session.metadata, isNull);
    });

    test('hasTokens() returns false on empty box', () {
      expect(store.hasTokens(), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // AuthTokenStore — save / load round-trip
  // -------------------------------------------------------------------------

  group('AuthTokenStore — save / load', () {
    test('persists tokens and metadata', () async {
      final expiry = DateTime.utc(2030, 1, 1);
      final session = AuthSession(
        accessToken: 'saved-access',
        refreshToken: 'saved-refresh',
        expiresAtUtc: expiry,
        userId: 'uid-saved',
        metadata: {'role': 'admin', 'isPremium': true},
      );

      await store.save(session);
      final loaded = store.load();

      expect(loaded.accessToken, 'saved-access');
      expect(loaded.refreshToken, 'saved-refresh');
      expect(loaded.expiresAtUtc, expiry);
      expect(loaded.userId, 'uid-saved');
      expect(loaded.metadata, {'role': 'admin', 'isPremium': true});
      expect(box.get('auth_access_token'), isNull);
      expect(box.get('auth_refresh_token'), isNull);
      expect(secretStore.values['auth_session_v1'], isNotNull);
    });

    test('hasTokens() returns true after save', () async {
      await store.save(
        AuthSession(accessToken: 'a', refreshToken: 'r'),
      );
      expect(store.hasTokens(), isTrue);
    });

    test('save clears metadata when session has no metadata', () async {
      // Save first with metadata
      await store.save(
        AuthSession(
          accessToken: 'a',
          refreshToken: 'r',
          metadata: {'role': 'admin'},
        ),
      );
      // Save again without metadata
      await store.save(
        AuthSession(accessToken: 'a2', refreshToken: 'r2'),
      );
      final loaded = store.load();
      expect(loaded.metadata, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // AuthTokenStore — clear
  // -------------------------------------------------------------------------

  group('AuthTokenStore — clear', () {
    test('removes all stored data', () async {
      await store.save(AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        userId: 'u',
        metadata: {'role': 'player'},
      ));

      await store.clear();
      final loaded = store.load();

      expect(loaded.accessToken, '');
      expect(loaded.refreshToken, '');
      expect(loaded.userId, isNull);
      expect(loaded.metadata, isNull);
      expect(store.hasTokens(), isFalse);
      expect(secretStore.values['auth_session_v1'], isNull);
    });
  });

  group('AuthTokenStore migration', () {
    test('imports legacy Hive tokens into secure storage and deletes tokens',
        () async {
      final migratingSecrets = _MemorySecretStore();
      await box.put('auth_access_token', 'legacy-access');
      await box.put('auth_refresh_token', 'legacy-refresh');
      await box.put('auth_user_id', 'legacy-user');
      await box.put('auth_metadata', '{"role":"player"}');

      final migratingStore = AuthTokenStore(
        box,
        secretStore: migratingSecrets,
      );
      await migratingStore.initialize();

      final loaded = migratingStore.load();
      expect(loaded.accessToken, 'legacy-access');
      expect(loaded.refreshToken, 'legacy-refresh');
      expect(loaded.userId, 'legacy-user');
      expect(loaded.metadata, {'role': 'player'});
      expect(box.get('auth_access_token'), isNull);
      expect(box.get('auth_refresh_token'), isNull);
      expect(migratingSecrets.values['auth_session_v1'], isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // AuthTokenStore — updateAccessToken
  // -------------------------------------------------------------------------

  group('AuthTokenStore — updateAccessToken', () {
    test('replaces access token and expiry while keeping refresh token',
        () async {
      await store.save(AuthSession(
        accessToken: 'old-access',
        refreshToken: 'keep-refresh',
        userId: 'uid',
      ));

      final newExpiry = DateTime.utc(2035, 1, 1);
      await store.updateAccessToken('new-access', newExpiry);

      final loaded = store.load();
      expect(loaded.accessToken, 'new-access');
      expect(loaded.refreshToken, 'keep-refresh');
      expect(loaded.expiresAtUtc, newExpiry);
    });
  });

  // -------------------------------------------------------------------------
  // AuthTokenStore — getRole / isPremium
  // -------------------------------------------------------------------------

  group('AuthTokenStore — getRole', () {
    test('returns role from stored metadata', () async {
      await store.save(AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        metadata: {'role': 'moderator'},
      ));
      expect(store.getRole(), 'moderator');
    });

    test('returns first role from "roles" list', () async {
      await store.save(AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        metadata: {
          'roles': ['admin', 'player']
        },
      ));
      expect(store.getRole(), 'admin');
    });

    test('returns null when no metadata stored', () {
      expect(store.getRole(), isNull);
    });
  });

  group('AuthTokenStore — isPremium', () {
    test('returns true from isPremium=true in metadata', () async {
      await store.save(AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        metadata: {'isPremium': true},
      ));
      expect(store.isPremium(), isTrue);
    });

    test('returns false from isPremium=false in metadata', () async {
      await store.save(AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        metadata: {'isPremium': false},
      ));
      expect(store.isPremium(), isFalse);
    });

    test('returns false when no metadata stored', () {
      expect(store.isPremium(), isFalse);
    });
  });
}
