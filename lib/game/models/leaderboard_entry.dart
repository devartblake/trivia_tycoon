
/// Model representing a leaderboard entry
class LeaderboardEntry {
  final int userId;
  final String playerName;
  final int score;
  final int rank;
  final int tier;   // 1-10 (Bronze = 1, Tycoon Hall = 10)
  final int tierRank; // 1-100 within tier
  final bool isPromotionEligible;
  final bool isRewardEligible;
  final int wins;
  final String country;
  final String state;
  final String countryCode;  // ISO2/ISO3
  final int level;
  final String badges;
  final double xpProgress;
  final String timeframe; // e.g. "daily", "weekly", "global"
  final String avatar;
  final DateTime lastActive;
  final DateTime timestamp;
  final String gender;     // 'male', 'female', 'other'
  final String ageGroup;   // 'kids', 'teens', 'adults'
  final DateTime joinedDate;
  final int? streak;
  final double accuracy;
  final String favoriteCategory;
  final String title;
  final String status;
  final String device;
  final String language;
  final double sessionLength;
  final String lastQuestionCategory;
  final List<String> interests;
  final bool emailVerified;
  final String accountStatus; // active, suspended, etc.
  final String timezone;
  final List<String>? powerUps;
  final String lastDeviceType; // mobile, tablet, desktop
  final String preferredNotificationMethod; // push, email, sms, none
  final String subscriptionStatus; // free, premium, expired
  final double averageAnswerTime; // in seconds
  final bool isBot;
  final double accountAgeDays;
  final double engagementScore;

  LeaderboardEntry({
    required this.userId,
    required this.playerName,
    required this.score,
    required this.rank,
    required this.tier,
    required this.tierRank,
    required this.isPromotionEligible,
    required this.isRewardEligible,
    required this.wins,
    required this.country,
    required this.state,
    required this.countryCode,
    required this.level,
    required this.badges,
    required this.xpProgress,
    required this.timeframe,
    required this.avatar,
    required this.lastActive,
    required this.timestamp,
    required this.gender,
    required this.ageGroup,
    required this.joinedDate,
    required this.streak,
    required this.accuracy,
    required this.favoriteCategory,
    required this.title,
    required this.status,
    required this.device,
    required this.language,
    required this.sessionLength,
    required this.lastQuestionCategory,
    required this.interests,
    required this.emailVerified,
    required this.accountStatus,
    required this.timezone,
    required this.powerUps,
    required this.lastDeviceType,
    required this.preferredNotificationMethod,
    required this.subscriptionStatus,
    required this.averageAnswerTime,
    required this.isBot,
    required this.accountAgeDays,
    required this.engagementScore,
  });

  LeaderboardEntry copyWith({
    int? userId,
    String? playerName,
    int? score,
    int? rank,
    int? tier,
    int? tierRank,
    bool? isPromotionEligible,
    bool? isRewardEligible,
    int? wins,
    String? country,
    String? state,
    String? countryCode,
    int? level,
    String? badges,
    double? xpProgress,
    String? timeframe,
    String? avatar,
    DateTime? lastActive,
    DateTime? timestamp,
    String? gender,
    String? ageGroup,
    DateTime? joinedDate,
    int? streak,
    double? accuracy,
    String? favoriteCategory,
    String? title,
    String? status,
    String? device,
    String? language,
    double? sessionLength,
    String? lastQuestionCategory,
    List<String>? interests,
    bool? emailVerified,
    String? accountStatus,
    String? timezone,
    List<String>? powerUps,
    String? lastDeviceType,
    String? preferredNotificationMethod,
    String? subscriptionStatus,
    double? averageAnswerTime,
    bool? isBot,
    double? accountAgeDays,
    double? engagementScore,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      playerName: playerName ?? this.playerName,
      score: score ?? this.score,
      rank: rank ?? this.rank,
      tier: tier ?? this.tier,
      tierRank: tierRank ?? this.tierRank,
      isPromotionEligible: isPromotionEligible ?? this.isPromotionEligible,
      isRewardEligible: isRewardEligible ?? this.isRewardEligible,
      wins: wins ?? this.wins,
      country: country ?? this.country,
      state: state ?? this.state,
      countryCode: countryCode ?? this.countryCode,
      level: level ?? this.level,
      badges: badges ?? this.badges,
      xpProgress: xpProgress ?? this.xpProgress,
      timeframe: timeframe ?? this.timeframe,
      avatar: avatar ?? this.avatar,
      lastActive: lastActive ?? this.lastActive,
      timestamp: timestamp ?? this.timestamp,
      gender: gender ?? this.gender,
      ageGroup: ageGroup ?? this.ageGroup,
      joinedDate: joinedDate ?? this.joinedDate,
      streak: streak ?? this.streak,
      accuracy: accuracy ?? this.accuracy,
      favoriteCategory: favoriteCategory ?? this.favoriteCategory,
      title: title ?? this.title,
      status: status ?? this.status,
      device: device ?? this.device,
      language: language ?? this.language,
      sessionLength: sessionLength ?? this.sessionLength,
      lastQuestionCategory: lastQuestionCategory ?? this.lastQuestionCategory,
      interests: interests ?? this.interests,
      emailVerified: emailVerified ?? this.emailVerified,
      accountStatus: accountStatus ?? this.accountStatus,
      timezone: timezone ?? this.timezone,
      powerUps: powerUps ?? this.powerUps,
      lastDeviceType: lastDeviceType ?? this.lastDeviceType,
      preferredNotificationMethod: preferredNotificationMethod ?? this.preferredNotificationMethod,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      averageAnswerTime: averageAnswerTime ?? this.averageAnswerTime,
      isBot: isBot ?? this.isBot,
      accountAgeDays: accountAgeDays ?? this.accountAgeDays,
      engagementScore: engagementScore ?? this.engagementScore,
    );
  }

