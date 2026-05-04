import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../services/auth_http_client.dart';
import '../services/device_id_service.dart';
import 'secure_channel_exceptions.dart';
import 'secure_channel_models.dart';
import 'secure_payload_codec.dart';
import 'secure_session_store.dart';

abstract class SecureChannelService {
  Future<SecureSession> startSession({required String accessToken});
  Future<EncryptedPayload> encryptJson({
    required Uri uri,
    required String method,
    required Map<String, dynamic> body,
    required String accessToken,
  });
  Future<Map<String, dynamic>> decryptJsonResponse({
    required Uri uri,
    required String method,
    required Map<String, dynamic> encryptedBody,
  });
  Future<void> clearSession();
  Future<SecureSession?> loadSession();
}

class DefaultSecureChannelService implements SecureChannelService {
  final AuthHttpClient _httpClient;
  final SecureSessionStore _sessionStore;
  final DeviceIdService _deviceIdService;
  final SecurePayloadCodec _codec;
  final String _baseUrl;

  static const _suite = 'X25519-HKDF-SHA256-AES256GCM';

  SimpleKeyPairData? _ephemeralKeyPair;

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  DefaultSecureChannelService({
    required AuthHttpClient httpClient,
    required SecureSessionStore sessionStore,
    required DeviceIdService deviceIdService,
    required String baseUrl,
    SecurePayloadCodec? codec,
  })  : _httpClient = httpClient,
        _sessionStore = sessionStore,
        _deviceIdService = deviceIdService,
        _codec = codec ?? SecurePayloadCodec(),
        _baseUrl = baseUrl;

  @override
  Future<SecureSession?> loadSession() => _sessionStore.load();

  @override
  Future<SecureSession> startSession({required String accessToken}) async {
    final algorithm = X25519();
    final clientNonce = _randomBytes(16);
    final keyPair = await algorithm.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    _ephemeralKeyPair = await keyPair.extract();

    final deviceId = await _deviceIdService.getOrCreate();
    final uri = Uri.parse('$_baseUrl/api/v1/security/sessions/start');
    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'deviceId': deviceId,
        'clientNonce': base64Url.encode(clientNonce),
        'clientPublicKey': base64Url.encode(publicKey.bytes),
        'supportedSuites': [_suite],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SecureChannelException(
          'Secure session start failed (${response.statusCode})');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final serverPublicKey = (payload['serverPublicKey'] ?? '').toString();
    if (serverPublicKey.isEmpty) {
      throw const SecureChannelException('Missing serverPublicKey in response');
    }

    final shared = await algorithm.sharedSecretKey(
      keyPair: _ephemeralKeyPair!,
      remotePublicKey: SimplePublicKey(base64Url.decode(serverPublicKey),
          type: KeyPairType.x25519),
    );
    final sharedBytes = await shared.extractBytes();

    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 64);
    final expanded = await hkdf.deriveKey(
      secretKey: SecretKey(sharedBytes),
      nonce: clientNonce,
      info: utf8.encode('syn-sec-v1|$_suite'),
    );
    final expandedBytes = await expanded.extractBytes();

    final expiresAt = DateTime.tryParse(payload['expiresAtUtc']?.toString() ?? '')
            ?.toUtc() ??
        DateTime.now().toUtc().add(const Duration(minutes: 20));

    final session = SecureSession(
      sessionId: payload['sessionId']?.toString() ?? '',
      protocolVersion: payload['protocolVersion']?.toString() ?? 'syn-sec-v1',
      selectedSuite: payload['selectedSuite']?.toString() ?? _suite,
      clientToServerKey: expandedBytes.sublist(0, 32),
      serverToClientKey: expandedBytes.sublist(32, 64),
      expiresAtUtc: expiresAt,
      nextSequence: 1,
    );

    await _sessionStore.save(session);
    return session;
  }

  @override
  Future<EncryptedPayload> encryptJson({
    required Uri uri,
    required String method,
    required Map<String, dynamic> body,
    required String accessToken,
  }) async {
    var session = await _sessionStore.load();
    session ??= await startSession(accessToken: accessToken);

    if (session.isExpired) {
      session = await startSession(accessToken: accessToken);
    }

    final encrypted = await _codec.encryptJson(
      body: body,
      keyBytes: session.clientToServerKey,
      method: method,
      uri: uri,
    );

    await _sessionStore.save(session.copyWith(nextSequence: session.nextSequence + 1));
    return encrypted;
  }

  @override
  Future<Map<String, dynamic>> decryptJsonResponse({
    required Uri uri,
    required String method,
    required Map<String, dynamic> encryptedBody,
  }) async {
    final session = await _sessionStore.load();
    if (session == null) {
      throw const SecureChannelException('No secure session exists');
    }
    return _codec.decryptJson(
      encryptedBody: encryptedBody,
      keyBytes: session.serverToClientKey,
      method: method,
      uri: uri,
    );
  }

  @override
  Future<void> clearSession() async {
    _ephemeralKeyPair = null;
    await _sessionStore.clear();
  }
}
