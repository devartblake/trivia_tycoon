import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/networking/certificate_pinning.dart';

String _pinOf(List<int> der) => base64.encode(sha256.convert(der).bytes);

void main() {
  group('CertificatePinningPolicy.certificateMatches', () {
    final der = utf8.encode('fake-leaf-certificate-der-bytes');
    final pin = _pinOf(der);

    CertificatePinningPolicy policyFor(Map<String, List<String>> pins) =>
        CertificatePinningPolicy(enabled: true, pinsByHost: pins);

    test('accepts a leaf whose SHA-256 matches a pin for the host', () {
      final policy = policyFor({'api.synaptixplay.com': [pin]});
      expect(policy.certificateMatches('api.synaptixplay.com', der), isTrue);
    });

    test('is case-insensitive on host', () {
      final policy = policyFor({'api.synaptixplay.com': [pin]});
      expect(policy.certificateMatches('API.SynaptixPlay.com', der), isTrue);
    });

    test('rejects a non-matching certificate', () {
      final policy = policyFor({'api.synaptixplay.com': [pin]});
      final other = utf8.encode('a-different-certificate');
      expect(policy.certificateMatches('api.synaptixplay.com', other), isFalse);
    });

    test('rejects a valid pin presented for a different (unpinned) host', () {
      final policy = policyFor({'api.synaptixplay.com': [pin]});
      // Same cert, wrong host -> the pin is bound to the host, so reject.
      expect(policy.certificateMatches('evil.example.com', der), isFalse);
    });

    test('supports multiple pins (current + next-rotation cert)', () {
      final nextDer = utf8.encode('next-rotation-cert');
      final policy = policyFor({
        'api.synaptixplay.com': [pin, _pinOf(nextDer)],
      });
      expect(policy.certificateMatches('api.synaptixplay.com', nextDer), isTrue);
    });
  });

  group('CertificatePinningPolicy.isActive', () {
    test('inactive when disabled', () {
      final policy = CertificatePinningPolicy(
          enabled: false, pinsByHost: {'h': ['p']});
      expect(policy.isActive, isFalse);
    });

    test('inactive when no pins configured', () {
      const policy =
          CertificatePinningPolicy(enabled: true, pinsByHost: {});
      expect(policy.isActive, isFalse);
    });
  });
}
