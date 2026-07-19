import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'secure_channel_exceptions.dart';
import 'secure_channel_models.dart';

class SecurePayloadCodec {
  static const _aadVersion = 'syn-sec-v1';
  final Cipher _cipher = AesGcm.with256bits();

  String _buildAad(SecureRequestContext ctx, {required bool isResponse}) =>
      '$_aadVersion|${isResponse ? 'response' : 'request'}'
      '|${ctx.method.toUpperCase()}|${ctx.pathAndQuery}'
      '|${ctx.sessionId}|${ctx.sequence}|${ctx.subjectId}|${ctx.encryptedAtUtc}';

  Future<EncryptedPayload> encryptJson({
    required Map<String, dynamic> body,
    required List<int> keyBytes,
    required SecureRequestContext context,
    // Defaults to the request direction: the client encrypts requests. The
    // request/response tag is bound into the AAD so a payload can't be replayed
    // in the opposite direction. decryptJson must use the matching direction.
    bool isResponse = false,
  }) async {
    final random = Random.secure();
    final nonce = List<int>.generate(12, (_) => random.nextInt(256));
    final secretKey = SecretKey(keyBytes);
    final clear = utf8.encode(jsonEncode(body));
    final aad = utf8.encode(_buildAad(context, isResponse: isResponse));

    final box = await _cipher.encrypt(
      clear,
      secretKey: secretKey,
      nonce: nonce,
      aad: aad,
    );

    return EncryptedPayload(
      ciphertext: base64Url.encode(box.cipherText),
      nonce: base64Url.encode(nonce),
      mac: base64Url.encode(box.mac.bytes),
      contentType: 'application/json',
      encryptedAtUtc: context.encryptedAtUtc,
    );
  }

  Future<Map<String, dynamic>> decryptJson({
    required Map<String, dynamic> encryptedBody,
    required List<int> keyBytes,
    required SecureRequestContext context,
    // Defaults to the response direction: the client decrypts responses. Pass
    // isResponse: false to decrypt a payload that was encrypted as a request.
    bool isResponse = true,
  }) async {
    try {
      final payload = EncryptedPayload.fromJson(encryptedBody);
      final nonce = base64Url.decode(payload.nonce);
      final cipherText = base64Url.decode(payload.ciphertext);
      final mac = Mac(base64Url.decode(payload.mac));
      final aad = utf8.encode(_buildAad(context, isResponse: isResponse));

      final clear = await _cipher.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: mac),
        secretKey: SecretKey(keyBytes),
        aad: aad,
      );
      final decoded = jsonDecode(utf8.decode(Uint8List.fromList(clear)));
      if (decoded is! Map<String, dynamic>) {
        throw const SecureDecryptException(
            'Decrypted payload is not an object');
      }
      return decoded;
    } catch (e) {
      throw SecureDecryptException('Failed to decrypt secure payload: $e');
    }
  }
}
