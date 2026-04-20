/// Shimmer Avatar - Modern, modular avatar widget
///
/// A feature-rich avatar component with:
/// - Gradient borders and modern shadows
/// - Animated status indicators
/// - Badge support (level, notification, premium)
/// - Shimmer loading states
/// - Tap/long-press interactions
/// - Hero animations
/// - Custom overlays
///
/// Usage:
/// ```dart
/// import 'package:your_app/ui_components/shimmer_avatar/shimmer_avatar.dart';
///
/// ShimmerAvatar(
///   avatarPath: 'assets/avatar.png',
///   status: AvatarStatus.online,
///   badgeType: AvatarBadgeType.level,
///   badgeText: '42',
///   onTap: () => print('Avatar tapped!'),
/// )
/// ```

library shimmer_avatar;

// Main widget
export 'shimmer_avatar.dart';

// Models and enums
export 'models/avatar_enums.dart';

// Widgets (for advanced customization)
export 'widgets/avatar_content.dart';
export 'widgets/avatar_badge.dart';
export 'widgets/status_indicator.dart';
export 'widgets/avatar_overlay.dart';

// Utilities
export 'utils/avatar_helpers.dart';
