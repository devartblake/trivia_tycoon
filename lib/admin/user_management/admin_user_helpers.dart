import 'package:flutter/material.dart';

import '../../game/models/admin_user_model.dart';

// ---------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------

Color getStatusColor(UserStatus status) {
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

String getStatusText(UserStatus status) {
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

// ---------------------------------------------------------------------------
// Role
// ---------------------------------------------------------------------------

Color getRoleColor(UserRole role) {
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

String getRoleText(UserRole role) {
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

IconData getRoleIcon(UserRole role) {
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

// ---------------------------------------------------------------------------
// Age group
// ---------------------------------------------------------------------------

Color getAgeGroupColor(AgeGroup ageGroup) {
  switch (ageGroup) {
    case AgeGroup.child:
      return const Color(0xFF8B5CF6);
    case AgeGroup.teen:
      return const Color(0xFF3B82F6);
    case AgeGroup.adult:
      return const Color(0xFF10B981);
    case AgeGroup.senior:
      return const Color(0xFFF59E0B);
  }
}

String getAgeGroupText(AgeGroup ageGroup) {
  switch (ageGroup) {
    case AgeGroup.child:
      return 'Child (6-12)';
    case AgeGroup.teen:
      return 'Teen (13-17)';
    case AgeGroup.adult:
      return 'Adult (18-64)';
    case AgeGroup.senior:
      return 'Senior (65+)';
  }
}

// ---------------------------------------------------------------------------
// Date formatting
// ---------------------------------------------------------------------------

String formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

String formatTimeAgo(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  } else {
    return formatDate(date);
  }
}
