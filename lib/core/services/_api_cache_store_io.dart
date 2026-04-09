import 'dart:io';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:http_cache_hive_store/http_cache_hive_store.dart';
import 'package:path_provider/path_provider.dart';

/// Native: use Hive-backed persistent cache on iOS/Android/desktop.
Future<CacheStore> createCacheStore() async {
  final Directory cacheDir = await getTemporaryDirectory();
  return HiveCacheStore(cacheDir.path);
}
