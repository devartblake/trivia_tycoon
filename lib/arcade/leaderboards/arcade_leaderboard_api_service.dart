import '../../core/networking/synaptix_api_client.dart';

class ArcadeLeaderboardApiService {
  final SynaptixApiClient _apiClient;

  const ArcadeLeaderboardApiService(this._apiClient);

  Future<void> submitScore({
    required String gameId,
    required String difficulty,
    required int score,
    required int durationMs,
  }) async {
    final body = {
      'gameId': gameId,
      'difficulty': difficulty,
      'score': score,
      'durationMs': durationMs,
    };

    await _apiClient.postJson('/leaderboards/arcade/submit', body: body);
  }

  Future<ArcadeLeaderboardPage> fetchLeaderboard({
    required String gameId,
    required String difficulty,
    int page = 1,
    int pageSize = 50,
  }) async {
    final json = await _apiClient.getJson(
      '/leaderboards/arcade/$gameId/$difficulty',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
      },
    );

    return ArcadeLeaderboardPage.fromJson(json);
  }
}

class ArcadeLeaderboardEntry {
  final String playerId;
  final String username;
  final int score;
  final int durationMs;
  final DateTime achievedAtUtc;
  final int rank;

  const ArcadeLeaderboardEntry({
    required this.playerId,
    required this.username,
    required this.score,
    required this.durationMs,
    required this.achievedAtUtc,
    required this.rank,
  });

  factory ArcadeLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return ArcadeLeaderboardEntry(
      playerId: json['playerId'] as String? ?? '',
      username: json['username'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      achievedAtUtc:
          DateTime.tryParse(json['achievedAtUtc'] as String? ?? '') ??
              DateTime.now().toUtc(),
      rank: (json['rank'] as num?)?.toInt() ?? 0,
    );
  }
}

class ArcadeLeaderboardPage {
  final String gameId;
  final String difficulty;
  final int page;
  final int pageSize;
  final int total;
  final List<ArcadeLeaderboardEntry> items;
  final int? myRank;
  final int? myScore;

  const ArcadeLeaderboardPage({
    required this.gameId,
    required this.difficulty,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
    this.myRank,
    this.myScore,
  });

  factory ArcadeLeaderboardPage.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((item) => ArcadeLeaderboardEntry.fromJson(item))
        .toList();

    return ArcadeLeaderboardPage(
      gameId: json['gameId'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 50,
      total: (json['total'] as num?)?.toInt() ?? 0,
      items: itemsList,
      myRank: (json['myRank'] as num?)?.toInt(),
      myScore: (json['myScore'] as num?)?.toInt(),
    );
  }
}
