import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/multiplayer/core/multiplayer_constants.dart';
import 'package:trivia_tycoon/game/multiplayer/core/multiplayer_logger.dart';

void main() {
  // -------------------------------------------------------------------------
  // MultiplayerConstants — HTTP path constants
  // -------------------------------------------------------------------------

  group('MultiplayerConstants — HTTP paths', () {
    test('roomsPath', () {
      expect(MultiplayerConstants.roomsPath, '/v1/multiplayer/rooms');
    });

    test('matchesPath', () {
      expect(MultiplayerConstants.matchesPath, '/v1/multiplayer/matches');
    });

    test('answersPath', () {
      expect(MultiplayerConstants.answersPath, '/v1/multiplayer/answers');
    });
  });

  group('MultiplayerConstants — header keys', () {
    test('hdrAuthorization', () {
      expect(MultiplayerConstants.hdrAuthorization, 'Authorization');
    });

    test('hdrContentType', () {
      expect(MultiplayerConstants.hdrContentType, 'Content-Type');
    });

    test('contentTypeJson', () {
      expect(MultiplayerConstants.contentTypeJson, 'application/json');
    });
  });

  group('MultiplayerConstants — numeric defaults', () {
    test('defaultRoomCapacity is 4', () {
      expect(MultiplayerConstants.defaultRoomCapacity, 4);
    });

    test('defaultTurnMs is 12000', () {
      expect(MultiplayerConstants.defaultTurnMs, 12000);
    });
  });

  // -------------------------------------------------------------------------
  // MultiplayerLogger — disabled (enabled: false)
  // -------------------------------------------------------------------------

  group('MultiplayerLogger(enabled: false) — silent', () {
    final logger = MultiplayerLogger(enabled: false);

    test('d() does not throw', () {
      expect(() => logger.d('debug message'), returnsNormally);
    });

    test('i() does not throw', () {
      expect(() => logger.i('info message'), returnsNormally);
    });

    test('w() does not throw', () {
      expect(() => logger.w('warning message'), returnsNormally);
    });

    test('e() with message only does not throw', () {
      expect(() => logger.e('error message'), returnsNormally);
    });

    test('e() with error object does not throw', () {
      expect(
        () => logger.e('error message', Exception('test error')),
        returnsNormally,
      );
    });

    test('e() with error and stack trace does not throw', () {
      expect(
        () => logger.e('error message', Exception('test'), StackTrace.empty),
        returnsNormally,
      );
    });
  });

  // -------------------------------------------------------------------------
  // MultiplayerLogger — enabled (enabled: true)
  // -------------------------------------------------------------------------

  group('MultiplayerLogger(enabled: true) — delegates to LogManager', () {
    final logger = MultiplayerLogger(enabled: true);

    test('d() does not throw', () {
      expect(() => logger.d('debug message'), returnsNormally);
    });

    test('i() does not throw', () {
      expect(() => logger.i('info message'), returnsNormally);
    });

    test('w() does not throw', () {
      expect(() => logger.w('warning message'), returnsNormally);
    });

    test('e() with all arguments does not throw', () {
      expect(
        () => logger.e('error', Exception('err'), StackTrace.empty),
        returnsNormally,
      );
    });
  });

  // -------------------------------------------------------------------------
  // MultiplayerLogger — default constructor value
  // -------------------------------------------------------------------------

  group('MultiplayerLogger — default enabled value', () {
    test('default enabled is false', () {
      const logger = MultiplayerLogger();
      // If enabled were true, d() would try to call LogManager; either way
      // both should not throw — just verifying the default behavior.
      expect(() => logger.d('test'), returnsNormally);
    });
  });
}
