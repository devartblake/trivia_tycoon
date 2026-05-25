import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_tycoon/core/services/asset_download_service.dart';
import 'package:trivia_tycoon/core/services/asset_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadString returns downloaded server asset before fallback', () async {
    final tempDir =
        await Directory.systemTemp.createTemp('asset_resolver_test');
    addTearDown(() => tempDir.delete(recursive: true));

    final downloadService = AssetDownloadService(
      httpClient: http.Client(),
      manifestUrl: 'http://example.invalid/manifest.json',
      baseDirOverride: tempDir,
    );
    final resolver = AssetResolver(downloadService: downloadService);

    await File('${tempDir.path}/questions_offline').writeAsString('server');

    final result = await resolver.loadString(
      'questions/offline',
      bundledFallbackPath: 'assets/questions/misc/questions_offline_pack.json',
    );

    expect(result, 'server');
  });

  test('loadString throws when no server asset or fallback exists', () async {
    final tempDir =
        await Directory.systemTemp.createTemp('asset_resolver_test');
    addTearDown(() => tempDir.delete(recursive: true));

    final resolver = AssetResolver(
      downloadService: AssetDownloadService(
        httpClient: http.Client(),
        manifestUrl: 'http://example.invalid/manifest.json',
        baseDirOverride: tempDir,
      ),
    );

    expect(
      () => resolver.loadString('store-catalog/items'),
      throwsA(isA<FlutterError>()),
    );
  });
}
