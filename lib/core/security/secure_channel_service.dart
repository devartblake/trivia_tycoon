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

  /// Encrypts [body] using [keyBytes] and [context] for AAD binding.
  /// Does NOT persist the sequence increment — caller must call
  /// [persistSequenceIncrement] after successfully assembling headers.
  Future<EncryptedPayload> encryptJson({
    required Map<String, dynamic> body,
    required List<int> keyBytes,
    required SecureRequestContext context,
  });

  Future<Map<String, dynamic>> decryptJsonResponse({
    required SecureRequestContext context,
    required Map<String, dynamic> encryptedBody,
  });

  /// Persists the incremented sequence number after a request envelope and
  /// headers have been assembled successfully.
  Future<void> persistSequenceIncrement(SecureSession session);

  Future<void> clearSession();
  Future<SecureSession?> loadSession();
}

class DefaultSecureChannelService implements SecureChannelService {
  final AuthHttpClient _httpClient;
  final SecureSessionStore _sessionStore;
  final DeviceIdService _deviceIdService;
  final SecurePayloadCodec _codec;
  final String _baseUrl;

  static const _suiteX25519 = 'X25519-HKDF-SHA256-AES256GCM';

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
    final clientNonce = _randomBytes(16);
    final deviceId = await _deviceIdService.getOrCreate();
    final uri = Uri.parse('$_baseUrl/api/v1/security/sessions/start');

    // Advertise both suites; backend selects the one to use.
    final x25519 = X25519();
    final keyPair = await x25519.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    _ephemeralKeyPair = await keyPair.extract();

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
        'supportedSuites': [_suiteX25519, 'P256-HKDF-SHA256-AES256GCM'],
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

    final selectedSuite =
        payload['selectedSuite']?.toString() ?? _suiteX25519;

    // We always send an X25519 public key; the server performs X25519 ECDH
    // regardless of the selected suite label. The suite label differentiates
    // the HKDF info string so keys derived for different suites are distinct.
    final sharedSecret = await x25519.sharedSecretKey(
      keyPair: _ephemeralKeyPair!,
      remotePublicKey: SimplePublicKey(base64Url.decode(serverPublicKey),
          type: KeyPairType.x25519),
    );

    final sharedBytes = await sharedSecret.extractBytes();
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 64);
    final expanded = await hkdf.deriveKey(
      secretKey: SecretKey(sharedBytes),
      nonce: clientNonce,
      info: utf8.encode('syn-sec-v1|$selectedSuite'),
    );
    final expandedBytes = await expanded.extractBytes();

    final expiresAt =
        DateTime.tryParse(payload['expiresAtUtc']?.toString() ?? '')?.toUtc() ??
            DateTime.now().toUtc().add(const Duration(minutes: 20));

    final session = SecureSession(
      sessionId: payload['sessionId']?.toString() ?? '',
      protocolVersion: payload['protocolVersion']?.toString() ?? 'syn-sec-v1',
      selectedSuite: selectedSuite,
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
    required Map<String, dynamic> body,
    required List<int> keyBytes,
    required SecureRequestContext context,
  }) =>
      _codec.encryptJson(body: body, keyBytes: keyBytes, context: context);

  @override
  Future<Map<String, dynamic>> decryptJsonResponse({
    required SecureRequestContext context,
    required Map<String, dynamic> encryptedBody,
  }) async {
    final session = await _sessionStore.load();
    if (session == null) {
      throw const SecureChannelException('No secure session exists');
    }
    return _codec.decryptJson(
      encryptedBody: encryptedBody,
      keyBytes: session.serverToClientKey,
      context: context,
    );
  }

  @override
  Future<void> persistSequenceIncrement(SecureSession session) =>
      _sessionStore.save(session.copyWith(nextSequence: session.nextSequence + 1));

  @override
  Future<void> clearSession() async {
    _ephemeralKeyPair = null;
    await _sessionStore.clear();
  }
}
