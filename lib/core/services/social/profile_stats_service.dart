import 'dart:async';
import 'package:flutter/foundation.dart';

enum GameResult {
  win,
  loss,
  draw;

  String get displayName {
    switch (this) {
      case GameResult.win:
        return 'Win';
      case GameResult.loss:
        return 'Loss';
      case GameResult.draw:
        return 'Draw';
    }
  }
}

class GameMatch {
  final String id;
  final String userId;
  final String category;
  final String? opponentId;
  final String? opponentName;
  final int score;
  final int opponentScore;
  final GameResult result;
  final int questionsAnswered;
  final int correctAnswers;
  final Duration timeTaken;
  final DateTime playedAt;
  final String difficulty;

  const GameMatch({
    required this.id,
    required this.userId,
    required this.category,
    this.opponentId,
    this.opponentName,
    required this.score,
    this.opponentScore = 0,
    required this.result,
    required this.questionsAnswered,
    required this.correctAnswers,
    required this.timeTaken,
    required this.playedAt,
    this.difficulty = 'Medium',
  });

  double get accuracy => questionsAnswered > 0
      ? (correctAnswers / questionsAnswered) * 100
      : 0.0;

  int get pointsEarned {
    switch (result) {
      case GameResult.win:
        return score + 50; // Bonus for winning
      case GameResult.loss:
        return (score * 0.7).round(); // 70% of score
      case GameResult.draw:
        return score;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      if (opponentId != null) 'opponentId': opponentId,
      if (opponentName != null) 'opponentName': opponentName,
      'score': score,
      'opponentScore': opponentScore,
      'result': result.name,
      'questionsAnswered': questionsAnswered,
      'correctAnswers': correctAnswers,
      'timeTaken': timeTaken.inSeconds,
      'playedAt': playedAt.toIso8601String(),
      'difficulty': difficulty,
    };
  }

  factory GameMatch.fromJson(Map<String, dynamic> json) {
    return GameMatch(
      id: json['id'] as String,
      userId: json['userId'] as String,
      category: json['category'] as String,
      opponentId: json['opponentId'] as String?,
      opponentName: json['opponentName'] as String?,
      score: json['score'] as int,
      opponentScore: json['opponentScore'] as int? ?? 0,
      result: GameResult.values.byName(json['result'] as String),
      questionsAnswered: json['questionsAnswered'] as int,
      correctAnswers: json['correctAnswers'] as int,
      timeTaken: Duration(seconds: json['timeTaken'] as int),
      playedAt: DateTime.parse(json['playedAt'] as String),
      difficulty: json['difficulty'] as String? ?? 'Medium',
    );
  }
}

class CategoryStats {
  final String category;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final int totalScore;
  final int highestScore;
  final double averageAccuracy;

  const CategoryStats({
    required this.category,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.totalScore = 0,
    this.highestScore = 0,
    this.averageAccuracy = 0.0,
  });

  double get winRate => gamesPlayed > 0 ? (wins / gamesPlayed) * 100 : 0.0;
  double get averageScore => gamesPlayed > 0 ? totalScore / gamesPlayed : 0.0;

  CategoryStats copyWith({
    String? category,
    int? gamesPlayed,
    int? wins,
    int? losses,
    int? draws,
    int? totalScore,
    int? highestScore,
    double? averageAccuracy,
  }) {
    return CategoryStats(
      category: category ?? this.category,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      totalScore: totalScore ?? this.totalScore,
      highestScore: highestScore ?? this.highestScore,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
    );
  }
}

class StreakInfo {
  final int currentStreak;
  final int longestStreak;
  final int currentWinStreak;
  final int longestWinStreak;
  final DateTime? lastPlayedDate;
  final DateTime? streakStartDate;

  const StreakInfo({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.currentWinStreak = 0,
    this.longestWinStreak = 0,
    this.lastPlayedDate,
    this.streakStartDate,
  });

  bool get isStreakActive {
    if (lastPlayedDate == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastPlayedDate!);
    return difference.inHours < 48; // Grace period of 48 hours
  }

  StreakInfo copyWith({
    int? currentStreak,
    int? longestStreak,
    int? currentWinStreak,
    int? longestWinStreak,
    DateTime? lastPlayedDate,
    DateTime? streakStartDate,
  }) {
    return StreakInfo(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      longestWinStreak: longestWinStreak ?? this.longestWinStreak,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      streakStartDate: streakStartDate ?? this.streakStartDate,
    );
  }
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int progress;
  final int target;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String category;
  final int coinReward;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.progress = 0,
    required this.target,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.category,
    this.coinReward = 0,
  });

  double get progressPercentage => target > 0 ? (progress / target) * 100 : 0.0;
  bool get isCompleted => progress >= target;

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    int? progress,
    int? target,
    bool? isUnlocked,
    DateTime? unlockedAt,
    String? category,
    int? coinReward,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      category: category ?? this.category,
      coinReward: coinReward ?? this.coinReward,
    );
  }
}