  /// Converts JSON to LeaderboardEntry object
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      playerName: json['playerName']?.toString() ?? 'Unknown',
      score: json['score'] ?? 0,
      rank: json['rank'] ?? 0,
      tier: json ['tier'] ?? 1,
      tierRank: json['tierRank'] ?? 0,
      isPromotionEligible: json['isPromotionEligible'] ?? false,
      isRewardEligible: json['isRewardEligible'] ?? false,
      wins: json['wins'] ?? 0,
      country: json['country']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      level: int.tryParse(json['level'].toString()) ?? 1,
      badges: json['badges']?.toString() ?? '',
      xpProgress: double.tryParse(json['xpProgress'].toString()) ?? 0.0,
      timeframe: json['timeframe']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      lastActive: DateTime.parse(json['last_active']),
      timestamp: DateTime.parse(json['timestamp']),
      gender: json['gender']?.toString() ?? '',
      ageGroup: json['ageGroup']?.toString() ?? '',
      joinedDate: DateTime.parse(json['joinedDate']),
      streak: json['streak'] ?? 0,
      accuracy: (json['accuracy']?? 0).toDouble() ?? 0.0,
      favoriteCategory: json['favoriteCategory'],
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      device: json['device']?.toString() ?? '',
      language: json['language']?.toString() ?? '',
      sessionLength: json['sessionLength'].toDouble() ?? 0.0,
      lastQuestionCategory: json['lastQuestionCategory'],
      interests: List<String>.from(json['interests'] ?? []),
      countryCode: json['countryCode']?.toString() ?? '',
      emailVerified: json['emailVerified'] ?? false,
      accountStatus: json['accountStatus'] ?? 'active',
      timezone: json['timezone'] ?? 'UTC',
      powerUps: List<String>.from(json['powerUps'] ?? []),
      lastDeviceType: json['lastDeviceType'] ?? '',
      preferredNotificationMethod: json['preferredNotificationMethod'] ?? 'push',
      subscriptionStatus: json['subscriptionStatus'] ?? 'free',
      averageAnswerTime: (json['averageAnswerTime'] ?? 0).toDouble(),
      isBot: json['isBot'] ?? false,
      accountAgeDays: (json['accountAgeDays'] ?? 0).toDouble(),
      engagementScore: (json['engagementScore'] ?? 0).toDouble(),
    );
  }

  /// Converts LeaderboardEntry object to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_Id': userId,
      'playerName': playerName,
      'score': score,
      'rank': rank,
      'tier': tier,
      'tierRank': tierRank,
      'isPromotionEligible': isPromotionEligible,
      'isRewardEligible': isRewardEligible,
      'wins': wins,
      'country': country,
      'state': state,
      'level': level,
      'badges': badges,
      'xpProgress': xpProgress,
      'timeframe': timeframe,
      'avatar': avatar,
      'lastActive': lastActive.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
      'gender': gender,
      'ageGroup': ageGroup,
      'joinedDate': joinedDate.toIso8601String(),
      'streak': streak,
      'accuracy': accuracy,
      'favoriteCategory': favoriteCategory,
      'title': title,
      'status': status,
      'device': device,
      'language': language,
      'sessionLength': sessionLength,
      'lastQuestionCategory': lastQuestionCategory,
      'interests': interests,
      'countryCode': countryCode,
      'emailVerified': emailVerified,
      'accountStatus': accountStatus,
      'timezone': timezone,
      'powerUps': powerUps,
      'lastDeviceType': lastDeviceType,
      'preferredNotificationMethod': preferredNotificationMethod,
      'subscriptionStatus': subscriptionStatus,
      'averageAnswerTime': averageAnswerTime,
      'isBot': isBot,
      'accountAgeDays': accountAgeDays,
      'engagementScore': engagementScore,
    };
  }
}
