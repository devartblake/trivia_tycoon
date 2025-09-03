import 'dart:convert';
import 'package:flutter/services.dart';

import 'api_service.dart';
import 'package:flutter/material.dart';
import '../../game/models/leaderboard_entry.dart';
import '../../game/services/leaderboard_service.dart';
import 'package:trivia_tycoon/core/services/storage/app_cache_service.dart';

class LeaderboardDataService {
  final ApiService apiService;
  late AppCacheService appCache;
  final Future<List<LeaderboardEntry>> Function()? assetLoader;

  LeaderboardDataService({required this.apiService, this.assetLoader});

  Future<List<LeaderboardEntry>> loadLeaderboard() async {
    // 1. Try loading from asset loader if provided (Riverpod-based)
    try {
      final jsonStr = await rootBundle.loadString('assets/data/leaderboard/leaderboard.json');
      debugPrint("✅ Loaded JSON content: ${jsonStr.substring(0, 100)}...");
      if (assetLoader != null) {
        final assetData = await assetLoader!();
        if (assetData.isNotEmpty) return assetData;
      }
    } catch (e) {
      debugPrint("📁 Asset loader failed: $e");
    }

    // 2. Try API
    try {
      final remote = await LeaderboardService(apiService: apiService).fetchLeaderboard();
      await appCache.cacheLeaderboard(remote);
      return remote;
    } catch (e) {
      debugPrint("🌐 API load failed: $e");
    }

    // 3. Try local cache
    try {
      final cached = await appCache.getCachedLeaderboard();
      if (cached.isNotEmpty) return cached;
    } catch (e) {
      debugPrint("💾 Hive cache failed: $e");
    }

    return [];
  }

  List<LeaderboardEntry> _parseLeaderboardJson(String jsonStr) {
    final List<dynamic> decoded = json.decode(jsonStr);
    return decoded.map((e) => LeaderboardEntry.fromJson(e)).toList();
  }

  Future<void> submitScore(String playerName, int score) async {
    try {
      await LeaderboardService(
        apiService: apiService,
      ).submitScore(playerName, score);
    } catch (e) {
      debugPrint('⚠️ Failed to submit score: $e');
    }
  }
}
