import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../game/models/question_model.dart';
import '../../../game/models/leaderboard_entry.dart';
import '../../../ui_components/qr_code/models/scan_history_item.dart';

class AppCacheService {
  static const _boxName = 'cache';
  late final Box _box;

  /// Call this in your ServiceManager before using other methods
  static Future<AppCacheService> initialize() async {
    final service = AppCacheService();
    service._box = await Hive.openBox(_boxName);
    return service;
  }

  /// Generic get
  T? get<T>(String key) {
    final raw = _box.get(key);
    if (raw is String) {
      return jsonDecode(raw) as T?;
    }
    return raw as T?;
  }

  Future<void> put(String key, dynamic value) async {
    await _box.put(key, value);
  }

  /// Generic set (JSON encodes all non-primitive values)
  Future<void> set(String key, dynamic value) async {
    final encoded = value is String || value is num || value is bool
        ? value
        : jsonEncode(value);
    await _box.put(key, encoded);
  }

  Future<void> remove(String key) async {
    await _box.delete(key);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  /// 🔹 Leaderboard helpers
  Future<void> cacheLeaderboard(List<LeaderboardEntry> entries) async {
    final encoded = entries.map((e) => e.toJson()).toList();
    await _box.put(_boxName, encoded);
  }

  Future<List<LeaderboardEntry>> getCachedLeaderboard() async {
    final raw = _box.get(_boxName);
    if (raw is List) {
      return raw
          .map((e) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  /// ✅ Save QuestionModel list to Hive (as JSON strings)
  Future<void> saveQuestionCache(String key, List<QuestionModel> questions) async {
    final encoded = questions.map((q) => json.encode(q.toJson())).toList();
    await _box.put(key, json.encode(encoded));
  }

  /// ✅ Load QuestionModel list from Hive
  Future<List<QuestionModel>> loadQuestionCache(String key) async {
    final raw = _box.get(key);
    if (raw == null) return [];

    try {
      final List<dynamic> decoded = json.decode(raw);
      return decoded
          .map((e) => QuestionModel.fromJson(json.decode(e)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// ✅ Clear cached question data for a given key
  Future<void> clearQuestionCache(String key) async {
    await _box.delete(key);
  }

  /// Saves question from admin question editor
  Future<void> saveQuestions(List<QuestionModel> questions) async {
    final box = await Hive.openBox('questions');
    await box.put('all', questions.map((q) => q.toJson()).toList());
  }

  /// Retrieves questions from model
  Future<List<QuestionModel>> getQuestions() async {
    final box = await Hive.openBox('questions');
    final raw = box.get('all', defaultValue: []);
    if (raw is List) {
      return raw.map((q) => QuestionModel.fromJson(q)).toList();
    }
    return [];
  }

  /// Saves QR Code Camera scan history
  Future<void> saveScanHistory(List<ScanHistoryItem> items) async {
    final encoded = items.map((e) => e.toJson()).toList();
    await set('qr_scan_history', encoded);
  }

  /// Retrieves QR Cde Camera scan history
  Future<List<ScanHistoryItem>> loadScanHistory() async {
    final raw = await get<List<dynamic>>('qr_scan_history') ?? [];
    return raw.map((e) => ScanHistoryItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// Clears QR Code Camera scan history
  Future<void> clearScanHistory() async {
    await remove('qr_scan_history');
  }
}
