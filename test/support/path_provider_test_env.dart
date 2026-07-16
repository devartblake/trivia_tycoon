import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stubs the `path_provider` platform channel so code that calls
/// `getApplicationDocumentsDirectory()` / `getTemporaryDirectory()` etc. works
/// in unit tests without the native plugin (otherwise:
/// `MissingPluginException(No implementation found for method
/// getApplicationDocumentsDirectory ...)`).
///
/// Usage:
/// ```dart
/// late PathProviderTestEnv pp;
/// setUp(() async { pp = await PathProviderTestEnv.install(); });
/// tearDown(() => pp.remove());
/// ```
class PathProviderTestEnv {
  final Directory dir;

  PathProviderTestEnv._(this.dir);

  static const MethodChannel _channel =
      MethodChannel('plugins.flutter.io/path_provider');

  static Future<PathProviderTestEnv> install() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('pp_test_env');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      // Every path getter resolves to the same temp dir for tests.
      return dir.path;
    });
    return PathProviderTestEnv._(dir);
  }

  void remove() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }
}
