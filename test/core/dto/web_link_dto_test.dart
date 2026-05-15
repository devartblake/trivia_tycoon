import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/dto/web_link_dto.dart';

void main() {
  // -------------------------------------------------------------------------
  // QrTokenResponse
  // -------------------------------------------------------------------------

  group('QrTokenResponse', () {
    test('fromJson parses all fields', () {
      final r = QrTokenResponse.fromJson({
        'qrToken': 'abc123xyz',
        'expiresIn': 300,
      });
      expect(r.qrToken, 'abc123xyz');
      expect(r.expiresIn, 300);
    });

    test('fromJson defaults qrToken to empty string when missing', () {
      final r = QrTokenResponse.fromJson({'expiresIn': 180});
      expect(r.qrToken, '');
    });

    test('fromJson defaults expiresIn to 300 when missing', () {
      final r = QrTokenResponse.fromJson({'qrToken': 'tok'});
      expect(r.expiresIn, 300);
    });

    test('fromJson handles null values', () {
      final r = QrTokenResponse.fromJson({
        'qrToken': null,
        'expiresIn': null,
      });
      expect(r.qrToken, '');
      expect(r.expiresIn, 300);
    });
  });

  // -------------------------------------------------------------------------
  // QrLinkStatus
  // -------------------------------------------------------------------------

  group('QrLinkStatus', () {
    test('has 3 distinct values', () {
      expect(QrLinkStatus.values.length, 3);
      expect(
        {QrLinkStatus.pending, QrLinkStatus.consumed, QrLinkStatus.expired}
            .length,
        3,
      );
    });
  });

  // -------------------------------------------------------------------------
  // QrStatusResponse
  // -------------------------------------------------------------------------

  group('QrStatusResponse', () {
    test('fromJson parses pending status', () {
      final r = QrStatusResponse.fromJson({'status': 'pending'});
      expect(r.status, QrLinkStatus.pending);
      expect(r.sessionToken, isNull);
    });

    test('fromJson parses consumed status with sessionToken', () {
      final r = QrStatusResponse.fromJson({
        'status': 'consumed',
        'sessionToken': 'session-abc',
      });
      expect(r.status, QrLinkStatus.consumed);
      expect(r.sessionToken, 'session-abc');
    });

    test('fromJson parses expired status', () {
      final r = QrStatusResponse.fromJson({'status': 'expired'});
      expect(r.status, QrLinkStatus.expired);
      expect(r.sessionToken, isNull);
    });

    test('fromJson defaults unknown status to pending', () {
      final r = QrStatusResponse.fromJson({'status': 'unknown_value'});
      expect(r.status, QrLinkStatus.pending);
    });

    test('fromJson defaults to pending when status key is missing', () {
      final r = QrStatusResponse.fromJson({});
      expect(r.status, QrLinkStatus.pending);
    });

    test('fromJson defaults to pending when status is null', () {
      final r = QrStatusResponse.fromJson({'status': null});
      expect(r.status, QrLinkStatus.pending);
    });

    test('sessionToken is null when absent in consumed payload', () {
      final r = QrStatusResponse.fromJson({'status': 'consumed'});
      expect(r.status, QrLinkStatus.consumed);
      expect(r.sessionToken, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // LinkCodeResponse
  // -------------------------------------------------------------------------

  group('LinkCodeResponse', () {
    test('fromJson parses all fields', () {
      final r = LinkCodeResponse.fromJson({
        'code': 'ABC123',
        'expiresIn': 300,
      });
      expect(r.code, 'ABC123');
      expect(r.expiresIn, 300);
    });

    test('fromJson defaults code to empty string when missing', () {
      final r = LinkCodeResponse.fromJson({'expiresIn': 180});
      expect(r.code, '');
    });

    test('fromJson defaults expiresIn to 300 when missing', () {
      final r = LinkCodeResponse.fromJson({'code': 'XY2KM9'});
      expect(r.expiresIn, 300);
    });

    test('fromJson handles null values', () {
      final r = LinkCodeResponse.fromJson({'code': null, 'expiresIn': null});
      expect(r.code, '');
      expect(r.expiresIn, 300);
    });
  });

  // -------------------------------------------------------------------------
  // GoogleWebAuthResponse
  // -------------------------------------------------------------------------

  group('GoogleWebAuthResponse', () {
    test('fromJson parses camelCase fields', () {
      final r = GoogleWebAuthResponse.fromJson({
        'accessToken': 'at123',
        'refreshToken': 'rt456',
        'userId': 'u789',
      });
      expect(r.accessToken, 'at123');
      expect(r.refreshToken, 'rt456');
      expect(r.userId, 'u789');
    });

    test('fromJson falls back to snake_case accessToken', () {
      final r = GoogleWebAuthResponse.fromJson({
        'access_token': 'at-snake',
        'refresh_token': 'rt-snake',
      });
      expect(r.accessToken, 'at-snake');
      expect(r.refreshToken, 'rt-snake');
    });

    test('camelCase takes precedence over snake_case', () {
      final r = GoogleWebAuthResponse.fromJson({
        'accessToken': 'camel',
        'access_token': 'snake',
        'refreshToken': 'r-camel',
        'refresh_token': 'r-snake',
      });
      expect(r.accessToken, 'camel');
      expect(r.refreshToken, 'r-camel');
    });

    test('fromJson falls back to user_id for userId', () {
      final r = GoogleWebAuthResponse.fromJson({
        'accessToken': 'at',
        'refreshToken': 'rt',
        'user_id': 'uid-snake',
      });
      expect(r.userId, 'uid-snake');
    });

    test('userId is null when absent', () {
      final r = GoogleWebAuthResponse.fromJson({
        'accessToken': 'at',
        'refreshToken': 'rt',
      });
      expect(r.userId, isNull);
    });

    test('fromJson defaults accessToken to empty string when missing', () {
      final r = GoogleWebAuthResponse.fromJson({'refreshToken': 'rt'});
      expect(r.accessToken, '');
    });

    test('fromJson defaults refreshToken to empty string when missing', () {
      final r = GoogleWebAuthResponse.fromJson({'accessToken': 'at'});
      expect(r.refreshToken, '');
    });
  });
}
