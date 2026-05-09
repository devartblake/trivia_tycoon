import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/security/secure_channel_exceptions.dart';
import 'package:trivia_tycoon/core/security/secure_payload_codec.dart';

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
      json['mac'] = mac.substring(0, mac.length - 1) +
          (mac.endsWith('A') ? 'B' : 'A');

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
  });
}