class UserStats {
  final String userId;
  final int totalGames;
  final int totalWins;
  final int totalLosses;
  final int totalDraws;
  final int totalPoints;
  final int level;
  final int experiencePoints;
  final Map<String, CategoryStats> categoryStats;
  final StreakInfo streaks;
  final List<Achievement> achievements;
  final DateTime firstGameDate;
  final DateTime lastUpdated;

  const UserStats({
    required this.userId,
    this.totalGames = 0,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.totalDraws = 0,
    this.totalPoints = 0,
    this.level = 1,
    this.experiencePoints = 0,
    this.categoryStats = const {},
    this.streaks = const StreakInfo(),
    this.achievements = const [],
    required this.firstGameDate,
    required this.lastUpdated,
  });

  double get winRate => totalGames > 0 ? (totalWins / totalGames) * 100 : 0.0;
  double get averageScore => totalGames > 0 ? totalPoints / totalGames : 0.0;
  int get achievementCount => achievements.where((a) => a.isUnlocked).length;
  int get experienceToNextLevel => (level * 1000);
  double get levelProgress => (experiencePoints % 1000) / 10.0; // 0-100%

  CategoryStats? getBestCategory() {
    if (categoryStats.isEmpty) return null;
    return categoryStats.values.reduce((a, b) =>
    a.winRate > b.winRate ? a : b);
  }
}

class ProfileStatsService extends ChangeNotifier {
  static final ProfileStatsService _instance = ProfileStatsService._internal();
  factory ProfileStatsService() => _instance;
  ProfileStatsService._internal();

  // Storage
  final Map<String, List<GameMatch>> _userMatches = {};
  final Map<String, UserStats> _userStats = {};
  final Map<String, List<Achievement>> _userAchievements = {};

  // Streams
  final Map<String, StreamController<UserStats>> _statsStreams = {};

  // Predefined achievements
  late List<Achievement> _achievementTemplates;

  void initialize() {
    _initializeAchievements();
    _loadMockData();
    debugPrint('ProfileStatsService initialized');
  }

  void dispose() {
    for (final controller in _statsStreams.values) {
      controller.close();
    }
    _statsStreams.clear();
    super.dispose();
  }

  // ============ Record Match ============

  Future<void> recordMatch(GameMatch match) async {
    _userMatches[match.userId] ??= [];
    _userMatches[match.userId]!.add(match);

    // Update stats
    await _updateUserStats(match.userId);

    // Check achievements
    await _checkAchievements(match.userId);

    debugPrint('Match recorded for user ${match.userId}: ${match.result.displayName}');
    _broadcastStatsUpdate(match.userId);
    notifyListeners();
  }

  Future<void> recordMultipleMatches(List<GameMatch> matches) async {
    for (final match in matches) {
      _userMatches[match.userId] ??= [];
      _userMatches[match.userId]!.add(match);
    }

    // Update stats for all affected users
    final userIds = matches.map((m) => m.userId).toSet();
    for (final userId in userIds) {
      await _updateUserStats(userId);
      await _checkAchievements(userId);
      _broadcastStatsUpdate(userId);
    }

    notifyListeners();
  }

  // ============ Stats Calculation ============

