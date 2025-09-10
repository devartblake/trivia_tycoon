import 'package:flutter/material.dart';

enum SearchCategory {
  skills,
  questions,
  leaderboard,
  players,
  achievements,
  store,
  settings,
  help,
}

enum SearchResultType {
  skill,
  question,
  player,
  achievement,
  storeItem,
  settingPage,
  helpArticle,
  navigation,
}

class SearchResult {
  final String id;
  final String title;
  final String description;
  final SearchResultType type;
  final SearchCategory category;
  final String? subtitle;
  final String? imageUrl;
  final IconData? icon;
  final Color? color;
  final Map<String, dynamic>? metadata;
  final String? navigationRoute;
  final int relevanceScore;
  final DateTime? lastUpdated;

  SearchResult({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    this.subtitle,
    this.imageUrl,
    this.icon,
    this.color,
    this.metadata,
    this.navigationRoute,
    required this.relevanceScore,
    this.lastUpdated,
  });
}

class SearchFilter {
  final Set<SearchCategory> categories;
  final Set<SearchResultType> types;
  final bool includeUnlocked;
  final bool includeLocked;
  final DateTimeRange? dateRange;

  SearchFilter({
    this.categories = const {},
    this.types = const {},
    this.includeUnlocked = true,
    this.includeLocked = true,
    this.dateRange,
  });

  SearchFilter copyWith({
    Set<SearchCategory>? categories,
    Set<SearchResultType>? types,
    bool? includeUnlocked,
    bool? includeLocked,
    DateTimeRange? dateRange,
  }) {
    return SearchFilter(
      categories: categories ?? this.categories,
      types: types ?? this.types,
      includeUnlocked: includeUnlocked ?? this.includeUnlocked,
      includeLocked: includeLocked ?? this.includeLocked,
      dateRange: dateRange ?? this.dateRange,
    );
  }
}