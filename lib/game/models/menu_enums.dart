/// Menu-related enumerations

/// Age group for theme customization
enum AgeGroup {
  kids,
  teens,
  adults,
  general,
}

extension AgeGroupExtension on AgeGroup {
  String get value {
    switch (this) {
      case AgeGroup.kids:
        return 'kids';
      case AgeGroup.teens:
        return 'teens';
      case AgeGroup.adults:
        return 'adults';
      case AgeGroup.general:
        return 'general';
    }
  }

  static AgeGroup fromString(String value) {
    switch (value.toLowerCase()) {
      case 'kids':
        return AgeGroup.kids;
      case 'teens':
        return AgeGroup.teens;
      case 'adults':
        return AgeGroup.adults;
      default:
        return AgeGroup.general;
    }
  }
}

/// Match status types
enum MatchStatus {
  yourTurn,
  waiting,
  similarStats,
  fastPlayer,
  finished,
}

extension MatchStatusExtension on MatchStatus {
  String get displayText {
    switch (this) {
      case MatchStatus.yourTurn:
        return 'Your turn';
      case MatchStatus.waiting:
        return 'Waiting...';
      case MatchStatus.similarStats:
        return '#SimilarStats';
      case MatchStatus.fastPlayer:
        return '#FastPlayer';
      case MatchStatus.finished:
        return 'Finished';
    }
  }

  String get value {
    switch (this) {
      case MatchStatus.yourTurn:
        return 'your_turn';
      case MatchStatus.waiting:
        return 'waiting';
      case MatchStatus.similarStats:
        return 'similar_stats';
      case MatchStatus.fastPlayer:
        return 'fast_player';
      case MatchStatus.finished:
        return 'finished';
    }
  }

  static MatchStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'your_turn':
        return MatchStatus.yourTurn;
      case 'waiting':
        return MatchStatus.waiting;
      case 'similar_stats':
        return MatchStatus.similarStats;
      case 'fast_player':
        return MatchStatus.fastPlayer;
      case 'finished':
        return MatchStatus.finished;
      default:
        return MatchStatus.waiting;
    }
  }
}

/// Match tab types
enum MatchTab {
  classic,
  live,
}

extension MatchTabExtension on MatchTab {
  String get displayText {
    switch (this) {
      case MatchTab.classic:
        return 'Classic';
      case MatchTab.live:
        return 'Live';
    }
  }
}

/// Match filter types
enum MatchFilter {
  all,
  yourTurn,
  suggestions,
}

extension MatchFilterExtension on MatchFilter {
  String get displayText {
    switch (this) {
      case MatchFilter.all:
        return 'All';
      case MatchFilter.yourTurn:
        return 'Your turn';
      case MatchFilter.suggestions:
        return 'Suggestions';
    }
  }
}

/// Layout mode for responsive design
enum LayoutMode {
  mobile,
  tablet,
  desktop,
}

extension LayoutModeExtension on LayoutMode {
  bool get isMobile => this == LayoutMode.mobile;
  bool get isTablet => this == LayoutMode.tablet;
  bool get isDesktop => this == LayoutMode.desktop;
}
