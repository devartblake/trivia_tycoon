import 'dart:io';

import 'package:dio/dio.dart' show HttpClientAdapter;
import 'package:dio/io.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'certificate_pinning.dart';
import '../manager/log_manager.dart';

/// dart:io implementation of API certificate pinning.
///
/// The underlying [HttpClient] trusts no roots, so every presented certificate
/// lands in [HttpClient.badCertificateCallback]; we accept it only when its leaf
/// DER matches a configured pin for that host. This both enforces the pin and
/// binds the connection to the expected host (a cert pinned for host A won't
/// satisfy a request to host B).
bool _pinCheck(CertificatePinningPolicy policy, X509Certificate cert,
    String host, int port) {
  final matched = policy.certificateMatches(host, cert.der);
  if (!matched) {
    LogManager.debug(
        '[CertPinning] Rejected TLS cert for $host:$port — no pin match.');
  }
  return matched;
}

HttpClient _newPinnedHttpClient(CertificatePinningPolicy policy) {
  return HttpClient(context: SecurityContext(withTrustedRoots: false))
    ..badCertificateCallback =
        (cert, host, port) => _pinCheck(policy, cert, host, port);
}

http.Client createPinnedClient(CertificatePinningPolicy policy) {
  LogManager.debug(
      '[CertPinning] API certificate pinning ACTIVE for ${policy.pinsByHost.keys.join(', ')}.');
  return IOClient(_newPinnedHttpClient(policy));
}

HttpClientAdapter? createPinnedDioAdapter(CertificatePinningPolicy policy) {
  return IOHttpClientAdapter(
    createHttpClient: () => _newPinnedHttpClient(policy),
  );
}
