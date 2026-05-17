import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/multiplayer/core/multiplayer_exceptions.dart';

void main() {
  // -------------------------------------------------------------------------
  // WsDisconnected
  // -------------------------------------------------------------------------

  group('WsDisconnected', () {
    test('uses default message when none provided', () {
      const e = WsDisconnected();
      expect(e.message, 'WebSocket disconnected');
    });

    test('accepts custom message', () {
      const e = WsDisconnected('connection lost');
      expect(e.message, 'connection lost');
    });

    test('status is null', () {
      expect(const WsDisconnected().status, isNull);
    });

    test('is a MultiplayerException', () {
      expect(const WsDisconnected(), isA<MultiplayerException>());
    });

    test('is an Exception', () {
      expect(const WsDisconnected(), isA<Exception>());
    });

    test('toString contains class name and message', () {
      final s = const WsDisconnected('lost').toString();
      expect(s, contains('WsDisconnected'));
      expect(s, contains('lost'));
    });
  });

  // -------------------------------------------------------------------------
  // HttpFailure
  // -------------------------------------------------------------------------

  group('HttpFailure', () {
    test('stores status code', () {
      const e = HttpFailure(status: 404);
      expect(e.status, 404);
    });

    test('stores optional body', () {
      const e = HttpFailure(status: 500, body: '{"error":"oops"}');
      expect(e.body, '{"error":"oops"}');
    });

    test('body is null when not provided', () {
      expect(const HttpFailure(status: 400).body, isNull);
    });

    test('default message is "HTTP failure"', () {
      expect(const HttpFailure(status: 200).message, 'HTTP failure');
    });

    test('accepts custom message', () {
      const e = HttpFailure(status: 403, message: 'Forbidden');
      expect(e.message, 'Forbidden');
    });

    test('toString contains status code', () {
      expect(const HttpFailure(status: 503).toString(), contains('503'));
    });
  });

  // -------------------------------------------------------------------------
  // ProtocolFailure
  // -------------------------------------------------------------------------

  group('ProtocolFailure', () {
    test('stores message', () {
      expect(const ProtocolFailure('bad op').message, 'bad op');
    });

    test('status is null', () {
      expect(const ProtocolFailure('x').status, isNull);
    });

    test('toString contains message', () {
      expect(const ProtocolFailure('parse error').toString(), contains('parse error'));
    });
  });

  // -------------------------------------------------------------------------
  // NotAuthorized
  // -------------------------------------------------------------------------

  group('NotAuthorized', () {
    test('default message is "Not authorized"', () {
      expect(const NotAuthorized().message, 'Not authorized');
    });

    test('status is 401', () {
      expect(const NotAuthorized().status, 401);
    });

    test('accepts custom message', () {
      expect(const NotAuthorized('Token expired').message, 'Token expired');
    });

    test('toString contains 401', () {
      expect(const NotAuthorized().toString(), contains('401'));
    });
  });

  // -------------------------------------------------------------------------
  // RoomFull
  // -------------------------------------------------------------------------

  group('RoomFull', () {
    test('default message is "Room is full"', () {
      expect(const RoomFull().message, 'Room is full');
    });

    test('status is null', () {
      expect(const RoomFull().status, isNull);
    });

    test('accepts custom message', () {
      expect(const RoomFull('capacity reached').message, 'capacity reached');
    });
  });

  // -------------------------------------------------------------------------
  // BadRequest
  // -------------------------------------------------------------------------

  group('BadRequest', () {
    test('default message is "Bad request"', () {
      expect(const BadRequest().message, 'Bad request');
    });

    test('status is 400', () {
      expect(const BadRequest().status, 400);
    });

    test('accepts custom message', () {
      expect(const BadRequest('invalid room id').message, 'invalid room id');
    });

    test('toString contains 400', () {
      expect(const BadRequest().toString(), contains('400'));
    });
  });

  // -------------------------------------------------------------------------
  // Sealed class — catch as MultiplayerException
  // -------------------------------------------------------------------------

  group('MultiplayerException catch hierarchy', () {
    test('all subtypes catchable as MultiplayerException', () {
      final exceptions = <MultiplayerException>[
        const WsDisconnected(),
        const HttpFailure(status: 500),
        const ProtocolFailure('err'),
        const NotAuthorized(),
        const RoomFull(),
        const BadRequest(),
      ];
      for (final e in exceptions) {
        expect(e, isA<MultiplayerException>());
        expect(e, isA<Exception>());
      }
    });
  });
}
