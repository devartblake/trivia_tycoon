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
