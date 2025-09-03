import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import 'package:trivia_tycoon/core/services/settings/spin_wheel_settings_service.dart';
import 'package:trivia_tycoon/core/services/storage/app_cache_service.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import '../../../core/services/storage/config_storage_service.dart';
import '../models/wheel_segment.dart';

enum SegmentSource { local, remote }

class SegmentLoader {
  final SegmentSource source;
  final String? remoteUrl;
  late AppCacheService appCache;
  late ConfigStorageService configStorage;
  late SpinWheelSettingsService spinWheelService;
  late GeneralKeyValueStorageService generalKeyStorage;

  SegmentLoader({
    this.source = SegmentSource.local,
    this.remoteUrl,
    required this.appCache,
    required this.configStorage,
    required this.spinWheelService,
    required this.generalKeyStorage,
  });

  bool usedFallback = false;

  /// Entry point — decides where to load segments from and filters based on unlock rules
  Future<List<WheelSegment>> loadSegments() async {
    List<WheelSegment> rawSegments = [];

    try {
      if (source == SegmentSource.remote && remoteUrl != null) {
        rawSegments = await _loadFromRemote();
        await configStorage.saveConfig('segments', json.encode(rawSegments.map((s) => s.toJson()).toList()));
        await spinWheelService.setSegmentFetchTime(DateTime.now());
      } else {
        rawSegments = await _loadFromLocal();
      }
    } catch (e) {
      // Fallback to local if remote fails
      usedFallback = true;
      rawSegments = await _loadFromLocal();
    }

    return _filterUnlockedSegments(rawSegments);
  }

  /// Load segments from local JSON config
  Future<List<WheelSegment>> _loadFromLocal() async {
    final raw = await rootBundle.loadString('assets/config/segments.json');
    final List data = json.decode(raw);
    return data.map((e) => WheelSegment.fromJson(e)).toList();
  }

  /// Load segments from remote API
  Future<List<WheelSegment>> _loadFromRemote() async {
    if (remoteUrl == null) throw Exception("Remote URL not provided.");

    final response = await http.get(Uri.parse(remoteUrl!));
    if (response.statusCode != 200) throw Exception("Failed to load remote segments");

    final List<dynamic> data = json.decode(response.body);
    return data.map((e) => WheelSegment.fromJson(e)).toList();
  }

  Future<List<WheelSegment>> _loadFromLocalOrCache() async {
    try {
      final cached = await configStorage.getConfig('segments');
      if (cached != null) {
        final List decoded = json.decode(cached);
        return decoded.map((e) => WheelSegment.fromJson(e)).toList();
      }
    } catch (_) {}
    return _loadFromLocal();
  }

  /// Filter segments based on streak & currency unlock requirements
  Future<List<WheelSegment>> _filterUnlockedSegments(
      List<WheelSegment> all) async {
    final streak = await spinWheelService.getWinStreak();
    final currency = await generalKeyStorage.getInt("exclusiveCurrency") ?? 0;

    return all.where((seg) {
      if (!seg.isExclusive) return true;

      final unlockStreak = (seg.metadata?['requiredStreak'] ?? 5) as int;
      final unlockCurrency = (seg.metadata?['requiredCurrency'] ?? 50) as int;

      return streak >= unlockStreak && currency >= unlockCurrency;
    }).toList();
  }

  final segmentLoaderProvider = Provider<SegmentLoader>((ref) {
    final manager = ref.read(serviceManagerProvider);
    return SegmentLoader(
      source: SegmentSource.remote,
      remoteUrl: 'https://example.com/api/segments',
      appCache: manager.appCacheService,
      configStorage: manager.configStorageService,
      spinWheelService: manager.spinWheelSettingsService,
      generalKeyStorage: manager.generalKeyValueStorageService,
    );
  });

}
