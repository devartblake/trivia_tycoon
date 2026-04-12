import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

/// Web stub: use in-memory cache (no filesystem on web).
Future<CacheStore> createCacheStore() async => MemCacheStore();