  Future<void> _updateUserStats(String userId) async {
    final matches = _userMatches[userId] ?? [];
    if (matches.isEmpty) {
      return;
    }

    // Basic stats
    final totalGames = matches.length;
    final totalWins = matches.where((m) => m.result == GameResult.win).length;
    final totalLosses = matches.where((m) => m.result == GameResult.loss).length;
    final totalDraws = matches.where((m) => m.result == GameResult.draw).length;
    final totalPoints = matches.fold<int>(0, (sum, m) => sum + m.pointsEarned);

    // Category stats
    final categoryStats = <String, CategoryStats>{};
    final categories = matches.map((m) => m.category).toSet();

    for (final category in categories) {
      final categoryMatches = matches.where((m) => m.category == category).toList();
      final wins = categoryMatches.where((m) => m.result == GameResult.win).length;
      final losses = categoryMatches.where((m) => m.result == GameResult.loss).length;
      final draws = categoryMatches.where((m) => m.result == GameResult.draw).length;
      final totalScore = categoryMatches.fold<int>(0, (sum, m) => sum + m.score);
      final highestScore = categoryMatches.fold<int>(0, (max, m) => m.score > max ? m.score : max);
      final avgAccuracy = categoryMatches.isEmpty ? 0.0 :
      categoryMatches.fold<double>(0, (sum, m) => sum + m.accuracy) / categoryMatches.length;

      categoryStats[category] = CategoryStats(
        category: category,
        gamesPlayed: categoryMatches.length,
        wins: wins,
        losses: losses,
        draws: draws,
        totalScore: totalScore,
        highestScore: highestScore,
        averageAccuracy: avgAccuracy,
      );
    }

    // Streak calculation
    final streaks = _calculateStreaks(matches);

    // Level and XP
    final xp = totalPoints;
    final level = (xp / 1000).floor() + 1;

    // Get achievements
    final achievements = _userAchievements[userId] ?? List.from(_achievementTemplates);

    _userStats[userId] = UserStats(
      userId: userId,
      totalGames: totalGames,
      totalWins: totalWins,
      totalLosses: totalLosses,
      totalDraws: totalDraws,
      totalPoints: totalPoints,
      level: level,
      experiencePoints: xp,
      categoryStats: categoryStats,
      streaks: streaks,
      achievements: achievements,
      firstGameDate: matches.first.playedAt,
      lastUpdated: DateTime.now(),
    );
  }

  StreakInfo _calculateStreaks(List<GameMatch> matches) {
    if (matches.isEmpty) return const StreakInfo();

    // Sort matches by date
    final sortedMatches = List<GameMatch>.from(matches)
      ..sort((a, b) => a.playedAt.compareTo(b.playedAt));

    int currentStreak = 0;
    int longestStreak = 0;
    int currentWinStreak = 0;
    int longestWinStreak = 0;
    DateTime? lastDate;
    DateTime? streakStartDate;

    for (final match in sortedMatches) {
      final matchDate = DateTime(
        match.playedAt.year,
        match.playedAt.month,
        match.playedAt.day,
      );

      if (lastDate == null) {
        currentStreak = 1;
        streakStartDate = matchDate;
      } else {
        final dayDifference = matchDate.difference(lastDate).inDays;

        if (dayDifference == 1) {
          currentStreak++;
        } else if (dayDifference > 1) {
          currentStreak = 1;
          streakStartDate = matchDate;
        }
      }

      longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;

      // Win streak
      if (match.result == GameResult.win) {
        currentWinStreak++;
        longestWinStreak = currentWinStreak > longestWinStreak
            ? currentWinStreak
            : longestWinStreak;
      } else {
        currentWinStreak = 0;
      }

      lastDate = matchDate;
    }

    return StreakInfo(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      currentWinStreak: currentWinStreak,
      longestWinStreak: longestWinStreak,
      lastPlayedDate: sortedMatches.last.playedAt,
      streakStartDate: streakStartDate,
    );
  }

  // ============ Achievements ============

  void _initializeAchievements() {
    _achievementTemplates = [
      const Achievement(
        id: 'first_win',
        name: 'First Victory',
        description: 'Win your first game',
        icon: '⭐',
        target: 1,
        category: 'Milestones',
        coinReward: 50,
      ),
      const Achievement(
        id: 'win_10',
        name: 'Rising Star',
        description: 'Win 10 games',
        icon: '🌟',
        target: 10,
        category: 'Milestones',
        coinReward: 100,
      ),
      const Achievement(
        id: 'win_50',
        name: 'Champion',
        description: 'Win 50 games',
        icon: '🏆',
        target: 50,
        category: 'Milestones',
        coinReward: 500,
      ),
      const Achievement(
        id: 'win_100',
        name: 'Legend',
        description: 'Win 100 games',
        icon: '👑',
        target: 100,
        category: 'Milestones',
        coinReward: 1000,
      ),
      const Achievement(
        id: 'streak_7',
        name: 'Week Warrior',
        description: 'Play for 7 days in a row',
        icon: '🔥',
        target: 7,
        category: 'Streaks',
        coinReward: 200,
      ),
      const Achievement(
        id: 'streak_30',
        name: 'Streak Master',
        description: 'Play for 30 days in a row',
        icon: '💪',
        target: 30,
        category: 'Streaks',
        coinReward: 1000,
      ),
      const Achievement(
        id: 'perfect_game',
        name: 'Perfectionist',
        description: 'Get 100% accuracy in a game',
        icon: '💯',
        target: 1,
        category: 'Performance',
        coinReward: 150,
      ),
      const Achievement(
        id: 'speed_demon',
        name: 'Speed Demon',
        description: 'Complete 10 questions in under 30 seconds',
        icon: '⚡',
        target: 1,
        category: 'Performance',
        coinReward: 200,
      ),
      const Achievement(
        id: 'brain_box',
        name: 'Brain Box',
        description: 'Score 1000+ in a single game',
        icon: '🧠',
        target: 1,
        category: 'Performance',
        coinReward: 250,
      ),
      const Achievement(
        id: 'social_butterfly',
        name: 'Social Butterfly',
        description: 'Play with 10 different opponents',
        icon: '🦋',
        target: 10,
        category: 'Social',
        coinReward: 300,
      ),
      const Achievement(
        id: 'category_master_science',
        name: 'Science Master',
        description: 'Win 20 Science games',
        icon: '🔬',
        target: 20,
        category: 'Categories',
        coinReward: 400,
      ),
      const Achievement(
        id: 'category_master_history',
        name: 'History Master',
        description: 'Win 20 History games',
        icon: '📚',
        target: 20,
        category: 'Categories',
        coinReward: 400,
      ),
      const Achievement(
        id: 'all_rounder',
        name: 'All-Rounder',
        description: 'Win at least 5 games in each category',
        icon: '🌈',
        target: 1,
        category: 'Categories',
        coinReward: 500,
      ),
    ];
  }

