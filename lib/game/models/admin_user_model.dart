import 'package:flutter/material.dart';
import 'menu_enums.dart';
export 'menu_enums.dart' show AgeGroup;

enum UserStatus { online, offline, away, busy }
enum UserRole { user, premium, moderator, admin }

class AdminUserModel {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final UserStatus status;
  final UserRole role;
  final AgeGroup ageGroup;
  final DateTime createdAt;
  final DateTime lastActive;
  final int totalGamesPlayed;
  final int totalPoints;
  final double winRate;
  final bool isVerified;
  final bool isBanned;
  final String? banReason;
  final Map<String, dynamic>? metadata;

  const AdminUserModel({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    required this.status,
    required this.role,
    required this.ageGroup,
    required this.createdAt,
    required this.lastActive,
    this.totalGamesPlayed = 0,
    this.totalPoints = 0,
    this.winRate = 0.0,
    this.isVerified = false,
    this.isBanned = false,
    this.banReason,
    this.metadata,
  });

  // Status helpers
  Color get statusColor {
    switch (status) {
      case UserStatus.online:
        return const Color(0xFF10B981);
      case UserStatus.offline:
        return const Color(0xFF6B7280);
      case UserStatus.away:
        return const Color(0xFFF59E0B);
      case UserStatus.busy:
        return const Color(0xFFEF4444);
    }
  }

  String get statusText {
    switch (status) {
      case UserStatus.online:
        return 'Online';
      case UserStatus.offline:
        return 'Offline';
      case UserStatus.away:
        return 'Away';
      case UserStatus.busy:
        return 'Busy';
    }
  }

  // Role helpers
  Color get roleColor {
    switch (role) {
      case UserRole.user:
        return const Color(0xFF6B7280);
      case UserRole.premium:
        return const Color(0xFFFFD700);
      case UserRole.moderator:
        return const Color(0xFF3B82F6);
      case UserRole.admin:
        return const Color(0xFFEF4444);
    }
  }

  String get roleText {
    switch (role) {
      case UserRole.user:
        return 'User';
      case UserRole.premium:
        return 'Premium';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.admin:
        return 'Admin';
    }
  }

  IconData get roleIcon {
    switch (role) {
      case UserRole.user:
        return Icons.person;
      case UserRole.premium:
        return Icons.stars;
      case UserRole.moderator:
        return Icons.shield;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  // Age group helpers
  String get ageGroupText {
    switch (ageGroup) {
      case AgeGroup.kids:
        return 'Kids (Under 13)';
      case AgeGroup.teens:
        return 'Teens (13-17)';
      case AgeGroup.adults:
        return 'Adults (18-24)';
      case AgeGroup.general:
        return 'General (25+)';
    }
  }

  Color get ageGroupColor {
    switch (ageGroup) {
      case AgeGroup.kids:
        return const Color(0xFF8B5CF6);
      case AgeGroup.teens:
        return const Color(0xFF3B82F6);
      case AgeGroup.adults:
        return const Color(0xFF10B981);
      case AgeGroup.general:
        return const Color(0xFFF59E0B);
    }
  }

  // Copy with method
  AdminUserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUrl,
    UserStatus? status,
    UserRole? role,
    AgeGroup? ageGroup,
    DateTime? createdAt,
    DateTime? lastActive,
    int? totalGamesPlayed,
    int? totalPoints,
    double? winRate,
    bool? isVerified,
    bool? isBanned,
    String? banReason,
    Map<String, dynamic>? metadata,
  }) {
    return AdminUserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      role: role ?? this.role,
      ageGroup: ageGroup ?? this.ageGroup,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalPoints: totalPoints ?? this.totalPoints,
      winRate: winRate ?? this.winRate,
      isVerified: isVerified ?? this.isVerified,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      metadata: metadata ?? this.metadata,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'status': status.name,
      'role': role.name,
      'ageGroup': ageGroup.name,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'totalGamesPlayed': totalGamesPlayed,
      'totalPoints': totalPoints,
      'winRate': winRate,
      'isVerified': isVerified,
      'isBanned': isBanned,
      'banReason': banReason,
      'metadata': metadata,
    };
  }

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      status: UserStatus.values.firstWhere(
            (e) => e.name == json['status'],
        orElse: () => UserStatus.offline,
      ),
      role: UserRole.values.firstWhere(
            (e) => e.name == json['role'],
        orElse: () => UserRole.user,
      ),
      ageGroup: AgeGroup.values.firstWhere(
            (e) => e.name == json['ageGroup'],
        orElse: () => AgeGroup.adults,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActive: DateTime.parse(json['lastActive'] as String),
      totalGamesPlayed: json['totalGamesPlayed'] as int? ?? 0,
      totalPoints: json['totalPoints'] as int? ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
      isVerified: json['isVerified'] as bool? ?? false,
      isBanned: json['isBanned'] as bool? ?? false,
      banReason: json['banReason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
