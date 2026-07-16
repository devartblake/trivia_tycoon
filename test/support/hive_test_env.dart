import 'dart:io';

import 'package:hive/hive.dart';

/// Shared Hive setup for unit tests whose services persist through Hive
/// (`Hive.openBox`) but don't otherwise need Flutter plugins. Without an
/// initialized Hive, `openBox` throws
/// "You need to initialize Hive or provide a path to store the box."
///
/// Usage:
/// ```dart
/// late HiveTestEnv hiveEnv;
/// setUp(() async { hiveEnv = await HiveTestEnv.create(); });
/// tearDown(() async { await hiveEnv.dispose(); });
/// ```
class HiveTestEnv {
  final Directory dir;

  HiveTestEnv._(this.dir);

  static Future<HiveTestEnv> create() async {
    final dir = await Directory.systemTemp.createTemp('hive_test_env');
    Hive.init(dir.path);
    return HiveTestEnv._(dir);
  }

  /// Closes all open boxes. The temp directory is intentionally **left in
  /// place** (the OS reclaims the ephemeral test `/tmp`): some services persist
  /// fire-and-forget, and deleting the dir mid-run races those late writes into
  /// `PathNotFoundException`. Each test still gets a fresh dir via [create], so
  /// box contents stay isolated between tests.
  Future<void> dispose() async {
    await Hive.close();
  }
}