  Future<void> _checkAchievements(String userId) async {
    final stats = _userStats[userId];
    if (stats == null) return;

    final matches = _userMatches[userId] ?? [];
    final achievements = _userAchievements[userId] ??
        List<Achievement>.from(_achievementTemplates);

    bool hasNewAchievement = false;

    for (int i = 0; i < achievements.length; i++) {
      if (achievements[i].isUnlocked) continue;

      int progress = 0;

      switch (achievements[i].id) {
        case 'first_win':
        case 'win_10':
        case 'win_50':
        case 'win_100':
          progress = stats.totalWins;
          break;
        case 'streak_7':
        case 'streak_30':
          progress = stats.streaks.longestStreak;
          break;
        case 'perfect_game':
          progress = matches.any((m) => m.accuracy == 100.0) ? 1 : 0;
          break;
        case 'speed_demon':
          progress = matches.any((m) =>
          m.questionsAnswered >= 10 &&
              m.timeTaken.inSeconds <= 30) ? 1 : 0;
          break;
        case 'brain_box':
          progress = matches.any((m) => m.score >= 1000) ? 1 : 0;
          break;
        case 'social_butterfly':
          progress = matches.map((m) => m.opponentId).toSet().length;
          break;
        case 'category_master_science':
          progress = matches.where((m) =>
          m.category == 'Science' && m.result == GameResult.win).length;
          break;
        case 'category_master_history':
          progress = matches.where((m) =>
          m.category == 'History' && m.result == GameResult.win).length;
          break;
        case 'all_rounder':
          final categories = ['Science', 'History', 'Sports', 'Movies', 'Music'];
          progress = categories.every((cat) =>
          matches.where((m) =>
          m.category == cat &&
              m.result == GameResult.win).length >= 5) ? 1 : 0;
          break;
      }

      achievements[i] = achievements[i].copyWith(progress: progress);

      if (progress >= achievements[i].target && !achievements[i].isUnlocked) {
        achievements[i] = achievements[i].copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        hasNewAchievement = true;
        debugPrint('🎉 Achievement unlocked: ${achievements[i].name}');
      }
    }

    _userAchievements[userId] = achievements;

    if (hasNewAchievement) {
      // Trigger notification or animation
      notifyListeners();
    }
  }

  List<Achievement> getNewlyUnlockedAchievements(String userId) {
    final achievements = _userAchievements[userId] ?? [];
    final now = DateTime.now();

    return achievements.where((a) =>
    a.isUnlocked &&
        a.unlockedAt != null &&
        now.difference(a.unlockedAt!).inMinutes < 5).toList();
  }

  // ============ Query Methods ============

  UserStats? getUserStats(String userId) {
    return _userStats[userId];
  }

  List<GameMatch> getRecentMatches(String userId, {int limit = 10}) {
    final matches = _userMatches[userId] ?? [];
    return matches.reversed.take(limit).toList();
  }

  List<GameMatch> getMatchesByCategory(String userId, String category) {
    final matches = _userMatches[userId] ?? [];
    return matches.where((m) => m.category == category).toList();
  }

  CategoryStats? getCategoryStats(String userId, String category) {
    final stats = _userStats[userId];
    return stats?.categoryStats[category];
  }

  List<Achievement> getAchievements(String userId) {
    return _userAchievements[userId] ?? _achievementTemplates;
  }

