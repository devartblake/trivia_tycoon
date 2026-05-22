import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../security/secure_channel_exceptions.dart';
import '../security/secure_channel_models.dart';
import '../security/secure_channel_service.dart';
import '../services/auth_http_client.dart';
import '../services/auth_token_store.dart';

class EncryptedApiClient {
  final AuthHttpClient _authClient;
  final SecureChannelService _secureChannel;
  final AuthTokenStore _tokenStore;
  final String baseUrl;

  EncryptedApiClient({
    required AuthHttpClient authClient,
    required SecureChannelService secureChannel,
    required AuthTokenStore tokenStore,
    required this.baseUrl,
  })  : _authClient = authClient,
        _secureChannel = secureChannel,
        _tokenStore = tokenStore;

  Future<Map<String, dynamic>> postEncrypted(
    String path, {
    required Map<String, dynamic> body,
  }) =>
      _sendEncrypted(method: 'POST', path: path, body: body);

  Future<Map<String, dynamic>> putEncrypted(
    String path, {
    required Map<String, dynamic> body,
  }) =>
      _sendEncrypted(method: 'PUT', path: path, body: body);

  Future<Map<String, dynamic>> patchEncrypted(
    String path, {
    required Map<String, dynamic> body,
  }) =>
      _sendEncrypted(method: 'PATCH', path: path, body: body);

  Future<Map<String, dynamic>> deleteEncrypted(
    String path, {
    required Map<String, dynamic> body,
  }) =>
      _sendEncrypted(method: 'DELETE', path: path, body: body);

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  Future<Map<String, dynamic>> _sendEncrypted({
    required String method,
    required String path,
    required Map<String, dynamic> body,
  }) async {
    final authSession = _tokenStore.load();
    final accessToken = authSession.accessToken;
    if (accessToken.isEmpty) {
      throw const SecureChannelException('No access token available');
    }

    Future<Map<String, dynamic>> doSend() async {
      // 1. Load or start a secure session.
      var secureSession = await _secureChannel.loadSession();
      if (secureSession == null || secureSession.isExpired) {
        secureSession =
            await _secureChannel.startSession(accessToken: accessToken);
      }

      final uri = Uri.parse('$baseUrl$path');

      // 2. Capture sequence, generate nonce and timestamp before encryption.
      final sequence = secureSession.nextSequence;
      final replayNonce = base64Url.encode(_randomBytes(16));
      final encryptedAtUtc = DateTime.now().toUtc().toIso8601String();
      final pathAndQuery =
          uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;

      final context = SecureRequestContext(
        method: method,
        pathAndQuery: pathAndQuery,
        sessionId: secureSession.sessionId.replaceAll('-', ''),
        sequence: sequence,
        replayNonce: replayNonce,
        subjectId: '',
        encryptedAtUtc: encryptedAtUtc,
      );

      // 3. Encrypt using the captured context.
      final encrypted = await _secureChannel.encryptJson(
        body: body,
        keyBytes: secureSession.clientToServerKey,
        context: context,
      );

      // 4. Persist incremented sequence only after envelope is assembled.
      await _secureChannel.persistSequenceIncrement(secureSession);

      // 5. Send the request.
      final response = await _request(
        method: method,
        uri: uri,
        encrypted: encrypted,
        context: context,
        protocolVersion: secureSession.protocolVersion,
      );

      // 6. Decrypt if the response body is an encrypted payload.
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> &&
          decoded.containsKey('ciphertext')) {
        return _secureChannel.decryptJsonResponse(
          context: context,
          encryptedBody: decoded,
        );
      }
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{'data': decoded};
    }

    try {
      return await doSend();
    } on SecureSessionExpiredException {
      // Session-expired/invalid: clear and let doSend() start a fresh one.
      await _secureChannel.clearSession();
      return doSend();
    }
  }

  Future<http.Response> _request({
    required String method,
    required Uri uri,
    required EncryptedPayload encrypted,
    required SecureRequestContext context,
    required String protocolVersion,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Syn-Sec-Session': context.sessionId,
      'X-Syn-Sec-Seq': context.sequence.toString(),
      'X-Syn-Sec-Nonce': context.replayNonce,
      'X-Syn-Sec-Version': protocolVersion,
    };

    switch (method.toUpperCase()) {
      case 'POST':
        return _authClient.post(uri,
            headers: headers, body: jsonEncode(encrypted.toJson()));
      case 'PUT':
        return _authClient.put(uri,
            headers: headers, body: jsonEncode(encrypted.toJson()));
      case 'PATCH':
        return _authClient.patch(uri,
            headers: headers, body: jsonEncode(encrypted.toJson()));
      case 'DELETE':
        return _authClient.delete(uri,
            headers: headers, body: jsonEncode(encrypted.toJson()));
      default:
        throw SecureChannelException('Unsupported secure method: $method');
    }
  }
}
