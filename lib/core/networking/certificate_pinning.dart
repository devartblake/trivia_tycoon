import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart' show HttpClientAdapter;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:synaptix/core/env.dart';

// Platform split: the io implementation uses dart:io TLS APIs; the stub is used
// on web (no dart:io — the browser owns certificate trust there).
import 'certificate_pinning_stub.dart'
    if (dart.library.io) 'certificate_pinning_io.dart' as platform;

/// TLS certificate pinning policy for outbound API traffic.
///
/// Pins are base64-encoded SHA-256 hashes of a host's **leaf certificate DER**.
/// Supply the current cert plus the next-rotation cert so a server cert renewal
/// doesn't lock clients out. Obtain a pin with:
///
/// ```
/// openssl s_client -servername HOST -connect HOST:443 </dev/null 2>/dev/null \
///   | openssl x509 -outform der | openssl dgst -sha256 -binary | openssl base64
/// ```
///
/// See docs/api/TLS_CERTIFICATE_PINNING.md.
@immutable
class CertificatePinningPolicy {
  const CertificatePinningPolicy({
    required this.enabled,
    required this.pinsByHost,
  });

  /// Builds the policy from [EnvConfig] (API host + TLS_* env vars).
  factory CertificatePinningPolicy.fromEnv() {
    final host = EnvConfig.tlsApiHost;
    final pins = EnvConfig.tlsApiPins
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    return CertificatePinningPolicy(
      enabled: EnvConfig.tlsPinningEnabled,
      pinsByHost: (host != null && host.isNotEmpty && pins.isNotEmpty)
          ? {host.toLowerCase(): pins}
          : const {},
    );
  }

  final bool enabled;

  /// host (lowercased) -> list of base64 SHA-256 leaf-DER pins.
  final Map<String, List<String>> pinsByHost;

  /// Pinning only engages when enabled, off-web (dart:io TLS unavailable on
  /// web — the browser owns trust there), and at least one pin is configured.
  bool get isActive =>
      enabled && !kIsWeb && pinsByHost.values.any((p) => p.isNotEmpty);

  List<String>? pinsFor(String host) => pinsByHost[host.toLowerCase()];

  /// Pure fingerprint check — used by the TLS callback and unit tests.
  /// Returns true iff [der] (a leaf certificate's DER bytes) hashes to one of
  /// the pins registered for [host].
  bool certificateMatches(String host, List<int> der) {
    final pins = pinsFor(host);
    if (pins == null || pins.isEmpty) return false;
    final fingerprint = base64.encode(sha256.convert(der).bytes);
    return pins.contains(fingerprint);
  }
}

/// Builds an [http.Client] that pins TLS to the API host per [policy].
///
/// When the policy is inactive (disabled / web / no pins) this returns a plain
/// [http.Client] so nothing changes. When active it returns a client that trusts
/// **no** roots and accepts a connection only if the presented leaf certificate
/// matches a configured pin for that host — which both enforces the pin and
/// binds the connection to the expected host.
///
/// Use this ONLY for clients that talk exclusively to the pinned API host
/// (auth, secure channel, core API). A pinned client rejects every other host.
http.Client createPinnedApiClient(CertificatePinningPolicy policy) {
  if (!policy.isActive) return http.Client();
  return platform.createPinnedClient(policy);
}

/// Returns a Dio [HttpClientAdapter] that pins to the API host, or null when
/// pinning is inactive (caller keeps Dio's default adapter). Always null on web.
HttpClientAdapter? createPinnedDioAdapter(CertificatePinningPolicy policy) {
  if (!policy.isActive) return null;
  return platform.createPinnedDioAdapter(policy);
}