  List<Achievement> getUnlockedAchievements(String userId) {
    final achievements = _userAchievements[userId] ?? [];
    return achievements.where((a) => a.isUnlocked).toList();
  }

  List<Achievement> getLockedAchievements(String userId) {
    final achievements = _userAchievements[userId] ?? _achievementTemplates;
    return achievements.where((a) => !a.isUnlocked).toList();
  }

  // ============ Leaderboard ============

  List<MapEntry<String, UserStats>> getGlobalLeaderboard({int limit = 100}) {
    final entries = _userStats.entries.toList()
      ..sort((a, b) => b.value.totalPoints.compareTo(a.value.totalPoints));
    return entries.take(limit).toList();
  }

  List<MapEntry<String, CategoryStats>> getCategoryLeaderboard(
      String category, {
        int limit = 100,
      }) {
    final entries = <MapEntry<String, CategoryStats>>[];

    for (final entry in _userStats.entries) {
      final catStats = entry.value.categoryStats[category];
      if (catStats != null) {
        entries.add(MapEntry(entry.key, catStats));
      }
    }

    entries.sort((a, b) => b.value.totalScore.compareTo(a.value.totalScore));
    return entries.take(limit).toList();
  }

  int? getUserRank(String userId) {
    final leaderboard = getGlobalLeaderboard(limit: 10000);
    final index = leaderboard.indexWhere((entry) => entry.key == userId);
    return index == -1 ? null : index + 1;
  }

  // ============ Streams ============

  Stream<UserStats> watchUserStats(String userId) {
    _statsStreams[userId] ??= StreamController<UserStats>.broadcast();

    // Send initial data
    Future.delayed(Duration.zero, () {
      final stats = _userStats[userId];
      if (stats != null) {
        _broadcastStatsUpdate(userId);
      }
    });

    return _statsStreams[userId]!.stream;
  }

  void _broadcastStatsUpdate(String userId) {
    final stats = _userStats[userId];
    if (stats != null) {
      final controller = _statsStreams[userId];
      if (controller != null && !controller.isClosed) {
        controller.add(stats);
      }
    }
  }

  // ============ Mock Data ============

  void _loadMockData() {
    // Generate some mock matches for demo
    final mockUserId = 'current_user';
    final mockMatches = <GameMatch>[];
    final now = DateTime.now();

    for (int i = 0; i < 50; i++) {
      mockMatches.add(GameMatch(
        id: 'match_$i',
        userId: mockUserId,
        category: ['Science', 'History', 'Sports', 'Movies'][i % 4],
        score: 500 + (i * 20) + (i % 5) * 100,
        result: i % 3 == 0 ? GameResult.win : (i % 3 == 1 ? GameResult.loss : GameResult.draw),
        questionsAnswered: 10,
        correctAnswers: 7 + (i % 4),
        timeTaken: Duration(seconds: 120 + i),
        playedAt: now.subtract(Duration(days: 50 - i, hours: i % 24)),
        difficulty: ['Easy', 'Medium', 'Hard'][i % 3],
      ));
    }

    for (final match in mockMatches) {
      _userMatches[mockUserId] ??= [];
      _userMatches[mockUserId]!.add(match);
    }

    _updateUserStats(mockUserId);
    _checkAchievements(mockUserId);

    debugPrint('Loaded mock data: ${mockMatches.length} matches');
  }

  // ============ Analytics ============

  Map<String, dynamic> getDetailedAnalytics(String userId) {
    final stats = _userStats[userId];
    if (stats == null) return {};

    final matches = _userMatches[userId] ?? [];

    return {
      'overview': {
        'totalGames': stats.totalGames,
        'winRate': stats.winRate,
        'averageScore': stats.averageScore,
        'level': stats.level,
        'xpProgress': stats.levelProgress,
      },
      'streaks': {
        'current': stats.streaks.currentStreak,
        'longest': stats.streaks.longestStreak,
        'currentWinStreak': stats.streaks.currentWinStreak,
        'longestWinStreak': stats.streaks.longestWinStreak,
        'isActive': stats.streaks.isStreakActive,
      },
      'achievements': {
        'total': stats.achievements.length,
        'unlocked': stats.achievementCount,
        'progress': (stats.achievementCount / stats.achievements.length) * 100,
      },
      'categories': stats.categoryStats.map((key, value) => MapEntry(key, {
        'games': value.gamesPlayed,
        'winRate': value.winRate,
        'avgScore': value.averageScore,
      })),
      'recentPerformance': matches.take(10).map((m) => {
        'category': m.category,
        'result': m.result.name,
        'score': m.score,
        'accuracy': m.accuracy,
      }).toList(),
    };
  }
}