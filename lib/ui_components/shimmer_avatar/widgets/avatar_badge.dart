import 'package:flutter/material.dart';
import '../models/avatar_enums.dart';

/// Modern avatar badge with gradients and shadows
class AvatarBadge extends StatelessWidget {
  final AvatarBadgeType badgeType;
  final String? badgeText;
  final int? notificationCount;
  final double avatarRadius;

  const AvatarBadge({
    super.key,
    required this.badgeType,
    required this.avatarRadius,
    this.badgeText,
    this.notificationCount,
  });

  @override
  Widget build(BuildContext context) {
    if (badgeType == AvatarBadgeType.none) {
      return const SizedBox.shrink();
    }

    final gradientColors = badgeType.getGradientColors();
    final minSize = avatarRadius * 0.4;

    Widget? badgeContent;

    switch (badgeType) {
      case AvatarBadgeType.level:
        badgeContent = Text(
          badgeText ?? 'LV',
          style: TextStyle(
            color: Colors.white,
            fontSize: avatarRadius * 0.2,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        );
        break;
      case AvatarBadgeType.notification:
        final count = notificationCount ?? 0;
        final displayText = count > 99 ? '99+' : '$count';
        badgeContent = Text(
          displayText,
          style: TextStyle(
            color: Colors.white,
            fontSize: avatarRadius * 0.18,
            fontWeight: FontWeight.bold,
          ),
        );
        break;
      case AvatarBadgeType.premium:
        badgeContent = Icon(
          Icons.star_rounded,
          size: avatarRadius * 0.25,
          color: Colors.white,
        );
        break;
      case AvatarBadgeType.none:
        return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(avatarRadius * 0.08),
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: gradientColors.last.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: badgeContent),
    );
  }
}
