import 'dart:convert';

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
  }) async {
    return _sendEncrypted(method: 'POST', path: path, body: body);
  }

  Future<Map<String, dynamic>> putEncrypted(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    return _sendEncrypted(method: 'PUT', path: path, body: body);
  }

  Future<Map<String, dynamic>> patchEncrypted(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    return _sendEncrypted(method: 'PATCH', path: path, body: body);
  }

  Future<Map<String, dynamic>> deleteEncrypted(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    return _sendEncrypted(method: 'DELETE', path: path, body: body);
  }

  Future<Map<String, dynamic>> _sendEncrypted({
    required String method,
    required String path,
    required Map<String, dynamic> body,
  }) async {
    final session = _tokenStore.load();
    final accessToken = session.accessToken;
    if (accessToken.isEmpty) {
      throw const SecureChannelException('No access token available');
    }

    Future<Map<String, dynamic>> doSend() async {
      final uri = Uri.parse('$baseUrl$path');
      final encrypted = await _secureChannel.encryptJson(
        uri: uri,
        method: method,
        body: body,
        accessToken: accessToken,
      );
      final activeSession = await _secureChannel.loadSession();
      if (activeSession == null) {
        throw const SecureChannelException(
            'No secure session after encryptJson');
      }
      final response = await _request(
        method: method,
        uri: uri,
        encrypted: encrypted,
        secureSession: activeSession,
      );

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> &&
          decoded.containsKey('ciphertext')) {
        return _secureChannel.decryptJsonResponse(
          uri: uri,
          method: method,
          encryptedBody: decoded,
        );
      }
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{'data': decoded};
    }

    try {
      return await doSend();
    } on SecureSessionExpiredException {
      await _secureChannel.startSession(accessToken: accessToken);
      return doSend();
    }
  }

  Future<http.Response> _request({
    required String method,
    required Uri uri,
    required EncryptedPayload encrypted,
    required SecureSession secureSession,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Syn-Sec-Session': secureSession.sessionId,
      'X-Syn-Sec-Seq': secureSession.nextSequence.toString(),
      'X-Syn-Sec-Nonce': encrypted.nonce,
      'X-Syn-Sec-Version': secureSession.protocolVersion,
    };

    switch (method.toUpperCase()) {
      case 'POST':
        return _authClient.post(
          uri,
          headers: headers,
          body: jsonEncode(encrypted.toJson()),
        );
      case 'PUT':
        return _authClient.put(
          uri,
          headers: headers,
          body: jsonEncode(encrypted.toJson()),
        );
      case 'PATCH':
        return _authClient.patch(
          uri,
          headers: headers,
          body: jsonEncode(encrypted.toJson()),
        );
      case 'DELETE':
        return _authClient.delete(
          uri,
          headers: headers,
          body: jsonEncode(encrypted.toJson()),
        );
      default:
        throw SecureChannelException('Unsupported secure method: $method');
    }
  }
}
