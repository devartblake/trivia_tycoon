import '../../core/theme/themes.dart';

/// Seasonal theme configuration from backend
class SeasonalTheme {
  final String id;
  final String name;
  final ThemeType themeType;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? description;
  final String? iconEmoji;

  SeasonalTheme({
    required this.id,
    required this.name,
    required this.themeType,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.description,
    this.iconEmoji,
  });

  factory SeasonalTheme.fromJson(Map<String, dynamic> json) {
    return SeasonalTheme(
      id: json['id'] as String,
      name: json['name'] as String,
      themeType: AppTheme.fromString(json['theme_type'] as String?),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isActive: json['is_active'] as bool? ?? false,
      description: json['description'] as String?,
      iconEmoji: json['icon_emoji'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'theme_type': themeType.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'description': description,
      'icon_emoji': iconEmoji,
    };
  }

  bool isCurrentlyActive() {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }
}
