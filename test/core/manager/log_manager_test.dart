import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

void main() {
  setUp(() {
    // clearLogs() clears the list then adds one "All logs cleared" info entry.
    LogManager.clearLogs();
  });

  // -------------------------------------------------------------------------
  // LogLevel enum
  // -------------------------------------------------------------------------

  group('LogLevel enum', () {
    test('has exactly 5 values', () {
      expect(LogLevel.values.length, 5);
    });

    test('contains info, debug, warning, error, performance', () {
      expect(
          LogLevel.values,
          containsAll([
            LogLevel.info,
            LogLevel.debug,
            LogLevel.warning,
            LogLevel.error,
            LogLevel.performance,
          ]));
    });

    test('all values are distinct', () {
      final set = LogLevel.values.toSet();
      expect(set.length, LogLevel.values.length);
    });
  });

  // -------------------------------------------------------------------------
  // LogColors constants
  // -------------------------------------------------------------------------

  group('LogColors constants', () {
    test('reset contains ANSI escape prefix', () {
      expect(LogColors.reset, contains('\x1B['));
    });

    test('red contains ANSI escape prefix', () {
      expect(LogColors.red, contains('\x1B['));
    });

    test('green contains ANSI escape prefix', () {
      expect(LogColors.green, contains('\x1B['));
    });

    test('brightBlue contains ANSI escape prefix', () {
      expect(LogColors.brightBlue, contains('\x1B['));
    });

    test('bold contains ANSI escape prefix', () {
      expect(LogColors.bold, contains('\x1B['));
    });

    test('bgRed contains ANSI escape prefix', () {
      expect(LogColors.bgRed, contains('\x1B['));
    });

    test('all color constants are non-empty strings', () {
      final colors = [
        LogColors.reset,
        LogColors.black,
        LogColors.red,
        LogColors.green,
        LogColors.yellow,
        LogColors.blue,
        LogColors.magenta,
        LogColors.cyan,
        LogColors.white,
        LogColors.gray,
        LogColors.brightRed,
        LogColors.brightGreen,
        LogColors.brightYellow,
        LogColors.brightBlue,
        LogColors.brightMagenta,
        LogColors.brightCyan,
        LogColors.brightWhite,
        LogColors.bgRed,
        LogColors.bgGreen,
        LogColors.bgYellow,
        LogColors.bgBlue,
        LogColors.bgMagenta,
        LogColors.bgCyan,
        LogColors.bold,
        LogColors.dim,
        LogColors.italic,
        LogColors.underline,
      ];
      for (final c in colors) {
        expect(c.isNotEmpty, isTrue);
      }
    });
  });

  // -------------------------------------------------------------------------
  // LogEntry data class
  // -------------------------------------------------------------------------

  group('LogEntry', () {
    test('stores level and message', () {
      final e = LogEntry(LogLevel.info, 'hello');
      expect(e.level, LogLevel.info);
      expect(e.message, 'hello');
    });

    test('source is null by default', () {
      final e = LogEntry(LogLevel.debug, 'msg');
      expect(e.source, isNull);
    });

    test('source stored when provided', () {
      final e = LogEntry(LogLevel.warning, 'msg', source: 'TestSrc');
      expect(e.source, 'TestSrc');
    });

    test('timestamp is set to recent DateTime', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final e = LogEntry(LogLevel.error, 'err');
      expect(e.timestamp.isAfter(before), isTrue);
    });

    test('toString returns non-empty string', () {
      final e = LogEntry(LogLevel.info, 'test message');
      final result = e.toString(useColors: false);
      expect(result.isNotEmpty, isTrue);
      expect(result, contains('test message'));
    });

    test('toString with source includes source tag', () {
      final e = LogEntry(LogLevel.debug, 'msg', source: 'Src');
      final result = e.toString(useColors: false);
      expect(result, contains('Src'));
    });
  });

  // -------------------------------------------------------------------------
  // LogManager: logging methods
  // -------------------------------------------------------------------------

  group('LogManager logging methods', () {
    test('info() does not throw', () {
      expect(() => LogManager.info('info message'), returnsNormally);
    });

    test('debug() does not throw', () {
      expect(() => LogManager.debug('debug message'), returnsNormally);
    });

    test('warning() does not throw', () {
      expect(() => LogManager.warning('warn message'), returnsNormally);
    });

    test('error() does not throw', () {
      expect(() => LogManager.error('error message'), returnsNormally);
    });

    test('performance() does not throw', () {
      expect(() => LogManager.performance('perf message'), returnsNormally);
    });

    test('log() with explicit level does not throw', () {
      expect(
        () => LogManager.log('direct log', level: LogLevel.info),
        returnsNormally,
      );
    });

    test('info() adds an entry with LogLevel.info', () {
      LogManager.info('my info');
      final infoLogs = LogManager.getLogs(level: LogLevel.info);
      expect(infoLogs.any((e) => e.message == 'my info'), isTrue);
    });

    test('debug() adds an entry with LogLevel.debug', () {
      LogManager.debug('my debug');
      final debugLogs = LogManager.getLogs(level: LogLevel.debug);
      expect(debugLogs.any((e) => e.message == 'my debug'), isTrue);
    });

    test('warning() adds an entry with LogLevel.warning', () {
      LogManager.warning('my warn');
      final warnLogs = LogManager.getLogs(level: LogLevel.warning);
      expect(warnLogs.any((e) => e.message == 'my warn'), isTrue);
    });

    test('error() adds an entry with LogLevel.error', () {
      LogManager.error('my error');
      final errorLogs = LogManager.getLogs(level: LogLevel.error);
      expect(errorLogs.any((e) => e.message == 'my error'), isTrue);
    });

    test('performance() adds an entry with LogLevel.performance', () {
      LogManager.performance('my perf');
      final perfLogs = LogManager.getLogs(level: LogLevel.performance);
      expect(perfLogs.any((e) => e.message == 'my perf'), isTrue);
    });

    test('error() with error object appends error to message', () {
      LogManager.error('base', error: Exception('err-obj'));
      final errorLogs = LogManager.getLogs(level: LogLevel.error);
      expect(
        errorLogs.any((e) => e.message.contains('base')),
        isTrue,
      );
    });

    test('performance() with duration appends ms suffix', () {
      LogManager.performance('op', duration: const Duration(milliseconds: 42));
      final perfLogs = LogManager.getLogs(level: LogLevel.performance);
      expect(
        perfLogs.any((e) => e.message.contains('42ms')),
        isTrue,
      );
    });

    test('log() with source stores source on entry', () {
      LogManager.log('src msg', level: LogLevel.info, source: 'MySource');
      final entries = LogManager.getLogs(source: 'MySource');
      expect(entries.any((e) => e.message == 'src msg'), isTrue);
    });

    test('highlight() does not throw', () {
      expect(() => LogManager.highlight('highlighted'), returnsNormally);
    });

    test('success() does not throw', () {
      expect(() => LogManager.success('success msg'), returnsNormally);
    });

    test('critical() does not throw', () {
      expect(() => LogManager.critical('critical msg'), returnsNormally);
    });

    test('divider() does not throw', () {
      expect(() => LogManager.divider(), returnsNormally);
    });

    test('divider(label:) does not throw', () {
      expect(() => LogManager.divider(label: 'SECTION'), returnsNormally);
    });
  });

  // -------------------------------------------------------------------------
  // LogManager: getLogs filtering
  // -------------------------------------------------------------------------

  group('LogManager.getLogs filtering', () {
    test('getLogs() returns non-empty list after logging', () {
      LogManager.info('test');
      expect(LogManager.getLogs().isNotEmpty, isTrue);
    });

    test('getLogs(level:) returns only matching level entries', () {
      LogManager.info('i1');
      LogManager.debug('d1');
      final infoLogs = LogManager.getLogs(level: LogLevel.info);
      for (final e in infoLogs) {
        expect(e.level, LogLevel.info);
      }
    });

    test('getLogs(source:) returns only matching source entries', () {
      LogManager.log('s1', source: 'Alpha');
      LogManager.log('s2', source: 'Beta');
      final alphaLogs = LogManager.getLogs(source: 'Alpha');
      expect(alphaLogs.every((e) => e.source == 'Alpha'), isTrue);
    });

    test('getLogs(level:, source:) applies both filters', () {
      LogManager.log('combo', level: LogLevel.warning, source: 'Combo');
      final filtered =
          LogManager.getLogs(level: LogLevel.warning, source: 'Combo');
      expect(filtered.any((e) => e.message == 'combo'), isTrue);
    });

    test('getLogs returns List<LogEntry>', () {
      expect(LogManager.getLogs(), isA<List<LogEntry>>());
    });
  });

  // -------------------------------------------------------------------------
  // LogManager: clearLogs
  // -------------------------------------------------------------------------

  group('LogManager.clearLogs', () {
    test('clearLogs leaves exactly one entry (the clear notification)', () {
      LogManager.info('extra1');
      LogManager.debug('extra2');
      LogManager.clearLogs();
      expect(LogManager.getLogs().length, 1);
    });

    test('clearLogs notification message is "All logs cleared"', () {
      LogManager.clearLogs();
      expect(LogManager.getLogs().first.message, 'All logs cleared');
    });

    test('clearLogs notification has source "LogManager"', () {
      LogManager.clearLogs();
      expect(LogManager.getLogs().first.source, 'LogManager');
    });

    test('clearLogs notification has level info', () {
      LogManager.clearLogs();
      expect(LogManager.getLogs().first.level, LogLevel.info);
    });
  });

  // -------------------------------------------------------------------------
  // LogManager: exportLogs / exportLogsAsJson
  // -------------------------------------------------------------------------

  group('LogManager export', () {
    test('exportLogs returns a non-empty string when logs exist', () {
      LogManager.info('exportable');
      final result = LogManager.exportLogs();
      expect(result.isNotEmpty, isTrue);
    });

    test('exportLogs filters by level', () {
      LogManager.info('info-only');
      LogManager.debug('debug-only');
      final result = LogManager.exportLogs(level: LogLevel.info);
      expect(result, contains('info-only'));
    });

    test('exportLogsAsJson returns a string', () {
      LogManager.info('json-export');
      final result = LogManager.exportLogsAsJson();
      expect(result, isA<String>());
      expect(result.isNotEmpty, isTrue);
    });

    test('exportLogsAsJson contains log message text', () {
      LogManager.info('json-msg');
      final result = LogManager.exportLogsAsJson();
      expect(result, contains('json-msg'));
    });
  });

  // -------------------------------------------------------------------------
  // LogManager: getLogStatistics
  // -------------------------------------------------------------------------

  group('LogManager.getLogStatistics', () {
    test('returns map with required keys', () {
      final stats = LogManager.getLogStatistics();
      expect(stats.containsKey('total_logs'), isTrue);
      expect(stats.containsKey('by_level'), isTrue);
      expect(stats.containsKey('sources'), isTrue);
      expect(stats.containsKey('colors_enabled'), isTrue);
    });

    test('total_logs matches getLogs().length', () {
      LogManager.info('s1');
      LogManager.debug('s2');
      final stats = LogManager.getLogStatistics();
      expect(stats['total_logs'], LogManager.getLogs().length);
    });

    test('by_level contains all LogLevel names', () {
      final stats = LogManager.getLogStatistics();
      final byLevel = stats['by_level'] as Map<String, int>;
      for (final level in LogLevel.values) {
        expect(byLevel.containsKey(level.name), isTrue);
      }
    });

    test('colors_enabled reflects setColorEnabled state', () {
      LogManager.setColorEnabled(false);
      expect(LogManager.getLogStatistics()['colors_enabled'], isFalse);
      LogManager.setColorEnabled(true);
      expect(LogManager.getLogStatistics()['colors_enabled'], isTrue);
    });

    test('sources list includes logged sources', () {
      LogManager.log('with-src', source: 'SrcX');
      final stats = LogManager.getLogStatistics();
      final sources = stats['sources'] as List;
      expect(sources, contains('SrcX'));
    });
  });

  // -------------------------------------------------------------------------
  // LogManager: timeOperation / timeAsyncOperation
  // -------------------------------------------------------------------------

  group('LogManager timing helpers', () {
    test('timeOperation completes without error', () {
      expect(
        () => LogManager.timeOperation('op', () {}),
        returnsNormally,
      );
    });

    test('timeOperation adds performance entries', () {
      LogManager.timeOperation('myOp', () {});
      final perfLogs = LogManager.getLogs(level: LogLevel.performance);
      expect(perfLogs.any((e) => e.message.contains('myOp')), isTrue);
    });

    test('timeAsyncOperation completes without error', () async {
      await expectLater(
        LogManager.timeAsyncOperation('asyncOp', () async {}),
        completes,
      );
    });

    test('timeAsyncOperation adds performance entries', () async {
      await LogManager.timeAsyncOperation('asyncTask', () async {});
      final perfLogs = LogManager.getLogs(level: LogLevel.performance);
      expect(perfLogs.any((e) => e.message.contains('asyncTask')), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // LogManager: colorsEnabled / setColorEnabled
  // -------------------------------------------------------------------------

  group('LogManager color settings', () {
    test('setColorEnabled(false) sets colorsEnabled to false', () {
      LogManager.setColorEnabled(false);
      expect(LogManager.colorsEnabled, isFalse);
    });

    test('setColorEnabled(true) sets colorsEnabled to true', () {
      LogManager.setColorEnabled(false);
      LogManager.setColorEnabled(true);
      expect(LogManager.colorsEnabled, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // LogManager: logStream
  // -------------------------------------------------------------------------

  group('LogManager.logStream', () {
    test('logStream is a broadcast stream', () {
      expect(LogManager.logStream.isBroadcast, isTrue);
    });

    test('logStream emits entry when log() is called', () async {
      final events = <LogEntry>[];
      final sub = LogManager.logStream.listen(events.add);
      addTearDown(sub.cancel);

      LogManager.info('stream-test');
      await Future.delayed(Duration.zero);

      expect(events.any((e) => e.message == 'stream-test'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // LogManager: profile-specific helpers
  // -------------------------------------------------------------------------

  group('LogManager profile helpers', () {
    test('logProfileCreated does not throw', () {
      expect(
        () => LogManager.logProfileCreated('Alice', 'id-1'),
        returnsNormally,
      );
    });

    test('logProfileSwitched does not throw', () {
      expect(
        () => LogManager.logProfileSwitched('Alice', 'Bob'),
        returnsNormally,
      );
    });

    test('logProfileDeleted does not throw', () {
      expect(
        () => LogManager.logProfileDeleted('Alice', 'id-1'),
        returnsNormally,
      );
    });

    test('logProfileError does not throw', () {
      expect(
        () => LogManager.logProfileError('create', 'duplicate name'),
        returnsNormally,
      );
    });

    test('logProfileValidation does not throw', () {
      expect(
        () => LogManager.logProfileValidation('Alice', 'name too long'),
        returnsNormally,
      );
    });
  });
}
