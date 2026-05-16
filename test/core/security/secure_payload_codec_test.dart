import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/security/secure_channel_exceptions.dart';
import 'package:trivia_tycoon/core/security/secure_channel_models.dart';
import 'package:trivia_tycoon/core/security/secure_payload_codec.dart';
import 'package:trivia_tycoon/core/security/secure_session_store.dart';
import 'package:trivia_tycoon/core/services/storage/secure_storage.dart';

List<int> _randomKey() =>
    List<int>.generate(32, (_) => Random.secure().nextInt(256));

void main() {
  late SecurePayloadCodec codec;
  late List<int> keyBytes;
  final uri = Uri.parse('https://api.example.com/users/me/friends/request');

  setUp(() {
    codec = SecurePayloadCodec();
    keyBytes = _randomKey();
  });

  group('SecurePayloadCodec', () {
    test('encrypt/decrypt round-trip returns original payload', () async {
      final body = {'targetUserId': 'user-123', 'message': 'hello'};

      final encrypted = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        method: 'POST',
        uri: uri,
      );

      final decrypted = await codec.decryptJson(
        encryptedBody: encrypted.toJson(),
        keyBytes: keyBytes,
        method: 'POST',
        uri: uri,
      );

      expect(decrypted, equals(body));
    });

    test('two successive encryptions produce different nonces', () async {
      final body = {'key': 'value'};

      final enc1 = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        method: 'POST',
        uri: uri,
      );
      final enc2 = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        method: 'POST',
        uri: uri,
      );

      expect(enc1.nonce, isNot(equals(enc2.nonce)));
    });

    test('two successive encryptions produce different ciphertexts', () async {
      final body = {'key': 'value'};

      final enc1 = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        method: 'POST',
        uri: uri,
      );
      final enc2 = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        method: 'POST',
        uri: uri,
      );

      expect(enc1.ciphertext, isNot(equals(enc2.ciphertext)));
    });

    test('wrong key throws SecureDecryptException', () async {
      final body = {'data': 42};
      final wrongKey = _randomKey();

      final encrypted = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        method: 'POST',
        uri: uri,
      );

      expect(
        () => codec.decryptJson(
          encryptedBody: encrypted.toJson(),
          keyBytes: wrongKey,
          method: 'POST',
          uri: uri,
        ),
        throwsA(isA<SecureDecryptException>()),
      );
    });

    test('tampered MAC throws SecureDecryptException', () async {
      final body = {'amount': 100};
      final encrypted = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        method: 'POST',
        uri: uri,
      );

      final json = encrypted.toJson();
      // Flip the last character of the MAC
      final mac = json['mac'] as String;
      json['mac'] =
          mac.substring(0, mac.length - 1) + (mac.endsWith('A') ? 'B' : 'A');

      expect(
        () => codec.decryptJson(
          encryptedBody: json,
          keyBytes: keyBytes,
          method: 'POST',
          uri: uri,
        ),
        throwsA(isA<SecureDecryptException>()),
      );
    });

    test('wrong nonce throws SecureDecryptException', () async {
      final body = {'amount': 100};
      final encrypted = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        method: 'POST',
        uri: uri,
      );

      final json = encrypted.toJson();
      final nonce = json['nonce'] as String;
      json['nonce'] = nonce.substring(0, nonce.length - 1) +
          (nonce.endsWith('A') ? 'B' : 'A');

      expect(
        () => codec.decryptJson(
          encryptedBody: json,
          keyBytes: keyBytes,
          method: 'POST',
          uri: uri,
        ),
        throwsA(isA<SecureDecryptException>()),
      );
    });

    test('wrong method in AAD causes decryption failure', () async {
      final body = {'x': 1};
      final encrypted = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        method: 'POST',
        uri: uri,
      );

      expect(
        () => codec.decryptJson(
          encryptedBody: encrypted.toJson(),
          keyBytes: keyBytes,
          method: 'GET', // wrong method
          uri: uri,
        ),
        throwsA(isA<SecureDecryptException>()),
      );
    });

    test('wrong URI path in AAD causes decryption failure', () async {
      final body = {'x': 1};
      final encrypted = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        method: 'POST',
        uri: uri,
      );

      expect(
        () => codec.decryptJson(
          encryptedBody: encrypted.toJson(),
          keyBytes: keyBytes,
          method: 'POST',
          uri: Uri.parse('https://api.example.com/different/path'),
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
        method: 'PUT',
        uri: uri,
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

        final encrypted = await codec.encryptJson(
          body: body,
          keyBytes: keyBytes,
          method: 'PATCH',
          uri: uri,
        );

        final decrypted = await codec.decryptJson(
          encryptedBody: encrypted.toJson(),
          keyBytes: keyBytes,
          method: 'PATCH',
          uri: uri,
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
          method: 'POST',
          uri: uri,
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

      final enc1 = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        method: 'POST',
        uri: uri,
      );
      final enc2 = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        method: 'POST',
        uri: uri,
      );

      // Swap nonces: enc1's ciphertext with enc2's nonce
      final tampered = {
        'ciphertext': enc1.ciphertext,
        'nonce': enc2.nonce, // wrong nonce for this ciphertext
        'mac': enc1.mac,
        'contentType': enc1.contentType,
        'encryptedAtUtc': enc1.encryptedAtUtc,
      };

      await expectLater(
        () => codec.decryptJson(
          encryptedBody: tampered,
          keyBytes: keyBytes,
          method: 'POST',
          uri: uri,
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

      final enc = await codec.encryptJson(
        body: body,
        keyBytes: keyA,
        method: 'DELETE',
        uri: uri,
      );

      await expectLater(
        () => codec.decryptJson(
          encryptedBody: enc.toJson(),
          keyBytes:
              keyB, // wrong session key — simulates session-A payload replayed in session-B
          method: 'DELETE',
          uri: uri,
        ),
        throwsA(isA<SecureDecryptException>()),
        reason: 'cross-session replay with a different key must be rejected',
      );
    });

    test(
        'AAD binding: ciphertext for endpoint A cannot be replayed at endpoint B',
        () async {
      final uriA = Uri.parse('https://api.example.com/friends/request');
      final uriB = Uri.parse('https://api.example.com/friends/accept');
      final body = {'targetUserId': 'u-42'};

      final enc = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        method: 'POST',
        uri: uriA,
      );

      await expectLater(
        () => codec.decryptJson(
          encryptedBody: enc.toJson(),
          keyBytes: keyBytes,
          method: 'POST',
          uri: uriB, // different endpoint — AAD mismatch
        ),
        throwsA(isA<SecureDecryptException>()),
        reason:
            'replay to a different endpoint must fail due to AAD URI binding',
      );
    });

    test('AAD binding: ciphertext for POST cannot be replayed as DELETE',
        () async {
      final body = {'resourceId': 'r-99'};

      final enc = await codec.encryptJson(
        body: body,
        keyBytes: keyBytes,
        method: 'POST',
        uri: uri,
      );

      await expectLater(
        () => codec.decryptJson(
          encryptedBody: enc.toJson(),
          keyBytes: keyBytes,
          method: 'DELETE', // different verb — AAD mismatch
          uri: uri,
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
    SecureSession _makeSession({bool expired = false}) => SecureSession(
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
      final session = _makeSession();

      await store.save(session);
      final loaded = await store.load();

      expect(loaded, isNotNull);
      expect(loaded!.sessionId, session.sessionId);
      expect(loaded.nextSequence, session.nextSequence);
    });

    test('clear then load returns null — reinstall simulation', () async {
      final store = SecureSessionStore(_MemorySecureStorage());
      await store.save(_makeSession());
      expect(await store.load(), isNotNull);

      await store.clear(); // simulate reinstall wiping secure storage
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
      final expiredSession = _makeSession(expired: true);

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

      final session = _makeSession();
      await storeA.save(session);

      final loaded = await storeB.load();
      expect(loaded?.sessionId, session.sessionId,
          reason:
              'any store instance sharing the same secure storage must see the same session');
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
