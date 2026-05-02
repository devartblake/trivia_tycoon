# Synaptix Frontend Secure Channel Implementation Handoff

Repository: `devartblake/trivia_tycoon`

## Objective

Add a dedicated secure client-server payload encryption layer to the Flutter app without replacing the existing `ApiService`, `AuthHttpClient`, `SecureStorage`, or auth flow.

This should be implemented as a network security feature, separate from the current local encryption utilities.

## Current frontend fit

The app already initializes these services centrally in `ServiceManager`:

- `ApiService`
- `SecureStorage`
- `EncryptionService`
- `FernetService`
- `AuthTokenStore`
- `AuthHttpClient`
- `SynaptixApiClient`
- SignalR hubs

Add secure-channel support into this same initialization path.

## New files

```text
lib/core/security/
  secure_channel_models.dart
  secure_channel_service.dart
  secure_session_store.dart
  secure_payload_codec.dart
  secure_channel_exceptions.dart

lib/core/networking/
  encrypted_api_client.dart
```

## Dependencies

Add a reviewed cryptography package that supports AEAD and key exchange.

Recommended initial option:

```yaml
dependencies:
  cryptography: ^2.9.0
```

Do not implement AES, nonce generation, HKDF, or key exchange manually.

## Data models

### `SecureSession`

```dart
class SecureSession {
  final String sessionId;
  final String protocolVersion;
  final String selectedSuite;
  final List<int> clientToServerKey;
  final List<int> serverToClientKey;
  final DateTime expiresAtUtc;
  final int nextSequence;

  const SecureSession({
    required this.sessionId,
    required this.protocolVersion,
    required this.selectedSuite,
    required this.clientToServerKey,
    required this.serverToClientKey,
    required this.expiresAtUtc,
    required this.nextSequence,
  });

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAtUtc);
}
```

### `EncryptedPayload`

```dart
class EncryptedPayload {
  final String ciphertext;
  final String nonce;
  final String mac;
  final String contentType;
  final String encryptedAtUtc;

  const EncryptedPayload({
    required this.ciphertext,
    required this.nonce,
    required this.mac,
    required this.contentType,
    required this.encryptedAtUtc,
  });

  Map<String, dynamic> toJson() => {
    'ciphertext': ciphertext,
    'nonce': nonce,
    'mac': mac,
    'contentType': contentType,
    'encryptedAtUtc': encryptedAtUtc,
  };
}
```

## Secure channel flow

### 1. Start session after login

Call:

```http
POST /security/sessions/start
```

Request:

```json
{
  "deviceId": "device-id",
  "clientNonce": "base64url",
  "clientPublicKey": "base64url",
  "supportedSuites": [
    "X25519-HKDF-SHA256-AES256GCM"
  ]
}
```

### 2. Derive directional keys

Use X25519 to derive a shared secret, then HKDF-SHA256 to derive:

- `clientToServerKey`
- `serverToClientKey`

Never store the server root key or any static shared secret in the Flutter app.

### 3. Encrypt selected requests

Wrap only sensitive endpoints first:

- `/auth/login`
- `/auth/refresh`
- `/players/me`
- `/economy/*`
- `/matches/submit`
- `/admin/*` if admin mobile tooling exists
- `/messages/*`
- `/guardians/*`

Do not encrypt public catalog, static asset, or public leaderboard reads at first.

## `SecureChannelService` responsibilities

```dart
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
}
```

## `EncryptedApiClient` behavior

The wrapper should:

1. Get access token from `AuthTokenStore`.
2. Ensure a secure session exists.
3. Encrypt request body.
4. Add secure headers.
5. Send through existing authenticated HTTP client.
6. Decrypt encrypted responses.
7. Retry once after session renewal if session expired.

Headers:

```http
X-Syn-Sec-Session: <sessionId>
X-Syn-Sec-Seq: <number>
X-Syn-Sec-Nonce: <base64url nonce>
X-Syn-Sec-Version: syn-sec-v1
```

## ServiceManager patch

Add fields:

```dart
final SecureSessionStore secureSessionStore;
final SecureChannelService secureChannelService;
final EncryptedApiClient encryptedApiClient;
```

Initialize after auth/token services exist:

```dart
final secureSessionStore = SecureSessionStore(secureStorage);
final secureChannel = DefaultSecureChannelService(
  httpClient: authHttpClient,
  sessionStore: secureSessionStore,
  deviceIdService: deviceIdSvc,
  baseUrl: baseUrl,
);
final encryptedApiClient = EncryptedApiClient(
  authClient: authHttpClient,
  secureChannel: secureChannel,
  tokenStore: tokenStore,
  baseUrl: '$baseUrl/api/v1',
);
```

## Storage rules

Use `SecureStorage` only for:

- Current secure session metadata.
- Ephemeral private key if app backgrounding requires it.
- Sequence counter.

Do not store:

- Backend root keys.
- Vault tokens.
- Long-lived symmetric payload keys.
- Hardcoded encryption secrets.

## Testing checklist

- Encrypt/decrypt roundtrip works for JSON payloads.
- Wrong nonce fails decryption.
- Wrong sequence fails on backend.
- Expired secure session renews automatically.
- Logout clears secure session.
- App reinstall invalidates old secure session.
- Web build has fallback behavior if selected crypto is unsupported.
- Performance test with 1 KB, 10 KB, and 100 KB payloads.

## First implementation milestone

Implement `SecureChannelService` and use it only for one non-critical endpoint in dev. Once stable, move to auth refresh, match submission, economy claims, and private messages.
