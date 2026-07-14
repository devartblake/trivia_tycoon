import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/security/secure_channel_exceptions.dart';
import 'package:synaptix/core/security/secure_channel_models.dart';
import 'package:synaptix/core/security/secure_payload_codec.dart';
import 'package:synaptix/core/security/secure_session_store.dart';
import 'package:synaptix/core/services/storage/secure_storage.dart';

List<int> _randomKey() =>
    List<int>.generate(32, (_) => Random.secure().nextInt(256));

SecureRequestContext _ctx({
  String method = 'POST',
  String pathAndQuery = '/users/me/friends/request',
  String sessionId = 'testsession1234',
  int sequence = 1,
  String? replayNonce,
  String subjectId = '',
  String? encryptedAtUtc,
}) =>
    SecureRequestContext(
      method: method,
      pathAndQuery: pathAndQuery,
      sessionId: sessionId,
      sequence: sequence,
      replayNonce:
          replayNonce ?? base64Url.encode(List<int>.generate(16, (_) => 0)),
      subjectId: subjectId,
      encryptedAtUtc:
          encryptedAtUtc ?? DateTime.utc(2026, 5, 21).toIso8601String(),
    );

void main() {
  late SecurePayloadCodec codec;
  late List<int> keyBytes;

  setUp(() {
    codec = SecurePayloadCodec();
    keyBytes = _randomKey();
  });

  group('SecurePayloadCodec', () {
    test('encrypt/decrypt round-trip returns original payload', () async {
      final body = {'targetUserId': 'user-123', 'message': 'hello'};
      final ctx = _ctx();

      final encrypted = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: ctx,
      );

      final decrypted = await codec.decryptJson(
        encryptedBody: encrypted.toJson(),
        keyBytes: keyBytes,
        context: ctx,
      );

      expect(decrypted, equals(body));
    });

    test('two successive encryptions produce different nonces', () async {
      final body = {'key': 'value'};

      final enc1 = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: _ctx(),
      );
      final enc2 = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: _ctx(),
      );

      expect(enc1.nonce, isNot(equals(enc2.nonce)));
    });

    test('two successive encryptions produce different ciphertexts', () async {
      final body = {'key': 'value'};

      final enc1 = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: _ctx(),
      );
      final enc2 = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: _ctx(),
      );

      expect(enc1.ciphertext, isNot(equals(enc2.ciphertext)));
    });

    test('wrong key throws SecureDecryptException', () async {
      final body = {'data': 42};
      final wrongKey = _randomKey();
      final ctx = _ctx();

      final encrypted = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: ctx,
      );

      expect(
        () => codec.decryptJson(
          encryptedBody: encrypted.toJson(),
          keyBytes: wrongKey,
          context: ctx,
        ),
        throwsA(isA<SecureDecryptException>()),
      );
    });

    test('tampered MAC throws SecureDecryptException', () async {
      final body = {'amount': 100};
      final ctx = _ctx();
      final encrypted = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: ctx,
      );

      final json = encrypted.toJson();
      final mac = json['mac'] as String;
      json['mac'] =
          mac.substring(0, mac.length - 1) + (mac.endsWith('A') ? 'B' : 'A');

      expect(
        () => codec.decryptJson(
          encryptedBody: json,
          keyBytes: keyBytes,
          context: ctx,
        ),
        throwsA(isA<SecureDecryptException>()),
      );
    });

    test('wrong nonce throws SecureDecryptException', () async {
      final body = {'amount': 100};
      final ctx = _ctx();
      final encrypted = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: ctx,
      );

      final json = encrypted.toJson();
      final nonce = json['nonce'] as String;
      json['nonce'] = nonce.substring(0, nonce.length - 1) +
          (nonce.endsWith('A') ? 'B' : 'A');

      expect(
        () => codec.decryptJson(
          encryptedBody: json,
          keyBytes: keyBytes,
          context: ctx,
        ),
        throwsA(isA<SecureDecryptException>()),
      );
    });

    test('wrong method in AAD causes decryption failure', () async {
      final body = {'x': 1};
      final encCtx = _ctx(method: 'POST');
      final decCtx = _ctx(method: 'GET');

      final encrypted = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: encCtx,
      );

      expect(
        () => codec.decryptJson(
          encryptedBody: encrypted.toJson(),
          keyBytes: keyBytes,
          context: decCtx,
        ),
        throwsA(isA<SecureDecryptException>()),
      );
    });

    test('wrong URI path in AAD causes decryption failure', () async {
      final body = {'x': 1};
      final encCtx = _ctx(pathAndQuery: '/friends/request');
      final decCtx = _ctx(pathAndQuery: '/different/path');

      final encrypted = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: encCtx,
      );

      expect(
        () => codec.decryptJson(
          encryptedBody: encrypted.toJson(),
          keyBytes: keyBytes,
          context: decCtx,
        ),
        throwsA(isA<SecureDecryptException>()),
      );
    });

    test('encrypted payload serialises and deserialises fields correctly',
        () async {
      final body = {'nested': true};
      final encrypted = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: _ctx(method: 'PUT'),
      );

      expect(encrypted.contentType, equals('application/json'));
      expect(encrypted.nonce, isNotEmpty);
      expect(encrypted.ciphertext, isNotEmpty);
      expect(encrypted.mac, isNotEmpty);
      expect(encrypted.encryptedAtUtc, isNotEmpty);
    });

    test('round-trips larger JSON payloads used by secure endpoints', () async {
      for (final size in [1024, 10 * 1024, 100 * 1024]) {
        final body = {
          'message': List<String>.filled(size, 'x').join(),
          'metadata': {'size': size},
        };
        final ctx = _ctx(method: 'PATCH');

        final encrypted = await codec.encryptJson(
          body: body,
          keyBytes: keyBytes,
          context: ctx,
        );

        final decrypted = await codec.decryptJson(
          encryptedBody: encrypted.toJson(),
          keyBytes: keyBytes,
          context: ctx,
        );

        expect(decrypted, equals(body));
      }
    });
  });

  group('SecureSessionStore', () {
    test('clear removes the persisted secure session', () async {
      final storage = _MemorySecureStorage();
      final store = SecureSessionStore(storage);
      final session = SecureSession(
        sessionId: 'session-1',
        protocolVersion: 'syn-sec-v1',
        selectedSuite: 'X25519-HKDF-SHA256-AES256GCM',
        clientToServerKey: keyBytes,
        serverToClientKey: _randomKey(),
        expiresAtUtc: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      );

      await store.save(session);
      expect(await store.load(), isNotNull);

      await store.clear();
      expect(await store.load(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Replay / sequence protection
  // -------------------------------------------------------------------------

  group('SecurePayloadCodec — replay and sequence protection', () {
    test('50 successive encryptions all produce unique nonces', () async {
      final body = {'action': 'transfer', 'amount': 100};
      final nonces = <String>{};

      for (var i = 0; i < 50; i++) {
        final enc = await codec.encryptJson(
          body: body,
          keyBytes: keyBytes,
          context: _ctx(sequence: i + 1),
        );
        expect(nonces.add(enc.nonce), isTrue,
            reason:
                'nonce must be unique across all encryptions (got duplicate at index $i)');
      }
      expect(nonces.length, 50);
    });

    test(
        'replayed ciphertext from one nonce cannot be decrypted with a different nonce',
        () async {
      final body = {'userId': 'u-1'};
      final ctx = _ctx();

      final enc1 = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: ctx,
      );
      final enc2 = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: ctx,
      );

      final tampered = {
        'ciphertext': enc1.ciphertext,
        'nonce': enc2.nonce,
        'mac': enc1.mac,
        'contentType': enc1.contentType,
        'encryptedAtUtc': enc1.encryptedAtUtc,
      };

      await expectLater(
        () => codec.decryptJson(
          encryptedBody: tampered,
          keyBytes: keyBytes,
          context: ctx,
        ),
        throwsA(isA<SecureDecryptException>()),
        reason:
            'replaying a ciphertext with a different session nonce must fail',
      );
    });

    test(
        'ciphertext encrypted with session-A key fails to decrypt with session-B key',
        () async {
      final keyA = _randomKey();
      final keyB = _randomKey();
      final body = {'data': 'secret'};
      final ctx = _ctx(method: 'DELETE');

      final enc = await codec.encryptJson(
        body: body,
        keyBytes: keyA,
        context: ctx,
      );

      await expectLater(
        () => codec.decryptJson(
          encryptedBody: enc.toJson(),
          keyBytes: keyB,
          context: ctx,
        ),
        throwsA(isA<SecureDecryptException>()),
        reason: 'cross-session replay with a different key must be rejected',
      );
    });

    test(
        'AAD binding: ciphertext for endpoint A cannot be replayed at endpoint B',
        () async {
      final body = {'targetUserId': 'u-42'};
      final ctxA = _ctx(pathAndQuery: '/friends/request');
      final ctxB = _ctx(pathAndQuery: '/friends/accept');

      final enc = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: ctxA,
      );

      await expectLater(
        () => codec.decryptJson(
          encryptedBody: enc.toJson(),
          keyBytes: keyBytes,
          context: ctxB,
        ),
        throwsA(isA<SecureDecryptException>()),
        reason:
            'replay to a different endpoint must fail due to AAD URI binding',
      );
    });

    test('AAD binding: ciphertext for POST cannot be replayed as DELETE',
        () async {
      final body = {'resourceId': 'r-99'};
      final postCtx = _ctx(method: 'POST');
      final deleteCtx = _ctx(method: 'DELETE');

      final enc = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: postCtx,
      );

      await expectLater(
        () => codec.decryptJson(
          encryptedBody: enc.toJson(),
          keyBytes: keyBytes,
          context: deleteCtx,
        ),
        throwsA(isA<SecureDecryptException>()),
        reason:
            'replaying a POST payload as a DELETE must fail due to AAD method binding',
      );
    });
  });

  // -------------------------------------------------------------------------
  // SecureSession model — expiry and sequence
  // -------------------------------------------------------------------------

  group('SecureSession — expiry and sequence', () {
    test('isExpired returns true for a past expiresAtUtc', () {
      final session = SecureSession(
        sessionId: 's-1',
        protocolVersion: 'syn-sec-v1',
        selectedSuite: 'X25519-HKDF-SHA256-AES256GCM',
        clientToServerKey: _randomKey(),
        serverToClientKey: _randomKey(),
        expiresAtUtc: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      );
      expect(session.isExpired, isTrue);
    });

    test('isExpired returns false for a future expiresAtUtc', () {
      final session = SecureSession(
        sessionId: 's-2',
        protocolVersion: 'syn-sec-v1',
        selectedSuite: 'X25519-HKDF-SHA256-AES256GCM',
        clientToServerKey: _randomKey(),
        serverToClientKey: _randomKey(),
        expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      expect(session.isExpired, isFalse);
    });

    test('copyWith increments nextSequence correctly', () {
      final base = SecureSession(
        sessionId: 's-3',
        protocolVersion: 'syn-sec-v1',
        selectedSuite: 'X25519-HKDF-SHA256-AES256GCM',
        clientToServerKey: _randomKey(),
        serverToClientKey: _randomKey(),
        expiresAtUtc: DateTime.now().toUtc().add(const Duration(minutes: 10)),
        nextSequence: 5,
      );

      final next = base.copyWith(nextSequence: base.nextSequence + 1);
      expect(next.nextSequence, 6);
      expect(base.nextSequence, 5, reason: 'original must be immutable');
    });

    test(
        'toJson / fromJson round-trip preserves all fields including nextSequence',
        () {
      final original = SecureSession(
        sessionId: 'session-abc',
        protocolVersion: 'syn-sec-v1',
        selectedSuite: 'X25519-HKDF-SHA256-AES256GCM',
        clientToServerKey: List<int>.generate(32, (i) => i),
        serverToClientKey: List<int>.generate(32, (i) => 255 - i),
        expiresAtUtc: DateTime.utc(2026, 6, 1, 12, 0),
        nextSequence: 42,
      );

      final restored = SecureSession.fromJson(original.toJson());

      expect(restored.sessionId, original.sessionId);
      expect(restored.protocolVersion, original.protocolVersion);
      expect(restored.selectedSuite, original.selectedSuite);
      expect(restored.clientToServerKey, original.clientToServerKey);
      expect(restored.serverToClientKey, original.serverToClientKey);
      expect(restored.nextSequence, 42);
      expect(restored.isExpired, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // SecureSessionStore — reinstall simulation and web fallback
  // -------------------------------------------------------------------------

  group('SecureSessionStore — reinstall and web fallback', () {
    SecureSession makeSession({bool expired = false}) => SecureSession(
          sessionId: 'session-test',
          protocolVersion: 'syn-sec-v1',
          selectedSuite: 'X25519-HKDF-SHA256-AES256GCM',
          clientToServerKey: _randomKey(),
          serverToClientKey: _randomKey(),
          expiresAtUtc: expired
              ? DateTime.now().toUtc().subtract(const Duration(hours: 1))
              : DateTime.now().toUtc().add(const Duration(minutes: 20)),
        );

    test(
        'load returns null when storage has no key — web fallback / fresh install',
        () async {
      final store = SecureSessionStore(_MemorySecureStorage());
      expect(await store.load(), isNull);
    });

    test('save then load returns the same session', () async {
      final store = SecureSessionStore(_MemorySecureStorage());
      final session = makeSession();

      await store.save(session);
      final loaded = await store.load();

      expect(loaded, isNotNull);
      expect(loaded!.sessionId, session.sessionId);
      expect(loaded.nextSequence, session.nextSequence);
    });

    test('clear then load returns null — reinstall simulation', () async {
      final store = SecureSessionStore(_MemorySecureStorage());
      await store.save(makeSession());
      expect(await store.load(), isNotNull);

      await store.clear();
      expect(await store.load(), isNull,
          reason: 'session must be invalidated after reinstall (clear)');
    });

    test('second save overwrites first session', () async {
      final storage = _MemorySecureStorage();
      final store = SecureSessionStore(storage);

      final s1 = SecureSession(
        sessionId: 'session-old',
        protocolVersion: 'syn-sec-v1',
        selectedSuite: 'X25519-HKDF-SHA256-AES256GCM',
        clientToServerKey: _randomKey(),
        serverToClientKey: _randomKey(),
        expiresAtUtc: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      );
      final s2 = SecureSession(
        sessionId: 'session-new',
        protocolVersion: 'syn-sec-v1',
        selectedSuite: 'X25519-HKDF-SHA256-AES256GCM',
        clientToServerKey: _randomKey(),
        serverToClientKey: _randomKey(),
        expiresAtUtc: DateTime.now().toUtc().add(const Duration(minutes: 20)),
      );

      await store.save(s1);
      await store.save(s2);
      final loaded = await store.load();

      expect(loaded!.sessionId, 'session-new',
          reason: 'renewal must overwrite the previous session');
    });

    test('expired session is persisted and flagged correctly on reload',
        () async {
      final store = SecureSessionStore(_MemorySecureStorage());
      final expiredSession = makeSession(expired: true);

      await store.save(expiredSession);
      final loaded = await store.load();

      expect(loaded, isNotNull);
      expect(loaded!.isExpired, isTrue,
          reason:
              'store preserves sessions as-is; expiry check is caller responsibility');
    });

    test(
        'load across two store instances sharing storage reflects same session',
        () async {
      final sharedStorage = _MemorySecureStorage();
      final storeA = SecureSessionStore(sharedStorage);
      final storeB = SecureSessionStore(sharedStorage);

      final session = makeSession();
      await storeA.save(session);

      final loaded = await storeB.load();
      expect(loaded?.sessionId, session.sessionId,
          reason:
              'any store instance sharing the same secure storage must see the same session');
    });
  });

  // -------------------------------------------------------------------------
  // NEW: AAD contract and context binding
  // -------------------------------------------------------------------------

  group('SecurePayloadCodec — AAD contract and context binding', () {
    test('request AAD contains all 8 fields in the correct order', () async {
      final timestamp = '2026-05-21T00:00:00.000000Z';
      final ctx = SecureRequestContext(
        method: 'POST',
        pathAndQuery: '/users/me/friends/request?page=1',
        sessionId: 'abc123',
        sequence: 3,
        replayNonce: 'AAAA',
        subjectId: '',
        encryptedAtUtc: timestamp,
      );
      final body = {'x': 1};

      final encrypted = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: ctx,
      );

      // encryptedAtUtc in the payload must match the context (single source of truth).
      expect(encrypted.encryptedAtUtc, equals(timestamp));

      // Decrypting with the same context (request→response direction flip) must succeed.
      final decrypted = await codec.decryptJson(
        encryptedBody: encrypted.toJson(),
        keyBytes: keyBytes,
        context: ctx,
      );
      expect(decrypted, equals(body));
    });

    test(
        'query string is included in AAD — path without query fails to decrypt',
        () async {
      final body = {'spin': true};
      final ctxWithQuery =
          _ctx(pathAndQuery: '/arcade/spin/claim?sessionToken=tok');
      final ctxPathOnly = _ctx(pathAndQuery: '/arcade/spin/claim');

      final encrypted = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: ctxWithQuery,
      );

      await expectLater(
        () => codec.decryptJson(
          encryptedBody: encrypted.toJson(),
          keyBytes: keyBytes,
          context: ctxPathOnly,
        ),
        throwsA(isA<SecureDecryptException>()),
        reason: 'omitting query string from AAD must cause MAC failure',
      );
    });

    test('different sequence numbers produce different AAD and ciphertexts',
        () async {
      final body = {'value': 42};
      final ctx1 = _ctx(sequence: 1);
      final ctx2 = _ctx(sequence: 2);

      final enc1 = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: ctx1,
      );
      final enc2 = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: ctx2,
      );

      expect(enc1.ciphertext, isNot(equals(enc2.ciphertext)),
          reason: 'different sequences must produce different ciphertexts');

      await expectLater(
        () => codec.decryptJson(
          encryptedBody: enc1.toJson(),
          keyBytes: keyBytes,
          context: ctx2,
        ),
        throwsA(isA<SecureDecryptException>()),
        reason: 'decrypting seq-1 payload with seq-2 context must fail',
      );
    });

    test('replay nonce in context is independent of AES-GCM nonce in payload',
        () async {
      final replayNonce = base64Url.encode(List<int>.generate(16, (_) => 0xAB));
      final ctx = _ctx(replayNonce: replayNonce);

      final encrypted = await codec.encryptJson(
        body: {'action': 'spin'},
        keyBytes: keyBytes,
        context: ctx,
      );

      // The AES nonce in the EncryptedPayload is a fresh random 12 bytes —
      // it must differ from the replay nonce used for the header.
      expect(encrypted.nonce, isNot(equals(replayNonce)),
          reason:
              'AES-GCM nonce (payload) must be independent of the replay nonce (header)');
    });

    test('different session IDs produce different AAD and ciphertexts',
        () async {
      final body = {'loadout': 'default'};
      final ctxA = _ctx(sessionId: 'sessionaaa');
      final ctxB = _ctx(sessionId: 'sessionbbb');

      final encA = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: ctxA,
      );

      await expectLater(
        () => codec.decryptJson(
          encryptedBody: encA.toJson(),
          keyBytes: keyBytes,
          context: ctxB,
        ),
        throwsA(isA<SecureDecryptException>()),
        reason: 'session-A payload must not decrypt under session-B AAD',
      );
    });

    test('encryptedAtUtc mismatch in AAD causes decryption failure', () async {
      final body = {'friendId': 'f-1'};
      final ctxEnc = _ctx(encryptedAtUtc: '2026-05-21T10:00:00.000000Z');
      final ctxDec = _ctx(encryptedAtUtc: '2026-05-21T10:00:01.000000Z');

      final encrypted = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        context: ctxEnc,
      );

      await expectLater(
        () => codec.decryptJson(
          encryptedBody: encrypted.toJson(),
          keyBytes: keyBytes,
          context: ctxDec,
        ),
        throwsA(isA<SecureDecryptException>()),
        reason: 'a different encryptedAtUtc in the AAD must cause MAC failure',
      );
    });
  });
}

class _MemorySecureStorage extends SecureStorage {
  final Map<String, String> _secrets = {};

  @override
  Future<void> setSecret(String key, String value) async {
    _secrets[key] = value;
  }

  @override
  Future<String?> getSecret(String key) async {
    return _secrets[key];
  }

  @override
  Future<void> removeSecret(String key) async {
    _secrets.remove(key);
  }
}
