# TLS certificate pinning

Step 5 of the security hardening plan. Two independent channels are pinned:

1. **Client → API** (Flutter, `trivia_tycoon`) — the mobile app pins the API
   host's leaf certificate.
2. **Backend → KMS** (.NET, `TycoonTycoon_Backend`) — the API's KMS HTTP clients
   pin the KMS host's leaf certificate.

> The mobile client never connects to the KMS directly — `/api/v1/security/sessions/*`
> proxies to KMS server-side — so the client only pins the API host, and KMS
> pinning lives on the backend.

Both are **disabled by default** and activate only when pins are configured, so
nothing breaks until you deliberately turn them on with real fingerprints.

## What is pinned

A **pin** is the base64-encoded SHA-256 of the server's **leaf certificate DER**
(the raw cert bytes). Both repos use the identical pin shape, so one fingerprint
works for both.

> Leaf-DER pinning breaks when the server certificate is renewed (even with the
> same key). Always configure **two** pins — the current cert and the
> next-rotation cert — and add the new pin *before* rotating. See
> [Rotation](#rotation).

## Obtaining a pin

```bash
openssl s_client -servername api.synaptixplay.com \
  -connect api.synaptixplay.com:443 </dev/null 2>/dev/null \
  | openssl x509 -outform der \
  | openssl dgst -sha256 -binary \
  | openssl base64
```

Run the same against the KMS host for the backend pin.

## Client (Flutter → API)

Configured via env (`.env` or `--dart-define`):

| Var | Meaning |
|-----|---------|
| `TLS_PINNING_ENABLED` | `true` to enable pinning for the API host |
| `TLS_API_PINS` | comma-separated base64 SHA-256 leaf pins |

The host is derived from `API_BASE_URL`. Implementation:
`lib/core/networking/certificate_pinning.dart` (+ `_io`/`_stub` platform split).

- When active, the auth client, secure-channel client, refresh transport, and
  the legacy `ApiService` Dio all run over a pinned `HttpClient` that trusts
  **no** roots and accepts a connection only if the presented leaf matches a pin
  for that host (this also binds the connection to the expected host).
- **Web builds** never pin (the browser owns TLS trust); the stub returns a
  plain client. Non-API hosts (assets, compliance, CDNs) are unaffected.

## Backend (API → KMS)

Configured under the `KmsClient` options section (appsettings / env):

| Key | Meaning |
|-----|---------|
| `KmsClient:PinningEnabled` | `true` to enable KMS-host pinning |
| `KmsClient:PinnedCertificatesSha256` | array of base64 SHA-256 leaf pins |

Implementation: `ConfigureKmsCertificatePinning` in
`Synaptix.Security.Kms.Client/Extensions/ServiceCollectionExtensions.cs`, using
`KmsCertificatePinning`. When enabled, every KMS typed client
(`IKmsSessionClient`, `IKmsPayloadClient`, `IKmsKeyClient`, `IKmsInternalClient`)
uses a `SocketsHttpHandler` whose `RemoteCertificateValidationCallback` refuses
any leaf whose SHA-256 isn't in the pin set. When disabled, standard chain
validation applies unchanged.

Example `appsettings.Production.json`:

```json
{
  "KmsClient": {
    "PinningEnabled": true,
    "PinnedCertificatesSha256": [
      "<current-kms-leaf-sha256-b64>",
      "<next-kms-leaf-sha256-b64>"
    ]
  }
}
```

## Rotation

Because pins target the leaf cert, a naive renewal locks clients/servers out.
Safe procedure:

1. Obtain the fingerprint of the **new** cert before deploying it.
2. Add it to the pin list (`TLS_API_PINS` / `KmsClient:PinnedCertificatesSha256`)
   **alongside** the current pin, and ship that config.
3. Once the updated config is live everywhere, rotate the server certificate.
4. After rotation, drop the retired pin on the next config release.

For the mobile client, step 2 means a client release must reach users before the
cert rotates — so keep the pin window generous and prefer certs with longer
validity, or move to SPKI (public-key) pinning if you adopt a key-continuity
rotation policy.

## Testing

- Client: `test/core/networking/certificate_pinning_test.dart` (fingerprint
  match/reject, host binding, multi-pin rotation, inactive states).
- Backend: `Synaptix.Backend.Api.Tests/Security/KmsCertificatePinningTests.cs`.

The unit tests cover the fingerprint logic; end-to-end enforcement (a real TLS
handshake being accepted/refused) must be smoke-tested against a running host
with a known cert before enabling in production.
