import 'package:flutter/material.dart';

enum MissionType { daily, weekly,science, streak, explorer, wildcard }
enum MissionStatus { active, completed, expired, swapped }

class Mission {
  final String id;
  final String title;
  final String? description;
  final int progress;
  final int total;
  final int reward;
  final IconData icon;
  final String badge;
  final MissionType type;
  final MissionStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic>? metadata;

  Mission({
    required this.id,
    required this.title,
    this.description,
    required this.progress,
    required this.total,
    required this.reward,
    required this.icon,
    required this.badge,
    required this.type,
    this.status = MissionStatus.active,
    required this.createdAt,
    this.completedAt,
    this.expiresAt,
    this.metadata,
  });

  bool get isCompleted => progress >= total;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  double get progressPercentage => (progress / total).clamp(0.0, 1.0);

  // Factory constructor for creating from Supabase JSON
  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      progress: json['progress'] as int,
      total: json['total'] as int,
      reward: json['reward'] as int,
      icon: _iconFromString(json['icon_name'] as String),
      badge: json['badge'] as String,
      type: MissionType.values.byName(json['type'] as String),
      status: MissionStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'progress': progress,
      'total': total,
      'reward': reward,
      'icon_name': _iconToString(icon),
      'badge': badge,
      'type': type.name,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Create a copy with updated fields
  Mission copyWith({
    String? id,
    String? title,
    String? description,
    int? progress,
    int? total,
    int? reward,
    IconData? icon,
    String? badge,
    MissionType? type,
    MissionStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) {
    return Mission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      progress: progress ?? this.progress,
      total: total ?? this.total,
      reward: reward ?? this.reward,
      icon: icon ?? this.icon,
      badge: badge ?? this.badge,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods for icon conversion
  static IconData _iconFromString(String iconName) {
    switch (iconName) {
      case 'science':
        return Icons.science;
      case 'flash_on':
        return Icons.flash_on;
      case 'explore':
        return Icons.explore;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'star':
        return Icons.star;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'school':
        return Icons.school;
      case 'timeline':
        return Icons.timeline;
      default:
        return Icons.assignment;
    }
  }

  static String _iconToString(IconData icon) {
    if (icon == Icons.science) return 'science';
    if (icon == Icons.flash_on) return 'flash_on';
    if (icon == Icons.explore) return 'explore';
    if (icon == Icons.calendar_today) return 'calendar_today';
    if (icon == Icons.star) return 'star';
    if (icon == Icons.fitness_center) return 'fitness_center';
    if (icon == Icons.school) return 'school';
    if (icon == Icons.timeline) return 'timeline';
    return 'assignment';
  }
}

// User Mission Progress Model (for tracking user-specific data)
class UserMission {
  final String id;
  final String userId;
  final String missionId;
  final Mission mission; // The actual mission data
  final int progress;
  final MissionStatus status;
  final DateTime assignedAt;
  final DateTime? completedAt;
  final int swapCount; // Track how many times user has swapped

  UserMission({
    required this.id,
    required this.userId,
    required this.missionId,
    required this.mission,
    required this.progress,
    required this.status,
    required this.assignedAt,
    this.completedAt,
    this.swapCount = 0,
  });

  factory UserMission.fromJson(Map<String, dynamic> json) {
    return UserMission(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      missionId: json['mission_id'] as String,
      mission: Mission.fromJson(json['mission'] as Map<String, dynamic>),
      progress: json['progress'] as int,
      status: MissionStatus.values.byName(json['status'] as String),
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      swapCount: json['swap_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mission_id': missionId,
      'progress': progress,
      'status': status.name,
      'assigned_at': assignedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'swap_count': swapCount,
    };
  }

  UserMission copyWith({
    String? id,
    String? userId,
    String? missionId,
    Mission? mission,
    int? progress,
    MissionStatus? status,
    DateTime? assignedAt,
    DateTime? completedAt,
    int? swapCount,
  }) {
    return UserMission(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      missionId: missionId ?? this.missionId,
      mission: mission ?? this.mission,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
      completedAt: completedAt ?? this.completedAt,
      swapCount: swapCount ?? this.swapCount,
    );
  }

  bool get isCompleted => progress >= mission.total;
  bool get canSwap => swapCount < 3 && status == MissionStatus.active; // Max 3 swaps per mission
  double get progressPercentage => (progress / mission.total).clamp(0.0, 1.0);
}
