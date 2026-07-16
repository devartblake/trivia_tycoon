import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:synaptix/core/dto/web_link_dto.dart';
import 'package:synaptix/core/services/web_link_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

WebLinkService _svc(MockClientHandler handler,
    {String baseUrl = 'https://api.test'}) {
  return WebLinkService(
    httpClient: MockClient(handler),
    apiBaseUrl: baseUrl,
    accessTokenGetter: () => 'test-token',
  );
}

http.Response _json(Map<String, dynamic> body, {int status = 200}) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

http.Response _error(int status) => http.Response('{"error":"fail"}', status);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Constructor — URL normalisation
  // -------------------------------------------------------------------------

  group('WebLinkService URL normalisation', () {
    test('trailing slash is stripped from apiBaseUrl', () async {
      Uri? captured;
      final svc = _svc(
        (req) async {
          captured = req.url;
          return _json({'qrToken': 'tok', 'expiresIn': 300});
        },
        baseUrl: 'https://api.test/',
      );
      await svc.generateQrToken();
      expect(captured?.toString(), 'https://api.test/auth/link/qr/generate');
    });

    test('URL without trailing slash is unchanged', () async {
      Uri? captured;
      final svc = _svc(
        (req) async {
          captured = req.url;
          return _json({'qrToken': 'tok', 'expiresIn': 300});
        },
        baseUrl: 'https://api.test',
      );
      await svc.generateQrToken();
      expect(captured?.toString(), 'https://api.test/auth/link/qr/generate');
    });
  });

  // -------------------------------------------------------------------------
  // generateQrToken
  // -------------------------------------------------------------------------

  group('generateQrToken()', () {
    test('success returns QrTokenResponse', () async {
      final svc =
          _svc((_) async => _json({'qrToken': 'abc123', 'expiresIn': 120}));
      final r = await svc.generateQrToken();
      expect(r.qrToken, 'abc123');
      expect(r.expiresIn, 120);
    });

    test('POSTs to /auth/link/qr/generate', () async {
      Uri? captured;
      String? method;
      final svc = _svc((req) async {
        captured = req.url;
        method = req.method;
        return _json({'qrToken': 't', 'expiresIn': 300});
      });
      await svc.generateQrToken();
      expect(method, 'POST');
      expect(captured?.path, '/auth/link/qr/generate');
    });

    test('uses public (no auth) headers', () async {
      Map<String, String>? headers;
      final svc = _svc((req) async {
        headers = req.headers;
        return _json({'qrToken': 't', 'expiresIn': 300});
      });
      await svc.generateQrToken();
      expect(headers?.containsKey('Authorization'), isFalse);
      expect(headers?['content-type'], contains('application/json'));
    });

    test('throws WebLinkException on HTTP 4xx', () async {
      final svc = _svc((_) async => _error(401));
      expect(svc.generateQrToken(), throwsA(isA<WebLinkException>()));
    });

    test('throws WebLinkException on HTTP 5xx', () async {
      final svc = _svc((_) async => _error(500));
      expect(svc.generateQrToken(), throwsA(isA<WebLinkException>()));
    });
  });

  // -------------------------------------------------------------------------
  // pollQrStatus
  // -------------------------------------------------------------------------

  group('pollQrStatus()', () {
    test('returns pending status', () async {
      final svc = _svc((_) async => _json({'status': 'pending'}));
      final r = await svc.pollQrStatus('token-xyz');
      expect(r.status, QrLinkStatus.pending);
      expect(r.sessionToken, isNull);
    });

    test('returns consumed status with sessionToken', () async {
      final svc = _svc((_) async =>
          _json({'status': 'consumed', 'sessionToken': 'ses-123'}));
      final r = await svc.pollQrStatus('token-xyz');
      expect(r.status, QrLinkStatus.consumed);
      expect(r.sessionToken, 'ses-123');
    });

    test('returns expired status', () async {
      final svc = _svc((_) async => _json({'status': 'expired'}));
      final r = await svc.pollQrStatus('token-xyz');
      expect(r.status, QrLinkStatus.expired);
    });

    test('GETs /auth/link/qr/status/{qrToken}', () async {
      Uri? captured;
      String? method;
      final svc = _svc((req) async {
        captured = req.url;
        method = req.method;
        return _json({'status': 'pending'});
      });
      await svc.pollQrStatus('mytoken');
      expect(method, 'GET');
      expect(captured?.path, '/auth/link/qr/status/mytoken');
    });

    test('URL-encodes QR token path segment', () async {
      Uri? captured;
      final svc = _svc((req) async {
        captured = req.url;
        return _json({'status': 'pending'});
      });
      await svc.pollQrStatus('token/with spaces?and=plus+');
      expect(
        captured?.toString(),
        'https://api.test/auth/link/qr/status/token%2Fwith%20spaces%3Fand%3Dplus%2B',
      );
    });

    test('throws WebLinkException on HTTP error', () {
      final svc = _svc((_) async => _error(404));
      expect(svc.pollQrStatus('t'), throwsA(isA<WebLinkException>()));
    });
  });

  // -------------------------------------------------------------------------
  // consumeQrToken
  // -------------------------------------------------------------------------

  group('consumeQrToken()', () {
    test('completes without error on 200', () async {
      final svc = _svc((_) async => http.Response('{}', 200));
      await expectLater(svc.consumeQrToken('qr-tok'), completes);
    });

    test('POSTs to /auth/link/qr/consume with Bearer header', () async {
      Uri? captured;
      Map<String, String>? headers;
      String? body;
      final svc = _svc((req) async {
        captured = req.url;
        headers = req.headers;
        body = req.body;
        return http.Response('{}', 200);
      });
      await svc.consumeQrToken('qr-tok');
      expect(captured?.path, '/auth/link/qr/consume');
      expect(headers?['Authorization'], 'Bearer test-token');
      final decoded = jsonDecode(body!) as Map<String, dynamic>;
      expect(decoded['qrToken'], 'qr-tok');
    });

    test('throws WebLinkException on HTTP 403', () {
      final svc = _svc((_) async => _error(403));
      expect(svc.consumeQrToken('t'), throwsA(isA<WebLinkException>()));
    });
  });

  // -------------------------------------------------------------------------
  // authenticateWithGoogleToken
  // -------------------------------------------------------------------------

  group('authenticateWithGoogleToken()', () {
    test('returns GoogleWebAuthResponse on success', () async {
      final svc = _svc((_) async => _json({
            'accessToken': 'at-123',
            'refreshToken': 'rt-456',
            'userId': 'u-789',
          }));
      final r = await svc.authenticateWithGoogleToken('google-id-token');
      expect(r.accessToken, 'at-123');
      expect(r.refreshToken, 'rt-456');
      expect(r.userId, 'u-789');
    });

    test('POSTs to /auth/google-web with googleIdToken body', () async {
      Uri? captured;
      String? body;
      final svc = _svc((req) async {
        captured = req.url;
        body = req.body;
        return _json({'accessToken': 'at', 'refreshToken': 'rt'});
      });
      await svc.authenticateWithGoogleToken('my-google-token');
      expect(captured?.path, '/auth/google-web');
      final decoded = jsonDecode(body!) as Map<String, dynamic>;
      expect(decoded['googleIdToken'], 'my-google-token');
    });

    test('uses public headers (no Authorization)', () async {
      Map<String, String>? headers;
      final svc = _svc((req) async {
        headers = req.headers;
        return _json({'accessToken': 'at', 'refreshToken': 'rt'});
      });
      await svc.authenticateWithGoogleToken('tok');
      expect(headers?.containsKey('Authorization'), isFalse);
    });

    test('throws WebLinkException on HTTP error', () {
      final svc = _svc((_) async => _error(401));
      expect(svc.authenticateWithGoogleToken('t'),
          throwsA(isA<WebLinkException>()));
    });
  });

  // -------------------------------------------------------------------------
  // generateLinkCode
  // -------------------------------------------------------------------------

  group('generateLinkCode()', () {
    test('returns LinkCodeResponse on success', () async {
      final svc =
          _svc((_) async => _json({'code': 'ABC123', 'expiresIn': 600}));
      final r = await svc.generateLinkCode();
      expect(r.code, 'ABC123');
      expect(r.expiresIn, 600);
    });

    test('POSTs to /auth/link/code/generate with Bearer token', () async {
      Uri? captured;
      Map<String, String>? headers;
      final svc = _svc((req) async {
        captured = req.url;
        headers = req.headers;
        return _json({'code': 'XY9', 'expiresIn': 300});
      });
      await svc.generateLinkCode();
      expect(captured?.path, '/auth/link/code/generate');
      expect(headers?['Authorization'], 'Bearer test-token');
    });

    test('throws WebLinkException on HTTP error', () {
      final svc = _svc((_) async => _error(500));
      expect(svc.generateLinkCode(), throwsA(isA<WebLinkException>()));
    });
  });

  // -------------------------------------------------------------------------
  // consumeLinkCode
  // -------------------------------------------------------------------------

  group('consumeLinkCode()', () {
    test('returns GoogleWebAuthResponse on success', () async {
      final svc = _svc((_) async => _json({
            'accessToken': 'access',
            'refreshToken': 'refresh',
          }));
      final r = await svc.consumeLinkCode('XY9KM2');
      expect(r.accessToken, 'access');
      expect(r.refreshToken, 'refresh');
    });

    test('POSTs to /auth/link/code/consume with code body', () async {
      Uri? captured;
      String? body;
      final svc = _svc((req) async {
        captured = req.url;
        body = req.body;
        return _json({'accessToken': 'at', 'refreshToken': 'rt'});
      });
      await svc.consumeLinkCode('XY9KM2');
      expect(captured?.path, '/auth/link/code/consume');
      final decoded = jsonDecode(body!) as Map<String, dynamic>;
      expect(decoded['code'], 'XY9KM2');
    });

    test('uses public headers (no Authorization)', () async {
      Map<String, String>? headers;
      final svc = _svc((req) async {
        headers = req.headers;
        return _json({'accessToken': 'at', 'refreshToken': 'rt'});
      });
      await svc.consumeLinkCode('CODE');
      expect(headers?.containsKey('Authorization'), isFalse);
    });

    test('throws WebLinkException on HTTP error', () {
      final svc = _svc((_) async => _error(422));
      expect(svc.consumeLinkCode('bad'), throwsA(isA<WebLinkException>()));
    });
  });

  // -------------------------------------------------------------------------
  // WebLinkException
  // -------------------------------------------------------------------------

  group('WebLinkException', () {
    test('toString includes message, status code, and path', () {
      const ex = WebLinkException(
        'HTTP 404 from /auth/link/qr/generate',
        statusCode: 404,
        path: '/auth/link/qr/generate',
      );
      final s = ex.toString();
      expect(s, contains('404'));
      expect(s, contains('/auth/link/qr/generate'));
      expect(s, contains('WebLinkException'));
    });

    test('toString without statusCode omits HTTP part', () {
      const ex = WebLinkException('Invalid JSON response', path: '?');
      final s = ex.toString();
      expect(s, contains('Invalid JSON response'));
      expect(s, isNot(contains('HTTP null')));
    });
  });

  // -------------------------------------------------------------------------
  // _decode edge cases (exercised via any endpoint)
  // -------------------------------------------------------------------------

  group('_decode edge cases', () {
    test('invalid JSON body throws WebLinkException', () {
      final svc = _svc((_) async => http.Response('not-json', 200));
      expect(svc.generateQrToken(), throwsA(isA<WebLinkException>()));
    });

    test('JSON array response throws WebLinkException', () {
      final svc = _svc((_) async => http.Response('[1,2,3]', 200));
      expect(svc.generateQrToken(), throwsA(isA<WebLinkException>()));
    });

    test('JSON string response throws WebLinkException', () {
      final svc = _svc((_) async => http.Response('"just-a-string"', 200));
      expect(svc.generateQrToken(), throwsA(isA<WebLinkException>()));
    });
  });
}
