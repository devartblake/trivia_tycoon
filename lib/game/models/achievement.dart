/// Model for tracking player achievements
class Achievement {
  final String id;
  final String title;
  final String description;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.isUnlocked = false,
    DateTime? unlockedAt,
  }) : unlockedAt = isUnlocked ? (unlockedAt ?? DateTime.now()) : null;

  /// Unlock the achievement
  Achievement unlock() {
    return Achievement(
      id: id,
      title: title,
      description: description,
      isUnlocked: true,
      unlockedAt: unlockedAt ?? DateTime.now(),
    );
  }

  /// Creates a new Achievement instance with modified values
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  /// Convert Achievement to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  /// Convert JSON to Achievement object
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
    );
  }

  /// Equality operator override
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Achievement &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.isUnlocked == isUnlocked &&
        other.unlockedAt == unlockedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ description.hashCode ^ isUnlocked.hashCode ^ unlockedAt.hashCode;
  }
}
